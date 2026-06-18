extends CharacterBody2D

# Kecepatan lari otomatis dan kekuatan lompat
const SPEED = 300.0
const JUMP_VELOCITY = -400.0

# Mengambil nilai gravitasi default dari pengaturan proyek (Project Settings)
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

func _physics_process(delta):
	# 1. Terapkan Gravitasi jika karakter tidak berada di tanah
	if not is_on_floor():
		velocity.y += gravity * delta

	# 2. Fitur Lompat (opsional, menggunakan tombol Spasi/Enter bawaan "ui_accept")
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# 3. Gerakan Otomatis ke Depan (Kanan)
	# Kita kunci kecepatan sumbu X agar karakter terus berlari
	velocity.x = SPEED

	# 4. Eksekusi pergerakan
	move_and_slide()
