# Codex Cyber Aurora（Windows）

这是一个可更换背景图的 Codex 科技风皮肤。它仅通过本机回环 CDP 在运行期间注入样式，不会修改 WindowsApps、`app.asar`、应用签名或 `~/.codex/config.toml`。

更新记录见 [CHANGELOG.md](CHANGELOG.md)，参考来源说明见 [NOTICE.md](NOTICE.md)。

## 重要安全说明

此版本**不需要安装**，也不会创建桌面/开始菜单快捷方式。请先正常启动 ChatGPT/Codex；只有应用可稳定打开后，才手动启动皮肤。若任何时候出现启动或设置问题，先停止使用皮肤并按原方式启动应用。

## 手动启动

在本目录执行：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\cyber-skin-tray.ps1 -LaunchSkin
```

该命令会在系统托盘显示控制菜单，并按需重启 Codex，以便只在 `127.0.0.1:9336` 开放本机调试端口；不会对局域网开放端口。它不会写入或迁移任何 Codex 配置。

## 随时更换背景

右键系统托盘中的 `Codex Cyber Aurora` 图标，选择 `Change background image...`，再选择 PNG/JPG/JPEG/WebP 即可。皮肤正在运行时，背景会立即热更新。

也可以带路径运行：

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\set-cyber-background.ps1 -Path "F:\壁纸\你的图片.png"
```

默认背景是 `assets/backgrounds/aurora-night.png`。每次自选背景会复制到 `assets/backgrounds/`，不会改动原图。

## 恢复

运行：

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\restore-cyber-skin.ps1 -Uninstall
```

这会移除实时注入和旧版快捷方式；不会读取、修改或恢复 `config.toml`。

## 说明

- Codex 更新后无需修改安装包；重新运行手动启动命令即可。
- 皮肤依赖本机可用的 `node` 命令。
- 背景图片会以 Base64 数据传给本机 Codex 渲染器；请只选择你信任的本地图片，单张限制为 15 MB。
