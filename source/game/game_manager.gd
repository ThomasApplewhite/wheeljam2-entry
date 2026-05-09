extends Node

#this manages fight start and end brb gotta pee
#except, idk what I want this to do yet...

@export_category("Game Settings")
@export var rounds_to_win : int

@export_category("Scene Exports")
@export var opponent : WCharacter
@export var player : WCharacter
@export var gameover_camera : Camera3D
@export_file("*.tscn") var main_menu_scenepath : String

@export var opponent_start : Marker3D
@export var player_start : Marker3D

@onready var restart_timer : Timer = $Timers/RestartTimer
@onready var prerestart_timer : Timer = $Timers/PreRestartTimer

@onready var restart_ui : Control = $CanvasLayer/GameUI/RoundRestart
@onready var restart_ui_bar = $CanvasLayer/GameUI/RoundRestart/ProgressBar
@onready var restart_round_label : Label = $CanvasLayer/GameUI/RoundRestart/Label

@onready var gameover_ui : Control = $CanvasLayer/GameUI/EndOfGameControl
@onready var gameover_label : Control = $CanvasLayer/GameUI/EndOfGameControl/Label

@onready var win_jingle : AudioStreamPlayer = $GameAudio/WinAudioStreamPlayer
@onready var lose_jingle : AudioStreamPlayer = $GameAudio/LoseAudioStreamPlayer
@onready var round_start_jingle : AudioStreamPlayer = $GameAudio/BeginAudioStreamPlayer

var _player_wins : int = 0
var _opp_wins : int = 0

var _rounds : int = 1

func _ready() -> void:
	restart_round()
	win_jingle.finished.connect(_return_to_menu)
	lose_jingle.finished.connect(_return_to_menu)


func _process(_delta: float) -> void:
	restart_ui_bar.value = restart_timer.time_left


func prerestart_round(slain : WCharacter) -> void:
	player.lock_movement = true
	opponent.lock_movement = true
	
	_rounds += 1
	if slain == player:
		_opp_wins += 1
	else:
		_player_wins += 1
	
	prerestart_timer.start()


func restart_round() -> void:
	# set positions and do something on the UI
	player.global_position = player_start.global_position
	opponent.global_position = opponent_start.global_position
	
	for in_char in [player, opponent]:
		in_char.hp = in_char.max_hp
		in_char.lock_movement = true
		in_char.anim_handler.play_action_animation(AnimationHandler.AnimatedAction.STANCE_CHANGE, 
			AnimationHandler.SwordStance.NORTH)
	
	#UI thing goes here
	restart_ui.visible = true
	restart_round_label.text = ("ROUND %d" % [_rounds])
	restart_ui_bar.max_value = restart_timer.wait_time
	
	restart_timer.start()


func _handle_win() -> bool:
	if _player_wins < rounds_to_win and _opp_wins < rounds_to_win:
		return false
	
	var win_text : String
	if _player_wins >= rounds_to_win:
		win_text = "You Win!"
		win_jingle.play()
	if _opp_wins >= rounds_to_win:
		win_text = "You Lose"
		lose_jingle.play()
	
	player.disable_anims_for_gameover()
	opponent.disable_anims_for_gameover()
	
	gameover_camera.make_current()
	gameover_label.text = win_text
	print(win_text)
	gameover_ui.visible = true
	
	return true

func _on_restart_timer_timeout() -> void:
	#start fight!
	restart_ui.visible = false
	player.lock_movement = false
	opponent.lock_movement = false
	round_start_jingle.play()


func _on_pre_restart_timer_timeout() -> void:
	if not _handle_win():
		restart_round()


func _on_w_character_slain(who: WCharacter) -> void:
	prerestart_round(who)
	

func _return_to_menu() -> void:
	get_tree().change_scene_to_file(main_menu_scenepath)
