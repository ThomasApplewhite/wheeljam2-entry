extends FPSController3D
class_name WCharacter

## This script is a copy of the expressobits controller, because there's really no reason to
## reinvent the wheel

signal slain(who : WCharacter)

const NO_PARRY : int = -99

@export var max_hp : int = 100
@export var sword : WSwordHitbox

@onready var dodge_ability : WDodgeAbility3D = $WDodgeAbility3D
@onready var camera_ref : Marker3D = $Head
@onready var col_handler : CollisionHandler = $CollisionHandler

@onready var hp : int = max_hp
var _parry_commit : int = 0


#this should be set automatically but who really cares
@export var ztarget : Node3D

enum ActionState {
	BLOCKING,
	STRIKING,
	PARRYING,
	STUNNED
}

enum SwordStance {
	NORTH,
	EAST,
	SOUTH,
	WEST
}

var current_state : ActionState = ActionState.BLOCKING
var lock_movement : bool = false


func _ready():
	setup()
	_abilities.append(dodge_ability)


func receive_strike(hit_pos: Vector3, incoming_commitment : int, incoming_damage : int) -> int:
	var block : bool = current_state == ActionState.BLOCKING or current_state == ActionState.PARRYING
	var incoming_blocked : bool = col_handler.resolve_strike(position, hit_pos, get_current_stance(), 
		block, incoming_damage, incoming_commitment)
	
	# If the incoming attack was blocked AND we were parrying, tell the attacker they've been parried
	if incoming_blocked and current_state == ActionState.PARRYING:
		return _parry_commit
	
	# Otherwise, give them a value they'll always beat
	return NO_PARRY


# similarly "should be abstract but w/e" type method
func get_current_stance() -> SwordStance:
	return SwordStance.NORTH


func _look_at_ztarget() -> void:
	# rotate head to face z target
	var forward = -transform.basis.z
	var dir_to_target = (ztarget.global_position - global_position).normalized()
	dir_to_target.y = 0.0
	var rotate_dir = (dir_to_target - forward)
	if(dir_to_target.dot(forward) != 1.0):
		rotate_head(Vector2(rotate_dir.x, rotate_dir.y) * 100.0)

func _on_collision_handler_strike_taken(damage: int) -> void:
	hp -= damage
	if hp <= 0:
		slain.emit(self)
		lock_movement = true


func _on_collision_handler_strike_blocked(attack_commitment : int) -> void:
	if current_state == ActionState.BLOCKING:
		#idk, nothing?
		return
	
	if current_state == ActionState.PARRYING:
		if _parry_commit < attack_commitment:
			_on_parried()


func _on_parried() -> void:
	# get parried loser: set to stun state (which blocks all inputs except stepping)
	# and restore after a timer passes.
	pass
