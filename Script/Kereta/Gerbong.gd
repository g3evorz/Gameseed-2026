extends CharacterBody2D

@onready var sprite = $Sprite2D 
@onready var coupler_sensor = $Coupler/RayCast2D
@onready var coupler_visual = $Coupler/Sprite2D

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var sedang_aktif = true
var tersambung = true

var node_target: Node2D = null 

var target_x_velocity = 0.0
var target_rot = 0.0
var kekakuan_rantai = 15.0
var posisi_y_kepala_absolut = 0.0
var was_on_floor = false

var timer_imunitas = 0.0

@export var MAX_SPRING_VELOCITY = 1000.0 
@export var BATAS_MAKSIMUM_COUPLER = 35.0
@export var BATAS_MINIMUM_COUPLER = 12.5
@export var LEBAR_ASLI_GAMBAR_HIDROLIK = 110.0 

@export var MAX_HP : float = 200.0

# BATAS EKSTREM GERBONG HANCUR
@export var BATAS_HANCUR = 1500.0
@export var BATAS_EKSTRIM_X = 200.0 
@export var BATAS_EKSTRIM_Y = 100.0 

var FAST_FALL_VELOCITY = 0.0

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
	
	var immune_frame = false
	if timer_imunitas > 0.0:
		timer_imunitas -= delta
		immune_frame = true
	
	# --- 1. JIKA PUTUS SAMBUNGAN ---
	if not tersambung or not sedang_aktif:
		position.x -= GameManager.current_world_speed * delta
		velocity.y += gravity * delta
		move_and_slide()
		
		if global_position.y - posisi_y_kepala_absolut > BATAS_HANCUR:
			hancur()
		return

	# --- 2. FISIKA DASAR & SPRING Y ---
	velocity.x = target_x_velocity
	
	if is_instance_valid(node_target):
		var jarak_y = node_target.global_position.y - global_position.y
		
		if jarak_y > 15.0 and is_on_floor():
			# Target ada di bawah dan gerbong di lantai: tembus One-Way
			global_position.y += 2.0
		elif not is_on_floor():
			# Deteksi jika target sedang jatuh cepat (opsional)
			if node_target.velocity.y >= FAST_FALL_VELOCITY:
				velocity.y = FAST_FALL_VELOCITY
		else:
			if was_on_floor and velocity.y < 0: velocity.y = 0.0
			velocity.y += gravity * delta
				
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
		var jarak_x_absolut = abs(vektor_jarak.x) 
		
		# Deklarasi variabel di luar agar bisa diakses oleh blok sistem kebal di bawah
		var gerak_tug = Vector2.ZERO 
		
		# 1. Tentukan arah dan besar tarikan/dorongan dulu
		if jarak_x_absolut > BATAS_MAKSIMUM_COUPLER:
			var overstretch = jarak_x_absolut - BATAS_MAKSIMUM_COUPLER
			var KOREKSI_MAX_PER_FRAME = 12.0  
			var koreksi = min(overstretch, KOREKSI_MAX_PER_FRAME)
			gerak_tug = Vector2(arah_x * koreksi, 0)
			
		elif jarak_x_absolut < BATAS_MINIMUM_COUPLER:
			var overcompression = BATAS_MINIMUM_COUPLER - jarak_x_absolut
			gerak_tug = Vector2(-arah_x * overcompression, 0)

		# 2. Eksekusi pergerakan HANYA JIKA ada gerak_tug yang terisi
		if gerak_tug != Vector2.ZERO:
			if test_move(global_transform, gerak_tug):
				akan_macet = true
			else:
				move_and_collide(gerak_tug)

		# --- PRIORITAS SEDANG: Penanganan Macet ---
		if akan_macet:
			if immune_frame:
				global_position += gerak_tug
			else:
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
		if not immune_frame:
			if coupler_sensor.is_colliding():
				var hit_normal = coupler_sensor.get_collision_normal()
				if abs(hit_normal.x) > abs(hit_normal.y):
					putus_sambungan()
			if jarak_sekarang > BATAS_MAKSIMUM_COUPLER + BATAS_EKSTRIM_X:
				putus_sambungan()
			if global_position.y - node_target.global_position.y > BATAS_EKSTRIM_Y:
				putus_sambungan()

func take_damage(jumlah_damage: int):
	if GameManager.status_sekarang != GameManager.GameState.BERMAIN:
		return
		
	var current_health = MAX_HP
	
	current_health -= jumlah_damage
	
	if current_health <= 0:
		current_health = 0 
		hancur()

func hancur():
	queue_free()
