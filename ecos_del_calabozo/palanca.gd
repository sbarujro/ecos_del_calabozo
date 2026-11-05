class_name Palanca
extends Node2D
## Palanca: se acciona con E y revela un cofre oculto en la sala.

signal activada

var _usada = false


func _ready():
    $Sprite.sprite_frames = Util.frames({
        "off": {"archivos": ["res://assets/palanca_off_0.png"], "vel": 1.0, "bucle": true},
        "on": {"archivos": ["res://assets/palanca_on_0.png"], "vel": 1.0, "bucle": true},
    })
    $Sprite.play("off")


func _unhandled_input(event):
    if _usada:
        return
    if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_E:
        var j = get_tree().get_first_node_in_group("jugador")
        if j == null or global_position.distance_to(j.global_position) > 80.0:
            return
        _usada = true
        $Sprite.play("on")
        Sonido.reproducir("palanca")
        j.mensaje.emit("Un mecanismo se activó: ¡apareció un cofre!")
        activada.emit()
