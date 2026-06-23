extends Node2D

# Memasukkan scene yang ingin di-spawn
@export var item_to_spawn: PackedScene

# Memasukkan node Player agar spawner tahu posisinya
@export var player: Node2D 

# Waktu jeda (dalam detik) antar spawn
@export var spawn_interval: float = 2.0

@export var game_manager: Node2D

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
		print("Level Spawned !")
		
		spawned_instance.game_manager = self.game_manager

	spawned_instance.position = Vector2(self.global_position.x, self.global_position.y)
	
	add_child(spawned_instance)
