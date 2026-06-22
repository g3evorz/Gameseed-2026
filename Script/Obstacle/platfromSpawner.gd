extends Node2D

# Memasukkan scene yang ingin di-spawn
@export var item_to_spawn: PackedScene

# Memasukkan node Player agar spawner tahu posisinya
@export var player: Node2D 

# Waktu jeda (dalam detik) antar spawn
@export var spawn_interval: float = 2.0

@export var game_manager: Node2D

# --- VARIABEL BARU UNTUK RANDOMISASI ---
@export_group("Randomization Settings")
@export var min_scale_x: float = 0.5
@export var max_scale_x: float = 2.0

# Posisi Y minimal di set -10 sesuai permintaan
@export var min_y_offset: float = -300.0
@export var max_y_offset: float = -500.0 

var _time_passed: float = 0.0

func _process(delta: float) -> void:
	if item_to_spawn == null:
		return
		
	# 1. Logika untuk menelurkan (spawn) objek
	_time_passed += delta
	if _time_passed >= spawn_interval:
		_spawn_item()
		_time_passed = 0.0

func _spawn_item() -> void:
	var spawned_instance = item_to_spawn.instantiate()
	
	if game_manager != null:
		spawned_instance.game_manager = self.game_manager
			
	# --- 2. LOGIKA RANDOMISASI ---
	
	# Skala X Acak (Lebar Platform)
	var random_scale_x = randf_range(min_scale_x, max_scale_x)
	# Mengubah skala X saja, skala Y tetap 1.0 agar platform tidak memipih secara vertikal
	spawned_instance.scale = Vector2(random_scale_x, 1.0) 
	
	# Posisi Y Acak (Ketinggian Platform)
	var random_y_offset = randf_range(min_y_offset, max_y_offset)
	var target_y = self.global_position.y + random_y_offset
	
	# Terapkan posisi akhir (X tetap di spawner, Y diacak)
	spawned_instance.position = Vector2(self.global_position.x, target_y)
	
	add_child(spawned_instance)
