### Player.gd

extends CharacterBody2D

# Node References
@onready var animated_sprite = $AnimatedSprite2D

# Player states
var color: String
var speed = 100

func _ready():
	# Randomly assign it a color on spawn
	color = Global.color[randi() % Global.color.size()]
	
func _physics_process(delta):
	movement_input()
	move_and_slide()
# Player movement
func movement_input():
	var input_direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	velocity = input_direction * speed
	
	# -------- Animations by color ------------
	#left anim
	if Input.is_action_pressed("ui_left"):
		animated_sprite.play(color + "_side")
		animated_sprite.flip_h = false
	#right anim
	elif Input.is_action_pressed("ui_right"):
		animated_sprite.flip_h = true
		animated_sprite.play(color + "_side")
	#up anim
	elif Input.is_action_pressed("ui_up"):
		animated_sprite.play(color + "_up")
	#down anim
	elif Input.is_action_pressed("ui_down"):
		animated_sprite.play(color + "_down")
	#idle anim
	else:
		animated_sprite.play(color + "_idle")
		animated_sprite.flip_h = false
	
