class_name Objeto
extends Area2D
## Objetos recolectables: pocion, llave y moneda.

var tipo = "moneda"


func _ready():
    var circulo = CircleShape2D.new()
    circulo.radius = 16.0
    $Colision.shape = circulo
    var base = "res://assets/%s_idle_" % tipo
    var archivos = [base + "0.png"]
    var vel = 1.0
    if tipo == "moneda":
        archivos = [base + "0.png", base + "1.png", base + "2.png", base + "3.png"]
        vel = 6.0
    $Sprite.sprite_frames = Util.frames({"idle": {"archivos": archivos, "vel": vel, "bucle": true}})
    $Sprite.play("idle")
    body_entered.connect(_al_entrar)


func _al_entrar(cuerpo):
    if not (cuerpo is Jugador):
        return
    set_deferred("monitoring", false)
    cuerpo.recoger(tipo, 1)
    Sonido.reproducir("recoger")
    queue_free()
