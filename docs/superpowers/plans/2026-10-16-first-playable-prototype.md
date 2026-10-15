# 首个可玩原型实现计划

> **执行说明：**逐任务推进，每项完成后运行项目并检查玩家可见结果。Gameplay Gate 必须通过实际游玩完成；自动化检查不能替代试玩。

**目标：**在 Godot 4.x 中制作一个可从开局玩到胜负结算、可快速重开的俯视角像素风 Roguelike 短流程原型。

**架构：**采用少量可复用 Godot 场景：主流程节点持有本局状态，房间负责敌人编排与清房事件，玩家和敌人各自处理移动及受伤，HUD 只呈现状态并发出玩家选择。道具用小型 Resource 数据定义，并由玩家/武器按道具类型应用效果；不建立通用框架或程序化关卡系统。

**技术栈：**Godot 4.x、GDScript、2D 场景与占位绘图；准确的编辑器/运行时版本须在开始实现前核实。

**设计依据：**`docs/superpowers/specs/2026-10-16-first-playable-design.md`

## 全局约束

- 目标平台为 PC，游戏为 2D、单人、离线。
- 使用 WASD 移动、鼠标瞄准、按住鼠标左键射击、空格闪避。
- 单局包括三间战斗房、约 8 件局内道具和一场 Boss 战。
- 只使用占位或自制素材；不可复刻《霓虹深渊》的专有角色、美术、名称或关卡。
- 暂不实现永久成长、剧情战役、多人、在线服务、大规模程序生成或正式发布打包。
- 每个阶段都从 Godot 实际运行项目；玩法结论必须来自真实游玩。

---

## 文件结构与职责

- 修改 `project.godot`：设置主场景、窗口与渲染配置、输入映射。
- 创建 `KNOWN-ISSUES.md`：记录持续存在问题的影响和复现步骤；若无未解决问题则不创建。
- 创建 `scenes/main/Main.tscn`、`scripts/main/Main.gd`：控制一局状态、房间顺序、奖励选择、胜负与重开。
- 创建 `scenes/player/Player.tscn`、`scripts/player/Player.gd`：移动、瞄准、射击、生命、闪避和局内道具效果。
- 创建 `scenes/combat/Projectile.tscn`、`scripts/combat/Projectile.gd`：玩家投射物移动、命中与消失。
- 创建 `scenes/enemies/Enemy.tscn`、`scripts/enemies/Enemy.gd`：近战追击敌人和远程敌人的公共生命/受伤/死亡流程；用导出参数区分行为。
- 创建 `scenes/rooms/Room.tscn`、`scripts/rooms/Room.gd`：房间边界、敌人实例化、清房判定和出口状态。
- 创建 `resources/items/ItemData.gd` 与 8 个 `.tres`：道具展示信息及有限、明确的效果参数。
- 创建 `scenes/ui/HUD.tscn`、`scripts/ui/HUD.gd`：生命、房间进度、奖励选择和结束提示。
- 创建 `docs/superpowers/phases/phase-1-combat-room.md`、`phase-2-room-rewards.md`、`phase-3-complete-run.md`、`phase-4-playtest.md`：记录阶段范围、验收和结果。
- 创建 `docs/superpowers/playtests/first-playable.md`：记录构建版本、试玩者/环境、观察、问题和 Gameplay Gate 决策。

## 场景与接口约定

- `Main.gd` 持有 `current_room_index:int`、`selected_items:Array[ItemData]` 和 `run_state:StringName`；只负责协调，不处理移动或战斗细节。生命值由 `Player.gd` 唯一持有。
- `Room.gd` 发出 `room_cleared` 信号；所有敌人死亡后只发出一次。主流程收到信号后显示奖励选择，Boss 房清空后进入胜利结算。
- `Player.gd` 发出 `health_changed(current:int, maximum:int)` 与 `died`；公开 `apply_item(item: ItemData) -> void`，让主流程按选择应用局内效果。
- `HUD.gd` 发出 `item_chosen(item_index:int)` 与 `restart_requested`；它不直接改写玩家或房间状态。
- `Enemy.gd` 发出 `died`，并提供 `take_damage(amount: float) -> void`；投射物仅通过命中接口造成伤害。
- 主流程只从固定房间序列装载内容，不在本原型中生成任意地图。

---

## 阶段 0：确认 Godot 运行环境

### Task 1：定位并确认编辑器版本

**涉及文件：**无

- 在 Windows 开始菜单、Godot 项目管理器或已安装应用位置找到 Godot 编辑器。
- 在编辑器的关于窗口或终端 `godot --version` 中读取完整版本号，确认属于 Godot 4.x。
- 若没有可用 Godot 4.x 编辑器，先安装后再继续；不在未确认版本时编写依赖版本特性的实现。

