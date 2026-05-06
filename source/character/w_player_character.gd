extends FPSController3D
class_name WPlayerCharacter

## This script is a copy of the expressobits controller, because there's really no reason to
## reinvent the wheel

signal player_slain()

@export var input_back_action_name := "move_backward"
@export var input_forward_action_name := "move_forward"
@export var input_left_action_name := "move_left"
@export var input_right_action_name := "move_right"
@export var max_hp : int = 100

@onready var dodge_ability : WDodgeAbility3D = $WDodgeAbility3D
@onready var camera_ref : Marker3D = $Head
# the wheel handles its own input, we only need to respond to it. praise be.
@onready var wheel : Wheel = $Control/Wheel
@onready var debug_label : Label = $Control/Label
@onready var col_handler : CollisionHandler = $CollisionHandler

@onready var hp : int = max_hp

#this should be set automatically but who really cares
@export var ztarget : Node3D
@export var show_debug_values : bool = true


func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	setup()
	_abilities.append(dodge_ability)
	


func _physics_process(delta):
	# rotate head to face z target
	var forward = -transform.basis.z
	var dir_to_target = (ztarget.global_position - global_position).normalized()
	dir_to_target.y = 0.0
	var rotate_dir = (dir_to_target - forward)
	if(dir_to_target.dot(forward) != 1.0):
		rotate_head(Vector2(rotate_dir.x, rotate_dir.y) * 100.0)
	
	var is_valid_input := Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED
	
	if is_valid_input:
		var input_axis = Input.get_vector(input_left_action_name, input_right_action_name, input_back_action_name, input_forward_action_name)
		move(delta, input_axis, false, false, false, false, false)
	else:
		move(delta)


func receive_strike(hit_pos: Vector3, incoming_damage : int) -> void:
	col_handler.resolve_strike(position, hit_pos, wheel.current_direction, true, incoming_damage)


"""
#region WheelPayload Class
## allows us to create wheel payload objects and assign values to the wheel.
class WheelPayload:
	var base_value:int
	var slice_value:int
	var total_value:int
#endregion
var current_direction:int = 0 ## where the selector currently is.
const DIRECTIONS:Array[int] = [0,90,180,270] ## rotation value (in degrees) for the wheel directions. [UP,RIGHT,DOWN,LEFT]
"""
# Wheel Slice selected
func _on_wheel_new_dir_chosen(payload: RefCounted) -> void:
	#attacks go here, the above payload can be used to calculate wheel value
	pass


# Wheel rotated
func _on_wheel_new_dir_selected() -> void:
	var text = "Wheel direction: %d" % wheel.current_direction
	debug_label.text = text
	#change stance here


func _on_collision_handler_strike_taken(damage: int) -> void:
	hp -= damage
	if hp >= 0:
		player_slain.emit()


func _on_collision_handler_strike_blocked() -> void:
	pass # Replace with function body.
