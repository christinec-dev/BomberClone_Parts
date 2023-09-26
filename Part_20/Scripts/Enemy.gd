### Enemy.gd

extends CharacterBody2D

# Node references
@onready var animated_sprite = $AnimatedSprite2D
@onready var animation_player = $AnimationPlayer
@onready var movement_timer = $MovementTimer

# Music Node refs
@onready var damage_sfx = $GameMusic/Damage_SFX

# Enemy properties
var is_destroyed = false
var color: String
var damage: int
var enemy_properties = {
	"orange": {"damage": 1, "idle_animation": "orange_idle", "movement_animation": "orange_movement"},
	"blue": {"damage": 2,  "idle_animation": "blue_idle", "movement_animation": "blue_movement"},
	"green": {"damage": 3, "idle_animation": "green_idle", "movement_animation": "green_movement"}
}

# Movement properties
var rng = RandomNumberGenerator.new()	
var directions = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
var current_direction = Vector2i.ZERO

func _ready():
	# Sets enemy properties based on the color assigned in the Level scene
	color = Global.enemy_color
	var properties = enemy_properties[color]
	# Initialize its damage and idle animation
	damage = properties["damage"]
	animated_sprite.play(properties["idle_animation"])
	# Reset color
	animated_sprite.modulate = Color(1,1,1,1)
	# Start roaming
	redirect_enemy()
	movement_timer.start()
	
# Moves the enemy in the current direction
func move_enemy():
	var tilemap = get_parent().get_node("../TileMap")
	var tile_size = 16
	var next_cell = tilemap.local_to_map(global_position) + current_direction
	var next_position = global_position + Vector2(current_direction.x, current_direction.y) * tile_size
	# if no obstacle
	if tilemap.get_cell_tile_data(1, next_cell) == null and tilemap.get_cell_tile_data(2, next_cell) == null:
		var properties = enemy_properties[color]
		animated_sprite.play(properties["movement_animation"])
		global_position = next_position
	# if obstacle
	else:
		redirect_enemy()
		
# Changes the enemy's direction randomly
func redirect_enemy():
	rng.randomize()
	current_direction = directions[rng.randi() % directions.size()]
		
# Move Enemy
func _on_movement_timer_timeout():
	move_enemy()
	
# Damage Player
func _on_collision_indicator_body_entered(body):
	const damage_cooldown_time = 1.0 
	var last_damage_time = 0.0
	if body.is_in_group("player"):
		var current_time = Time.get_ticks_msec() / 1000.0 
		if current_time - last_damage_time >= damage_cooldown_time:
			last_damage_time = current_time
			body.take_damage(damage)

# Damage Enemy
func take_damage():
	if not is_destroyed:
		# Music state
		damage_sfx.play()
		animation_player.play("take_damage")
		Global.enemy_count -= 1
		Global.update_enemy_count(Global.enemy_count)
		is_destroyed = true
		
# Remove Enemy
func _on_animation_player_animation_finished(anim_name):
	# Reset color
	animated_sprite.modulate = Color(1,1,1,1)
	# Remove from scene
	self.queue_free()