**验收：**记录 Godot 完整版本和打开 `G:\Codex\NeonRoguelike` 的方式；项目能被编辑器识别。

### Task 2：设置最小运行入口

**文件：**修改 `project.godot`；创建 `scenes/main/Main.tscn`、`scripts/main/Main.gd`

- 设置主场景为 `res://scenes/main/Main.tscn`。
- 创建一个 `Node2D` 根节点并挂载空 `Main.gd`。
- 在 Godot 编辑器启动项目，确认主场景打开且没有解析错误。

**验收：**按 F6 可运行主场景，窗口正常打开并可关闭；将确认的 Godot 版本写入 `PROJECT-BOOTSTRAP.md` 和 `project/CURRENT-STATE.md`。

## 阶段 1：基础战斗房间

### Task 3：定义输入和玩家移动场景

**文件：**修改 `project.godot`、`scenes/main/Main.tscn`；创建 `scenes/player/Player.tscn`、`scripts/player/Player.gd`

- 在 Input Map 中定义 `move_left/right/up/down`、`fire`、`dodge`、`restart`。
- `move_*` 分别绑定 A/D/W/S，`fire` 绑定鼠标左键，`dodge` 绑定空格，`restart` 绑定 R。
- 玩家场景使用 `CharacterBody2D` 根节点、碰撞形状和一个高对比度占位绘图；基础生命值为 5。
- 使用归一化的 `Input.get_vector()` 结果移动；角色速度为可调导出参数，首版取 `240.0` 像素/秒。
- 将玩家实例加入主场景，位于游戏窗口可见区域中央；玩家朝向鼠标位置；移动不能因斜向输入超过轴向速度。

**验收：**运行主场景后可八方向移动；鼠标移动时角色朝向目标；此阶段尚无物理墙体，房间碰撞边界在 Task 6 接入后复核。

### Task 4：加入瞄准射击和投射物

**文件：**创建 `scenes/combat/Projectile.tscn`、`scripts/combat/Projectile.gd`；修改玩家场景与脚本

- 投射物使用 `Area2D`、碰撞形状和占位可视图；提供 `launch(direction: Vector2, damage: float, speed: float) -> void`，基础速度为每秒 600 像素。
- 玩家按住 `fire` 时按射速间隔生成投射物，枪口朝鼠标方向；射速与伤害为可调参数，初值分别为每秒 5 发和 1 点伤害。
- 投射物命中敌人后调用 `take_damage()` 并销毁自身；离开房间边界或超时也销毁。
- 使用碰撞层/掩码区分玩家、敌人和投射物，避免玩家弹命中玩家。

**验收：**按住左键能稳定发射、投射物方向准确、命中仅伤害敌人，射速不受帧率变化影响。

### Task 5：加入玩家生命与闪避

**文件：**修改 `Player.tscn`、`Player.gd`

- 玩家具有当前/最大生命值；受伤时发出 `health_changed`，生命归零时只发出一次 `died`。
- 空格触发闪避，移动速度为每秒 720 像素；闪避期间短暂忽略敌方伤害，并通过颜色/透明度变化表现无敌帧。
- 闪避时长初值 0.18 秒、冷却初值 0.8 秒，做成可调参数；未到冷却时不重复触发。
- 普通状态和闪避状态的移动速度按设计固定，不添加冲刺攻击或复杂状态机。

**验收：**可观察生命变化、死亡状态信号和闪避反馈；连续按空格不会绕过冷却；受伤与无敌时间行为清楚。

### Task 6：创建基础房间与近战敌人

**文件：**创建 `scenes/enemies/Enemy.tscn`、`scripts/enemies/Enemy.gd`、`scenes/rooms/Room.tscn`、`scripts/rooms/Room.gd`；修改 `scenes/main/Main.tscn`、`scripts/main/Main.gd`

- 房间使用静态边界和固定出生点；不使用 TileMap 或程序生成。
- 敌人首版为近战追击型，使用 `CharacterBody2D`，生命值 4 点，朝玩家移动并在近身时造成 1 点伤害；攻击间隔首值 1 秒。
- 敌人具备可见生命/受击反馈、生命值和死亡信号。
- `Room.gd` 追踪本房间敌人，敌人全部死亡后发出一次 `room_cleared`。
- 主流程连接玩家死亡信号，显示临时失败文字；按 R 调用重开（完整按钮由 HUD 任务补齐）。

**验收：**一间房可完整运行：玩家能攻击并击败敌人，也会受伤、失败和重开；清房信号只触发一次。

### Task 7：阶段一试玩与记录

**文件：**创建 `docs/superpowers/phases/phase-1-combat-room.md`

