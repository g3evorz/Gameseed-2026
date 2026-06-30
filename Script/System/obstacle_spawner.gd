extends Marker2D

@export var possible_obstacles: Array[ObstacleData]

# Tambahkan variabel peluang: 0.0 (0%) hingga 1.0 (100%)
# Default 0.7 berarti ada peluang 70% objek muncul, dan 30% kosong.

func spawn_obstacle():
	# --- 1. CEK PELUANG UTAMA ---
	var current_chance = GameManager.current_difficulty.spawn_chance
	# randf() menghasilkan angka acak antara 0.0 sampai 1.0
	if randf() > current_chance:
		LevelManager.register_empty_slot(self)
		return

	if possible_obstacles.is_empty():
		return
		
	# --- 2. KALKULASI WEIGHTED RANDOM ---
	var total_weight: float = 0.0
	for obstacle in possible_obstacles:
		if obstacle == null:
			continue 
		total_weight += obstacle.spawn_weight
		
	if total_weight <= 0.0:
		return 

	var random_value: float = randf_range(0.0, total_weight)
	
	var selected_data: ObstacleData = null
	for obstacle in possible_obstacles:
		if obstacle == null:
			continue
		random_value -= obstacle.spawn_weight
		if random_value <= 0.0:
			selected_data = obstacle
			break
			
	# --- 3. INSTANSIASI ---
	if selected_data and selected_data.obstacle_scene:
		var obstacle_instance = selected_data.obstacle_scene.instantiate()
		
		if "data" in obstacle_instance:
			obstacle_instance.data = selected_data
			
		add_child(obstacle_instance)
