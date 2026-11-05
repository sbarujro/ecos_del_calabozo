class_name Puerta
extends StaticBody2D
## Puerta de salida de cada sala. Se abre con E si el jugador tiene una llave.

var abierta = false


func _ready():
    var caja = RectangleShape2D.new()
    caja.size = Vector2(32, 128)
    $Colision.shape = caja
    $Sprite.sprite_frames = Util.frames({
        "cerrada": {"archivos": ["res://assets/puerta_cerrada_0.png"], "vel": 1.0, "bucle": true},
        "abierta": {"archivos": ["res://assets/puerta_abierta_0.png"], "vel": 1.0, "bucle": true},
    })
    $Sprite.play("cerrada")


func _unhandled_input(event):
    if abierta:
        return
    if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_E:
        var j = get_tree().get_first_node_in_group("jugador")
        if j == null or global_position.distance_to(j.global_position) > 110.0:
            return
        if j.gastar("llave"):
            abrir()
            j.mensaje.emit("¡Puerta abierta! Sigue hacia la derecha")
        else:
            j.mensaje.emit("La puerta está cerrada: necesitas una llave")


func abrir():
    abierta = true
    $Colision.set_deferred("disabled", true)
    $Sprite.play("abierta")
    Sonido.reproducir("puerta")
