extends Node2D

# 1. Mengubah variabel tunggal menjadi Array untuk menampung banyak scene
@export var list_scene_level: Array[PackedScene]

# Memasukkan node Player agar spawner tahu posisinya
@export var player: Node2D 

# Waktu jeda (dalam detik) antar spawn
@export var spawn_interval: float = 2.0

var _time_passed: float = 0.0

func _process(delta: float) -> void:
	# Cek apakah array kosong (belum ada scene yang dimasukkan di Inspector)
	if list_scene_level.is_empty():
		return
		
	# Logika untuk menelurkan (spawn) objek
	_time_passed += delta
	if _time_passed >= spawn_interval:
		#_spawn_item()
		_time_passed = 0.0

func _spawn_item() -> void:
	# 2. Memilih satu scene secara acak dari dalam Array
	var scene_terpilih = list_scene_level.pick_random()
	
	# Keamanan tambahan jika ada slot array yang kosong
	if scene_terpilih == null:
		return

	# 3. Instantiate scene yang terpilih
	var spawned_instance = scene_terpilih.instantiate()

	# 4. Atur posisi (menggunakan global_position lebih akurat)
	spawned_instance.global_position = self.global_position
	
	# Tambahkan ke scene
	add_child(spawned_instance)
