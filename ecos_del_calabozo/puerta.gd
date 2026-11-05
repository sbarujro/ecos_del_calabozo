class_name Puerta
extends StaticBody2D
## Puerta de salida de cada sala. Se abre con E si el jugador tiene una llave.

signal mensaje(texto)

var abierta = false
var _colision = null


func _ready():
    var forma = CollisionShape2D.new()
    var caja = RectangleShape2D.new()
    caja.size = Vector2(30, 120)
    forma.shape = caja
    add_child(forma)
    _colision = forma


func _unhandled_input(event):
    if abierta:
        return
    if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_E:
        var j = get_tree().get_first_node_in_group("jugador")
        if j == null or global_position.distance_to(j.global_position) > 90.0:
            return
        if j.gastar("llave"):
            abrir()
        else:
            mensaje.emit("La puerta está cerrada: necesitas una llave")


func abrir():
    abierta = true
    _colision.set_deferred("disabled", true)
    queue_redraw()
    mensaje.emit("¡Puerta abierta! Sigue hacia la derecha")


func _draw():
    if abierta:
        draw_rect(Rect2(-15, -60, 30, 120), Color(0.3, 0.8, 0.3, 0.25))
    else:
        draw_rect(Rect2(-15, -60, 30, 120), Color.html("6d4c41"))
        draw_rect(Rect2(-15, -60, 30, 120), Color.html("3e2723"), false, 3.0)
        draw_circle(Vector2(5, 0), 5.0, Color.html("ffd54f"))
