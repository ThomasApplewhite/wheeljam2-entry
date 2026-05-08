extends RefCounted
class_name WOpponentDecisionTree

enum Intention {
	NONE,
	BLOCK,
	PARRY,
	PREP,
	DODGE,
	STRIKE
}

# Copied from Character
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

enum StanceEval {
	FASTEST,
	BIGGEST,
	MATCH,
	MISMATCH
}


var _current_intention : Intention = Intention.BLOCK
var _desired_move_dir : SwordStance = SwordStance.NORTH #This will be converted to a direction
var _desied_stance : StanceEval = StanceEval.FASTEST
var _prepframes : int = 0

func evaluate_and_act(player_stance_int : int, my_stance_int : int, 
	player_state_int : int, my_state_int : int) -> Intention:
	var my_state : ActionState = my_state_int as ActionState
	var my_stance : SwordStance = my_stance_int as SwordStance
	var player_state : ActionState = player_state_int as ActionState
	var player_stance : SwordStance = player_stance_int as SwordStance
	
	# If can't act, do nothing
	if my_state == ActionState.STRIKING or my_state == ActionState.PARRYING:
		return _current_intention
	
	# Self defense if player is actively striking
	if player_state == ActionState.STRIKING:
		return _evaluate_defense(my_state, my_stance, player_state, player_stance)
	
	# If it's go time, attack
	if _current_intention == Intention.PREP:
		if _prepframes > 0:
			_prepframes -= 1
			return Intention.PREP
		else:
			_current_intention = Intention.STRIKE
			return Intention.STRIKE
			
	# If available to attack, attack
	return _evaluate_offense(my_state, my_stance, player_state, player_stance)


func get_desired_dodge_dir() -> Vector2:
	return [Vector2.UP, Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT][_desired_move_dir]


func get_desired_stance() -> StanceEval:
	return _desied_stance


func _evaluate_defense(my_state : ActionState, my_stance : SwordStance, 
	player_state : ActionState, player_stance : SwordStance) -> Intention:
	# If stunned and player attacking, try to dodge
	if my_state == ActionState.STUNNED:
		_current_intention = Intention.DODGE	
	# If parry, try to parry
	elif my_stance == player_stance:
		_current_intention = Intention.PARRY
	# Can't parry? Try to block
	else:
		_current_intention = Intention.BLOCK
	
	# This is where desperate counterattack would go, but idk what that'd be
	#_current_intention = Intention.PREP
	#_desied_stance = StanceEval.FASTEST
	#_prepframes = 0
		
	return _current_intention


func _evaluate_offense(my_state : ActionState, my_stance : SwordStance, 
	player_state : ActionState, player_stance : SwordStance) -> Intention:
	# Move closer if the player is too far away to attack
	# Judge that here	
		
	# If player stunned, quick punish
	_current_intention = Intention.PREP
	if player_state == ActionState.STUNNED:
		_desied_stance = StanceEval.FASTEST
		_prepframes = 0
	# If player parrying, hard punish
	elif player_state == ActionState.PARRYING:
		_desied_stance = StanceEval.BIGGEST
		_prepframes = 0
	# If neither, wait a bit then get 'em
	else:
		_desied_stance = StanceEval.MISMATCH
		_prepframes = randi_range(6, 30)
	
	return _current_intention
