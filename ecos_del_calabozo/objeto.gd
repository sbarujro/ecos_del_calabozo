class_name Objeto
extends Area2D
## Objetos recolectables: pocion, llave, moneda y cofre.

var tipo = "moneda"


func _ready():
    var forma = CollisionShape2D.new()
    var circulo = CircleShape2D.new()
    circulo.radius = 14.0
    forma.shape = circulo
    add_child(forma)
    body_entered.connect(_al_entrar)


func _al_entrar(cuerpo):
    if not (cuerpo is Jugador):
        return
    match tipo:
        "cofre":
            if randf() < 0.5:
                cuerpo.recoger("pocion", 1)
            else:
                cuerpo.recoger("moneda", 3)
        _:
            cuerpo.recoger(tipo, 1)
    queue_free()


func _draw():
    match tipo:
        "pocion":
            draw_circle(Vector2.ZERO, 10.0, Color.html("e53935"))
            draw_rect(Rect2(-2, -6, 4, 12), Color.WHITE)
            draw_rect(Rect2(-6, -2, 12, 4), Color.WHITE)
        "llave":
            draw_circle(Vector2(-6, 0), 6.0, Color.html("fdd835"))
            draw_rect(Rect2(-2, -2, 16, 4), Color.html("fdd835"))
        "cofre":
            draw_rect(Rect2(-14, -10, 28, 20), Color.html("8d6e63"))
            draw_rect(Rect2(-14, -2, 28, 4), Color.html("ffd54f"))
        _:
            draw_circle(Vector2.ZERO, 7.0, Color.html("ffc107"))
