### SaveLoadManager.gd

extends Node

func save_game():
	var save_file = ConfigFile.new()
	# Save the current level
	save_file.set_value("level_values", "current_level", Global.current_level)
	# Save the file to the user:// directory
	var save_path = "user://bomberclone_save.ini"
	var err = save_file.save(save_path)
	if err != OK:
		print("An error occurred while saving the game.")

func load_game():
	# Get save file at user:// directory
	var save_file = ConfigFile.new()
	var save_path = "user://bomberclone_save.ini"
	var err = save_file.load(save_path)
	# Load current level that was saved
	if err == OK:
		Global.current_level = save_file.get_value("level_values", "current_level", 1)
	else:
		print("An error occurred while loading the game.")

# Checks if save file exists
func is_save_file_exists():
	var save_file = ConfigFile.new()
	var save_path = "user://bomberclone_save.ini"
	return save_file.load(save_path) == OK

# Returns last level saved 
func get_last_saved_level():
	var save_file = ConfigFile.new()
	var save_path = "user://bomberclone_save.ini"
	var err = save_file.load(save_path)
	if err == OK:
		return save_file.get_value("level_values", "current_level", 1)
	else:
		return

