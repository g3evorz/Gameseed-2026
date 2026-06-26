extends Area2D

## State machine roket:
## - WARNING: diam di posisi, melakukan telegraph (blinking/goyang) agar player bersiap.
## - LAUNCHING: roket meluncur lurus ke atas.
enum State { WARNING, LAUNCHING }

var current_state: State = State.WARNING

# --- Variabel konfigurasi ---
@export var warning_duration: float = 2.0
@export var launch_speed: float = 800.0
@export var telegraph_speed: float = 25.0

var _time_passed: float = 0.0
var _base_y_position: float

func _ready() -> void:
	# Simpan Y awal untuk acuan (X tidak kita sentuh agar aman dari double-scroll chunk)
	_base_y_position = position.y
	
	# Sambungkan sinyal untuk deteksi tabrakan
	body_entered.connect(_on_body_entered)
	# Jika kereta menggunakan Area2D, gunakan area_entered:
	# area_entered.connect(_on_area_entered)
	
	_enter_state(State.WARNING)

func _process(delta: float) -> void:
	_time_passed += delta
	
	match current_state:
		State.WARNING:
			# Telegraph: Efek blinking menggunakan alpha/transparansi (modulate)
			modulate.a = 0.5 + (sin(_time_passed * telegraph_speed) * 0.5)
			
			# (Opsional) Alternatif telegraph goyang tipis di sumbu Y:
			# position.y = _base_y_position + sin(_time_passed * telegraph_speed) * 2.0
			
		State.LAUNCHING:
			# Gerak lurus ke atas. Sumbu X murni ikut scroll induknya.
			position.y -= launch_speed * delta

func _enter_state(new_state: State) -> void:
	current_state = new_state
	
	match current_state:
		State.WARNING:
			# Diam di tempat selama warning_duration, lalu tembak state LAUNCHING
			await get_tree().create_timer(warning_duration).timeout
			_enter_state(State.LAUNCHING)
			
		State.LAUNCHING:
			# Pastikan alpha/warna kembali solid saat mulai meluncur
			modulate.a = 1.0
			# Catatan: Bisa tambahkan trigger partikel api roket atau AudioStreamPlayer di sini.

func _on_body_entered(body: Node2D) -> void:
	# Deteksi tabrakan dengan kereta (sesuaikan nama grup/class dengan project)
	if body.is_in_group("Player") or body.name == "Kereta":
		# Panggil fungsi interaksi, samakan dengan obstacle lain
		# Contoh:
		# GameManager.terapkan_efek_ram(...)
		
		# Hancurkan roket setelah sukses menabrak
		queue_free()

# (Opsional) Jika kereta player menggunakan Area2D dan bukan CharacterBody2D/RigidBody2D
func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("Player"):
		# GameManager.terapkan_efek_ram(...)
		queue_free()
