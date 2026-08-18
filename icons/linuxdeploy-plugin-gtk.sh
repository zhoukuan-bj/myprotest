#!/bin/bash
set -euo pipefail

# linuxdeploy-plugin-gtk.sh
# https://github.com/linuxdeploy/linuxdeploy-plugin-gtk

# Exclude list
EXCLUDE_LIST=(
  "libgtk-3.so.0"
  "libgdk-3.so.0"
  "libgtk-4.so.1"
  "libgdk-4.so.1"
)

# Helper: check if file is in exclude list
is_excluded() {
  local lib="$1"
  for e in "${EXCLUDE_LIST[@]}"; do
    if [[ "$(basename "$lib")" == "$e" ]]; then
      return 0
    fi
  done
  return 1
}

# Find schemas
find_glib_schemas() {
  find /usr/share/glib-2.0/schemas -name "*.gschema.xml" 2>/dev/null || true
}

# Main plugin entry
main() {
  if [[ -z "${APPDIR:-}" ]]; then
    echo "ERROR: APPDIR environment variable not set" >&2
    exit 1
  fi

  # Copy glib schemas
  local schemas_dir="${APPDIR}/usr/share/glib-2.0/schemas"
  mkdir -p "$schemas_dir"
  while read -r schema; do
    cp -v "$schema" "$schemas_dir/"
  done < <(find_glib_schemas)

  # Compile schemas if any found
  if [[ -d "$schemas_dir" && $(ls -1 "$schemas_dir" | wc -l) -gt 0 ]]; then
    glib-compile-schemas "$schemas_dir"
  fi
}

main "$@"
