# Movement playground

On-hit elemental pickups are in the eastern arena. See [STATUS_EFFECTS.md](STATUS_EFFECTS.md)
for Burn, Poison, Ice, Stun, Knockback and Mark configuration and current AI-related limits.

The playground now includes automatic shooting, hit feedback, dual-layer HP bars and three
20-HP respawning targets. See [COMBAT_PLAYGROUND.md](COMBAT_PLAYGROUND.md) for current controls,
weapon tuning and the combat contracts; its scope supersedes the earlier deferred-combat notes below.

## Training targets

Three stationary grey dummies are authored under `TargetDummies`, just north of the spawn.
Each starts at 1,000,000 HP and uses `features/target_dummy/target_dummy.tscn`. Move or
duplicate these instances in the editor. Their grey colors and hexagonal details are saved
resources; their convex collision shape is authored separately to match the default silhouette.
If changing geometry, update the collision shape deliberately too.

`TargetDummy.apply_damage(amount: int) -> int` returns damage actually applied and emits
`damage_received(amount: int, remaining_hp: int)` after a positive hit. Health is per instance;
negative/zero damage and damage while paused are ignored. `current_hp` is read-only;
`reset_health()` restores the exported `max_hp`. Health clamps at zero, but a dummy is never
removed or disabled. Restarting the scene restores all targets. Player reset (R) resets only
the player, as before. No HP bars, projectiles, hit flashes or damage effects are added yet.

Dummies occupy physics layer 2 (bitmask 2); the player now checks world and target layers
(mask 3). Future projectile collision queries can target layer 2 and call the public API.
TargetDummy owns no dependencies on the playground or player.

Verified authored instances, initial health, damage isolation/signals, invalid damage, pause,
health clamping/non-removal, reset and stationary blocking with `tests/target_dummy_check.gd`.
Movement and dash regression tests also pass; the scene was rendered in D3D12 for visual review.
Manual review: press F5, move toward the three grey targets, and inspect their Max HP in Godot.

Suggested commit: `Add stationary million-HP training dummies to movement playground`.

Press F5, or open `res://features/movement_playground/movement_playground.tscn` and press F6.
WASD/arrows move the player. R resets position, velocity and camera smoothing.
F11 toggles fullscreen; Esc or controller Start opens the pause menu. Use a separate game window if Godot's
embedded view captures fullscreen shortcuts.

The player, its camera, all four obstacles, arena walls and spawn markers are authored
in the scene editor. There is no runtime scene construction. The 2400 × 1600 arena gives
room to test starting, stopping, reversing, diagonals, cornering and sliding along walls.

## Movement contract

`features/player/player.tscn` is a reusable CharacterBody2D scene. Its script owns local
movement input and velocity; its existing ShapeVisual child only renders. Circular collision
geometry is independent from the triangular visual. Camera2D is an editor-authored child
in the playground, not part of the reusable player scene.

Movement uses fixed physics updates, delta-scaled acceleration and braking, capped input
length, and move_and_slide. Physics interpolation smooths rendered transforms between ticks.
Visual facing eases toward input direction independently from collision geometry. Dash is
now supported; sprint, shooting, enemies, health and a global game manager remain deferred.

## Dash

Space or the controller right shoulder (RB/R1) triggers a short dash. Movement input chooses
its direction; while idle it uses current aim, then the last travel direction (up initially).
The direction locks for the burst. Dash lasts 0.18 seconds, covers roughly 150 pixels at
default settings and eases from a peak of 1150 px/s back to normal speed. Cooldown is 0.65
seconds from activation; the cyan recharge bar fills when it is available again. A new
button press is needed for each dash. Walls stop it; there is no invulnerability or damage.

Select Player to tune Dash Speed, Dash Duration and Dash Cooldown. The shape stretches
slightly along travel, then smoothly recovers. Its authored geometry/colors remain untouched.
`visuals/effects/dash_feedback.tscn` owns all effect nodes: a tapered world-space Line2D,
backward CPU sparks and a pulsing shader with a physics-timed tween. Trail Lifetime and
Pulse Duration are exported on DashFeedback. Open that scene to edit particle and material
settings. All nodes are placed in scenes; runtime code only updates their visual state.

