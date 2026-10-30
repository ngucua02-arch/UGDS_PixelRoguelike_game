# 阶段八：Windows 试玩包

## 目标

为已通过垂直切片验收的 PC 原型提供不依赖 Godot 编辑器的 Windows x86_64 试玩包，并附中文启动与操作说明。

## 范围

- Godot 4.7.2 stable Windows Desktop 导出预设。
- 单文件 EXE，项目资源嵌入可执行文件。
- ZIP 内附中文说明，保留工程版启动入口。
- 不包括代码签名、商店发行或自动更新。

## 验收

- Godot 导出命令成功生成独立 EXE。
- ZIP 同时包含 EXE 和中文说明。
- 用户从干净解压目录直接启动，并确认进入首个战斗房后，本阶段才算完成。

## 进度

- 垂直切片于 2026-10-29 获玩家确认通过；首领战视觉及 HUD 整合反馈均已记录。
- Windows x86_64 导出模板已从 Godot 4.7.2 官方稳定版模板包提取并安装到本机用户模板目录。
- Godot 4.7.2 stable 命令行导出成功：`build/NeonRoguelike.exe`，单文件 EXE 内嵌项目资源。
- 试玩包已生成：`dist/NeonRoguelike-Windows-试玩版.zip`，包含 EXE 与 `试玩说明.md`；说明文档源文件位于 `docs/releases/试玩版说明.md`。
- 玩家从干净目录启动独立 EXE 并确认进入首个战斗房后，本阶段即可完成。目前尚未执行 GUI 游戏测试。
