extends WCharacter
class_name WOpponentCharacter

## This script is a copy of the player copy of the expressobits controller
## because there's really no reason to have a robust inheretence system in a game
## that'll be done before the week is out
## jk I actually made the inheritence


func _physics_process(delta):
	_look_at_ztarget()
	
	# need to decide how AI does inputs
	if false and not lock_movement:
		var input_axis #= Input.get_vector(input_left_action_name, input_right_action_name, input_back_action_name, input_forward_action_name)
		move(delta, input_axis, false, false, false, false, false)
	else:
		move(delta)


# We might simulate a wheel for the opponent character? but it will need
# to be handled differently so it isn't tied to input. I'll do that later,
# once we have a more concrete idea of what inputs do what and what about
# the wheel needs to be simulated. If needed, wheel methods can just be copied
# from the player
