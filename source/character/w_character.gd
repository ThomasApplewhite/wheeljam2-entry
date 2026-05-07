extends FPSController3D
class_name WCharacter

## This script is a copy of the expressobits controller, because there's really no reason to
## reinvent the wheel

signal slain(who : WCharacter)

@export var max_hp : int = 100

@onready var dodge_ability : WDodgeAbility3D = $WDodgeAbility3D
@onready var camera_ref : Marker3D = $Head
@onready var col_handler : CollisionHandler = $CollisionHandler

@onready var hp : int = max_hp

#this should be set automatically but who really cares
@export var ztarget : Node3D

var lock_movement : bool = false

func _ready():
	setup()
	_abilities.append(dodge_ability)


# It's up to the client class to handle strikes
func receive_strike(_hit_pos: Vector3, _incoming_commitment : int, _incoming_damage : int) -> void:
	pass


func _on_collision_handler_strike_taken(damage: int) -> void:
	hp -= damage
	if hp <= 0:
		slain.emit(self)
		lock_movement = true


func _on_collision_handler_strike_blocked() -> void:
	pass # Replace with function body.
