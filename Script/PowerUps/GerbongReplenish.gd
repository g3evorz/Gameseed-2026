extends Area2D

func _on_body_entered(body):
	# Mengecek apakah yang menyentuh item ini adalah Kepala atau Gerbong
	if body.name == "Kepala" or "Gerbong" in body.name or body.is_in_group("Player"):
		
		# Panggil fungsi nambah gerbong di manajer kereta
		get_tree().call_deferred("call_group", "Kereta", "tambah_gerbong")
		
		# Hancurkan item dari map
		queue_free()
