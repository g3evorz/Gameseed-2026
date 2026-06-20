extends StaticBody2D

@export var max_hp: int = 30
var current_hp: int

func _ready():
	current_hp = max_hp

func take_damage(damage_amount: int):
	current_hp -= damage_amount
	
	if current_hp <= 0:
		die()

func die():
	queue_free()
