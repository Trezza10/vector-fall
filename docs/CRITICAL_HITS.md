# Critical hits

Direct projectile impacts roll crit chance independently per target. Starting chance is
0%; the two gold Critical Chance pickups near the player each add 10 percentage points,
stack for the run, recharge after 8 seconds, and cap total chance at 100%. The HUD shows
current chance. Burn/poison ticks do not crit. Default critical damage is 2x, rounded up,
then target vulnerability and remaining-HP clamping apply normally.

Inspector configuration:
- ProjectileDefinition: Crit Chance and Crit Multiplier.
- data/modifications/crit_chance.tres: Crit Chance Bonus and optional Duration Seconds.
- DamageNumbers/Critical and CriticalAlternate: gold color, 36px font, 1.8x punch,
  text prefix, motion and lifetime. Both are fixed scene instances.

Crit totals aggregate separately from ordinary white and colored effect totals. The label
reads CRIT followed by the actual damage total. Each number lasts one second and rolls
into its alternate slot after 0.5 seconds. Existing in-flight shots keep their original
crit stats; upgrading never changes shared presets. Critical is an appended DamageSource
kind; existing damage APIs retain their signatures.

Run F5, walk over the gold pickups near either side of the player, then shoot a training
target. Repeat pickups after recharge to increase the frequency; gold CRIT totals should
appear larger than white totals. Settings and damage stats remain available in the editor.

Verification: critical_hit_check exercises real pickup collection, additive stacking and
cap, snapshot isolation, noncrit and guaranteed crit damage, real projectile sweeps,
text/color/size/punch, overlap, pause, DoT separation and reset. Combat, pickup and damage
number regression checks pass. The D3D12 capture was reviewed for visual readability.

Suggested commit: Add critical hits and stackable crit-chance pickups.
