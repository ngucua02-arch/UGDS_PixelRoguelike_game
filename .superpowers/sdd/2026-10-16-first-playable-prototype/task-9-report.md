# Task 9 实施报告：道具数据与首批效果

## 完成内容

- 新增 `resources/items/ItemData.gd` 和八份 `.tres`，只包含约定的六个道具数据字段及固定八项 `EffectType`。
- `Player.apply_item(item: ItemData)` 实现本局效果，并按资源 ID 防止重复选择叠加；最大生命、射速、伤害、弹速和闪避冷却均有安全下限。新玩家实例仍由场景默认值初始化，因此重新开始时效果重置。
- 三向棱镜、穿透针、弹射芯片分别扩展弹丸生成、穿透和一次近敌弹射。`Projectile.launch(direction, damage, speed)` 三参数调用仍有效，新增参数均有默认值。
- 余烬回路通过玩家持有的 `Enemy.health` 和 `Enemy.is_dead` 在伤害前后识别击杀，并对附近敌人递归处理死亡爆炸；没有修改 `Enemy.take_damage()`。

## 验证

- Godot 4.7.2 headless editor scan：退出码 0。
- Godot 4.7.2 headless 主场景启动 300 帧：退出码 0。
- `git diff --check`：通过。
- 未新增或运行自动化测试。未进行键鼠实际试玩；道具战斗手感与组合效果仍需在阶段二试玩中验证。

## 范围与后续接口

- 八份资源路径：`resources/items/{triple_shot,pierce,ricochet,fire_rate,damage_speed,dodge_cooldown,max_health_heal,death_explosion}.tres`。
- Task 10 可直接 preload 这些资源并将 `ItemData` 传给 `Player.apply_item()`。Main/HUD/reward picker 未改。
- 弹射和穿透共存时，弹丸可先完成一次弹射，再消耗穿透次数；击杀爆炸连锁由受影响敌人的死亡继续触发，并受每个敌人仅死亡一次约束。
