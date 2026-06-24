extends Node2D

@export var bullet_scene: PackedScene
@export var fire_rate: float = 0.5 

@onready var head_pivot = $Head
@onready var muzzle = $Head/Muzzle
@onready var radar_collision = $RadarArea/CollisionPolygon2D

var can_shoot: bool = true 
var daftar_target: Array[Node2D] = [] 

func _ready():
	_sesuaikan_ukuran_radar()

func _sesuaikan_ukuran_radar():
	
	var ukuran_layar = get_viewport_rect().size
	#var kamera = get_viewport().get_camera_2d()
	#
	#if kamera:
		#ukuran_layar = ukuran_layar / kamera.zoom
	
	# Menentukan jarak dan lebar pandangan berdasarkan kamera yang sudah disesuaikan
	var jarak_pandang = ukuran_layar.x / 2 # Sejauh batas kanan layar
	var lebar_pandang = ukuran_layar.y # Selebar atas-bawah layar
	
	# Membuat wadah untuk titik-titik poligon
	var titik_kerucut = PackedVector2Array()
	
	# Titik 1: Pusat Turret (0,0)
	titik_kerucut.append(Vector2(0, 0)) 
	
	# Titik 2: Ujung Kanan Atas
	titik_kerucut.append(Vector2(jarak_pandang, -lebar_pandang / 2.0)) 
	
	# Titik 3: Ujung Kanan Bawah
	titik_kerucut.append(Vector2(jarak_pandang, lebar_pandang / 2.0)) 
	
	# Terapkan titik-titik tersebut ke node CollisionPolygon2D
	radar_collision.polygon = titik_kerucut

func _process(_delta):
	_proses_auto_aim()

func _proses_auto_aim():
	daftar_target = daftar_target.filter(func(target): return is_instance_valid(target))
	
	if daftar_target.size() > 0:
		var target_sekarang = daftar_target[0]
		
		# HANYA putar bagian HeadPivot ke arah target
		head_pivot.look_at(target_sekarang.global_position)
		
		shoot()
	else:
		# Kembalikan laras ke posisi istirahat (lurus) jika tidak ada target
		head_pivot.rotation = 0

func shoot():
	if not can_shoot:
		return
		
	can_shoot = false 
		
	var bullet = bullet_scene.instantiate()
	get_tree().current_scene.add_child(bullet) 

	# 1. Posisikan dan putar peluru TERLEBIH DAHULU
	bullet.global_position = muzzle.global_position
	bullet.global_rotation = muzzle.global_rotation
	
	# 2. BARU SURUH PELURU MENEMBAK/MENGKALKULASI
	bullet.fire()

	await get_tree().create_timer(fire_rate).timeout
	can_shoot = true

# --- SINYAL DARI RADAR AREA ---
func _on_radar_area_body_entered(body):
	print("RADAR MENDETEKSI: ", body.name)
	# Jika musuh masuk ke radar, tambahkan ke dalam antrean target
	if not daftar_target.has(body):
		daftar_target.append(body)

func _on_radar_area_body_exited(body):
	# Jika musuh keluar dari radar, hapus dari antrean
	if daftar_target.has(body):
		daftar_target.erase(body)
