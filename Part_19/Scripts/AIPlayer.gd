### AIPlayer.gd

extends CharacterBody2D

# Node References
@onready var animated_sprite = $AnimatedSprite2D
@onready var animation_player = $AnimationPlayer
@onready var explosion_boost_timer = $ExplosionBoostTimer
@onready var level = get_node("/root/Main/Level")
@onready var player = Global.player

# Music Node refs
@onready var damage_sfx = $GameMusic/Damage_SFX
@onready var pickup_sfx = $GameMusic/Pickup_SFX
@onready var bomb_drop_sfx = $GameMusic/BombDrop_SFX

# AI Player variables
var color: String
var speed = 50
var direction = Vector2(0, 0)
var current_state = "moving"
var is_dead = false

# Enemy Targeting 
var target
var target_position = Vector2()
var closest_enemy = null
var min_distance = 1e9

# Path and Obstacle Handling
var current_path = []
var path_index = 0
var last_recalculation_time = 0.0
var past_positions_with_time = []
var obstacle_contact_time = 0.0 
var max_obstacle_contact_time = 3.0  

# Bomb and Explosion
var last_bomb_time = 0.0
var bomb_positions = []
var bomb_cooldown 
var explosion_radius = 30
var max_explosion_radius = 70
var explosion_boost_count = 0

func _ready():   
	# Randomize the spawn color of AI
	color = Global.color[randi() % Global.color.size()]
	# Reset color
	animated_sprite.modulate = Color(1,1,1,1)
	# Initialize target_position and current_path vars
	target_position = Vector2(400, 300); 
	current_path = level.calculate_path(global_position, target_position)
	# Randomize bomb cooldown between 5 to 7 seconds
	bomb_cooldown = randf_range(5.0, 7.0)  
	
# ------------------- Processing -----------------------
func _physics_process(delta):
	handle_ai_processing()

func handle_ai_processing():
	find_and_set_closest_target()
	update_path_and_direction()
	handle_obstacles()
	update_state()
	update_animation()
	move_character()
	
	var current_time = Time.get_ticks_msec() / 1000.0
	past_positions_with_time.append({"position": global_position, "time": current_time})

	# Limit the size of past_positions_with_time to a reasonable number, say 10
	if past_positions_with_time.size() > 10:
		past_positions_with_time.pop_front()	   
# ------------------- Movement & Animation -----------------------
# Move the AI
func move_character():
	velocity = direction * speed
	move_and_slide()
	
# Movement States
func update_state():
	var next_tile_coords = level.tilemap.local_to_map(global_position + direction * Vector2(16, 16))
	var tile_data_breakables = level.tilemap.get_cell_source_id(1, next_tile_coords)
	var tile_data_unbreakables = level.tilemap.get_cell_source_id(2, next_tile_coords)
	# If there are no obstacles, set to 'moving'
	if tile_data_unbreakables == -1 and tile_data_breakables == -1 and obstacle_contact_time == 0:
		current_state = 'moving'
		return
	# If there are obstacles, set to 'idle'
	if tile_data_unbreakables != -1 or tile_data_breakables != -1 or obstacle_contact_time >= max_obstacle_contact_time:
		current_state = 'idle'
		return
	# If close to target, set to 'idle' 
	if global_position.distance_to(target.global_position) < 50:
		current_state = 'idle'
		return
		
# Update the movement animation based on state
func update_animation():
	match current_state:
		'idle':
			animated_sprite.play(color + "_idle")
			animated_sprite.flip_h = false
		'moving', 'chasing':
			if direction.x < 0:
				animated_sprite.play(color + "_side")
				animated_sprite.flip_h = false
			elif direction.x > 0:
				animated_sprite.flip_h = true
				animated_sprite.play(color + "_side")
			elif direction.y < 0:
				animated_sprite.play(color + "_up")
			elif direction.y > 0:
				animated_sprite.play(color + "_down")

# ------------------- Navigation & Enemy Targeting -------------------------				
# Find and set the closest target
func find_and_set_closest_target():
	# Reset min_distance
	min_distance = 1e9
	
	# Check if closest_enemy is null or destroyed
	if closest_enemy == null or closest_enemy.is_destroyed:
		for enemy in level.spawned_enemies.get_children():
			# Set enemy as target
			var distance = global_position.distance_to(enemy.global_position)
			if distance < min_distance:
				min_distance = distance
				closest_enemy = enemy
			# If no enemies are left, target the player
			if Global.enemy_count <= 0:
				target_position = player.global_position
				current_path = level.calculate_path(global_position, target_position)
				path_index = 0

