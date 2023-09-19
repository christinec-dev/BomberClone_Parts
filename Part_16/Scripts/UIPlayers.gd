### UIPLayers.gd

extends ColorRect

# Node references
@onready var value = $Container/Value

func _ready():
	update_players_count()
	Global.players_updated.connect(update_players_count)

func update_players_count():
	value.text = str(Global.player_count)
	
