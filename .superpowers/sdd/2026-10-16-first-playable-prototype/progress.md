# SDD ledger — plan: docs/superpowers/plans/2026-10-16-first-playable-prototype.md

## 任务清单

- [x] Task 1：定位并确认编辑器版本
- [x] Task 2：设置最小运行入口
- [x] Task 3：定义输入和玩家移动场景
- [x] Task 4：加入瞄准射击和投射物
- [x] Task 5：加入玩家生命与闪避
- [ ] Task 6：创建基础房间与近战敌人
- [ ] Task 7：阶段一试玩与记录
- [ ] Task 8：串联三间固定战斗房
- [ ] Task 9：建立道具数据与首批效果
- [ ] Task 10：奖励三选一界面
- [ ] Task 11：阶段二试玩与记录
- [ ] Task 12：加入第二种敌人
- [ ] Task 13：加入 Boss 房与攻击模式
- [ ] Task 14：完成结算与快速重开
- [ ] Task 15：像素霓虹占位视觉整理
- [ ] Task 16：阶段三完整流程试玩
- [ ] Task 17：按真实证据修复体验问题
- [ ] Task 18：完成 Gameplay Gate 与状态记录

Task 1 evidence: Godot 4.7.2 stable portable editor installed at `G:\Codex\tools\Godot-4.7.2\Godot_v4.7.2-stable_win64.exe`; Authenticode signature is Valid, signer Prehensile Tales B.V.; `--version` returned `4.7.2.stable.official.ed1daf0bf`. Headless editor scanned the project successfully before implementation.

## 预检：任务接口与一致性

| Task pair | Shared file / interface | Scan result |
|---|---|---|
| 2 ↔ 3 | `project.godot`; main scene and player scene | Task 2 sets the entry scene; Task 3 adds the named input actions and player instance. Compatible sequence. |
| 2 ↔ 6 | `Main.gd` | Task 2 creates the coordinator; Task 6 connects player death and room-cleared flow. Compatible. |
| 2 ↔ 8, 10, 13, 14 | `Main.gd` / `Main.tscn` | Tasks extend one existing run owner; no duplicate run-state owner specified. |
| 3 ↔ 4 | `Player.gd`, `Player.tscn` | Movement/aim scene from Task 3 is extended with firing in Task 4. |
| 3 ↔ 5 | `Player.gd` | Task 3 creates the player; Task 5 adds health/dodge. Health remains owned by Player. |
| 4 ↔ 5 | `Player.gd` | Fire and dodge are separate actions on the same player scene; no input conflict. |
| 4 ↔ 6 | `Projectile.gd`, `Enemy.gd` | Task 4 calls the `take_damage(float)` contract provided by Task 6; the brief must define the call as deferred/guarded until the enemy exists. |
| 4 ↔ 9 | `Projectile.gd`, `Player.gd` | Task 9 extends the established projectile and weapon values for item effects. |
| 4 ↔ 12, 13 | projectile collision/launch | Enemy/Boss projectiles use an explicit owner/faction collision mask; do not reuse player damage by accident. |
| 5 ↔ 6 | `Player.died`, enemy damage | Task 6 consumes the death and damage behavior produced by Task 5. |
| 5 ↔ 9 | `Player.apply_item(ItemData)` | Task 5 establishes the method; Task 9 implements item effects through it. |
| 5 ↔ 10 | `health_changed(current, maximum)` | Task 10 observes Player-owned health through the planned signal. |
| 6 ↔ 8 | `Room.room_cleared` | Task 6 emits once; Task 8 advances the fixed room sequence. |
| 6 ↔ 12, 13 | `Enemy.gd` damage/death | Task 12 adds a ranged behavior using the base; Task 13 adds a boss encounter with explicit death integration. |
| 6 ↔ 14 | `Main.gd`, `Player.died` | Task 14 replaces temporary defeat feedback with final UI while preserving the signal owner. |
| 8 ↔ 10 | `Main.gd`, `HUD.item_chosen` | Task 8 owns progression; Task 10 returns a choice index for the current choice array. |
| 8 ↔ 13 | room sequence | Task 8 ends at temporary victory after room 3; Task 13 replaces that endpoint with Boss. |
| 8 ↔ 14 | run outcome | Temporary prototype victory becomes full victory after Boss in Task 13/14. |
| 9 ↔ 10 | `ItemData`, item-choice array | Task 9 defines item data; Task 10 displays and returns indices into the same ordered array. |
| 9 ↔ 15 | item weapon effects / visual feedback | Task 15 visualizes effects without changing their gameplay semantics. |
| 10 ↔ 14 | HUD choice/restart signals | Task 14 adds outcome/restart UI while preserving `item_chosen` and `restart_requested`. |
| 13 ↔ 14 | Boss death / win flow | Boss death triggers one win path; Task 14 renders and restarts it. |
| 13 ↔ 15 | Boss scene visuals | Task 15 improves readability without altering attack timing or hit behavior. |
| 15 ↔ 17 | combat scenes and effects | Task 17 tunes only issues backed by playtest evidence; it may touch Task 15 files but occurs later. |
| 1 ↔ 18 | `PROJECT-BOOTSTRAP.md`, `project/CURRENT-STATE.md` | Task 1 records engine version; Task 18 updates state and gate evidence. |
| 7, 11, 16 ↔ 18 | phase and playtest records | Each phase record remains separate; Task 18 links final play evidence and updates the snapshot. |

