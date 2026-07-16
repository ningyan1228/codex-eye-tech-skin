# Codex Eye Tech Skin

一套给 Codex 桌面端使用的低刺激科技风主题。它不修改 Codex 的安装文件，而是使用应用内建的“外观 → 导入主题”功能，因此可随时在设置中撤回。

## 效果

- 深蓝灰背景代替纯黑，减少大面积高反差带来的疲劳感。
- 青绿强调色保留科技感，但降低饱和度和发光感。
- 冷白正文、低刺激的增删差异色，以及不透明侧栏，避免长时间使用时界面显得晃眼。
- 深色与浅色主题视觉语言一致；深色是推荐日常方案。

## 导入方法

1. 在 Codex 打开“设置 → 外观”。
2. 在 **Dark theme** 卡片右上角点击 **Import**，将 [aurora-calm-dark.txt](themes/aurora-calm-dark.txt) 的整行内容粘贴进去并确认。
3. 如需浅色模式，在 **Light theme** 卡片重复操作，使用 [aurora-calm-light.txt](themes/aurora-calm-light.txt)。
4. 在页面顶部将 Theme 设为 Dark、Light 或 System。

主题字符串会同时带入代码配色、字体建议和差异视图的语义颜色。若系统没有 `Cascadia Code`，Codex 会按后备字体正常显示。

## 配色一览

| 用途 | 深色 Aurora Calm | 浅色 Aurora Calm |
| --- | --- | --- |
| 背景 | `#101A24` | `#EDF4F5` |
| 正文 | `#D8E7EE` | `#20313D` |
| 强调 | `#4FD1C5` | `#167E87` |
| 新增差异 | `#71C994` | `#318A65` |
| 删除差异 | `#F08D8D` | `#C85E5E` |

## 本地预览

直接用浏览器打开 [preview.html](preview.html) 即可查看设计意图。预览页面仅用于展示，不是 Codex 的运行界面。

## 校验

无需安装依赖。运行下列命令可检查主题 JSON 与导入字符串是否彼此一致：

```powershell
node scripts/validate-themes.mjs
```

## 文件说明

- `themes/*.json`：便于编辑和审阅的源配置。
- `themes/*.txt`：可直接粘贴到 Codex 导入框的一行主题字符串。
- `preview.html`：静态视觉预览。

## 许可

MIT
