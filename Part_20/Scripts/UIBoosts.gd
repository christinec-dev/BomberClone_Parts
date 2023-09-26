### UIBoosts.gd

extends ColorRect

# Node reference
@onready var value = $Container/Value

func _ready():
	Global.boost_updated.connect(update_time)
	
func update_time(remaining_time):
	value.text = str(remaining_time) 
