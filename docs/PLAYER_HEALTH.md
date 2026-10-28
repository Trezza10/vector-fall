# Player health

The fixed bottom-left HUD bar reuses DamageHealthBar: cyan HP falls immediately and
an amber chip follows with the existing delay/ease. The label shows PLAYER current / max.
The shared bar now supports an optional prefix/current-max label and stretches its child
bars to its authored width; enemy bars retain their existing defaults and appearance.
The HUD instance and existing player audio nodes remain authored in scene files.

Player starts at 100 HP. Tune Max HP and Hit Grace Period on the Player instance. Enemy
contact and projectile damage are configured in each EnemyDefinition. Existing accepted
hit feedback now also subtracts actual HP, clamped to remaining health. Zero/negative,
paused, grace-window and already-depleted hits do nothing and do not replay the cue.

IncomingHitSound reuses ActionSound and assets/audio/hit.wav. Depletion reuses kill.wav.
Both route to Combat and obey saved volume/mute settings. Flash and damage grace continue
to work, and pause freezes grace, shared bar animation and gameplay sound playback.

At zero HP, movement, dash, firing and pickup collection stop. Any active dash ends and
its trail clears. A depletion hint asks for R. R restores HP and charges, resets the enemy
encounter and clears hostile shots, while preserving upgrades and auto-fire preference.
This is a playground reset, with no game-over menu, automatic respawn or saved HP state.

API: Player.current_hp and is_alive are read-only; health_changed(current, maximum),
hit_received(actual_damage) and died report changes. receive_enemy_hit(amount) retains its
bool success result. Player owns health; the playground connects its signal to the shared
bar. AutoShooter.firing_blocked gates manual and automatic firing without changing the
chosen auto-fire setting. The modifier timer owner and weapon resource copies are unchanged.

Verification: player_health_check covers shared HUD sizing/text/chip behavior, actual enemy
contact and projectile HP loss, damage sound and Combat routing, blocked hit audio, pause,
lethal clamping, zero-HP input/firing/collection guards, and reset with preserved upgrades
and fire preference. Enemy, combat, dash-upgrade and audio/settings regressions pass.
D3D12 screenshot reviewed at 65/100 HP with the amber chip visible. Existing Godot shutdown
script-reference and certificate-store diagnostics remain as documented for the enemy set.

Manual: F5, approach the western enemies, take hits, pause during the chip animation,
adjust Combat volume, reach zero HP and press R. Health should return to full immediately.

Suggested commit: Add player health using the shared damage bar and sound components.


Player health now also supports Player.heal and green repair pickups. Damage/healing
feedback, configuration and verification are described in DAMAGE_AND_HEALING.md.
