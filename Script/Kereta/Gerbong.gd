extends CharacterBody2D

@onready var sprite = $Sprite2D 
@onready var coupler_sensor = $Coupler/RayCast2D
@onready var coupler_visual = $Coupler/Sprite2D

@export var game_manager: Node2D = null	

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var sedang_aktif = true
var tersambung = true

var node_target: Node2D = null 

var target_x_velocity = 0.0
var target_rot = 0.0
var kekakuan_rantai = 15.0
var posisi_y_kepala_absolut = 0.0
var was_on_floor = false

@export var MAX_SPRING_VELOCITY = 1000.0 
@export var BATAS_MAKSIMUM_COUPLER = 35.0
@export var BATAS_MINIMUM_COUPLER = 12.5
@export var LEBAR_ASLI_GAMBAR_HIDROLIK = 110.0 

# BATAS EKSTREM GERBONG HANCUR
@export var BATAS_HANCUR = 1500.0
@export var BATAS_EKSTRIM_X = 200.0 
@export var BATAS_EKSTRIM_Y = 100.0 

func putus_sambungan():
	tersambung = false
	sedang_aktif = false
	
	var pos_global_lama = global_position
	var rot_global_lama = global_rotation
	
	set_as_top_level(true)
	
	global_position = pos_global_lama
	global_rotation = rot_global_lama

	
	# Sentakan kehilangan momentum saat coupler putus, agar gerbong langsung
	# terasa "ketinggalan" dari rangkaian, bukan terus melaju sekecepatan kereta.
	velocity.x *= 0.4
	
	if is_instance_valid(coupler_visual):
		coupler_visual.visible = false

