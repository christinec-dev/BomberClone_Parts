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

# Player variables
var player
var lives : int = 3 
var color: Array = ["blue", "grey", "orange"]

# Enemy variables
var enemy_color : String

# AI Player variables
var ai_players = [] 
var number_of_ai_players = 1

# Level variables
var current_level = 1
