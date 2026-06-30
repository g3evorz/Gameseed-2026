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

# Variabel khusus untuk musuh
@export_group("Enemy Spawner Settings")
## Tentukan bagaimana musuh men-spawn rintangan ini. 
## LEVEL_ONLY berarti rintangan ini HANYA spawn dari level dan diabaikan oleh musuh.
@export var spawn_behavior: SpawnBehavior = SpawnBehavior.LEVEL_ONLY

## Durasi ekstra peringatan bahaya (hanya berguna jika ini tipe DYNAMIC_TEMPORARY)
@export var extra_warning_duration: float = 3.0
