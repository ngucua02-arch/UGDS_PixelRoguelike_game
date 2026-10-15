# Task 3 Report — Input and Player Movement

## Implementation

- Added Input Map actions `move_left/right/up/down`, `fire`, `dodge`, and `restart`, bound to physical WASD, left mouse button, Space, and R respectively.
- Added a `CharacterBody2D` player scene with a circle collision shape and contrasting cyan/magenta polygon placeholder art.
- Added player movement using `Input.get_vector()` and an exported `move_speed` of `240.0` pixels per second. The player aims its upward-facing sprite toward the mouse and starts at half the current visible viewport size. Base/max health is 5.
- Instanced the player under the existing `Node2D` main scene. No shooting, damage, dodge behavior, or room boundaries were added.

## Godot verification

Godot executable: `G:\Codex\tools\Godot-4.7.2\Godot_v4.7.2-stable_win64.exe` (Godot 4.7.2 stable).

- `Godot_v4.7.2-stable_win64.exe --headless --editor --path G:\Codex\NeonRoguelike\.worktrees\first-playable --quit` — exit code 0; no parse errors reported.
- `Godot_v4.7.2-stable_win64.exe --headless --path G:\Codex\NeonRoguelike\.worktrees\first-playable --quit-after 5` — exit code 0; main scene started without parse errors.
- No automated tests were added or run.

## Files changed

- `project.godot`
- `scenes/main/Main.tscn`
- `scenes/player/Player.tscn`
- `scripts/player/Player.gd`

## Self-review and unverified items

- Diagonal input is normalized by `Input.get_vector()` before multiplying by movement speed.
- Spawn position derives from the current visible viewport rectangle rather than a fixed window coordinate.
- Mouse orientation accounts for the placeholder sprite pointing upward in its default pose.
- Interactive visual play was not performed, so the feel of movement/aiming and the displayed position in a graphical window remain unverified. The scene is intentionally not bounded until Task 6.
