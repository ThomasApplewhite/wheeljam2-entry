extends Node
class_name AnimationHandler

## The animation handler is a wrapper for the animation player;
## Because each animation is dependent on the current stance direction, 
## it's easier to ask for the group of animations and index them by stance

#signal animation_finished(anim_name : String)
signal action_animation_finished(anim_name : String)

@export var anim_player : AnimationPlayer

enum SwordStance {
	NORTH,
	EAST,
	SOUTH,
	WEST
}

enum AnimatedAction {
	DODGE,
	STANCE_CHANGE,
	STRIKE,
	PARRY,
	HURT,
	DIE
}

# TIME FOR SOME NESTED DICTIONARIES!!!
"""
const dodge_anims : Dictionary = {
	SwordStance.NORTH :, 
	SwordStance.EAST :, 
	SwordStance.SOUTH :,
	SwordStance.WEST :
}
"""
const stance_anims : Dictionary = {
	SwordStance.NORTH : "Custom/GuardUp", 
	SwordStance.EAST : "Custom/GuardRight", 
	SwordStance.SOUTH : "Custom/GuardDown",
	SwordStance.WEST : "Custom/GuardLeft"
}
const strike_anims : Dictionary = {
	SwordStance.NORTH : "Custom/AttackUp", 
	SwordStance.EAST : "Custom/AttackRight", 
	SwordStance.SOUTH : "Custom/AttackDown",
	SwordStance.WEST : "Custom/AttackLeft"
}
const parry_anims : Dictionary = {
	SwordStance.NORTH : "Custom/ParryUp", 
	SwordStance.EAST : "Custom/ParryRight", 
	SwordStance.SOUTH : "Custom/ParryDown",
	SwordStance.WEST : "Custom/ParryLeft"
}
const death_anims : Dictionary = {
	SwordStance.NORTH : "Main/Death02", 
	SwordStance.EAST : "Main/Death01", 
	SwordStance.SOUTH : "Main/Death02",
	SwordStance.WEST : "Main/Death01"
}
const anims : Dictionary = {
	#AnimatedAction.DODGE,
	AnimatedAction.STANCE_CHANGE : stance_anims,
	AnimatedAction.STRIKE : strike_anims,
	AnimatedAction.PARRY : parry_anims,
	#AnimatedAction.HURT,
	AnimatedAction.DIE : death_anims
}

var playing_action : bool = false


func _ready() -> void:
	pass
	anim_player.animation_finished.connect(_anim_action_finished)


func play_action_animation(action : AnimatedAction, stance_direction : SwordStance, custom_speed : float = 1.0) -> void:
	var anim_name = anims[action][stance_direction]
	anim_player.play(anim_name, -1, custom_speed, false)
	#anim_player.animation_finished.connect(_anim_action_finished, CONNECT_ONE_SHOT)
	playing_action = true


func _anim_action_finished(anim_name : String) -> void:
	action_animation_finished.emit(anim_name)

	# If this was a block (or death) anim, we're done.
	var stop : bool = stance_anims.values().has(anim_name) or death_anims.values().has(anim_name)
	if stop:
		playing_action = false
		return
	var anim_stance = _get_stance_anim_was_in(anim_name)
	play_action_animation(AnimatedAction.STANCE_CHANGE, anim_stance)


# this entire method sucks lol
func _get_stance_anim_was_in(anim_name : String) -> SwordStance:
	for action_type in anims.keys():
		for stance in anims[action_type].keys():
			if anims[action_type][stance] == anim_name:
				return stance
	return SwordStance.NORTH
