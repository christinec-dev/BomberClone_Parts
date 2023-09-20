### Main.gd

extends Node2D

@onready var game_panel = $GamePanel
@onready var game_mode_popup = $GamePanel/StartScreen/GameModePopup
@onready var ai_selection_popup = $GamePanel/StartScreen/AISelectionPopup
@onready var ai_player_amount = $GamePanel/StartScreen/AISelectionPopup/Border/Container/AIAmountTextEdit
@onready var error_label = $GamePanel/StartScreen/AISelectionPopup/Border/Container/ErrorLabel

func _ready():
	game_panel.visible = true

# ------------------------ Main Menu Buttons -------------------------	
# Start new game
func _on_new_game_button_pressed():
	Global.current_level = 1
	game_mode_popup.show()

# Load game
func _on_load_game_button_pressed():
	pass # Replace with function body.

# Exit game
func _on_exit_game_button_pressed():
	pass # Replace with function body.

# ------------------------ Game Start Logic -------------------------
# Create an instance of our Level scene
func start_level():
	game_panel.visible = false
	var level = Global.level_scene.instantiate()
	add_child(level)

# ------------------------ Game Mode Logic -------------------------
# NORMAL Mode
func _on_normal_mode_button_pressed():
	game_mode_popup.hide()
	Global.current_game_mode = Global.GameMode.NORMAL
	start_level()

# BATTLE Mode
func _on_battle_mode_button_pressed():
	game_mode_popup.hide()
	ai_selection_popup.show()

# Hide popups
func _on_close_button_pressed():
	game_mode_popup.hide()
	ai_selection_popup.hide()

# ------------------------ AI Selection Logic -------------------------
func _on_start_button_pressed():
	#fetch values
	Global.number_of_ai_players = int(ai_player_amount.text)
	Global.current_game_mode = Global.GameMode.BATTLE
	#err handling
	if Global.number_of_ai_players > 3 or Global.number_of_ai_players == 0:
		error_label.visible = true
	#start game
	else:
		ai_selection_popup.hide()
		start_level()
