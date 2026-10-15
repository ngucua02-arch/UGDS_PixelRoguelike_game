# Task 10 实施报告：奖励三选一界面

## 完成内容

- 新增独立 `HUD.tscn` 和 `HUD.gd`，显示奖励标题及最多三张道具卡；每张卡展示名称、效果描述，并通过鼠标按钮选择。可选项不足三件时隐藏多余按钮。
- Main 维护 `selected_items: Array[ItemData]`，从八份道具资源中排除已持有项，随机抽取最多三件；HUD 只回传当前奖励列表中的索引，Main 校验索引后只应用并记录一件。
- 清房时进入 `reward` 状态，清理活动投射物并禁用 Player 与当前 Room 的处理。HUD 作为 Main 的 CanvasLayer 子节点保持可操作。选择后应用道具，前两房恢复 Player 并创建下一房；第三房选择后进入临时胜利结算。
- 删除 Task 8 的 1.25 秒奖励占位计时。未改 Boss 或后续任务内容。

## 验证

- Godot 4.7.2 stable headless editor scan：退出码 0。
- Godot 4.7.2 stable headless 主场景短启动 120 帧：退出码 0，无错误输出。
- `git diff --check`：通过。
- 未新增或运行自动化测试；未进行 GUI 鼠标试玩，按钮交互、奖励推进及冻结期间无伤仍待实际试玩确认。
- Task 7 仍为 pending：本任务没有将其改为通过。

## 注意事项

- 清理投射物使用 deferred 关闭 Area2D 监测，再 `queue_free()`，避免清房回调发生于物理信号期间时直接修改监测状态。
- Room 在奖励时禁用处理，切房时旧 Room 被释放，新 Room 以默认继承处理模式创建；Player 恢复为 `PROCESS_MODE_INHERIT`。
