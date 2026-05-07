extends Area3D

## Sword Hitboxes handle both collisions and the damage that attacks deal
const character_hitbox_layer : int = 2

var _current_commitment : int
var _damage : int

func _ready() -> void:
	body_entered.connect(_on_body_entered)


func start_attack_active(attack_commitment : int, base_damage : int) -> void:
	set_collision_mask_value(character_hitbox_layer, true)


func end_attack_active() -> void:
	set_collision_mask_value(character_hitbox_layer, false)


func _on_body_entered(body : Node3D):
	var wcharacter : WCharacter = body as WCharacter
	if wcharacter:
		# damage needs to be recalculated based on some factors I'll get there
		wcharacter.col_handler.receive_strike(Vector3(), _current_commitment, _damage)
		end_attack_active()
	
