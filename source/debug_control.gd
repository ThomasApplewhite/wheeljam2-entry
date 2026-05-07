extends Control


@export var player : WCharacter
@export var opp : WCharacter

@onready var health_label : Label = $Label

func _process(_delta: float) -> void:
	health_label.text = ("Player Health: %d\nOpponent Health: %d" % [player.hp, opp.hp])


func _on_strike_player_button_pressed() -> void:
	player.receive_strike(player.global_position + Vector3.UP, 0, 10)


func _on_strike_opp_button_pressed() -> void:
	opp.receive_strike(opp.global_position + Vector3.UP, 0, 10)
