extends Area2D

@export var durasi_aktif: float = 7.0 # Aktif selama 7 detik

func _on_body_entered(body):
	# Mengecek apakah yang menyentuh item ini adalah Kepala atau Gerbong
	if body.name == "Kepala" or "Gerbong" in body.name or body.is_in_group("Player"):
		
		# Panggil fungsi mode hantu di manajer kereta
		get_tree().call_group("Kereta", "ghost_mode", durasi_aktif)
		
		# Hancurkan item dari map
		queue_free()
