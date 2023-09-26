### Bomb.gd

extends Area2D

# Node References
@onready var animated_sprite = $AnimatedSprite2D
@onready var explosion_timer = $Timer

# Music Node refs
@onready var explosion_sfx = $GameMusic/Explosion_SFX

# Bomb variablees
var bomb_owner
var detected_tilemaps = []

func _ready():
	animated_sprite.play("idle")
	explosion_timer.start()
	
# Detect and store the Tilemap node from the Level scene
func _on_body_entered(body):
	if body is TileMap:
		detected_tilemaps.append(body)

# Determine the explosion radius and explode the bomb with the appropriate animation
func _on_timer_timeout():
	var explosion_animation
	var explosion_boost_count = 0

	if is_instance_valid(bomb_owner):
		if bomb_owner:
			explosion_boost_count = bomb_owner.explosion_boost_count
	else:
		explosion_boost_count = 0
	
	#play explosion based on explosion boost acquired
	if explosion_boost_count <= 0:
		explosion_animation = "explosion_small"
	elif explosion_boost_count == 1:
		explosion_animation = "explosion_medium"
	else:
		explosion_animation = "explosion_large"
		
	animated_sprite.play(explosion_animation)
	# Music state
	explosion_sfx.play()
	
# After explosion animation finishes, remove damaged entities from the map.
func _on_animated_sprite_2d_animation_finished():
	# Remove tiles
	for tilemap in detected_tilemaps:
		tilemap.get_parent().remove_entities(
			self.global_position, 
			bomb_owner.explosion_radius if is_instance_valid(bomb_owner) else Global.player.explosion_radius, 
			bomb_owner)
	# Clear the list of detected tilemaps
	detected_tilemaps.clear()
	# Remove bomb after explosion animation duration
	self.queue_free()
	explosion_timer.stop()

# Visualize how big the explosion radius is
func _draw():
	if bomb_owner:
		draw_circle(Vector2.ZERO, bomb_owner.explosion_radius, Color(1,0,0,0.5))
	else:
		draw_circle(Vector2.ZERO,  Global.player.explosion_radius, Color(1,0,0,0.5))

