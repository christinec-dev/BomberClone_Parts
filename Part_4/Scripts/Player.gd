### Player.gd

extends CharacterBody2D

# Node References
@onready var animated_sprite = $AnimatedSprite2D
@onready var camera = $Camera2D
@onready var level = get_node("/root/Level")

# Player states
var color: String
var speed = 100

func _ready():
	# Randomly assign it a color on spawn
	color = Global.color[randi() % Global.color.size()]
	# Set camera limits
	#set_camera_limits()
	
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
	
# Sets camera limits to not go beyond map width/ height
func set_camera_limits():
	if level.map_width != 0 and  level.map_height != 0:
		var tile_size = 16  # Assuming each tile is 16x16 pixels
		camera.limit_left = 0
		camera.limit_top = tile_size - level.map_offset
		camera.limit_right = level.map_width * tile_size - 1
		camera.limit_bottom = (level.map_height + level.map_offset) * tile_size
