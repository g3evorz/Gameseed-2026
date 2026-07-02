extends Area2D

@export var durasi_aktif: float = 10.0 # Waktu double laser aktif

func _on_body_entered(body):
	# Mengecek apakah nama body adalah "Kepala" atau mengandung kata "Gerbong"
	if body.name == "Kepala" or "Gerbong" in body.name or body.is_in_group("Player"):
		AudioManager.putar_sfx(AudioManager.sfx_power_up_pick)
		
		# Panggil fungsi aktifkan_power_up_laser() ke SEMUA turret
		get_tree().call_group("TurretGroup", "aktifkan_power_up_laser", durasi_aktif)
		
		# Hancurkan item ini dari map
		queue_free()
