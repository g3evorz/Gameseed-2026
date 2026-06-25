extends Node2D

@export var bullet_scene: PackedScene
@export var fire_rate: float = 0.5 

@onready var head_pivot = $Head
@onready var muzzle = $Head/Muzzle
@onready var radar_collision = $RadarArea/CollisionPolygon2D

var can_shoot: bool = true 
var daftar_target: Array[Node2D] = [] 

# --- VARIABEL POWER UP ---
var is_double_laser: bool = false
var timer_double_laser: float = 0.0
@export var jarak_antar_laser: float = 15.0 # Jarak piksel antar 2 laser

func _ready():
	add_to_group("TurretGroup")
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
	
	if is_double_laser:
		timer_double_laser -= _delta
		if timer_double_laser <= 0:
			is_double_laser = false
			#print("Power up habis, kembali ke 1 laser.")

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
		
	if is_double_laser and daftar_target.size() >= 2:
		# --- MODE MULTI-TARGET: Tembak 2 musuh yang berbeda ---
		var musuh_1 = daftar_target[0]
		var musuh_2 = daftar_target[1]
		
		# Tembakkan laser ke koordinat masing-masing musuh
		_spawn_laser_ke_target(muzzle.global_position, musuh_1.global_position)
		_spawn_laser_ke_target(muzzle.global_position, musuh_2.global_position)
		
	elif is_double_laser and daftar_target.size() == 1:
		# --- MODE DOUBLE LASER NORMAL: 2 Laser fokus ke 1 musuh ---
		var offset_vektor = muzzle.global_transform.y * (jarak_antar_laser / 2.0)
		var musuh = daftar_target[0]
		
		# Tembak paralel seperti biasa tapi arahkan ke musuh yang sama
		_spawn_laser_ke_target(muzzle.global_position - offset_vektor, musuh.global_position)
		_spawn_laser_ke_target(muzzle.global_position + offset_vektor, musuh.global_position)
		
	elif daftar_target.size() > 0:
		# --- MODE 1 LASER (Normal / Power-up tidak aktif) ---
		_spawn_laser_ke_target(muzzle.global_position, daftar_target[0].global_position)

	# Cooldown tembakan
	await get_tree().create_timer(fire_rate).timeout
	can_shoot = true

# Fungsi bantuan yang diperbarui agar peluru memutar dirinya sendiri ke arah target
func _spawn_laser_ke_target(posisi_spawn: Vector2, posisi_target: Vector2):
	var bullet = bullet_scene.instantiate()
	get_tree().current_scene.add_child(bullet) 
	
	bullet.global_position = posisi_spawn
	
	# PENTING: Gunakan look_at agar peluru langsung mengarah tepat ke koordinat target
	bullet.look_at(posisi_target)
	
	bullet.fire()
	
func aktifkan_power_up_laser(durasi: float):
	is_double_laser = true
	timer_double_laser = durasi
	#print("Turret masuk ke mode Double Laser selama ", durasi, " detik!")

# --- SINYAL DARI RADAR AREA ---
func _on_radar_area_area_entered(area):
	#print("RADAR MENDETEKSI TARGET: ", area.name)
	# Jika musuh masuk ke radar, tambahkan ke dalam antrean target
	if not daftar_target.has(area):
		daftar_target.append(area)

func _on_radar_area_area_exited(area):
	# Jika musuh keluar dari radar, hapus dari antrean
	if daftar_target.has(area):
		daftar_target.erase(area)
