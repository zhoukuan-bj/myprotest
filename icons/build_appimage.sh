#!/usr/bin/env bash
# Copyright 2019-2023 Tauri Programme within The Commons Conservancy
# SPDX-License-Identifier: Apache-2.0
# SPDX-License-Identifier: MIT

set -euxo pipefail

export ARCH=aarch64
APPIMAGE_BUNDLE_XDG_OPEN=${APPIMAGE_BUNDLE_XDG_OPEN-0}
APPIMAGE_BUNDLE_GSTREAMER=${APPIMAGE_BUNDLE_GSTREAMER-0}
TRAY_LIBRARY_PATH=${TRAY_LIBRARY_PATH-0}

if [ "$ARCH" == "i686" ]; then
    linuxdeploy_arch="i386"
else
    linuxdeploy_arch="$ARCH"
fi

mkdir -p "my-excel-tool.AppDir"
cp -r ../appimage_deb/data/usr "my-excel-tool.AppDir"

cd "my-excel-tool.AppDir"
mkdir -p "usr/bin"
mkdir -p "usr/lib"

if [[ "$APPIMAGE_BUNDLE_XDG_OPEN" != "0" ]] && [[ -f "/usr/bin/xdg-open" ]]; then
  echo "Copying /usr/bin/xdg-open"
  cp /usr/bin/xdg-open usr/bin
fi

if [[ "$TRAY_LIBRARY_PATH" != "0" ]]; then
  echo "Copying appindicator library ${TRAY_LIBRARY_PATH}"
  cp ${TRAY_LIBRARY_PATH} usr/lib
  # It looks like we're practicing good hygiene by adding the ABI version.
  # But for compatibility we'll symlink this file to what we did before.
  # Specifically this prevents breaking libappindicator-sys v0.7.1 and v0.7.2.
  if [[ "$TRAY_LIBRARY_PATH" == *.so.1 ]]; then
    readonly soname=$(basename "$TRAY_LIBRARY_PATH")
    readonly old_name=$(basename "$TRAY_LIBRARY_PATH" .1)
    echo "Adding compatibility symlink ${old_name} -> ${soname}"
    ln -s ${soname} usr/lib/${old_name}
  fi
fi

# Copy WebKit files. Follow symlinks in case `/usr/lib64` is a symlink to `/usr/lib`
find -L /usr/lib* -name WebKitNetworkProcess -exec mkdir -p "$(dirname '{}')" \; -exec cp --parents '{}' "." \; || true
find -L /usr/lib* -name WebKitWebProcess -exec mkdir -p "$(dirname '{}')" \; -exec cp --parents '{}' "." \; || true
find -L /usr/lib* -name libwebkit2gtkinjectedbundle.so -exec mkdir -p "$(dirname '{}')" \; -exec cp --parents '{}' "." \; || true

( cd "/home/admin/.cache/tauri" && if [ ! -f "AppRun-${ARCH}" ]; then ( wget -q -4 -N https://github.com/AppImage/AppImageKit/releases/download/continuous/AppRun-${ARCH} || wget -q -4 -N https://github.com/AppImage/AppImageKit/releases/download/12/AppRun-${ARCH} ); fi )
chmod +x "/home/admin/.cache/tauri/AppRun-${ARCH}"

# We need AppRun to be installed as my-excel-tool.AppDir/AppRun.
# Otherwise the linuxdeploy scripts will default to symlinking our main bin instead and will crash on trying to launch.
cp "/home/admin/.cache/tauri/AppRun-${ARCH}" AppRun

cp "usr/share/icons/hicolor/256x256/apps/my-excel-tool.png" .DirIcon
ln -sf "usr/share/icons/hicolor/256x256/apps/my-excel-tool.png" "my-excel-tool.png"

ln -sf "usr/share/applications/my-excel-tool.desktop" "my-excel-tool.desktop"

cd ..

if [[ "$APPIMAGE_BUNDLE_GSTREAMER" != "0" ]]; then
  gst_plugin="--plugin gstreamer"
  if [ ! -f "linuxdeploy-plugin-gstreamer.sh" ]; then
    wget -q -4 -N "https://raw.githubusercontent.com/tauri-apps/linuxdeploy-plugin-gstreamer/master/linuxdeploy-plugin-gstreamer.sh"
  fi
  chmod +x linuxdeploy-plugin-gstreamer.sh
else
  gst_plugin=""
fi

cp -f "/home/admin/.cache/tauri/linuxdeploy-plugin-gtk.sh" ./
chmod +x ./linuxdeploy-plugin-gtk.sh
ln -sf ./linuxdeploy-plugin-gtk.sh ./linuxdeploy-plugin-gtk
export PATH="$PWD:$PATH"
( cd "/home/admin/.cache/tauri" && if [ ! -f "linuxdeploy-plugin-gtk.sh" ]; then ( wget -q -4 -N https://raw.githubusercontent.com/tauri-apps/linuxdeploy-plugin-gtk/master/linuxdeploy-plugin-gtk.sh) fi )
( cd "/home/admin/.cache/tauri" && if [ ! -f "linuxdeploy-${linuxdeploy_arch}.AppImage" ]; then ( wget -q -4 -N https://github.com/tauri-apps/binary-releases/releases/download/linuxdeploy/linuxdeploy-${linuxdeploy_arch}.AppImage) fi )

chmod +x "/home/admin/.cache/tauri/linuxdeploy-plugin-gtk.sh"
chmod +x "/home/admin/.cache/tauri/linuxdeploy-${linuxdeploy_arch}.AppImage"

dd if=/dev/zero bs=1 count=3 seek=8 conv=notrunc of="/home/admin/.cache/tauri/linuxdeploy-${linuxdeploy_arch}.AppImage"

OUTPUT="MyExcelTool.AppImage" "/home/admin/.cache/tauri/linuxdeploy-${linuxdeploy_arch}.AppImage" --appimage-extract-and-run --appdir "my-excel-tool.AppDir" --output appimage
