extends Node

#this manages fight start and end brb gotta pee
#except, idk what I want this to do yet...

@export_category("Game Settings")
@export var rounds_to_win : int

@export_category("Scene Exports")
@export var opponent : WCharacter
@export var player : WCharacter

@export var opponent_start : Marker3D
@export var player_start : Marker3D

@onready var restart_timer : Timer = $Timers/RestartTimer
@onready var prerestart_timer : Timer = $Timers/PreRestartTimer

@onready var restart_ui : Control = $GameUI/RoundRestart
@onready var restart_ui_bar : ProgressBar = $GameUI/RoundRestart/ProgressBar
@onready var restart_round_label : Label = $GameUI/RoundRestart/Label

@onready var win_jingle : AudioStreamPlayer = $GameAudio/WinAudioStreamPlayer
@onready var lose_jingle : AudioStreamPlayer = $GameAudio/LoseAudioStreamPlayer
@onready var round_start_jingle : AudioStreamPlayer = $GameAudio/BeginAudioStreamPlayer

var _player_wins : int = 0
var _opp_wins : int = 0

var _rounds : int = 1

func _ready() -> void:
	restart_round()


func _process(_delta: float) -> void:
	restart_ui_bar.value = restart_timer.time_left


func prerestart_round(winner : WCharacter) -> void:
	_rounds += 1
	if winner == player:
		_player_wins += 1
	else:
		_opp_wins += 1
	
	prerestart_timer.start()


func restart_round() -> void:
	# set positions and do something on the UI
	player.global_position = player_start.global_position
	player.hp = player.max_hp
	player.lock_movement = true
	opponent.global_position = opponent_start.global_position
	opponent.hp = opponent.max_hp
	
	#UI thing goes here
	restart_ui.visible = true
	restart_round_label.text = ("ROUND %d" % [_rounds])
	restart_ui_bar.max_value = restart_timer.wait_time
	
	restart_timer.start()


func _on_restart_timer_timeout() -> void:
	#start fight!
	restart_ui.visible = false
	player.lock_movement = false
	opponent.lock_movement = false
	round_start_jingle.play()


func _on_pre_restart_timer_timeout() -> void:
	if _player_wins >= rounds_to_win:
		print("Player wins!")
		win_jingle.play()
		return
	if _opp_wins >= rounds_to_win:
		print("Opponent wins!")
		lose_jingle.play()
		return
	
	restart_round()


func _on_w_character_slain(who: WCharacter) -> void:
	prerestart_round(who)
