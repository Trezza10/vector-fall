# Floating damage numbers

Each target owns a scene-authored `DamageNumbers` node with fixed pairs of Bullet, Burn, Poison,
Ice, Stun, Knockback and Mark lanes. No damage-number nodes are spawned during play.
Only lanes that receive actual damage become visible.

Each lane has a **hard one-second lifetime from its first hit**. Same-source hits during
the first 0.5 seconds add to its total and repeat its scale punch, but never restart its lifetime,
fade, or position. During the final 0.5 seconds, the next hit starts a fresh total in the alternate
authored slot while the previous total finishes fading unchanged. Continuous fire therefore
rolls into new windows rather than accumulating forever. Every source and target has an
independent window, and source lanes use different offsets to stay readable together.

Each new window samples bounded spawn scatter, launch angle/speed, horizontal drift, arc,
initial tilt, angular drift and punch strength. Same-window hits keep those samples, so the
number never jumps or changes direction abruptly. Defaults scatter within 6px horizontally
and vertically, tilt within 12 degrees and spin up to 10 degrees/second. Different source
lanes retain their base offsets. Travel stays bounded and every window still expires at one second.

The numbers use a compact bold monospace SystemFont (Cascadia Mono / Consolas / DejaVu Sans
Mono / monospace fallback), a restrained dark outline and a small shadow. They punch to 1.4×,
recover over 0.22 seconds, drift upward and fade after a 0.2-second hold. Travel is capped at
64 pixels. Knockback does not drag an existing world-space number around.

| Source | Default color |
| --- | --- |
| Bullet / direct damage | White |
| Burn | Red |
| Poison | Green |
| Ice | Cyan |
| Stun | Yellow |
| Knockback | Pale blue-grey |
| Mark | Pink |

Burn/poison ticks retain their source when routed to the numbers. Ice, stun, knockback and
Mark currently do not deal separate damage, so applying those statuses creates no fictitious
numbers. Mark amplifies the original damage source; a marked bullet hit remains white.
Elemental bullet tint does not change the source of its base damage.

## Configuration and contracts

Open `features/target_dummy/target_damage_numbers.tscn` and select a lane to edit its
**Number Color**, Lifetime, Fade Delay, Punch Scale/Duration, Spawn Offset, Drift Velocity,
Max Drift and Font Size. The **Variation** Inspector group exposes Spawn Scatter, Drift Angle
Variation, Horizontal Drift Variation, Speed Variation, Tilt Variation, Spin Variation,
Arc Gravity and Punch Variation. Open `floating_damage_number.tscn` to change the shared font style.
Enable Editable Children on a target for per-instance overrides. No color settings UI is added.

`TargetDummy.apply_damage(amount, source = DamageSource.Kind.BULLET)` keeps existing callers
white by default. ProjectileDefinition also exports `damage_source` for future direct elemental
shots. `DamageSource.Kind` is the typed source identifier; it is separate from status kind.
TargetDamageNumbers routes applied damage to its corresponding authored lane.

Simultaneous DoT retains separate burn/poison amounts. The target preserves the previous
combined tick's vulnerability rounding and HP clamp, then apportions that actual total to
the source lanes. Colored totals therefore sum to actual HP lost without changing balance.
`damage_received` retains its existing signature and fires for each positive source portion.

Pause freezes animation. Invalid/zero damage does not update a number. Lethal numbers remain
at the death location until expiry; health reset/respawn clears all lanes. FloatingDamageNumber
still exposes `add_damage`, `reset_number`, `displayed_damage`, `is_active`, and
`remaining_lifetime`. TargetDamageNumbers exposes `show_damage` and `reset_numbers`.

## Verification

`tests/damage_number_check.gd` passes hard expiry under sustained hits, new-window totals,
punch without lifetime/alpha reset, independent source colors/positions/windows, the monospace
font, real DoT attribution, unchanged vulnerability rounding, pause and lethal/respawn cleanup.
Combat and status regression checks pass. A D3D12 capture was inspected for white/red/green
numbers, source separation and readability.

`tests/damage_number_variety_check.gd` verifies 32 reproducible randomized windows, varied
origins/angles/paths, bounds, upward launches, stable aggregation, and hard expiry. Both
damage-number checks pass, and the updated D3D12 capture was visually reviewed.

The bullet lane now starts centered horizontally over its target, with only 6px of spawn
scatter on each axis. Effect lanes use compact symmetric offsets around that center rather
than the previous wide left/right arrangement. Trajectory/rotation variation remains active.

Manual review: combine Burn and Poison, hold fire on a training target and watch three
colored totals roll over independently each second. Late hits must not brighten or prolong
an expiring total. Stop firing, test pause, and kill/respawn a 20-HP target.

Suggested commit: `Bound damage-number windows and separate colored damage sources`.

Select DamageNumbers to configure Overlap Tail (default 0.5 seconds). The effective
tail is capped at half the lifetime to keep two slots sufficient. Paired slots expose
independent visual settings; keep paired lifetimes and styles matched.
