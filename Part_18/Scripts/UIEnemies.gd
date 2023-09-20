### UIEnemies.gd

extends ColorRect

# Node reference
@onready var value = $Container/Value

func _ready():
	Global.enemies_updated.connect(update_enemy_count)
	update_enemy_count()

func update_enemy_count():
	value.text = str(Global.enemy_count)
