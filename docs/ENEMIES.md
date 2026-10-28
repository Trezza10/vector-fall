# Enemy field

Run F5 and move west (left) from the starting point. The existing training targets and
upgrade stations remain available. Fixed enemies engage when you approach within 560px,
then chase, attack or hold their firing position. R resets the encounter, player hit
counter and hostile shots while retaining collected upgrades. Main enemies reboot after
8 seconds; changing Respawn On Death in an enemy instance can disable that reboot.

| Enemy | HP | Role |
| --- | --- | --- |
| Bulwark | 240 | Large grey octagon; slow pursuit at 44px/s |
| Skitter | 15 | Small amber triangle; fast pursuit at 200px/s |
| Wisp | 45 | Violet diamond; alternates diagonal evasive bursts |
| Ring Sentinel | 100 | Orange octagon; 12-shot rings alternate 0 / 15 degree offsets |
| Spiral Weaver | 85 | Pink star; one shot every 0.13s, advancing 19 degrees each shot |
| Lancer | 70 | Red triangle; locks an aim direction, warns for 0.65s, charges then recovers |
| Fracture | 75 | Green pentagon; releases three small 12-HP Fragments on death |

Burst attacks show a pulsing warning ring and direction line, followed by particles and
a short trail. Burst speed drops back for recovery rather than carrying invisible attack
speed into that phase. Warm, solid diamond bullets are hostile; their centers sweep
against player/world colliders to avoid tunneling. They expire after a configured lifetime.
Contact and projectile hits flash the player, play a cue and increment the hit counter,
with a 0.45s grace window shared by both sources. Accepted hits now subtract player HP
and update the shared HUD health bar; see PLAYER_HEALTH.md.
Dash does not grant invulnerability. Every attack and projectile pauses with gameplay.

EnemyField and all seven enemies are authored in features/enemies/enemy_field.tscn.
The splitter references three pre-placed dormant Fragment instances. Splitting activates
those instances at death offsets; fragments neither split nor respawn. Parent reboot or
encounter reset deactivates them. Only hostile projectiles are instantiated during play.
There is no spawn director or wave system.

Each archetype has its own reusable scene under features/enemies and EnemyDefinition
resource under data/enemies. Tune health, speed, acceleration, activation/leash range,
contact radius/damage, windup, burst speed/duration, recovery, firing interval/count/speed,
lifetime/damage and spiral step in that resource. Shapes, palettes, circle colliders,
warning/trail/particle nodes and sound players are authored in the reusable scenes.
Keep contact radius matched to the enemy collider plus the player's 18px radius.

PlaygroundEnemy extends the existing TargetDummy health/status/feedback contract. The base
now offers Die At Zero independently of Respawn On Death; defaults preserve old training
target behavior. Enemies inherit bullet damage, criticals, floating numbers, chip health
bars, burn/poison, Mark and sounds. Chill slows actual movement and bursts; stun interrupts
windups/bursts and pauses AI attacks; knockback resolves through existing physics. Data
resources are not mutated. Player.receive_enemy_hit(amount) returns whether feedback was
accepted and emits hit_received; it subtracts HP, clamps actual damage to remaining health, and emits health_changed.

Pursuit uses acceleration and move_and_slide, with a home leash. This basic version has
no navigation/pathfinding around complex layouts, separation steering or line-of-sight
prediction. Shooters hold position; bursts lock their direction when telegraphed. Ring
volleys offset by half a bullet spacing on odd shots, restoring the original spacing on
even shots. Spiral angles wrap around TAU without changing per-shot step.

Verification: tests/enemy_check.gd covers all seven authored definitions, HP/size/speed,
idle/engage behavior and pursuit, radial offsets and spiral advance, locked charge and
burst movement, evasive direction, stun/chill, pause, pre-authored splitting and fragment
death, real incoming projectile/wall sweeps, grace, real outgoing critical+burn hits,
and R reset. Combat, movement, dash-upgrade, pickup and status regression checks pass.
D3D12 field and overview captures were inspected. Godot reports some typed script/resource
references during shutdown in editor and several regression runs; functional checks pass
without runtime script errors. The usual local certificate-store diagnostic also remains.

Manual review: approach each archetype, dodge its tell, shoot it with upgrades, stun a
charging Lancer, kill Fracture, pause with bullets in flight, and press R. Check labels,
health bars, movement readability and the hit counter. Tune encounter density/HP after
playtesting; this is the first playable set rather than final combat balance.

Suggested commit: Add seven scene-authored enemy archetypes and hostile attack feedback.
