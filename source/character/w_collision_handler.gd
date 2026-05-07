extends Node
class_name CollisionHandler

signal strike_blocked(attack_commitment : int)
signal strike_taken(damage : int)


func resolve_strike(our_pos: Vector3, hit_pos: Vector3, block_quad : int, can_block: bool, 
	incoming_damage : int, incoming_commitment : int) -> bool:
	# Step 1: Calculate the hit angle
	# The wheel has up = 0 and goes clockwise, so this does too.
	var hit_directon : Vector3 = hit_pos - our_pos
	hit_directon.z = 0
	hit_directon = hit_directon.normalized()
	var hit_angle_cos : float = hit_directon.dot(Vector3.UP)
	
	# Step 2: Resolve which of the block quadrants the attack landed in
	# For hit angle x:
	# 0 <= x <= .25 : UP
	# .25 < x < .75 : LEFT or RIGHT
	# .75 <= x <= 1 : DOWN
	var hit_quad : int
	if hit_angle_cos <= .25:
		hit_quad = 0
	elif .75 <= hit_angle_cos:
		hit_quad = 180
	# because intermediate values could be left or right, just check the sign of the x axis
	elif hit_directon.x > 0:
		hit_quad = 270
	else:
		hit_quad = 90
	
	# Step 3: Resolve the attack
	if hit_quad == block_quad and can_block:
		# play blocking anims/signals if needed
		strike_blocked.emit(incoming_commitment)
		return true
	
	# Send all signals related to getting attacked
	strike_taken.emit(incoming_damage)
	return false
