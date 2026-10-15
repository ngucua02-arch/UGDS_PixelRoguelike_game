# Task 6 报告：基础房间与近战敌人

## 实现内容

- 新增 `Enemy.tscn` / `Enemy.gd`：敌人为 `CharacterBody2D`，collision layer = 4，mask = 3（静态墙 layer 1 与玩家 layer 2）；初始生命 4，追逐玩家，进入 34 px 范围后每 1 秒通过 `take_damage(float)` 造成 1 点伤害。
- 敌人提供 `take_damage(float)` 和一次性 `died` 信号；受击短暂变白，显示数值生命条和当前生命文本。
- 新增 `Room.tscn` / `Room.gd`：固定 1152×648 场地、四面静态碰撞墙和两个固定出生点，不用 TileMap 或程序生成。Room 追踪敌人，全部死亡后只发出一次 `room_cleared`。
- Main 按顺序实例化玩家和房间，并连接玩家生命/死亡、房间清空信号。临时覆盖层显示生命、失败/清房文字；R 重载当前场景。
- 玩家仍为 layer 2 / mask 1；玩家投射物仍为 layer 8 / mask 4。因敌人是 layer 4 的物理 body，投射物现可通过现有 `take_damage` 接口命中。

## 检查

- Godot 4.7.2 headless editor scan：退出码 0。
- Godot 4.7.2 headless 主场景运行 5 秒：退出码 0。
- `git diff --check`：通过。
- 未新增或运行自动化测试。

## 范围与未验证项

- 未进行实际 GUI 操控；追逐手感、弹体命中、受击/死亡视觉、玩家受伤和重开行为仍需阶段一至少三次试玩验证。
- 当前固定边界与 1152×648 viewport 一致。Task 4 的 viewport 离场清理暂时作为房间边界代理；单房阶段没有切房。Task 8 负责切房时清除遗留玩家投射物，并在修改房间尺寸时复核该代理。
- 本任务没有实现 HUD、多房间、道具、第二种敌人或 Boss。
