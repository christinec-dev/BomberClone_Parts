### Global.gd

extends Node

# Preloaded scenes
var level_scene = preload("res://Scenes/Level.tscn")
var player_scene = preload("res://Scenes/Player.tscn")

# Game State
enum GameMode { NORMAL, BATTLE }
var current_game_mode

# Player variables
var player
var color: Array = ["blue", "grey", "orange"]

# Level variables
var current_level = 1
