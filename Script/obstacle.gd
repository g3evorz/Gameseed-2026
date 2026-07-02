extends Area2D

@export var data: ObstacleData
@export var damage_tabrakan: int = 200
@export var kekuatan_slow: float = 0.7 

var current_hp: int

func _ready():
	current_hp = data.max_hp
	
func take_damage(damage_amount: int):
	current_hp -= damage_amount
	
	#print("CURRENT HP : ", current_hp)
	
	if current_hp <= 0:
		die()

func _on_body_entered(body):
	if body.name == "Kepala" or body.is_in_group("Player"):
		var kereta = body.get_parent() # Mengambil node KeretaManager
		
		# --- CEK GHOST MODE DI SINI ---
		if kereta and "is_invincible" in kereta and kereta.is_invincible:
			print("Kereta transparan menembus rintangan!")
			return # Fungsi dihentikan! Rintangan tidak akan hancur dan tidak memberi damage
		# ------------------------------
		
		# Jika Ghost Mode mati, jalankan tabrakan normal
		if kereta and kereta.has_method("terima_damage"):
			AudioManager.putar_sfx(AudioManager.sfx_crash)
			kereta.terima_damage(damage_tabrakan)
			GameManager.terapkan_efek_ram(kekuatan_slow)
			
		# Hancurkan obstacle
		die()

# DESTROY OBJECT

func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	print("Platform Terhapus !")
	queue_free()	

func die():
	queue_free()