Pause freezes dash timing, cooldown, tween and particles. Reset removes the trail and
restores the visual, velocity and cooldown. Using Space to activate a menu button does not
dash on Resume. DashFeedback emits no gameplay events; Player exposes `try_dash() -> bool`,
`is_dashing`, `dash_cooldown_remaining`, and `dash_started` / `dash_finished` signals.

Run `godot --headless --path . --script tests/dash_check.gd` for burst distance, easing,
cooldown, pause/tween freezing, reset, wall collision, controller binding and menu isolation.
These checks and existing movement/pause tests passed. D3D12 rendered preview also passed.
Manual acceptance: dash while turning, dash at rest in both control schemes, dash into a
wall, pause mid-burst, and check that the effect feels restrained and the recovery responsive.

Trail interpolation uses Godot's
[physics interpolation fraction](https://docs.godotengine.org/en/stable/classes/class_engine.html#class-engine-method-get-physics-interpolation-fraction)
to keep visual samples aligned between physics ticks.

Suggested commit: `Add eased player dash with trail, sparks and pulse feedback`.

## Tuning the feel

Select Player in the playground Inspector:

| Setting | Default | Effect |
| --- | --- | --- |
| Max Speed | 360 px/s | Cruise speed |
| Acceleration | 2400 px/s² | Around 0.15 seconds to full speed |
| Braking | 3000 px/s² | Around 0.12 seconds to stop; lower values feel slippery |
| Turn Acceleration | 3600 px/s² | Used when steering against existing velocity |
| Facing Response | 18 | Higher values turn the visual more quickly |

Select Player/Camera2D to tune Position Smoothing Speed (10 by default).
Higher values follow more tightly; disabling smoothing removes camera lag. Adjust player
response first, then camera response, so the two are easy to evaluate separately.
Input Map has move_left/right/up/down for WASD; existing ui direction actions supply arrows.

## Pause, saved controls and controllers

Escape / Start pauses gameplay. Resume returns to the game; Settings opens the controls
tab; Quit closes the running game. Sound and Graphics tabs are disabled and marked WIP.
Settings offers WASD/arrows or W + cursor steering. Cursor mode faces the mouse while idle;
hold W to travel toward it. Apply & save persists the choice across launches in
`user://settings.cfg` (Godot's per-user application data folder, outside the project).
Back discards an unapplied selection. Save failures leave the active scheme unchanged.

Controllers work in either keyboard scheme: left stick or D-pad moves, right stick aims,
Start pauses, A selects, B goes back/resumes. Analog inputs use a 0.2 deadzone and retain
stick magnitude. Menu focus is visible and uses Godot's normal direction navigation.
After controller input, idle facing stays put instead of snapping to an unused mouse cursor.
Moving the mouse or pressing a keyboard key switches keyboard/mouse aiming back on.
The HUD lists default directional controls; the controls tab describes cursor mode.

The pause menu is an editor-authored `features/pause_menu/pause_menu.tscn` instance.
ControlPreferences is owned by the playground; it loads at startup and saves only on Apply.
The menu emits `control_mode_applied`, and the playground passes it to its player.
There are no global managers or runtime-created controls.

Pause/settings checks use `tests/pause_settings_check.gd`. Run with an isolated user-data
environment because this test deliberately saves a control preference. Verified simulated
Start/D-pad/A/B navigation, paused movement, WIP tabs, persistence and analog movement/aim.
A separate rendered run restored the saved choice and verified W-to-cursor direction.
Hardware-controller acceptance remains a manual check. Existing movement checks also pass.

Suggested commit: `Add pause menu, persistent control schemes and controller input`.

## Verification

Automated checks pass for initial acceleration, maximum speed, diagonal normalization,
braking, no drift at rest, arrow actions, reversal, wall blocking/sliding, reset, and comparable
travel at 30/60/120 physics ticks per second. Run with:

`godot --headless --path . --script tests/movement_playground_check.gd`

Editor import and a rendered D3D12 capture also passed under Godot 4.7. The test environment
still emits its system certificate-store warning. Interactive feel is a human acceptance
check: circle the obstacles, release from full speed, reverse abruptly, and move diagonally.
Try fullscreen at your normal refresh rate; tune acceleration/braking/camera smoothing as needed.

Suggested commit: `Add smooth player movement playground with editor-authored arena`.
