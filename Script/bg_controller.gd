extends Node2D

@onready var langit = $ParallaxGalaxy
@onready var bintang = $ParallaxStars
@onready var planet = $ParallaxPlanet
@onready var rel = $ParallaxRel # [BARU] Tambahkan rel

func _process(delta):
	if GameManager.status_sekarang == GameManager.GameState.BERMAIN:
		var kecepatan = GameManager.current_world_speed * delta
		
		# Menggeser angkasa (background)
		langit.scroll_offset.x -= kecepatan
		bintang.scroll_offset.x -= kecepatan
		planet.scroll_offset.x -= kecepatan
		
		# Menggeser rel (foreground)
		rel.scroll_offset.x -= kecepatan # [BARU] Geser rel dengan kecepatan yang sama