- 实际运行至少 3 次短遭遇，分别观察移动/瞄准、命中反馈和闪避是否可理解。
- 记录观察到的事实、最明显的阻力、待解决问题和阶段判断；不把自动检查写成试玩。
- 只修复阻止核心操作的缺陷；数值微调进入后续游玩迭代。

**验收：**阶段记录包含运行版本、实际游玩次数、观察证据和通过/返工决定。

## 阶段 2：房间推进与道具选择

### Task 8：串联三间固定战斗房

**文件：**修改 `Main.tscn`、`Main.gd`、`Room.tscn`、`Room.gd`

- 由 `Main.gd` 按序装载三间固定房间内容：第一间 2 个近战敌人、第二间 3 个、第三间 4 个；每间房清空后进入奖励阶段。
- 房间切换前清除旧敌人、旧投射物并重置出生点；保留玩家生命和已选道具。
- 在 HUD 显示当前序号（1/3、2/3、3/3）。
- 第三间普通房清空并完成奖励选择后，显示临时原型胜利结算；阶段 3 再把该出口改为 Boss 房。

**验收：**可以按顺序进入三间不同配置的战斗房；不存在上间敌人或投射物遗留；玩家状态按规则保留；第三间房后可显示临时胜利结算。

### Task 9：建立道具数据与首批效果

**文件：**创建 `resources/items/ItemData.gd` 与 8 个道具 Resource；修改 `Player.gd`、`Projectile.gd`

- `ItemData` 只存 `id: StringName`、`display_name: String`、`description: String`、`effect_type: EffectType`、`value_primary: float`、`value_secondary: float`。`EffectType` 固定为 `TRIPLE_SHOT`、`PIERCE`、`RICOCHET`、`FIRE_RATE`、`DAMAGE_SPEED`、`DODGE_COOLDOWN`、`MAX_HEALTH_HEAL`、`DEATH_EXPLOSION`。
- 建立 8 件局内道具：三向棱镜（每次射击改为 -12°、0°、+12° 三发，每发伤害降为 0.7）；穿透针（每枚投射物可多穿透 1 个敌人）；弹射芯片（命中后弹向 180 像素内最近的另一名敌人一次）；过载电容（射速提升 25%）；重型弹头（伤害提升 50%、弹速降低 20%）；相位核心（闪避冷却缩短 20%）；护盾电池（最大生命 +1，选择时恢复 1 点生命）；余烬回路（击杀时以 48 像素半径造成 1 点范围伤害）。
- `Player.apply_item(item: ItemData) -> void` 按明确效果类型更新本局属性；禁止道具运行任意 GDScript 字符串。
- 至少三件武器道具改变发射/命中行为，而非纯数值加成。
- 仅本局保存道具；重开后恢复初始值。

**验收：**每件道具可被选中并表现出说明对应的效果；重开后效果清空；互斥或异常参数有安全下限。

### Task 10：奖励三选一界面

**文件：**创建 `scenes/ui/HUD.tscn`、`scripts/ui/HUD.gd`；修改 `Main.gd`

- 每间普通房清空后，从当前未持有道具中随机抽取最多 3 件，不重复抽取；展示名称、简短效果和选择按键。第三次选择后进入 Task 8 定义的临时胜利结算。
- 玩家选中一件后，HUD 发出 `item_chosen(item_index:int)`；主流程应用道具并继续下一房。
- 奖励期间暂停战斗并隐藏/禁用玩家攻击，避免 UI 打开时仍受伤。
- 抽取数量不足 3 件时展示实际可选数量，不重复同一选项填满。

**验收：**可通过鼠标点击三选一；每次只应用一件；选择后继续推进；奖励界面期间不会遭受隐藏伤害。

### Task 11：阶段二试玩与记录

**文件：**创建 `docs/superpowers/phases/phase-2-room-rewards.md`

- 实际游玩完整通过三间普通战斗房，观察道具选择是否改变后续作战策略。
- 检查连续房间切换、生命延续、奖励暂停/恢复和重开后清理局内状态。
- 记录选择是否有意义、UI 是否可读及发现的问题。

**验收：**阶段记录包含实际游玩证据和明确修正项；不以代码检查替代玩法判断。

## 阶段 3：完整短流程

### Task 12：加入第二种敌人

**文件：**修改 `Enemy.tscn`、`Enemy.gd`、三间房间配置

- 加入远程型敌人：与玩家保持距离，先显示攻击预警，再沿玩家所在方向发射可见弹丸。
- 敌弹命中玩家时走统一受伤接口；玩家闪避期间无效。
- 两种敌人的轮廓、颜色和攻击预警保持明显不同。

