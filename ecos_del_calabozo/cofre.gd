class_name Cofre
extends StaticBody2D
## Cofre: se abre con E y contiene una pocion o monedas.

var abierto = false


func _ready():
    var caja = RectangleShape2D.new()
    caja.size = Vector2(28, 20)
    $Colision.shape = caja
    $Sprite.sprite_frames = Util.frames({
        "cerrado": {"archivos": ["res://assets/cofre_cerrado_0.png"], "vel": 1.0, "bucle": true},
        "abierto": {"archivos": ["res://assets/cofre_abierto_0.png"], "vel": 1.0, "bucle": true},
    })
    $Sprite.play("cerrado")


func _unhandled_input(event):
    if abierto:
        return
    if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_E:
        var j = get_tree().get_first_node_in_group("jugador")
        if j == null or global_position.distance_to(j.global_position) > 80.0:
            return
        abierto = true
        $Sprite.play("abierto")
        Sonido.reproducir("recoger")
        if randf() < 0.5:
            j.recoger("pocion", 1)
        else:
            j.recoger("moneda", 3)
