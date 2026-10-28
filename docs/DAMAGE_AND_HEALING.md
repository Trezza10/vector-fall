# Player damage emphasis and healing

F5: take an enemy hit in the western field. Accepted hits now cause a brief, bounded
camera shake/kick, a directional red edge flash and arrow toward the attacker, a bold
floating -N HP label, a brighter player flash and a red pulse on the shared HUD bar.
Low hull (below 25%) adds a steady edge tint and a red repair hint. Damage still uses the
existing grace window, sound and HP calculation; rejected hits do not restart feedback.

Two green cross REPAIR pickups are authored at the hostile-field entrance (720,800) and
inside the field (400,1180). They restore up to 25 HP and recharge on the ground after
10 seconds. A full-health or depleted player cannot consume one. Healing never exceeds
maximum HP, never adds modifier stacks and does not grant or restart damage grace.

Healing animates the shared front/chip bars upward over 0.4 seconds with a green pulse.
Its numeric value immediately reflects actual HP. A new damaging hit interrupts that
fill and replaces the green pulse with damage feedback. Pause freezes camera effects,
bar animations and audio; R clears all temporary effects and restores full HP instantly.

Inspector configuration:
- Main scene / PlayerDamageFeedback: Shake Pixels (0 disables shake), Shake Duration,
  Flash Intensity (0 disables impact edge flash), Flash Duration, Number Duration,
  Low Health Threshold (0 disables steady low-hull tint) and Damage Color for the bar.
- CanvasLayer / PlayerHealth: Animate Healing, Heal Duration and Heal Color, plus the
  existing chip settings and prefix/current-max label options.
- HealingPickup scene/instances: Healing Amount, Healing Colors and Respawn Seconds.
  Its cross is an authored ShapeDefinition and remains editable independently.

Reuse: repairs are an optional healing mode on UpgradePickup, sharing its collision,
visual halo, collection particles, recharge timer and sound players. DamageHealthBar owns
its pulse and healing fill; enemies retain default instant-heal behavior. Player reuses
the target hit shader and existing ActionSound cues. Fixed feedback/pickup nodes are all
scene-authored. Only node transforms, material uniforms and tween values change at runtime.

API: Player.heal(amount) returns actual restored HP (zero for invalid/full/paused/depleted).
receive_enemy_hit(amount, source_position = Vector2.INF) remains backward-compatible.
The existing hit_received(amount) signal is unchanged; damage_taken(amount, direction)
provides a normalized world-space source direction and reset_performed clears presentation.
Unknown sources use a symmetric flash and hide the directional arrow. Camera feedback
owns only Camera2D.offset; it preserves following/smoothing and makes no zoom/time-scale
changes. The low-health threshold uses actual HP, not the animated fill value.

Verification: damage_healing_check covers real repair overlap, healing clamp/rejection,
source direction, bounded/expiring shake, damage label and shader values, grace rejection,
pause/reset cleanup, green healing fill/pulse, healing interrupted by damage, collection
sound, full/depleted handling and low-hull recovery. Player-health, enemy, combat and pickup
regression checks pass. Rendered damage and healing captures were visually inspected.
Existing shutdown script-reference diagnostics remain as documented in ENEMIES.md.

Manual: take a hit from either side, verify flash/arrow direction, walk onto a repair,
pause mid-fill, resume, reach low hull and reset. Tune strength/timing after playtesting.

Suggested commit: Emphasize player damage and add reusable repair pickups.
