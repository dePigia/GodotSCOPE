class_name TestArea
extends Node2D


var orientation: bool = true


@onready var sprite: Sprite2D = $Sprite2D


func _process(_delta: float) -> void:
    if (sprite.position.x >= 1152.0):
        orientation = false
    elif (sprite.position.x <= 0.0):
        orientation = true
    
    sprite.position.x += 1.0 if orientation else -1.0
