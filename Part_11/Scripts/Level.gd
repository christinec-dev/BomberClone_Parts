### Level.gd

extends Node2D

# Node references
@onready var tilemap = $TileMap
@onready var spawned_players = $SpawnedPlayers
@onready var spawned_boosts = $SpawnedBoosts
@onready var spawned_enemies = $SpawnedEnemies

# Randomizer & Dimension values ( make sure width & height is uneven)
const initial_width = 37 
const initial_height = 21 
var map_width = initial_width
var map_height = initial_height 
var map_offset = 4 #Shifts map four rows down for UI
var rng = RandomNumberGenerator.new()

# Tilemap constants
const BACKGROUND_TILE_ID = 0
const BREAKABLE_TILE_ID = 1
const UNBREAKABLE_TILE_ID = 2
const BACKGROUND_TILE_LAYER = 0
const BREAKABLE_TILE_LAYER = 1
const UNBREAKABLE_TILE_LAYER = 2

# Bomb variables
var boost_spawner_chance = RandomNumberGenerator.new()
var player_damaged_for_current_explosion = false

# Pathfinding variables
var astar = AStar2D.new()
var path = []

func _ready():
	start_level()
	
func start_level():   
	Global.current_game_mode = Global.GameMode.BATTLE # we'll remove this later
	
	match Global.current_game_mode:
		# Normal game setup
		Global.GameMode.NORMAL:
			generate_map()
			boost_spawner_chance.randomize() 
			var player = spawn_players(Global.player_scene, 1)
			if player:
				Global.player = player
			spawn_enemies()
		# Battle game setup	
		Global.GameMode.BATTLE:
			generate_map()
			generate_astar_path()
			boost_spawner_chance.randomize() 
			var player = spawn_players(Global.player_scene, 1)
			if player:
				Global.player = player
			var ai_players = spawn_players(Global.ai_player_scene, Global.number_of_ai_players) 
			if typeof(ai_players) == TYPE_ARRAY:
				for ai_player in ai_players:
					if ai_player:
						Global.ai_players.append(ai_player)
			spawn_enemies()
			
# ---------------- Map Generation -------------------------------------
func generate_map():
	generate_unbreakables()
	generate_breakables()
	generate_background()
	generate_boosts()

# Checks if tiles are empty or not
func is_cell_empty(layer, coords):
	var data = tilemap.get_cell_tile_data(layer, coords)
	return data == null

# Finds and returns remaining empty cells
func find_empty_cells(map_width, map_height, map_offset, BREAKABLE_TILE_LAYER, UNBREAKABLE_TILE_LAYER):
	# Array of empty tiles
	var empty_cells = []
	# Append empty tiles to array
	for x in range(1, map_width - 1):
		for y in range(1, map_height - 1):
			var current_cell = Vector2i(x, y + map_offset)
			# Checks if cells are empty only on breakable & unbreakable layers
			if is_cell_empty(BREAKABLE_TILE_LAYER, current_cell) and is_cell_empty(UNBREAKABLE_TILE_LAYER, current_cell):
				empty_cells.append(current_cell)
	return empty_cells	
	
func generate_unbreakables():
	#--------------------------------- UBREAKABLES ------------------------------
	# Generate unbreakable walls at the borders on Layer 2
	for x in range(map_width):
		for y in range(map_height):
			if x == 0 or x == map_width - 1 or y == 0 or y == map_height - 1:
				tilemap.set_cell(UNBREAKABLE_TILE_LAYER, Vector2i(x, y + map_offset), UNBREAKABLE_TILE_ID, Vector2i(0, 0), 0)
	# Generate solid walls in a grid on Layer 2, starting from (1, 1)
	for x in range(1, map_width - 2):  # Stop before the last column
		for y in range(1, map_height - 2):  # Stop before the last row
			if x % 2 == 0 and y % 2 == 0: # Check if row and column are even
				tilemap.set_cell(UNBREAKABLE_TILE_LAYER, Vector2i(x, y + map_offset), UNBREAKABLE_TILE_ID, Vector2i(0, 0), 0)
	
