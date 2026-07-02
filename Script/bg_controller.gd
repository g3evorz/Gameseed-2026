extends Node2D 

@onready var langit = $"."
@onready var bintang = $"../ParallaxStars"
@onready var planet = $"../ParallaxPlanet"

func _process(delta):
	# Hanya bergerak jika game sedang dimainkan
	if GameManager.status_sekarang == GameManager.GameState.BERMAIN:
		
		var kecepatan = GameManager.current_world_speed * delta / 2
		
		# Menggeser parallax ke kiri (-)
		# Karena Scroll Scale sudah diatur di Inspector, Anda cukup memasukkan kecepatan mentahnya
		# Godot akan otomatis melambatkan langit dan mencepatkan pohon
		langit.scroll_offset.x -= kecepatan
		bintang.scroll_offset.x -= kecepatan
		planet.scroll_offset.x -= kecepatan
