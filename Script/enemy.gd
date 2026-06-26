extends Node2D

## State machine musuh:
## - ENTRANCE: kemunculan pertama musuh di scene, cepat & dramatis (cinematic).
## - LURKING: musuh diam/menunggu di tepi layar, belum terlihat menyerang.
## - OVERTAKE: musuh mendahului pemain menuju titik drop.
## - DROPPING: musuh menjatuhkan rintangan di titik drop.
## - COOLDOWN: musuh kembali mundur ke area lurking, lalu mengulang siklus.
enum State { ENTRANCE, LURKING, OVERTAKE, DROPPING, COOLDOWN }

var current_state: State = State.ENTRANCE

## Dipancarkan saat musuh menjatuhkan rintangan (state DROPPING), beserta posisi globalnya.
## Spawner/level bisa "listen" sinyal ini untuk instance rintangan yang sebenarnya.
signal obstacle_dropped(drop_position: Vector2)

# --- Variabel dasar pergerakan ---

## Posisi X "standar" musuh, jadi acuan saat musuh tidak sedang di-tween ke posisi lain.
var base_x_position: float

## Posisi Y "standar" musuh, jadi titik tengah dari gelombang hover (sine wave).
var base_y_position: float

## Seberapa cepat musuh melayang naik-turun (semakin besar, semakin cepat getarannya).
@export var hover_speed: float = 2.0

## Seberapa jauh musuh melayang naik-turun dari posisi standarnya (dalam pixel).
@export var hover_amplitude: float = 8.0

# --- Variabel state machine ---

## Jarak ekstra di belakang posisi lurking, tempat musuh "muncul" pertama kali
## (lebih jauh dari titik lurking biasa). Arahnya otomatis ikut arah overtake
## (lawan arah maju), jadi tidak perlu dibalik manual seperti overtake_offset.
@export var entrance_offset: float = 2500.0

## Lama waktu (detik) untuk tween ENTRANCE. Sengaja jauh lebih singkat &
## dramatis dibanding overtake_duration — beda rasa dengan "menyalip yang fair"
## di OVERTAKE, di sini efeknya "musuh ini ngebut & berbahaya".
@export var entrance_duration: float = 15.0

# Posisi X tempat musuh pertama kali muncul (lebih jauh di belakang _lurk_x).
var _entrance_start_x: float

## Lama waktu (detik) untuk tween OVERTAKE (lurk -> drop). Karena musuh dan
## pemain dianggap sama-sama di top speed, selisih kecepatannya cuma kecil —
## makanya durasi ini perlu cukup panjang biar "menyalip"-nya kerasa pelan
## dan masuk akal, bukan dash instan.
@export var overtake_duration: float = 7.5

## Jarak musuh maju dari posisi lurking saat OVERTAKE, untuk mencapai titik drop.
## Tanda (+/-) tergantung arah "maju" di game ini (lihat catatan di _ready()).
@export var overtake_offset: float = 700.0

## Lama waktu (detik) untuk tween COOLDOWN (drop -> lurk).
@export var cooldown_duration: float = 5.0

## Jeda diam (detik) di titik drop sebelum mundur. Tanpa ini, kecepatan musuh
## membalik arah secara instan (maju -> mundur dalam 0 detik), yang justru ini
## yang bikin transisinya terasa "snap"/teleport walaupun tween-nya sendiri smooth.
@export var drop_hold_time: float = 3.5

## Rentang waktu (detik) musuh diam di LURKING sebelum mulai OVERTAKE lagi.
@export var lurk_time_min: float = 10.0
@export var lurk_time_max: float = 15.0

# Posisi X saat lurking & saat drop, dihitung dari base_x_position di _ready().
var _lurk_x: float
var _drop_x: float

# Timer untuk menentukan durasi LURKING sebelum state berpindah ke OVERTAKE.
var _lurk_timer: Timer

# Akumulator waktu khusus untuk hitungan sine wave, terpisah dari delta per-frame
# supaya tidak kebawa pengaruh time_scale/pause kalau nanti dipakai untuk hal lain.
var _time_passed: float = 0.0

