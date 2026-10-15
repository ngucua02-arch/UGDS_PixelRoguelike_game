# Task 4 Report — Aiming, Shooting, and Projectiles

## Implementation

- Added `Projectile.tscn` as an `Area2D` with a circle hit shape and contrasting pink placeholder visual. `Projectile.gd` exposes `launch(direction, damage, speed)`, with 600 px/s supplied by the player as its base speed.
- Player firing is held on the `fire` action. The player fires immediately, then carries elapsed-time remainder across frames at the exported 5 shots/s rate. Damage defaults to 1 and projectile speed, firing rate, and muzzle offset are exported.
- Projectiles are instanced under the current scene so they do not inherit player movement or rotation. They travel along the normalized mouse direction from a short muzzle offset.
- Collision convention: player layer 2, enemy layer 4, player projectile layer 8. Player projectiles mask only enemy layer 4, so they cannot hit the player.
- Projectile `body_entered` calls `take_damage(float)` when the target provides that method, then removes the projectile. The guard keeps this compatible while the Enemy scene is deferred to Task 6.
- Since Room does not exist yet, projectiles are removed outside the current viewport (with a 32 px margin) or after 2 seconds. Task 6 should confirm room bounds and clear projectiles on room transitions.

## Godot verification

Godot executable: `G:\Codex\tools\Godot-4.7.2\Godot_v4.7.2-stable_win64.exe`.

- Headless editor project scan — exit code 0.
- Headless main scene startup for 5 seconds — exit code 0.
- `git diff --check` — passed.
- No automated tests were added or run.

## Limits and review notes

- No enemy exists yet, so actual collision damage and hit feedback could not be exercised. Verify that Task 6's enemy is a physics body on collision layer 4 and implements `take_damage(float)`.
- Shooting direction, cadence, and visuals were not interactively playtested. The plan reserves gameplay conclusions for the phase playtest.
- Viewport bounds are a temporary room-exit proxy; review against the actual Room dimensions and scene transition cleanup in Task 6/8.
