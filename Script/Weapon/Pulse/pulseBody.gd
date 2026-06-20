extends Node2D

@export var bullet_scene: PackedScene
@onready var muzzle = $Muzzle
@export var fire_rate: float = 0.5 

var can_shoot: bool = true 

func shoot():
	if not can_shoot:
		return
		
	can_shoot = false
	
	var bullet = bullet_scene.instantiate()
	get_tree().current_scene.add_child(bullet) 

	bullet.global_position = muzzle.global_position
	bullet.global_rotation = muzzle.global_rotation

	await get_tree().create_timer(fire_rate).timeout
	can_shoot = true