# Referensi ke Tween yang sedang berjalan untuk pergerakan X, biar bisa di-kill
# kalau ada perintah move_to_x baru sebelum yang lama selesai.
var _move_tween: Tween


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Catat posisi awal sebagai posisi standar (base) untuk X dan Y.
	base_x_position = position.x
	base_y_position = position.y

	# Posisi lurking = posisi spawn awal. Posisi drop = lurking + offset.
	# CATATAN: kalau arah "maju" di game ini negatif (misal kamera/level scroll
	# ke kiri sementara musuh harus mendahului ke kiri juga), balik tanda
	# overtake_offset jadi negatif lewat Inspector.
	_lurk_x = base_x_position
	_drop_x = base_x_position + overtake_offset

	# Posisi munculnya musuh (ENTRANCE): lebih jauh di belakang _lurk_x, arah
	# "belakang" otomatis kebalikan dari arah overtake (jadi entrance_offset
	# tidak perlu dibalik manual walaupun overtake_offset-nya negatif).
	var overtake_direction: float = sign(overtake_offset) if overtake_offset != 0.0 else 1.0
	_entrance_start_x = _lurk_x - overtake_direction * entrance_offset

	# Timer dibuat lewat kode (bukan child node di scene) supaya script ini
	# tetap mandiri/self-contained, tidak gantung pada struktur scene tertentu.
	_lurk_timer = Timer.new()
	_lurk_timer.one_shot = true
	add_child(_lurk_timer)
	_lurk_timer.timeout.connect(_on_lurk_timer_timeout)

	_enter_state(State.ENTRANCE)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	_time_passed += delta

	# Gelombang sinus sederhana: posisi Y berosilasi di sekitar base_y_position.
	# sin() menghasilkan nilai antara -1 dan 1, dikali amplitude jadi rentang naik-turunnya.
	# Hover ini tetap jalan di semua state, jadi musuh selalu terasa "hidup".
	position.y = base_y_position + sin(_time_passed * hover_speed) * hover_amplitude

	# Logika per-frame untuk tiap state. Transisi antar-state (pindah dari satu
	# state ke state lain) ditangani di _enter_state(), dipanggil sekali saat
	# masuk state baru via sinyal (timer timeout / tween finished) — bukan di sini —
	# supaya tidak terpanggil berulang-ulang tiap frame selama tween/timer berjalan.
	match current_state:
		State.ENTRANCE:
			pass # Pergerakan ditangani oleh Tween dari move_to_x(); tidak perlu logika tiap frame.
		State.LURKING:
			pass # Diam menunggu; _lurk_timer yang akan memicu pindah ke OVERTAKE.
		State.OVERTAKE:
			pass # Pergerakan ditangani oleh Tween dari move_to_x(); tidak perlu logika tiap frame.
		State.DROPPING:
			pass # State ini transisional, ditangani sepenuhnya di _enter_state().
		State.COOLDOWN:
			pass # Pergerakan ditangani oleh Tween dari move_to_x(); tidak perlu logika tiap frame.


