const { app, BrowserWindow, ipcMain, dialog } = require('electron');
const mpath = require('path');
app.disableHardwareAcceleration();
let mainWindow;

function createWindow() {
  mainWindow = new BrowserWindow({
    width: 900,
    height: 650,
    title: "JS功能桌面工具",
    webPreferences: {
      // preload: mpath.join(__dirname, 'preload.js'),
      // nodeIntegration: false,
      nodeIntegration: true,
      contextIsolation: false,
      //enableRemoteModule: true
    }
  });
  
  // mainWindow.loadFile('index.html');
  mainWindow.loadFile(mpath.join(__dirname, 'index.html'));
  // 开发调试控制台，正式打包注释
  mainWindow.webContents.openDevTools();
}

app.whenReady().then(createWindow);
app.on('window-all-closed', () => app.quit());

// ========== IPC接口1：打开文件选择框（单个文件） ==========
ipcMain.handle('open-file-dialog', async () => {
  const result = await dialog.showOpenDialog(mainWindow, {
    properties: ['openFile'],
    filters: [
      { name: '所有文件', extensions: ['*'] },
      { name: '文本文件', extensions: ['txt', 'json', 'csv'] }
    ]
  });
  return result.filePaths[0] || '';
})

// ========== IPC接口2：打开文件夹选择框 ==========
ipcMain.handle('open-folder-dialog', async () => {
  const result = await dialog.showOpenDialog(mainWindow, {
    properties: ['openDirectory']
  });
  return result.filePaths[0] || '';
})