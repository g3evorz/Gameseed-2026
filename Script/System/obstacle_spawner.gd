extends Marker2D

@export var possible_obstacles: Array[ObstacleData]

# Pool terpisah, di-cache sekali agar tidak looping setiap spawn
var _obstacle_pool: Array[ObstacleData] = []
var _power_up_pool: Array[ObstacleData] = []


func _ready() -> void:
	_build_pools()


# Memisah possible_obstacles menjadi 2 pool berdasarkan ObstacleData.type
func _build_pools() -> void:
	_obstacle_pool.clear()
	_power_up_pool.clear()

	for obstacle in possible_obstacles:
		if obstacle == null:
			continue
		match obstacle.type:
			ObstacleData.SpawnType.POWER_UP:
				_power_up_pool.append(obstacle)
			_:
				_obstacle_pool.append(obstacle)


func spawn_obstacle():
	# --- 1. CEK PELUANG UTAMA ---
	var current_chance = GameManager.current_difficulty.spawn_chance
	# randf() menghasilkan angka acak antara 0.0 sampai 1.0
	if randf() > current_chance:
		LevelManager.register_empty_slot(self)
		return

	if possible_obstacles.is_empty():
		return

	# --- 2. TENTUKAN APAKAH SPAWN POWER UP ATAU OBSTACLE BIASA ---
	# power_up_chance diatur lewat GameManager.current_difficulty, jadi difficulty
	# bisa mengontrol seberapa sering power up muncul relatif obstacle biasa.
	var power_up_chance: float = 0.0
	if "power_up_chance" in GameManager.current_difficulty:
		power_up_chance = GameManager.current_difficulty.power_up_chance

	var target_pool: Array[ObstacleData] = _obstacle_pool

	if not _power_up_pool.is_empty() and randf() <= power_up_chance:
		target_pool = _power_up_pool

	# Fallback: kalau pool yang dipilih kosong, pakai pool lain yang tersedia
	if target_pool.is_empty():
		target_pool = _obstacle_pool if not _obstacle_pool.is_empty() else _power_up_pool

	if target_pool.is_empty():
		return

	# --- 3. KALKULASI WEIGHTED RANDOM (hanya di dalam pool terpilih) ---
	var total_weight: float = 0.0
	for obstacle in target_pool:
		total_weight += obstacle.spawn_weight

	if total_weight <= 0.0:
		return

	var random_value: float = randf_range(0.0, total_weight)

	var selected_data: ObstacleData = null
	for obstacle in target_pool:
		random_value -= obstacle.spawn_weight
		if random_value <= 0.0:
			selected_data = obstacle
			break

	# --- 4. INSTANSIASI ---
	if selected_data and selected_data.obstacle_scene:
		var obstacle_instance = selected_data.obstacle_scene.instantiate()

		if "data" in obstacle_instance:
			obstacle_instance.data = selected_data

		add_child(obstacle_instance)
