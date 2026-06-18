extends CharacterBody2D

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var sedang_aktif = true
var tersambung = true # Status apakah gerbong ini masih terikat ke rantai kereta

var target_x_velocity = 0.0
var target_y = 0.0
var target_rot = 0.0
var target_vel_y = 0.0
var target_di_tanah = true
var kekakuan_rantai = 15.0

var posisi_x_kepala = 0.0
@export var BATAS_TERTINGGAL = 2000.0 

func putus_sambungan():
	tersambung = false
	sedang_aktif = false

func _physics_process(delta):
	# --- 1. JIKA SAMBUNGAN TERPUTUS ---
	if not tersambung or not sedang_aktif:
		# Perlambat kecepatan X secara drastis (simulasi gesekan roda/rem)
		# 600 adalah kekuatan pengeremannya, bisa Anda sesuaikan
		velocity.x = move_toward(velocity.x, 0, 600 * delta)
		
		# Tetap patuhi gravitasi agar bisa jatuh ke jurang
		velocity.y += gravity * delta
		move_and_slide()
		
		# Hapus dari memori sepenuhnya JIKA sudah jatuh ke jurang luar angkasa
		if global_position.y > 2500:
			hancur()
		return

	# --- 2. LOGIKA FISIKA HIBRIDA (NORMAL) ---
	velocity.x = target_x_velocity
	var jarak_y = target_y - global_position.y

	if target_di_tanah:
		if is_on_floor():
			velocity.y = jarak_y * kekakuan_rantai
		else:
			velocity.y += gravity * delta
	else:
		if target_vel_y < 0 and jarak_y < 0:
			velocity.y = jarak_y * kekakuan_rantai
		else:
			velocity.y += gravity * delta

	move_and_slide()
	rotation = lerp_angle(rotation, target_rot, kekakuan_rantai * delta)

	# --- 3. DETEKSI SAMBUNGAN PATAH ---
	# Jika gerbong ini tersangkut tembok dan tertinggal jauh dari kepala
	if posisi_x_kepala - global_position.x > BATAS_TERTINGGAL:
		putus_sambungan() # Putuskan sambungan dirinya sendiri
		
	# Jatuh ke jurang luar angkasa
	if global_position.y > 2000:
		putus_sambungan()

func hancur():
	# Hapus node gerbong ini beserta Node2D pembungkusnya dari memori game
	get_parent().queue_free()