**验收：**远程敌人攻击有可反应的预警，不会无提示瞬间造成伤害；玩家能移动/闪避应对。

### Task 13：加入 Boss 房与攻击模式

**文件：**创建 `scenes/enemies/Boss.tscn`、`scripts/enemies/Boss.gd`、Boss 房间配置；修改 `Main.gd`

- 三间普通房之后固定进入 Boss 房；Boss 初始生命值 40 点，具有独立生命条和两种可辨攻击：速度每秒 320 像素、伤害 1 点的 5 发扇形弹幕；以及显示 0.7 秒预警后冲撞的攻击。冲撞速度为每秒 520 像素，命中造成 1 点伤害。
- 两种攻击按简单轮换或生命阈值切换；每次攻击之间给玩家留下可反应窗口。
- Boss 死亡触发胜利结算；玩家死亡触发失败结算。

**验收：**完整推进顺序正确；Boss 攻击有预警且可躲避；胜负条件只触发一次。

### Task 14：完成结算与快速重开

**文件：**修改 `HUD.tscn`、`HUD.gd`、`Main.gd`

- HUD 展示生命、当前房间、道具效果摘要和 Boss 生命。
- 胜利或失败后显示结算标题及重开按钮；重开重新建立玩家、房间序列与初始道具状态。
- 所有面向玩家的提示使用中文，避免调试信息进入游戏界面。

**验收：**胜利和失败都能到达正确结算；鼠标按钮或 Enter 可重开；连续重开 3 次没有状态残留。

### Task 15：像素霓虹占位视觉整理

**文件：**修改玩家、敌人、投射物、房间和 HUD 场景；创建需要的占位图形资源

- 采用暗色房间底色、少量霓虹强调色和清晰的阵营配色；友方弹、敌方弹、敌人、玩家必须可区分。
- 使用最近邻过滤与整数缩放友好的基础设置；避免模糊纹理和高强度全屏闪烁。
- 受击、闪避、攻击预警、房间完成和道具选择各有至少一种可见反馈。

**验收：**实际运行时不易把敌我弹幕混淆；主要 UI 在目标窗口尺寸下可读；视觉效果没有遮挡攻击预警。

### Task 16：阶段三完整流程试玩

**文件：**创建 `docs/superpowers/phases/phase-3-complete-run.md`

- 实际从新开局玩到胜利或失败，再重开开始下一局。
- 至少记录一局完整流程的时长、卡住或不清楚的时刻、道具影响和主要失误原因。
- 若无法稳定到达 Boss，先修复流程或难度阻塞再继续美术调整。

**验收：**阶段记录包含完整游玩路径和下一轮迭代的优先问题。

## 阶段 4：迭代与 Gameplay Gate

### Task 17：按真实证据修复体验问题

**文件：**仅修改试玩记录明确关联的场景/脚本；更新 `KNOWN-ISSUES.md`（如问题持续存在）

- 每次只选择一到三个影响最大的体验问题，例如瞄准不准、敌弹难读、奖励无法比较、Boss 等待时间过长。
- 每项调整前写出观察到的问题和预期变化；调整后再次实际游玩相同场景验证。
- 不增加新系统或扩大内容范围来绕开已有体验问题。

**验收：**每项保留/撤销的调整都有对应的试玩观察，不只记录“感觉更好”。

### Task 18：完成 Gameplay Gate 与状态记录

**文件：**创建 `docs/superpowers/playtests/first-playable.md`；更新 `project/CURRENT-STATE.md`；按 UGDS 阶段结果创建 Freeze 记录

- 根据实际游玩评估目标清晰度、操作响应、反馈、节奏、有意义的选择、挑战、奖惩、可读性、投入感和重玩动机。
- 每项记录 PASS、WEAK PASS、FAIL 或有理由的 N/A，并附实际观察证据。
- 做出 GO、ITERATE、PIVOT 或 KILL 决定；同步记录已知问题、Git 状态和下一步建议。

**验收：**Gameplay Gate 来自真实运行与游玩；状态文档能让新会话在五分钟内恢复目标和下一步。

---

## 计划自查

- 设计范围覆盖：Godot 4.x、键鼠操作、三间普通房、两种敌人、Boss、约 8 件局内道具、HUD、胜负和重开。
- 最小可玩目标在阶段 1 与阶段 2 完成：战斗、清房、奖励改变构筑、第二次遭遇、胜负和重开。
- 永久成长、剧情、在线、多人和复杂程序生成均未纳入。
- 自动化检查不是 Gameplay Gate 的证据；所有体验结论要求真实试玩。
- 版本依赖由阶段 0 先确认；若机器尚无 Godot 4.x，后续实现应等安装完成再继续。
