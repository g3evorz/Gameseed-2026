extends CharacterBody2D

# --- Konfigurasi Pergerakan ---
@export var JUMP_VELOCITY = -1000.0
@export var BASE_SPEED = 300.0 
@export var MAX_SPEED = 1000.0 
@export var ACCELERATION = 15.0 
var current_speed = 0.0
var is_dead: bool = false

# --- Konfigurasi Efek Tilting Parabola ---
@export var MAX_TILT_UP = -20.0   # Derajat maksimal saat naik (hidung ke atas)
@export var MAX_TILT_DOWN = 15.0  # Derajat maksimal saat turun (hidung menunduk)
@export var TILT_SMOOTHNESS = 10.0 # Seberapa mulus transisi rotasinya

@onready var sprite = $Sprite2D
@onready var label_speed = $CanvasLayer/LabelSpeed
@onready var gun = $Sprite2D/PulseBody

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

func _ready():
	current_speed = BASE_SPEED

func _physics_process(delta):
	# 1. Terapkan Gravitasi
	if not is_on_floor():
		velocity.y += gravity * delta
	if is_dead:
		move_and_slide()
		return

	# 2. Fitur Lompat & Turun
	if Input.is_action_just_pressed("ui_up") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		
	if Input.is_action_just_pressed("ui_down") and is_on_floor():
		global_position.y += 2.0

	# 3. Gerakan Otomatis ke Depan Gradually
	current_speed = move_toward(current_speed, MAX_SPEED, ACCELERATION * delta)
	velocity.x = current_speed

	# 4. Efek Tilting Parabola Berdasarkan Kecepatan Vertikal
	var target_rotation = 0.0

	if not is_on_floor():
		# Kita jadikan rasio kecepatan saat ini dibandingkan kekuatan lompat awal
		# Hasilnya berkisar sekitar -1.0 (naik mentok) hingga 1.0 atau lebih (jatuh cepat)
		var jump_kekuatan = max(abs(JUMP_VELOCITY), 1.0)
		var fall_ratio = velocity.y / jump_kekuatan
		
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
	label_speed.text = "Speed: " + str(round(current_speed))

	# 5. Eksekusi pergerakan fisika
	move_and_slide()
	
# Fungsi untuk menghentikan laju kereta saat Game Over
func mati():
	is_dead = true
	current_speed = 0.0
	velocity.x = 0.0
	# Mematikan proses fisika agar kepala kereta tidak lagi bergerak ke depan atau melompat