func generate_breakables():
	#--------------------------------- BREAKABLES ------------------------------
	# Define an array for the corners and their safe zones
	var spawn_zones = [
		# Near top-left corner
		[Vector2i(1, 1 + map_offset), Vector2i(1, 2 + map_offset), Vector2i(1, 3 + map_offset)],
		# Near top-right corner
		[Vector2i(map_width - 2, 1 + map_offset), Vector2i(map_width - 2, 2 + map_offset), Vector2i(map_width - 2, 3 + map_offset)],
		# Near bottom-left corner
		[Vector2i(1, map_height - 2 + map_offset), Vector2i(1, map_height - 3 + map_offset), Vector2i(1, map_height - 4 + map_offset)],
		# Near bottom-right corner
		[Vector2i(map_width - 2, map_height - 2 + map_offset), Vector2i(map_width - 2, map_height - 3 + map_offset), Vector2i(map_width - 2, map_height - 4 + map_offset)]
	]

	# Randomly place breakable walls on Layer 1
	rng.randomize()
	for x in range(1, map_width - 1):
		for y in range(1, map_height - 1):
			var base_breakable_chance = 0.2  # default 20% chance
			var level_chance_multiplier = 0.01  # increase by 1% per level
			var breakable_spawn_chance = base_breakable_chance + (Global.current_level - 1) * level_chance_multiplier
			breakable_spawn_chance = min(breakable_spawn_chance, 0.5) #max chance of 50%
			var current_cell = Vector2i(x, y  + map_offset)
			var skip_current_cell = false
			# Skip cells where solid tiles are placed
			if x % 2 == 0 and y % 2 == 0:
				skip_current_cell = true
			# Skip cells in the spawn_zones
			for corner in spawn_zones:
				if current_cell in corner:
					skip_current_cell = true
					break
			if skip_current_cell:
				continue
			# Place breakables
			if is_cell_empty(BREAKABLE_TILE_LAYER, current_cell):
				if rng.randf() < breakable_spawn_chance: 
					tilemap.set_cell(BREAKABLE_TILE_LAYER, current_cell, BREAKABLE_TILE_ID, Vector2i(0, 0), 0)

func generate_background():
	#--------------------------------- BACKGROUND ------------------------------
	for x in range(map_width):
		for y in range(map_height):
			var cell_coords = Vector2i(x, y + map_offset)
			if is_cell_empty(BREAKABLE_TILE_LAYER, cell_coords) and is_cell_empty(UNBREAKABLE_TILE_LAYER, cell_coords):
				tilemap.set_cell(BACKGROUND_TILE_LAYER, cell_coords, BACKGROUND_TILE_ID, Vector2i(0, 0), 0)

func generate_boosts():
	# ------------------------------------- BOOST SPAWNING ------------------
	# Get the array of empty cells
	var empty_cells = find_empty_cells(map_width, map_height, map_offset, BREAKABLE_TILE_LAYER, UNBREAKABLE_TILE_LAYER)
	# 1 - 5 boosts			
	var number_of_boosts = randi_range(1 , 5) 
	# Randomly spawn 1 - 5 boosts on empty cells
	for boost in range(number_of_boosts):
		if empty_cells.size() > 0:
			var random_index = rng.randi() % empty_cells.size()
			var random_cell = empty_cells[random_index]
			spawn_explosion_boost(random_cell)
			empty_cells.remove_at(random_index) 
			
# ---------------- Entity Spawning -------------------------------------
# Checks corners for valid spawnpoint		
func is_valid_spawnpoint(coords):
	for layer in [BREAKABLE_TILE_LAYER, UNBREAKABLE_TILE_ID]:
		var data = tilemap.get_cell_tile_data(layer, coords)
		if data != null:
			return false
	return true