| Task | Self-consistency scan |
|---|---|
| 1 | Environment check can complete before code; official portable version and executable path are known. |
| 2 | Main entry files are created and `project.godot` points to the created scene. |
| 3 | Input actions and player movement/aim are scoped to project config and Player scene/script. |
| 4 | Projectile launch contract and collision target are defined; enemy method arrives in Task 6. |
| 5 | Health/dodge signals and state are owned by Player; no second owner. |
| 6 | Room and enemy scenes/scripts are created; Main consumes their signals. |
| 7 | Playtest record can be created after Phase 1 runtime exists. |
| 8 | Fixed room progression uses existing Main/Room/HUD contracts; three-room temporary victory is explicit. |
| 9 | Item fields, effect enum, and eight effects have concrete values. |
| 10 | Reward selection uses the ItemData array and pauses combat. |
| 11 | Full three-room reward loop exists from Tasks 8–10. |
| 12 | Ranged enemy extends the existing enemy damage/death interface. |
| 13 | Boss attacks, telegraph times, speed, damage, HP, and progression endpoint are defined. |
| 14 | HUD outcome/restart signals are compatible with Main's run owner. |
| 15 | Visual pass modifies existing game scenes and keeps combat semantics unchanged. |
| 16 | Full short run exists after Task 14; record can capture end-to-end evidence. |
| 17 | Iteration is constrained to observed issues and their related files. |
| 18 | Gate/state/Freeze records are created after actual gameplay evidence exists. |

### Preflight rulings

- `Ruling: Godot 4.7.2 stable will be used — it is the latest stable version listed by the official download archive as of 2026-10-16 and the installed portable binary signature verifies — if compatibility issues appear, some project settings or scripts may need adjustment.`
- `Ruling: Game implementation and runtime work occur in the isolated feature worktree — user chose subagent-driven execution and the workflow requires isolation — incorrect assumptions about shared-path visibility could require copying reviewed artifacts back at integration time.`
- `Ruling: No automated test suite will be added or run unless requested; use the approved Godot runtime and real-play verification steps in the plan — developer instruction prohibits unsolicited tests — this gives less automated regression coverage.`
- `Ruling: Task 3 must instance Player.tscn in Main.tscn and defer physical-wall verification to Task 6 — the original acceptance required visible movement but did not place the player in the running scene — if coupling the entry scene this early is undesirable, a later scene replacement may be needed.`
- `Ruling: Enemy collision layer will be 4 and player projectile layer/mask will be 8/4 — Task 4 needs a stable faction filter before the Enemy scene exists — Task 6 must preserve this layer contract or update both sides together.`
- `Ruling: Task 6 uses fixed room walls that match the current 1152×648 viewport, so Task 4's viewport-exit projectile cleanup remains the room-boundary proxy for the single-room phase — no room transitions exist yet — Task 8 owns clearing any remaining projectiles when switching rooms and should revisit the boundary proxy if room dimensions change.`

## Task reports

Task 1: complete (Godot 4.7.2 stable verified; project headless editor scan completed).
Task 2: complete (commits b673017..f6a7369, review clean).
Task 3: complete (commit fd5645b; Godot parse/startup passed; independent review found no blockers; actual GUI play deferred to phase playtest).
Task 4: complete (commits 7d97b2d..3cd28ef; editor scan/startup passed; independent review passed with room-bounds cleanup deferred for Task 6; actual combat deferred to phase playtest).
Task 5: complete (commits cafaa7f..48e5e58; Godot scan/startup passed; independent review suggested an adjustable cooldown edge guard, fixed in 48e5e58; interactive play/damage connection deferred to Task6/7).
Task 6: implementation committed; awaiting independent review (fixed arena walls and two melee enemies; Main connects player health/death and room-clear signals, with temporary Chinese result text and R restart; headless editor scan and 5-second startup passed; no GUI play performed; Task 8 owns projectile cleanup at room transitions).
