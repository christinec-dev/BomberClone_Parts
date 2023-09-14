### AIPlayer.gd

extends CharacterBody2D

# Node References
@onready var animated_sprite = $AnimatedSprite2D
@onready var animation_player = $AnimationPlayer
@onready var explosion_boost_timer = $ExplosionBoostTimer

# AI Player variables
var color: String

func _ready():   
	# Randomize the spawn color of AI
	color = Global.color[randi() % Global.color.size()]
	# Reset color
	animated_sprite.modulate = Color(1,1,1,1)

func _on_animation_player_animation_finished(anim_name):
	# Reset color
	animated_sprite.modulate = Color(1,1,1,1)

func _on_explosion_boost_timer_timeout():
	pass # Replace with function body.
