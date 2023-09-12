### Player.gd

extends CharacterBody2D

# Node References
@onready var animated_sprite = $AnimatedSprite2D
@onready var camera = $Camera2D
@onready var level = get_node("/root/Level")
@onready var bomb_drop_timer = $Timer

# Player states
var color: String
var speed = 100

# Bomb variables
var bomb_positions = []
var explosion_radius = 30
var max_explosion_radius = 70

func _ready():
	# Randomly assign it a color on spawn
	color = Global.color[randi() % Global.color.size()]
	# Set camera limits
	set_camera_limits()
	
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

# Player input		
func _input(event):
	if event.is_action_pressed("ui_drop_bomb"):
		bomb_drop_timer.start()
		set_physics_process(false)
			
# Sets camera limits to not go beyond map width/ height
func set_camera_limits():
	if level.map_width != 0 and  level.map_height != 0:
		var tile_size = 16  # Assuming each tile is 16x16 pixels
		camera.limit_left = 0
		camera.limit_top = tile_size - level.map_offset
		camera.limit_right = level.map_width * tile_size - 1
		camera.limit_bottom = (level.map_height + level.map_offset) * tile_size

# Spawns bomb only if 1 second has passed since pressing SPACE
func _on_timer_timeout():
	var bomb_instance = Global.bomb_scene.instantiate()
	var spawned_bombs = get_parent().get_node("../SpawnedBombs")
	if spawned_bombs:
		spawned_bombs.add_child(bomb_instance)	
		bomb_instance.global_position = self.global_position
		bomb_instance.bomb_owner = self
		# Add the bomb's position to the tracking list
		bomb_positions.append(self.global_position)
		bomb_drop_timer.stop()
		set_physics_process(true)