func _physics_process(delta):
	# --- 1. JIKA PUTUS SAMBUNGAN ---
	if not tersambung or not sedang_aktif:
		if is_on_floor():
			if game_manager != null:
				print("Ada game manager")
				velocity.x = move_toward(velocity.x, -game_manager.current_world_speed, 600 * delta)
			else:
				velocity.x = move_toward(velocity.x, 0, 600 * delta)
				
		velocity.y += gravity * delta
		move_and_slide()
		
		if global_position.y - posisi_y_kepala_absolut > BATAS_HANCUR:
			hancur()
		return

	# --- 2. FISIKA DASAR & SPRING Y ---
	velocity.x = target_x_velocity
	
	if is_instance_valid(node_target):
		var jarak_y = node_target.global_position.y - global_position.y
		
		if is_on_floor() and jarak_y > 40.0:
			global_position.y += 2.0
			
		if node_target.is_class("CharacterBody2D") and node_target.is_on_floor():
			if is_on_floor():
				velocity.y = clamp(jarak_y * kekakuan_rantai, -MAX_SPRING_VELOCITY, MAX_SPRING_VELOCITY)
			else:
				if was_on_floor and velocity.y < 0: velocity.y = 0.0
				velocity.y += gravity * delta
		else:
			if node_target.velocity.y < 0 and jarak_y < 0:
				velocity.y = clamp(jarak_y * kekakuan_rantai, -MAX_SPRING_VELOCITY, MAX_SPRING_VELOCITY)
			else:
				if was_on_floor and velocity.y < 0: velocity.y = 0.0
				velocity.y += gravity * delta

	was_on_floor = is_on_floor()

	# --- 3. EKSEKUSI GERAK & ROTASI (PRIORITAS RENDAH TERSELESAIKAN) ---
	# move_and_slide() dijalankan LEBIH DULU agar body berada di posisi aktual frame ini
	move_and_slide()
	
	# Rotasi juga dieksekusi SEBELUM kalkulasi marker, agar posisi Marker2D
	# akurat 100% mengikuti kemiringan sprite di frame yang sama (tidak stale)
	var lerp_weight = clamp(kekakuan_rantai * delta, 0.0, 1.0)
	sprite.rotation = lerp_angle(sprite.rotation, target_rot, lerp_weight)

	# --- 4. LOGIKA COUPLER (MARKER, TUG, & VISUAL) ---
	if is_instance_valid(node_target):
		
		# Kalkulasi Titik Awal & Akhir (Setelah Sprite Berotasi)
		var titik_target = node_target.global_position
		var node_titik_belakang = node_target.get_node_or_null("Sprite2D/TitikSambungBelakang")
		if is_instance_valid(node_titik_belakang):
			titik_target = node_titik_belakang.global_position
			
		var titik_awal = global_position
		var node_titik_depan = get_node_or_null("Sprite2D/TitikSambungDepan")
		if is_instance_valid(node_titik_depan):
			titik_awal = node_titik_depan.global_position
			
		var vektor_jarak = titik_target - titik_awal
		var jarak_sekarang = vektor_jarak.length()
		
		var arah_x = 0.0
		var epsilon = 0.01 
		
		if jarak_sekarang > epsilon:
			arah_x = vektor_jarak.normalized().x
		else:
			arah_x = sign(target_x_velocity)
			if arah_x == 0:
				arah_x = 1.0
		
		# --- KINEMATIC TUG (PRIORITAS TINGGI: Jarak Sumbu X) ---
		var akan_macet = false
		var jarak_x_absolut = abs(vektor_jarak.x) # Isolasi perhitungan dari sumbu Y
		
		if jarak_x_absolut > BATAS_MAKSIMUM_COUPLER:
			var overstretch = jarak_x_absolut - BATAS_MAKSIMUM_COUPLER
			var KOREKSI_MAX_PER_FRAME = 6.0  # batasi agar tidak "snap" sekali jalan
			var koreksi = min(overstretch, KOREKSI_MAX_PER_FRAME)
			var gerak_tug = Vector2(arah_x * koreksi, 0)
			var posisi_sebelum_dbg = global_position
			if test_move(global_transform, gerak_tug):
				akan_macet = true
			else:
				move_and_collide(gerak_tug)
			
		elif jarak_x_absolut < BATAS_MINIMUM_COUPLER:
			var overcompression = BATAS_MINIMUM_COUPLER - jarak_x_absolut
			var gerak_tug2 = Vector2(-arah_x * overcompression, 0)
			if test_move(global_transform, gerak_tug2):
				akan_macet = true
			else:
				move_and_collide(gerak_tug2)

		# --- PRIORITAS SEDANG: Penanganan Macet ---
		if akan_macet:
			putus_sambungan()

		# Hitung Ulang Titik Awal JIKA Kinematic Tug menggeser posisi gerbong
		if is_instance_valid(node_titik_depan):
			titik_awal = node_titik_depan.global_position
			
		vektor_jarak = titik_target - titik_awal
		jarak_sekarang = vektor_jarak.length()

		# UPDATE VISUAL & SENSOR DI AKHIR FRAME (Mencegah Lag 1 Frame)
		coupler_visual.global_position = titik_awal
		coupler_sensor.global_position = titik_awal
			
		coupler_visual.rotation = vektor_jarak.angle()
		var panjang_visual_aktual = min(jarak_sekarang, BATAS_MAKSIMUM_COUPLER)
		coupler_visual.scale.x = panjang_visual_aktual / LEBAR_ASLI_GAMBAR_HIDROLIK
		
		coupler_sensor.target_position = coupler_sensor.to_local(titik_target)
		coupler_sensor.force_raycast_update()
		
		# DETEKSI PUTUS EKSTREM TERAKHIR
		if coupler_sensor.is_colliding():
			var hit_normal = coupler_sensor.get_collision_normal()
			if abs(hit_normal.x) > abs(hit_normal.y):
				putus_sambungan()
		if jarak_sekarang > BATAS_MAKSIMUM_COUPLER + BATAS_EKSTRIM_X:
			putus_sambungan()
		if global_position.y - node_target.global_position.y > BATAS_EKSTRIM_Y:
			putus_sambungan()

func hancur():
	queue_free()
