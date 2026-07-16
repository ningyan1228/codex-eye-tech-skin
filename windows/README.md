# Codex Cyber Aurora（Windows）

这是一个可更换背景图的 Codex 科技风皮肤。它使用本机回环 CDP 将样式注入运行中的 Codex，不会修改 WindowsApps、`app.asar` 或应用签名。

更新记录见 [CHANGELOG.md](CHANGELOG.md)，参考来源说明见 [NOTICE.md](NOTICE.md)。

## 首次安装

在本目录执行：

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\install-cyber-skin.ps1
```

安装会备份 `%USERPROFILE%\.codex\config.toml`，并创建三个桌面快捷方式：启动皮肤、更换背景、恢复外观。

## 启动皮肤

双击桌面的 `Codex Cyber Aurora`，或运行：

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\start-cyber-skin.ps1 -RestartExisting
```

启动时会关闭并重新启动当前 Codex 窗口，以便只在 `127.0.0.1:9336` 开放本机调试端口；不会对局域网开放端口。

## 随时更换背景

双击 `Codex Cyber Aurora - Change Background`，选择 PNG/JPG/JPEG/WebP 即可。皮肤正在运行时，背景会立即热更新。

也可以带路径运行：

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\set-cyber-background.ps1 -Path "F:\壁纸\你的图片.png"
```

默认背景是 `assets/backgrounds/aurora-night.png`。每次自选背景会复制到 `assets/backgrounds/`，不会改动原图。

## 恢复

运行：

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\restore-cyber-skin.ps1 -RestoreBaseTheme -Uninstall
```

这会移除实时注入、快捷方式，并恢复首次安装前备份的原生外观配置。

## 说明

- Codex 更新后无需修改安装包；重新运行“启动皮肤”即可。
- 皮肤依赖本机可用的 `node` 命令。
- 背景图片会以 Base64 数据传给本机 Codex 渲染器；请只选择你信任的本地图片，单张限制为 15 MB。