# Update the path and direction based on the closest target
func update_path_and_direction(): 
	if current_state == "chasing":
		# Target the player when chasing
		target = Global.player  
	else:
		# Target enemy if valid
		target = closest_enemy if is_instance_valid(closest_enemy) else player
	# Re-calculate updated path to target
	if target_position != target.global_position:
		target_position = target.global_position
		current_path = level.calculate_path(global_position, target_position)
		path_index = 0
	# Check if the AI is close enough to the target to drop a bomb
	if global_position.distance_to(target.global_position) < 50:
		drop_bomb()	
	# Move towards target
	if current_path.size() > 0:
		var next_point = current_path[path_index]
		var tile_size = Vector2(16, 16)
		var next_point_converted = next_point * tile_size + tile_size / 2
		var distance_to_next_point = global_position.distance_to(next_point_converted)
		if distance_to_next_point <= 16:
			path_index += 1
			if path_index >= current_path.size():
				path_index = 0
				current_path = []
		else:
			direction = (next_point_converted - global_position).normalized()			

# Update direction based on the current path
func update_direction():
	if current_path.size() > 0 and path_index < current_path.size():
		var next_point = current_path[path_index]
		var tile_size = Vector2(16, 16)
		var next_point_pixel = next_point * tile_size + tile_size / 2
		direction = (next_point_pixel - global_position).normalized()
	else:		
		print("Invalid path or path index. Cannot update direction.")
		var current_time = Time.get_ticks_msec() / 1000.0
		force_redirect(current_time)
		
# ------------------- Obstacle Handling -------------------------
# Check if stuck
func is_stuck():
	if past_positions_with_time.size() < 3: 
		return false
	var recent_data = past_positions_with_time[past_positions_with_time.size() - 1]
	var recent_position = recent_data["position"]
	var recent_time = recent_data["time"]
	for i in range(past_positions_with_time.size() - 2, -1, -1):
		var old_data = past_positions_with_time[i]
		var old_position = old_data["position"]
		var old_time = old_data["time"]
		var distance_moved = recent_position.distance_to(old_position)
		var time_elapsed = recent_time - old_time
		if time_elapsed >= 3.0:
			if distance_moved < 50:
				return true
			else:
				return false
	return false

# Redirect AI
func force_redirect(current_time):
	last_recalculation_time = current_time
	# Randomly choose a new direction
	direction = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
	# Update the target position based on the new direction
	target_position = global_position + direction * 100  # 100 is an arbitrary distance
	# Recalculate the path
	current_path = level.calculate_path(global_position, target_position)
	path_index = 0
	update_direction() 

# If stuck/colliding with tiles
func handle_obstacles():
	var current_time = Time.get_ticks_msec() / 1000.0  # current time in seconds
	var next_tile_coords = level.tilemap.local_to_map(global_position + direction * Vector2(16, 16))
	var tile_data_breakables = level.tilemap.get_cell_tile_data(1, next_tile_coords)
	var tile_data_unbreakables = level.tilemap.get_cell_tile_data(2, next_tile_coords)
	# Check if the AI is stuck
	if is_stuck():
		force_redirect(current_time)
		obstacle_contact_time = 0.0  # Reset the obstacle contact time
		return
	# Handle collisions
	if tile_data_unbreakables or tile_data_breakables:
		obstacle_contact_time += current_time - last_recalculation_time  # Increment the obstacle contact time
		# Redirect on unbreakable tile
		if obstacle_contact_time >= max_obstacle_contact_time:
			force_redirect(current_time)
			obstacle_contact_time = 0.0
		# Drop bomb on breakable tile
		if tile_data_breakables:	
			drop_bomb()
	else:
		obstacle_contact_time = 0.0 
	last_recalculation_time = current_time

# ------------------- Bombs & Explosion Boosts -------------------------
# Drops bomb
func drop_bomb():
	var current_time = Time.get_ticks_msec() / 1000.0 
	if current_time - last_bomb_time >= bomb_cooldown:
		var bomb_instance = Global.bomb_scene.instantiate()
		var spawned_bombs = get_parent().get_node("../SpawnedBombs")
		if spawned_bombs:      
			# Music state
			bomb_drop_sfx.play()
			spawned_bombs.add_child(bomb_instance)    
			bomb_instance.global_position = self.global_position
			bomb_instance.bomb_owner = self  # sets the bomb owner as this ai isntance
			bomb_positions.append(self.global_position)
			last_bomb_time = current_time
			animation_player.play("drop_bomb")
			
# Starts boost timer
func start_explosion_boost_timer():
	explosion_boost_timer.start(10)
	# Music state
	pickup_sfx.play()
	
# Stops boost timer
func _on_explosion_boost_timer_timeout():
	explosion_boost_count = 0
	explosion_radius = 30 
	explosion_boost_timer.stop()  
	
# ------------------- Damage & Death -------------------------
# AI Player damage
func take_damage():
	if not is_dead:
		# Music state
		damage_sfx.play()
		animation_player.play("take_damage")
		Global.player_count -= 1
		Global.update_player_count(Global.player_count)
		is_dead = true  # Mark the enemy as destroyed
	
# Resets animation player and removes AI from scene if is_dead
func _on_animation_player_animation_finished(anim_name):
	if is_dead:
		self.queue_free()
	animated_sprite.modulate = Color(1,1,1,1)
