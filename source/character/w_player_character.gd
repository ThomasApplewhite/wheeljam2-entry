extends FPSController3D
class_name WPlayerCharacter

## This script is a copy of the expressobits controller, because there's really no reason to
## reinvent the wheel

@export var input_back_action_name := "move_backward"
@export var input_forward_action_name := "move_forward"
@export var input_left_action_name := "move_left"
@export var input_right_action_name := "move_right"
#@export var input_sprint_action_name := "move_sprint"
#@export var input_jump_action_name := "move_jump"
#@export var input_crouch_action_name := "move_crouch"
#@export var input_fly_mode_action_name := "move_fly_mode"

@onready var dodge_ability : WDodgeAbility3D = $WDodgeAbility3D
@onready var camera_ref : Marker3D = $Head/FirstPersonCameraReference

@export var underwater_env: Environment


func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	setup()
	#emerged.connect(_on_controller_emerged.bind())
	#submerged.connect(_on_controller_subemerged.bind())


func _physics_process(delta):
	var is_valid_input := Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED
	
	# First, rotate towards whatever we are Z-targeting, if anything.
	#rotate_head(somehow)
	
	#Second, rotate our current velocity to go with it
	#this might be done for me
	#velocity = velocity
	
	#Third, handle the dodge!
	if is_valid_input:
		var dodge_dir : Vector3 = _determine_dodge_direction()
		velocity = dodge_ability.apply(velocity, 0.0, is_on_floor(), dodge_dir, delta)
		
	move(delta)


func _input(event: InputEvent) -> void:
	# Mouse look (only if the mouse is captured).
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		rotate_head(event.screen_relative)

func _determine_dodge_direction() -> Vector3:
	# The direction the camera is looking
	#var dir : Vector3 = camera_ref.transform.basis.z
	var dir : Vector3 
	# Flat plane direction of camera facing
	#dir.y = 0.0
	#dir = dir.normalized()
	
	if Input.is_action_just_pressed("move_forward"):
		dir.z -= 1.0
	if Input.is_action_just_pressed("move_backward"):
		dir.z += 1.0
	if Input.is_action_just_pressed("move_left"):
		dir.x -= 1.0
	if Input.is_action_just_pressed("move_right"):
		dir.x += 1.0
	
	return dir


#func _on_controller_emerged():
	#camera.environment = null
#
#
#func _on_controller_subemerged():
	#camera.environment = underwater_env
