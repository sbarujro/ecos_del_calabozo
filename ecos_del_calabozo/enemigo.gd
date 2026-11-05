class_name Enemigo
extends CharacterBody2D
## Clase base de los enemigos. Goblin y Orco heredan de ella.

signal murio(xp, posicion)

# Maquina de estados
enum Estado { INACTIVO, PATRULLANDO, PERSIGUIENDO, ATACANDO, MUERTO }

var vida_max = 30
var danio = 5
var velocidad = 120.0
var xp_otorgada = 20
var rango_vision = 240.0
var rango_ataque = 34.0
var cooldown_ataque = 1.0
var tamano = Vector2(22, 22)
var color = Color.html("4caf50")

var estado = Estado.INACTIVO

var _cd = 0.0
var _flash = 0.0
var _cargando = false
var _dir_patrulla = Vector2.RIGHT
var _t_patrulla = 0.0
var _colision = null

# Encapsulamiento: set controla que la vida no baje de 0 ni supere el maximo
var vida = 30:
    set(valor):
        vida = clampi(valor, 0, vida_max)
        if is_inside_tree():
            queue_redraw()
        if vida == 0 and estado != Estado.MUERTO:
            morir()


# Las clases hijas sobrescriben estos metodos (polimorfismo)
func _configurar():
    pass


func atacar():
    pass


func _ready():
    motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
    _configurar()
    vida = vida_max
    add_to_group("enemigos")
    collision_layer = 2
    collision_mask = 1
    var forma = CollisionShape2D.new()
    var caja = RectangleShape2D.new()
    caja.size = tamano
    forma.shape = caja
    add_child(forma)
    _colision = forma


func activar():
    if estado == Estado.INACTIVO:
        estado = Estado.PATRULLANDO


func _jugador():
    return get_tree().get_first_node_in_group("jugador")


func _physics_process(delta):
    if estado == Estado.MUERTO:
        return
    _cd = maxf(0.0, _cd - delta)
    _flash = maxf(0.0, _flash - delta)
    var j = _jugador()
    if j == null or estado == Estado.INACTIVO or _cargando:
        velocity = Vector2.ZERO
        queue_redraw()
        return

    var dist = global_position.distance_to(j.global_position)
    match estado:
        Estado.PATRULLANDO:
            _patrullar(delta)
            if dist < rango_vision:
                estado = Estado.PERSIGUIENDO
        Estado.PERSIGUIENDO:
            if dist > rango_vision * 1.6:
                estado = Estado.PATRULLANDO
            elif dist <= rango_ataque and _cd <= 0.0:
                estado = Estado.ATACANDO
            elif dist > rango_ataque * 0.7:
                velocity = (j.global_position - global_position).normalized() * velocidad
            else:
                velocity = Vector2.ZERO
        Estado.ATACANDO:
            velocity = Vector2.ZERO
            atacar()
            _cd = cooldown_ataque
            estado = Estado.PERSIGUIENDO
    move_and_slide()
    queue_redraw()


func _patrullar(delta):
    _t_patrulla -= delta
    if _t_patrulla <= 0.0 or get_slide_collision_count() > 0:
        _t_patrulla = randf_range(1.0, 2.5)
        _dir_patrulla = Vector2.from_angle(randf() * TAU)
    velocity = _dir_patrulla * velocidad * 0.4


func recibir_danio(cantidad, origen = Vector2.ZERO):
    if estado == Estado.MUERTO:
        return
    vida -= cantidad
    _flash = 0.12
    if estado != Estado.MUERTO and origen != Vector2.ZERO:
        move_and_collide((global_position - origen).normalized() * 10.0)


func morir():
    estado = Estado.MUERTO
    remove_from_group("enemigos")
    if _colision != null:
        _colision.set_deferred("disabled", true)
    murio.emit(xp_otorgada, global_position)
    queue_free()


func _draw():
    var c = color
    if _flash > 0.0:
        c = Color.WHITE
    elif _cargando:
        c = Color.html("ff9800")
    draw_rect(Rect2(-tamano / 2.0, tamano), c)
    var ancho = tamano.x
    var y = -tamano.y / 2.0 - 8.0
    draw_rect(Rect2(-ancho / 2.0, y, ancho, 4.0), Color(0.2, 0.0, 0.0))
    draw_rect(Rect2(-ancho / 2.0, y, ancho * float(vida) / float(vida_max), 4.0), Color(0.9, 0.1, 0.1))
