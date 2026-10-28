# Dash upgrades

F5: collect the blue Dash Reserve or green Quick Dash pickups just above either side
of the player's starting position. Both recharge on the ground after 8 seconds and stack
for the run. Existing pickup sounds, particles and stack summaries apply to both.

- Dash Reserve adds one capacity and grants that new charge immediately, up to 8 total.
- Quick Dash subtracts 10% of base recharge time per stack, capped at 80% reduction.
  Recharge cannot be shorter than the player's Minimum Dash Cooldown (default 0.2s).

Press Space / RB for each dash. A reserve allows another dash after the current burst
ends, even while a spent charge is still recharging. Charges return sequentially; spending
another charge never restarts a pending timer. The HUD shows available/maximum charges,
seconds per charge and progress toward the next charge. Default single-charge behavior
is preserved. Pause freezes recharge; R refills the current upgraded reserve.

Player Inspector: Base Dash Charges, Dash Cooldown, Minimum Dash Cooldown. Pickup resource
Inspector: Dash Charge Bonus and Dash Cooldown Reduction under Dash Upgrades, plus existing
Duration Seconds (0 = run-long). The two resources are data/modifications/dash_charge.tres
and dash_cooldown.tres. Fixed pickups and the HUD are authored in movement_playground.tscn.

The existing WeaponModification resource/AutoShooter stack owner also holds mobility bonus
values, avoiding a second duration system. Player remains responsible for actual charges and
recharge. A bonus change preserves the fraction of the current recharge; capacity loss from
optional timed stacks clamps available charges. Extra capacity grants only the newly added
slots, never refilling previously spent slots. Weapon switching preserves mobility stacks.
Run reconfiguration clears them. Public player reads: dash_charges, max_dash_charges,
effective_dash_cooldown and existing dash_cooldown_remaining.

Verification: dash_upgrade_check exercises real pickup overlap, new-slot grants during
recharge, repeat spending, sequential recharge, progress preservation, stacking/caps,
pause, reset, weapon switching and timed expiry. Existing dash, pickup, combat and critical
hit tests pass. D3D12 capture inspected for pickup placement and charge/recharge HUD.

Suggested commit: Add dash reserve and recharge upgrade pickups.
