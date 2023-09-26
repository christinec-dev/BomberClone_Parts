### Global.gd

extends Node

# Preloaded scenes
var level_scene = preload("res://Scenes/Level.tscn")
var player_scene = preload("res://Scenes/Player.tscn")
var bomb_scene = preload("res://Scenes/Bomb.tscn")
var explosion_boost_pickup_scene = preload("res://Scenes/ExplosionBoostPickup.tscn")
var enemy_scene = preload("res://Scenes/Enemy.tscn")
var ai_player_scene = preload("res://Scenes/AIPlayer.tscn")

# Game State
enum GameMode { NORMAL, BATTLE }
var current_game_mode
var can_play_button_sfx = false

# Player variables
var player
var lives : int = 3 
var color: Array = ["blue", "grey", "orange"]

# Enemy variables
var enemy_color : String
var enemy_count : int 

# AI Player variables
var ai_players = [] 
var number_of_ai_players = 3

# Level variables
var current_level = 1
var elapsed_time : float = 0.0
var player_count : int

# Signals to notify ui of changes
signal time_updated()
signal lives_updated()
signal enemies_updated()
signal players_updated()
signal boost_updated(new_time)
signal game_over

# Method to update the timer count and emit the signal
func update_time(new_time):
	elapsed_time = new_time
	time_updated.emit()

# Method to update the lives count and emit the signal
func update_lives_count(new_count):
	lives = new_count
	lives_updated.emit()

# Method to update the enemy count and emit the signal
func update_enemy_count(new_count):
	enemy_count = new_count
	enemies_updated.emit()

# Method to update the player  count and emit the signal
func update_player_count(new_count):
	player_count = new_count
	players_updated.emit()

# Method to update the boost time count and emit the signal
func update_boost_count(new_time):
	boost_updated.emit(new_time)

# Shows cursor
func activate_cursor():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	can_play_button_sfx = true
	
# Hides cursor
func deactivate_cursor():
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	can_play_button_sfx = false
