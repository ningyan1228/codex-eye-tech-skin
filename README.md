# Codex Eye Tech Skin

这是给 Codex/ChatGPT 桌面端准备的护眼科技风原生主题。推荐长期使用原生主题：它只通过“设置 → 外观 → 导入主题”生效，不修改应用安装包、启动参数或 `.codex/config.toml`。

## 推荐主题：Aurora Calm

| 模式 | 导入文件 | 风格 |
| --- | --- | --- |
| 深色 | [aurora-calm-dark.txt](themes/aurora-calm-dark.txt) | 深蓝灰底色、冷白正文、柔和青绿强调色 |
| 浅色 | [aurora-calm-light.txt](themes/aurora-calm-light.txt) | 低刺激雾蓝白底色、深石墨正文、克制青绿色 |

## 使用方法

1. 正常打开 ChatGPT/Codex，进入“设置 → 外观”。
2. 在“深色主题”或“浅色主题”点击“导入”。
3. 打开对应的 `.txt` 文件，复制全部一整行内容并粘贴到导入框。
4. 点击“导入主题”，再选择深色、浅色或跟随系统即可。

主题会同时导入界面颜色、代码字体建议和差异视图颜色。若没有安装 `Cascadia Code`，应用会自动使用后备字体。

## 校验

```powershell
node scripts/validate-themes.mjs
```

## 壁纸项目归档

壁纸版属于非官方运行时皮肤，源码、默认壁纸、宣传截图和完整使用教程均保留在 GitHub 的 [windows 归档目录](https://github.com/ningyan1228/codex-eye-tech-skin/tree/main/windows)。本地工作区默认不保留该目录。

## 许可

MIT