# Checks corners for existing players at spawnpoints	
func is_spawnpoint_taken(coords: Vector2i) -> bool:
	for player in spawned_players.get_children():
		if tilemap.local_to_map(player.global_position) == coords:
			return true
	return false
	
# Spawns player/ai_player in corners
func spawn_players(player_scene, instance_count = 1):
	rng.randomize()
	var spawn_points = [
		Vector2i(1, 1 + map_offset),
		Vector2i(map_width - 2, 1  + map_offset),
		Vector2i(1, map_height - 2  + map_offset),
		Vector2i(map_width - 2, map_height - 2  + map_offset)
	]
	var players_in_level = []
	
	for i in range(instance_count):
		var attempts = 0
		var spawned = false
		while attempts < spawn_points.size() and not spawned:
			var random_index = rng.randi() % spawn_points.size()
			var spawn_coords = spawn_points[random_index]
			spawn_points.remove_at(random_index)  # Remove the used spawn point
			if is_valid_spawnpoint(spawn_coords) and not is_spawnpoint_taken(spawn_coords):
				var player = player_scene.instantiate()
				player.global_position = tilemap.map_to_local(spawn_coords)
				spawned_players.add_child(player)
				players_in_level.append(player)
				spawned = true
			else:
				attempts += 1
				
	if instance_count == 1 and players_in_level.size() > 0:
		return players_in_level[0] #normal mode
	else:
		return players_in_level #battle mode

# Randomly spawns explosion boosts
func spawn_explosion_boost(coords):
	var boost = Global.explosion_boost_pickup_scene.instantiate()
	boost.global_position = tilemap.map_to_local(coords)
	spawned_boosts.add_child(boost)

# Spawns enemies
func spawn_enemies():
	# Gets the array of empty cells
	var empty_cells = find_empty_cells(map_width, map_height, map_offset, BREAKABLE_TILE_LAYER, UNBREAKABLE_TILE_LAYER)
	# Calculate the number of enemies based on the current level
	var number_of_enemies = 0 
	number_of_enemies = 1 + (1 * (Global.current_level - 1))
	number_of_enemies = min(number_of_enemies, 20) 
	# Enemy colors for each level
	var level_colors = {
		1: ["orange"],
		2: ["orange", "blue"],
		"default": ["orange", "blue", "green"]
	}
	for i in range(number_of_enemies):
		if empty_cells.size() > 0:
			var random_index = rng.randi() % empty_cells.size()
			var random_cell = empty_cells[random_index]
			empty_cells.remove_at(random_index)
			# Randomly choose an enemy color based on the available level colors or default colors
			var enemy_colors = level_colors.get(Global.current_level, level_colors["default"])
			Global.enemy_color = enemy_colors[rng.randi() % enemy_colors.size()]
			# Instantiate and place the enemy
			var enemy_scene = Global.enemy_scene
			if enemy_scene:
				var enemy = enemy_scene.instantiate()
				enemy.global_position = tilemap.map_to_local(random_cell)
				spawned_enemies.add_child(enemy)
		
