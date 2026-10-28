class_name TargetDamageNumbers
extends Node2D

@export_range(0.0, 0.5, 0.05) var overlap_tail: float = 0.5

@onready var _numbers: Array[FloatingDamageNumber] = [
	$Bullet, $Burn, $Poison, $Ice, $Stun, $Knockback, $Mark, $Critical]

@onready var _alternates: Array[FloatingDamageNumber] = [
	$BulletAlternate, $BurnAlternate, $PoisonAlternate, $IceAlternate,
	$StunAlternate, $KnockbackAlternate, $MarkAlternate, $CriticalAlternate]
var _use_alternate: Array[bool] = [false, false, false, false, false, false, false, false]

func show_damage(amount: int, target_position: Vector2, source: DamageSource.Kind) -> void:
	if amount <= 0 or get_tree().paused:
		return
	if source < 0 or source >= _numbers.size():
		push_error("Damage source has no authored damage-number lane.")
		return
	var number: FloatingDamageNumber = _alternates[source] if _use_alternate[source] else _numbers[source]
	# A half-lifetime minimum accumulation window keeps two authored slots sufficient.
	var tail: float = minf(overlap_tail, number.lifetime * 0.5)
	if number.is_active and number.remaining_lifetime <= tail + 0.00001:
		var next_number: FloatingDamageNumber = _numbers[source] if _use_alternate[source] else _alternates[source]
		if not next_number.is_active:
			_use_alternate[source] = not _use_alternate[source]
			number = next_number
	number.add_damage(amount, target_position)

func reset_numbers() -> void:
	for number: FloatingDamageNumber in _numbers: number.reset_number()
	for number: FloatingDamageNumber in _alternates: number.reset_number()
	_use_alternate.fill(false)