## Dipanggil sekali setiap kali musuh masuk ke state baru. Tempat semua logika
## "satu kali jalan" per state: set posisi, mulai timer, mulai tween, dsb.
func _enter_state(new_state: State) -> void:
	current_state = new_state

	match current_state:
		State.ENTRANCE:
			# Kemunculan pertama: posisikan musuh jauh di belakang dulu...
			position.x = _entrance_start_x
			base_x_position = _entrance_start_x

			# ...lalu TRANS_BACK + EASE_OUT bikin musuh "menyalip masuk" cepat
			# dengan sedikit overshoot (lewat dulu dari _lurk_x, baru balik
			# settle) — beda total dengan OVERTAKE yang sengaja konstan/fair.
			# Kontras ini yang langsung kasih kesan "musuh ini cepat & berbahaya"
			# ke pemain di detik-detik pertama (cinematic intro).
			move_to_x(
				_lurk_x, entrance_duration,
				func() -> void: _enter_state(State.LURKING),
				Tween.TRANS_BACK, Tween.EASE_OUT
			)

		State.LURKING:
			# Diam/menetap di tepi layar (posisi lurking).
			position.x = _lurk_x
			base_x_position = _lurk_x

			# Mulai timer acak sebelum musuh mulai menyerang lagi.
			_lurk_timer.wait_time = randf_range(lurk_time_min, lurk_time_max)
			_lurk_timer.start()

		State.OVERTAKE:
			# Mendahului pemain: TRANS_LINEAR = kecepatan relatif konstan
			# sepanjang gerakan. Ini lebih masuk akal secara fisik daripada
			# EASE_OUT (dash cepat lalu ngerem) — karena musuh & pemain
			# dianggap sama-sama di top speed, selisih kecepatan mereka
			# cuma kecil & stabil, bukan ledakan akselerasi di awal.
			move_to_x(
				_drop_x, overtake_duration,
				func() -> void: _enter_state(State.DROPPING),
				Tween.TRANS_LINEAR, Tween.EASE_IN_OUT
			)

		State.DROPPING:
			_drop_obstacle()

			# Jeda sejenak di titik drop sebelum mundur. Tanpa jeda ini,
			# kecepatan musuh membalik arah dalam 0 detik (maju -> mundur
			# instan), itulah yang tadinya kerasa "snappy"/teleport.
			await get_tree().create_timer(drop_hold_time).timeout
			_enter_state(State.COOLDOWN)

		State.COOLDOWN:
			# Mundur kembali ke area lurking: EASE_IN_OUT = berangkat pelan
			# (seolah "ngumpulin tenaga" buat mundur), lalu melambat lagi
			# pas mendekati posisi lurking, jadi tidak berhenti mendadak.
			move_to_x(
				_lurk_x, cooldown_duration,
				func() -> void: _enter_state(State.LURKING),
				Tween.TRANS_QUAD, Tween.EASE_IN_OUT
			)


func _on_lurk_timer_timeout() -> void:
	_enter_state(State.OVERTAKE)


## Logika menjatuhkan rintangan. Saat ini hanya memancarkan sinyal dengan posisi
## global musuh; instansiasi rintangan sebenarnya diserahkan ke spawner/level
## yang listen sinyal ini, supaya enemy.gd tidak perlu tahu scene rintangan apa.
func _drop_obstacle() -> void:
	obstacle_dropped.emit(global_position)


## Menggeser position.x secara mulus ke target_x dalam waktu `duration` detik
## menggunakan Tween. Dipakai untuk ilusi musuh "mendahului" (target_x lebih besar)
## atau "tertinggal" (target_x lebih kecil) dari posisi pemain/kereta.
## `on_finished` opsional: dipanggil sekali saat tween selesai (dipakai state
## machine untuk pindah ke state berikutnya begitu pergerakan selesai).
## `trans`/`ease` opsional: kurva easing, beda gerakan (dash vs mundur pelan)
## bisa dikasih "rasa" yang beda lewat parameter ini.
func move_to_x(
	target_x: float,
	duration: float,
	on_finished: Callable = Callable(),
	trans: Tween.TransitionType = Tween.TRANS_SINE,
	ease: Tween.EaseType = Tween.EASE_IN_OUT
) -> void:
	# Kalau ada tween X yang masih berjalan, hentikan dulu supaya tidak tabrakan
	# dengan perintah pergerakan baru.
	if _move_tween and _move_tween.is_running():
		_move_tween.kill()

	_move_tween = create_tween()
	_move_tween.tween_property(self, "position:x", target_x, duration)\
		.set_trans(trans)\
		.set_ease(ease)

	if on_finished.is_valid():
		_move_tween.finished.connect(on_finished, CONNECT_ONE_SHOT)

	# Update base_x_position juga, supaya kalau ada logika lain yang merujuk
	# ke "posisi standar" musuh, nilainya tetap sinkron dengan posisi terbaru.
	base_x_position = target_x