# ---------------- Entity Damage -------------------------------------	
# Remove bricks and check for player/enemy damage
func remove_entities(bomb_position, explosion_radius, bomb_owner):
	# Indicates whether the entity has already been damaged by the current explosion
	player_damaged_for_current_explosion = false
	#----------- Tile damage -------------------------------
	var tile_size = 16
	var tile_position = tilemap.local_to_map(bomb_position)
	var tiles_in_radius = int(explosion_radius / tile_size)
	# Explosion Bounds
	var explosion_min = tile_position - Vector2i(tiles_in_radius, tiles_in_radius)
	var explosion_max = tile_position + Vector2i(tiles_in_radius, tiles_in_radius)
	# Check tiles within bounds
	for x in range(explosion_min.x, explosion_max.x + 1):
		for y in range(explosion_min.y, explosion_max.y + 1):
			var cell_coords = Vector2i(x, y)
			var overlapping_tile = tilemap.get_cell_tile_data(BREAKABLE_TILE_LAYER, cell_coords)
			# If tile overlaps
			if overlapping_tile:
				# Remove breakables tile
				tilemap.set_cell(BREAKABLE_TILE_LAYER, cell_coords, -1) 
				# Replace with background tile
				tilemap.set_cell(BACKGROUND_TILE_LAYER, cell_coords, BACKGROUND_TILE_ID, Vector2i(0, 0), 0)
				# 10% chance of spawning an ExplosionBoost
				if boost_spawner_chance.randf() < 0.1:
					spawn_explosion_boost(cell_coords)
					
	#----------- Damage Bounds-------------------------------	
	var explosion_bounds = Rect2(tilemap.map_to_local(explosion_min), tilemap.map_to_local(explosion_max) - tilemap.map_to_local(explosion_min))				

	#----------- Player damage -------------------------------	
	var player_bounds = Rect2(Global.player.global_position - Vector2(16, 16), Vector2(25.6, 25.6))
	# Check if the player and explosion bounds
	if not player_damaged_for_current_explosion and player_bounds.intersects(explosion_bounds):
		Global.player.take_damage(1)
		player_damaged_for_current_explosion = true

	#----------- Enemy damage -------------------------------
	for enemy in spawned_enemies.get_children():
		var enemy_bounds = Rect2(enemy.global_position - Vector2(16, 16), Vector2(25.6, 25.6)) 
		if enemy_bounds.intersects(explosion_bounds):
			enemy.take_damage()


# ---------------- AI Path Generation -------------------------------------	
# Uniquely identifies grid cells
func unique_cell_identifier(coord):
	return coord.x + coord.y * 10000  

# Generates astar points & connects it to create a path
func generate_astar_path():
	for x in range(map_width):
		for y in range(map_height):
			var cell_coords = Vector2i(x, y + map_offset)
			if is_cell_empty(UNBREAKABLE_TILE_LAYER, cell_coords):
				astar.add_point(unique_cell_identifier(cell_coords), cell_coords)
	connect_astar_points()

# Connects A* points to create paths
func connect_astar_points():
	for x in range(map_width):
		for y in range(map_height):
			var cell_coords = Vector2i(x, y + map_offset)
			if astar.has_point(unique_cell_identifier(cell_coords)):
				for dx in [-1, 0, 1]:
					for dy in [-1, 0, 1]:
						if dx == 0 and dy == 0:
							continue
						if dx != 0 and dy != 0:  # Skip diagonals
							continue
						var neighbor_coords = cell_coords + Vector2i(dx, dy)
						if astar.has_point(unique_cell_identifier(neighbor_coords)):
							var cost = 1  # Cost is 1 for all neighbors now
							astar.connect_points(unique_cell_identifier(cell_coords), unique_cell_identifier(neighbor_coords), cost)

# Gets a path from start to end using A* algorithm
func calculate_path(start: Vector2, end: Vector2) -> Array:
	# convert coordinates to grid coordinates
	var start_point = Vector2(int(start.x / 16), int(start.y / 16))
	var end_point = Vector2(int(end.x / 16), int(end.y / 16))
	# get unique identifier for these grid coordinates
	var start_id = unique_cell_identifier(start_point)
	var end_id = unique_cell_identifier(end_point)
	# return shortest path
	if astar.has_point(start_id) and astar.has_point(end_id):
		return astar.get_point_path(start_id, end_id)
	return [] 

# Debug draw to see map path
func _draw():
	for point_id in astar.get_point_ids():
		var point = astar.get_point_position(point_id)
		var screen_point = tilemap.map_to_local(point) 
		# draw connected points
		for neighbor_id in astar.get_point_connections(point_id):
			var neighbor_point = astar.get_point_position(neighbor_id)
			var screen_neighbor_point = tilemap.map_to_local(neighbor_point)
			draw_line(screen_point, screen_neighbor_point, Color(0, 0, 1), 2)
