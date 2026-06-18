extends CharacterBody2D

# --- Konfigurasi Pergerakan ---
@export var SPEED = 300.0
@export var JUMP_VELOCITY = -500.0

# --- Konfigurasi Efek Tilting Parabola ---
@export var MAX_TILT_UP = -20.0   # Derajat maksimal saat naik (hidung ke atas)
@export var MAX_TILT_DOWN = 15.0  # Derajat maksimal saat turun (hidung menunduk)
@export var TILT_SMOOTHNESS = 10.0 # Seberapa mulus transisi rotasinya

@onready var sprite = $Sprite2D
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

func _physics_process(delta):
	# 1. Terapkan Gravitasi
	if not is_on_floor():
		velocity.y += gravity * delta

	# 2. Fitur Lompat
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# 3. Gerakan Otomatis ke Depan
	velocity.x = SPEED

	# 4. Efek Tilting Parabola Berdasarkan Kecepatan Vertikal
	var target_rotation = 0.0

	if not is_on_floor():
		# Kita jadikan rasio kecepatan saat ini dibandingkan kekuatan lompat awal
		# Hasilnya berkisar sekitar -1.0 (naik mentok) hingga 1.0 atau lebih (jatuh cepat)
		var fall_ratio = velocity.y / abs(JUMP_VELOCITY)
		
		if fall_ratio < 0:
			# Sedang naik (velocity.y negatif)
			target_rotation = deg_to_rad(MAX_TILT_UP) * abs(fall_ratio)
		else:
			# Sedang turun (velocity.y positif)
			target_rotation = deg_to_rad(MAX_TILT_DOWN) * abs(fall_ratio)
			
		# Kunci nilai rotasi agar kereta tidak berputar balik jika jatuh terlalu lama/cepat
		target_rotation = clamp(target_rotation, deg_to_rad(MAX_TILT_UP), deg_to_rad(MAX_TILT_DOWN))
	else:
		# Jika menyentuh tanah, target rotasi kembali ke 0 (datar)
		target_rotation = 0.0

	# Gunakan fungsi lerp_angle untuk menggerakkan rotasi secara mulus ke targetnya
	sprite.rotation = lerp_angle(sprite.rotation, target_rotation, TILT_SMOOTHNESS * delta)

	# 5. Eksekusi pergerakan fisika
	move_and_slide()
