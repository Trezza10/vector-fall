# Stackable pickup modifications

Six elemental/on-hit pickups are now available to the east: Burn, Poison, Ice, Stun,
Knockback and Mark. See [STATUS_EFFECTS.md](STATUS_EFFECTS.md) for their durations, stacking
and tuning. There are fifteen editor-authored pickups in total.

Press F5 and walk over a colored diamond. Pickups combine on the starting Pulse weapon;
the 1/2/3 and LB weapon-switch shortcuts have been removed. F still toggles auto-fire.

| Pickup | Effect per stack |
| --- | --- |
| Multishot | +1 bullet and +8 degrees of total fan spread |
| Rapid fire | +20% of base attacks per second |
| Impact | +2 bullet damage |
| Piercing | +1 target penetration |
| Velocity | +150 pixels/second bullet speed |

Each stack now lasts **the entire run** by default. Collecting another copy adds another
stack, and mixed pickup types combine. The HUD shows stack counts marked “run”. Restarting
the run clears all stacks; R only resets the player and does not reset upgrades.
Optional timed buffs still support independent expiration, including while auto-fire is off;
pause freezes their timers.

Fifteen pickups are authored under `Pickups` in the movement-playground scene. Each recharges
after **8 seconds**, allowing repeat collection to demonstrate stacking. Staying on a pickup
can collect its next recharge. Recharge does not extend or otherwise change active buff timers.

## Inspector configuration

Select a pickup instance:

- **Modification** references a saved resource under `data/modifications`.
- Expand it and change **Duration Seconds** to set the buff lifetime. `0` is the current
  default and lasts until the run restarts; a positive number enables timed expiration.
- **Respawn Seconds** on the pickup controls the separate ground-pickup recharge interval.
- Other resource fields set count, spread, fire-rate fraction, damage, pierce and velocity
  bonuses. Color resources control its core/halo and collection burst.
- Saved modification resources are intentionally shared. Make Unique before changing only
  one instance. Active stacks copy the resource and colors, so editing presets cannot change
  a stack already collected.

Pickups and their positions, shapes, labels, collider, burst and recharge Timer are authored
in `features/pickups/upgrade_pickup.tscn` and the playground. Tool-mode logic only refreshes
their existing preview nodes; it creates no scene nodes or files.

## Stacking contract

`AutoShooter.apply_modifier(definition) -> bool` snapshots the resource and adds one stack.
`modifier_stack_count(id)`, `modifier_time_left(id)` and `modifier_summary()` support the HUD.
`modifiers_changed` is emitted on collection/expiration. Stacks are private typed runtime
records, not saved-resource state.

Stats rebuild from a clean base whenever a stack changes. This avoids rounding drift and
incorrect removal after reaching caps, and makes collection order irrelevant. Fire-rate
bonuses add against the base: two Rapid fire stacks yield 5 × 1.4 = 7 attacks/second.
Caps are 32 bullets, 180 degrees spread, 30 attacks/sec, 10,000 damage, 32 penetrations and
3,000 projectile pixels/sec. Expiration preserves progress through the current firing interval.
Existing bullets retain their volley snapshot.

Use the modifier API for temporary upgrades. Direct edits to `active_weapon` are transient
and will be replaced by the next rebuild. `select_weapon()` is retained for authoring/tests;
it rebuilds from the selected base and current modifiers, without gameplay hotkeys.

## Verification

`godot --headless --path . --script tests/pickup_check.gd` verifies real player-overlap
collection, duplicate prevention, recharge, independent 30-second expiry, pausing, mixed
bonuses, order independence, resource isolation, capped-stat expiration and configurable
run-only duration. Combat checks also pass. D3D12 captures were inspected for labels and
the stacked HUD.

Manual acceptance: collect both Multishot pickups, combine them with Rapid fire/Piercing,
watch the fan grow, and confirm stacks remain after 30 seconds and after player reset.
Change Duration Seconds in the Inspector and restart to test a different lifetime.

Suggested commit: `Replace weapon hotkeys with configurable timed stacking pickups`.
