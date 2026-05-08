extends WCharacter
class_name WPlayerCharacter

## The player character!

@export var input_back_action_name := "move_backward"
@export var input_forward_action_name := "move_forward"
@export var input_left_action_name := "move_left"
@export var input_right_action_name := "move_right"
@export var input_parry_mode_name := "parry_mode"

# the wheel handles its own input, we only need to respond to it. praise be.
@onready var wheel : Wheel = $Control/Wheel
@onready var debug_label : Label = $Control/Label

@export var show_debug_values : bool = true


func _ready() -> void:
	super()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _physics_process(delta):
	_look_at_ztarget()
	
	var is_valid_input := Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED
	
	if is_valid_input and not lock_movement:
		var input_axis = Input.get_vector(input_left_action_name, input_right_action_name, input_back_action_name, input_forward_action_name)
		move(delta, input_axis, false, false, false, false, false)
	else:
		move(delta)


func get_current_stance() -> SwordStance:
	var i = wheel.current_direction / 90
	return i as SwordStance

"""
#region WheelPayload Class
## allows us to create wheel payload objects and assign values to the wheel.
class WheelPayload:
	var base_value:int
	var slice_value:int
	var total_value:int
#endregion
"""
# Wheel Slice selected
func _on_wheel_new_dir_chosen(payload: RefCounted) -> void:
	# Step 0: Can we even attack?
	if current_state != ActionState.BLOCKING:
		return
	
	# Step 1: Is this a parry?
	var is_parry : bool = Input.is_action_pressed(input_parry_mode_name)
	
	# If parrying, enter parry state
	# whatever that means
	if is_parry:
		return
	
	# What is damage? idk, put 10 here for now
	sword.start_attack_active(payload.slice_value, 10)
		
	# start animation; time it out based on commitment. When it's over
	# (or, some % through it), turn the attack off
	
	# oh, and if the wheel is full, it should be reset after striking or parrying


# Wheel rotated
func _on_wheel_new_dir_selected() -> void:
	var text = "Wheel direction: %d" % wheel.current_direction
	debug_label.text = text
	# stance change anim here
