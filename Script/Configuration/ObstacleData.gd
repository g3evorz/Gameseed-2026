class_name ObstacleData
extends Resource

# Enum lama (Biarkan utuh untuk keperluan Level Spawner)
enum ObstacleType { SMALL, BIG, ROCKET }

# Enum BARU (Khusus untuk mengatur perilaku Enemy Spawner)
enum SpawnBehavior { LEVEL_ONLY, DYNAMIC_TEMPORARY, DYNAMIC_PERMANENT }

# Variabel yang sudah ada
@export var obstacle_scene: PackedScene
@export var spawn_weight: float = 1.0
@export var obstacle_type: ObstacleType = ObstacleType.SMALL
@export var max_hp: int = 10

@export_group("Enemy Spawner Settings")
@export var spawn_behavior: SpawnBehavior = SpawnBehavior.LEVEL_ONLY
@export var extra_warning_duration: float = 3.0
@export var spawn_edge_margin: float = 150.0

@export_group("Telegraph Settings")
@export var warning_duration: float = 2.0
@export var telegraph_speed: float = 25.0

@export_group("Firing Settings")
## Lama beam/laser aktif menembak setelah fase warning selesai.
@export var fire_duration: float = 0.5
