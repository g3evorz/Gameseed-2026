extends CharacterBody2D

# Asumsikan ada node Sprite2D di dalam gerbong untuk efek tilting (FIX #2)
@onready var sprite = $Sprite2D 

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var sedang_aktif = true
var tersambung = true

var target_x_velocity = 0.0
var target_y = 0.0
var target_rot = 0.0
var target_vel_y = 0.0
var target_di_tanah = true
var kekakuan_rantai = 15.0

# FIX #1: Ganti posisi absolut kepala menjadi posisi relatif gerbong tepat di depannya
var posisi_x_depan = 0.0
var posisi_y_depan = 0.0

var posisi_y_kepala_absolut = 0.0

# Nilai ini sekarang bisa jauh lebih kecil karena diukur per sambungan (relatif)
@export var BATAS_TERTINGGAL = 400.0 
@export var BATAS_TERBANG = 200.0
@export var BATAS_JATUH = 250.0 
@export var BATAS_HANCUR = 2500.0

# FIX #3: Clamp untuk mencegah tunneling / lonjakan eksponensial spring
@export var MAX_SPRING_VELOCITY = 1500.0 

# FIX #4: Variabel memori untuk mengecek transisi lantai -> udara
var was_on_floor = false

func putus_sambungan():
	tersambung = false
	sedang_aktif = false

func _physics_process(delta):
	if not tersambung or not sedang_aktif:
		
		if is_on_floor():
			velocity.x = move_toward(velocity.x, 0, 600 * delta)
		
		velocity.y += gravity * delta
		move_and_slide()
		
		if global_position.y - posisi_y_kepala_absolut > 1500.0:
			hancur()
		return

	velocity.x = target_x_velocity
	var jarak_y = target_y - global_position.y

	# Logika Fisika Hibrida
	if target_di_tanah:
		if is_on_floor():
			# FIX #3: Clamp velocity dari proportional controller
			var raw_spring_vel = jarak_y * kekakuan_rantai
			velocity.y = clamp(raw_spring_vel, -MAX_SPRING_VELOCITY, MAX_SPRING_VELOCITY)
		else:
			# FIX #4: Reset velocity y yang bocor saat jalan keluar dari ujung platform
			if was_on_floor and velocity.y < 0:
				velocity.y = 0.0
			velocity.y += gravity * delta
	else:
		if target_vel_y < 0 and jarak_y < 0:
			var raw_spring_vel = jarak_y * kekakuan_rantai
			velocity.y = clamp(raw_spring_vel, -MAX_SPRING_VELOCITY, MAX_SPRING_VELOCITY)
		else:
			if was_on_floor and velocity.y < 0:
				velocity.y = 0.0
			velocity.y += gravity * delta

	# Catat status lantai frame ini untuk dipakai di frame berikutnya
	was_on_floor = is_on_floor()
	move_and_slide()

	var lerp_weight = clamp(kekakuan_rantai * delta, 0.0, 1.0)
	sprite.rotation = lerp_angle(sprite.rotation, target_rot, lerp_weight)

	if posisi_x_depan - global_position.x > BATAS_TERTINGGAL:
		putus_sambungan()
		
	if posisi_y_depan - global_position.y > BATAS_TERBANG:
		putus_sambungan()
		
	if global_position.y - posisi_y_depan > BATAS_JATUH:
		putus_sambungan()

func hancur():
	get_parent().queue_free()
