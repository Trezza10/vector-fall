# Elemental and on-hit modifiers

Walk east to the **ON-HIT EFFECTS** pickup area. The six colored pickups recharge every
eight seconds, stack with existing upgrades, and last the entire run by default.

| Pickup | One-stack effect on a target | More pickup stacks |
| --- | --- | --- |
| Burn | 2 damage every 0.5s for 3s | More damage per tick |
| Poison | 1 damage every 0.5s for 5s | More damage per tick |
| Ice | 15% slow for 2.5s | More slow, capped at 80% |
| Stun | Stunned for 0.35s | Longer stun, capped at 2s |
| Knockback | Push approximately 18 pixels | Longer push, capped at 100px per hit |
| Mark | +15% damage taken for 3s | More vulnerability, capped at +100% |

Burn and poison coexist. An additional hit refreshes the existing status and retains the
stronger potency; it does not create unbounded per-bullet damage stacks. Its tick clock is
preserved, so continuous shooting cannot postpone DoT damage forever. Pickup stacks increase
the potency of the status payload itself. Knockback applies a new impulse on each hit.
Mark affects damage after application, including later DoT; the initial hit applies direct
damage before statuses. Damage is rounded up to integer HP after vulnerability is applied.

Ice and Stun expose `movement_multiplier` and `is_stunned` on TargetStatus. The current
targets have no AI or autonomous movement, so those two have visible indicators and valid
gameplay state but no walking/attack behavior to interrupt yet. Knockback does physically
move targets, decays smoothly, and stops/slides at collision geometry. Multiple rapid pushes
are limited to 1200 px/s. A respawning target returns to its authored spawn after five seconds.

## Visual feedback

Bullet cores/trails inherit the average tint of their combined effect types. Targets get a
matching shader tint, fine animated aura, subtle particles and an active-effect label. Hit
flashes, dual HP bars and death particles still work. All status visuals are existing scene
nodes in `features/target_dummy/target_status.tscn`; the component creates no visual nodes.
The modifier HUD sizes to its contents rather than obscuring the entire right side.

## Inspector configuration

Each pickup references a `data/modifications/<effect>.tres` WeaponModification. Its
**Duration Seconds** controls how long the player owns the upgrade (`0` = entire run).
Expand **On Hit Effects** to inspect the linked `data/effects/<effect>.tres` resource:

- **Kind** selects Burn, Poison, Ice, Stun, Knockback or Mark.
- **Duration Seconds** here controls how long the status lasts on the enemy.
- **Potency** means damage per tick, slow fraction, knockback distance, or vulnerability fraction.
- **Tick Interval** controls Burn/Poison ticks. Stun uses duration; its potency is unused.
- **Color** controls elemental bullet tint and target feedback.

These are shared authored presets. Make Unique to change one pickup independently. Working
modification copies and every projectile volley explicitly copy nested effect resources, so
editing a preset or collecting another upgrade cannot alter already-fired bullets or statuses.
Statuses also copy received payloads and never write to the projectile definition.

`WeaponModification.on_hit_effects` and `ProjectileDefinition.on_hit_effects` are typed arrays.
AutoShooter merges matching kinds when rebuilding a weapon. TargetDummy exposes
`apply_status(effect, direction)` and delegates status clocks to its TargetStatus child.
TargetStatus exposes `has_effect`, `effect_strength`, `effect_time_left`, `movement_multiplier`,
`damage_multiplier` and `is_stunned`; it emits `damage_tick`, `knockback_requested` and
`state_changed` to its owner. There is no global effects manager or event bus.

Pause freezes status clocks, DoT, knockback and visuals. Death/health reset clears statuses
and push velocity; respawn starts with clean health, tint and movement/vulnerability state.
Million-HP training targets remain present even at zero HP, as before.

## Verification

`tests/status_effect_check.gd` passes actual on-hit delivery, nested snapshot isolation,
ongoing burn/poison, refresh cadence, slow/stun expiry, Mark amplification, physical knockback
and walls, pause, stacked limits, lethal DoT cleanup and clean respawn. Combat, pickup and
dummy regression checks pass. D3D12 captures were reviewed for the rack and combined statuses.

Manual review: collect one effect, shoot a million-HP dummy, stop shooting to watch its
duration, then collect it again to compare strength. Combine elements, push a target into
a wall, pause mid-effect and kill a 20-HP target with DoT. Restart restores pickup stacks
and all target positions.

Suggested commit: `Add stackable elemental on-hit pickups and target status feedback`.
