### UITime.gd

extends ColorRect

# Node References
@onready var value = $Container/Value
# 5 minutes in seconds
var countdown_time = 300  

func _ready():  
	Global.time_updated.connect(update_time)
	update_time()

# Update time each second
func update_time():
	# Decrease the countdown time by 1 second
	countdown_time -= 1 
	if countdown_time <= 0:
		countdown_time = 0
		# game over
	# Set value	
	var minutes = countdown_time / 60
	var seconds = countdown_time % 60
	value.text = "%02d:%02d" % [minutes, seconds]
	
# Resets timer when game restarts
func reset_timer():
	countdown_time = 300 
	update_time()  
