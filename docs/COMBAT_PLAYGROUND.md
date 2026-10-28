# Shooting and target playground

Targets now show one accumulating, punchy floating damage number. See
[DAMAGE_NUMBERS.md](DAMAGE_NUMBERS.md) for color/timing configuration and aggregation behavior.

Elemental/on-hit modifiers are now supported; see [STATUS_EFFECTS.md](STATUS_EFFECTS.md).
This supersedes the earlier deferred-status-effects note below. Targets remain stationary
apart from collision-resolved knockback and return to their authored positions on respawn.

**Current controls:** weapon-switch hotkeys have been replaced by collectible timed upgrades.
See [PICKUP_MODIFICATIONS.md](PICKUP_MODIFICATIONS.md) for the current stacking/duration model.
Weapon preset/selection notes below describe authoring and test APIs, not gameplay shortcuts.

Press F5. Shooting is automatic:

- Mouse aims the weapon in either keyboard control scheme.
- Controller right stick aims; without right-stick input, travel direction updates the aim,
  and the last direction is retained while stopped.
- Walk over colored pickups to combine modifications on the starting Pulse weapon.
- **F** toggles automatic fire for inspection. Pause freezes firing and active bullets.
- Three new 20-HP targets are south of spawn. The original three million-HP dummies remain north.

| Weapon | Attacks/sec | Bullets | Damage each | Behavior |
| --- | --- | --- | --- | --- |
| Pulse | 5 | 1 | 5 | Precise cyan core, tapered line trail |
| Fan | 2.5 | 3 | 3 | Symmetric 22-degree volley, short particle trails |
| Lance | 2 | 1 | 12 | Violet elongated core, pierces two additional targets |

There is no damage to the player, enemy movement, upgrade UI, homing or status-effect system yet.

## Inspector tuning and future upgrades

Open `features/player/player.tscn`, select its AutoShooter instance, and expand **Arsenal**.
The three saved WeaponDefinition presets live under `data/weapons`.

WeaponDefinition exposes `display_name`, `attacks_per_second`, `bullet_count`, total
`spread_degrees`, `muzzle_distance`, `projectile` and `projectile_scene`. A single pellet
always uses the centerline; multiple pellets distribute evenly across the total spread.
Volley size is capped at 32. Projectile scenes use CombatProjectile or a derived script.

ProjectileDefinition exposes `damage`, `speed`, `lifetime`, `pierce_count`, `shape`, `colors`,
`visual_scale`, `trail_style` (none/line/particles), `trail_length`, and `impact_particles`.
Shape/color data still use the shared ShapeVisual renderer. Geometry remains independent of
collision: bullets use segment ray sweeps against world and target layers, excluding their
owner. The initial sweep covers the muzzle gap too. Walls stop every weapon. Piercing tracks
hit bodies so each projectile damages a target once.

At configuration time, AutoShooter explicitly copies each preset and its nested projectile,
ShapeDefinition and ShapeColors resources. PackedScenes are immutable templates and are shared.
The pickup system rebuilds from a clean base plus active modifiers. A new run starts from saved presets again.
Inspector edits to authored presets take effect on the next run/configuration; runtime code
should use `player.shooter.apply_modifier(definition)` for upgrades. Direct edits to
`active_weapon` below are transient debugging examples and are replaced on the next modifier rebuild:

```gdscript
var weapon: WeaponDefinition = player.shooter.active_weapon
weapon.attacks_per_second *= 1.15
weapon.bullet_count += 1
weapon.spread_degrees = 16.0
weapon.projectile.pierce_count += 1
```

Each fired volley receives its own data snapshot, so later changes cannot alter bullets already
in flight. Fire timing reads the active working resource without requiring a new weapon class.
This is an extension point for upgrades, not a completed upgrade or persistence system.

## Target feedback and respawn

All six targets and their positions are authored under TargetDummies and LiveTargets in the
movement-playground scene. Each target owns a per-instance hit shader, restrained scale pulse,
dual HP bar, death particles and a physics Timer. These fixed nodes are not constructed in code.
Only actual bullets and temporary impact bursts are dynamically instantiated under Projectiles.

The cyan HP layer updates immediately. The amber damage layer waits 0.18 seconds, then eases
down over 0.45 seconds. Repeated hits restart the delay from the currently visible chip value.
The HealthBar scene exports both times. HP values are shown above each bar.

LiveTargets override Max HP to **20**, Respawn On Death to **true**, and Respawn Delay to **5**.
On death, their body/bar disappear, collision is disabled, particles burst and a REBOOT countdown
remains at the authored position. Five gameplay seconds later, health and collision are restored
with a small pop-in animation. Pause freezes this countdown and all feedback tweens.
Million-HP targets retain their previous non-removal behavior even at zero health.
Player reset (R) still resets only the player.

`TargetDummy.apply_damage(amount) -> int` and `damage_received` retain their existing contract.
New `is_alive`, `died` and `respawned` support the optional respawn lifecycle.

## Verification

`godot --headless --path . --script tests/combat_check.gd` checks explicit nested-copy isolation,
upgrade retention on weapon switches, symmetric spread, in-flight snapshots, actual projectile
damage, instant/chip bar behavior, repeated hits, paused tweens/countdowns, death and five-second
respawn, piercing without duplicate hits, high-speed wall sweeps and attack rate. Existing
movement, dash, pause/settings and target-dummy tests pass with automatic fire disabled in those
fixtures. D3D12 screenshots were inspected for bullet readability, the split bar and reboot state.
The environment still emits the known certificate-store warning.

Manual review: aim at the three southern targets, switch weapons, hit one target repeatedly,
pause its countdown, and confirm that it reappears at 20 HP after resuming. Try shots while
dashing and moving diagonally. Controller input tests are simulated; hardware remains a manual check.

Suggested commit: `Add resource-driven auto fire, projectile feedback and respawning targets`.
