### UILives.gd

extends ColorRect

# Node reference
@onready var value = $Container/Value

func _ready():
	Global.lives_updated.connect(update_lives_count)
	update_lives_count()
	
# Update lives value
func update_lives_count():
	value.text = str(Global.lives)
	if Global.lives == 0:
		#game over
		Global.game_over.emit()
