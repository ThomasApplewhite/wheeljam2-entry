extends WCharacter
class_name WOpponentCharacter

## This script is a copy of the player copy of the expressobits controller
## because there's really no reason to have a robust inheretence system in a game
## that'll be done before the week is out
## jk I actually made the inheritence

enum Intention {
	NONE,
	BLOCK,
	PARRY,
	PREP,
	DODGE,
	STRIKE
}

enum StanceEval {
	FASTEST,
	BIGGEST,
	MATCH,
	MISMATCH
}


@export var player : WPlayerCharacter

# Simulated Wheel.
# Each index is a direction (same as the sword stances).
# When a selection is made, the back wheel value goes to the front,
# and the index that was selected is added to used indicies.
# Once all 4 options are taken, the order of _wheel_values is randomized,
# and used indicies is reset.
var _wheel_values : Array[int] = [1, -1, 2, -2]
var _unused_indicies : Array[int] = [0, 1, 2, 3]
var _current_wheel_index : int = 0

@onready var brain : WOpponentDecisionTree = WOpponentDecisionTree.new()

func _ready() -> void:
	super()
	brain.player_proximity_raycast = $PlayerCLoseRayCast3D
	brain.player_proximity_raycast.add_exception(self)


func _physics_process(delta):
	_look_at_ztarget()
	
	# can't do anything if animating
	if anim_handler.playing_action:
		return
		
	var intent = brain.evaluate_and_act(player.get_current_stance(), get_current_stance(), 
		player.current_state, current_state)
	
	var input_dodge : bool = false
	
	match(intent):
		Intention.DODGE:
			input_dodge = true
		Intention.BLOCK:
			_change_wheel_index(brain._desied_stance as StanceEval)
		Intention.PARRY:
			_change_stance_and_parry()
		Intention.STRIKE:
			_change_stance_and_attack()
		# If NONE or PREP, do nothing
		_:
			pass
	
	# need to decide how AI does inputs
	if input_dodge and not lock_movement:
		var input_axis = brain.get_desired_dodge_dir()
		move(delta, input_axis, false, false, false, false, false)
	else:
		move(delta)


# "should be abstract but w/e" type method
func get_current_stance() -> SwordStance:
	return _current_wheel_index as SwordStance

func get_current_anim_stance() -> AnimationHandler.SwordStance:
	return _current_wheel_index as AnimationHandler.SwordStance


func _change_wheel_index(stance_eval : StanceEval) -> bool:
	var new_stance = _get_stance_from_eval(stance_eval)
	
	# If we're already in the stance, do nothing
	if _current_wheel_index == new_stance as int:
		return false
	
	_current_wheel_index = new_stance as int
	anim_handler.play_action_animation(AnimationHandler.AnimatedAction.STANCE_CHANGE, get_current_anim_stance())
	return true
	

func _change_stance_and_attack() -> void:
	# First, get into the right stance
	var stance_changing : bool = _change_wheel_index(brain.get_desired_stance() as StanceEval)
	
	#if the stance is changing, we need to wait for the anim
	if stance_changing:
		return
	
	# What is damage? idk, put 10 here for now
	sword.start_attack_active(_wheel_values[_current_wheel_index], 10)
	current_state = ActionState.STRIKING
	# hell yeah brother it's the inline dictionary lookup
	var attack_speed : float = {
		-2 : 1.25,
		-1 : 1.0,
		1 : .75,
		2 : .5
	}[_wheel_values[_current_wheel_index]]
	anim_handler.play_action_animation(
		AnimationHandler.AnimatedAction.STRIKE, 
		get_current_anim_stance(),
		attack_speed
	)
	
	_mark_index_as_used(_current_wheel_index)


func _change_stance_and_parry() -> void:
	# First, get into the right stance
	var stance_changing : bool = _change_wheel_index(brain.get_desired_stance() as StanceEval)
	
	#if the stance is changing, we need to wait for the anim
	if stance_changing:
		return
	
	# Parry time!
	current_state = ActionState.PARRYING
	anim_handler.play_action_animation(AnimationHandler.AnimatedAction.PARRY, get_current_anim_stance())
	
	_mark_index_as_used(_current_wheel_index)


func _mark_index_as_used(index : int) -> void:
	_unused_indicies.erase(index)
	var move : int = _wheel_values.pop_front()
	_wheel_values.push_back(move)
	
	if _unused_indicies.is_empty():
		_unused_indicies = [0, 1, 2, 3]
		_wheel_values.shuffle()


func _get_stance_from_eval(stance_eval : StanceEval) -> SwordStance:
	match(stance_eval):
		StanceEval.FASTEST:
			var fastest_stance : int = _wheel_values[_unused_indicies[0]]
			for index in _unused_indicies:
				if _wheel_values[_unused_indicies[index]] < fastest_stance:
					fastest_stance = _wheel_values[_unused_indicies[index]]
			return fastest_stance
		StanceEval.BIGGEST:
			var biggest_stance : int = _wheel_values[_unused_indicies[0]]
			for index in _unused_indicies:
				if _wheel_values[_unused_indicies[index]] > biggest_stance:
					biggest_stance = _wheel_values[_unused_indicies[index]]
			return biggest_stance
		StanceEval.MATCH:
			return player.get_current_stance()
		StanceEval.MISMATCH:
			var options = _unused_indicies.duplicate()
			options.erase(player.get_current_stance() as int)
			# If we're somehow out of mismatches, just match instead
			if options.is_empty():
				return player.get_current_stance() as int
			return options.pick_random()
		# If invalid eval, match to block
		_:
			return player.get_current_stance()

	


# We might simulate a wheel for the opponent character? but it will need
# to be handled differently so it isn't tied to input. I'll do that later,
# once we have a more concrete idea of what inputs do what and what about
# the wheel needs to be simulated. If needed, wheel methods can just be copied
# from the player
