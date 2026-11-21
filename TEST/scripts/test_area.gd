class_name TestArea
extends Node2D


@export var orientation: bool = true
@export var counter: int = 0
@export var si: float = 0
@export var player_health: float = 100.0


@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
    counter = 0


func _process(_delta: float) -> void:
    if (sprite.position.x >= 1152.0):
        orientation = false
    elif (sprite.position.x <= 0.0):
        orientation = true
    
    sprite.position.x += 1.0 if orientation else -1.0

    counter += 1 if orientation else -1

    si = sin(counter)
