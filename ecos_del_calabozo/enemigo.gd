class_name Enemigo
extends CharacterBody2D
## Clase base de los enemigos. Goblin y Orco heredan de ella.

signal murio(xp)

# Maquina de estados
enum Estado { INACTIVO, PATRULLANDO, PERSIGUIENDO, ATACANDO, MUERTO }

var prefijo = "goblin"
var vida_max = 30
var danio = 5
var velocidad = 120.0
var xp_otorgada = 20
var rango_vision = 260.0
var rango_ataque = 38.0
var cooldown_ataque = 1.0
var tamano = Vector2(22, 22)
var alto_visual = 32

var estado = Estado.INACTIVO

var _cd = 0.0
var _flash = 0.0
var _t_anim_ataque = 0.0
var _cargando = false
var _t_carga = 0.0
var _punto_a = Vector2.ZERO
var _punto_b = Vector2.ZERO
var _hacia_b = true
var _anim = ""

# Encapsulamiento: set controla que la vida no baje de 0 ni supere el maximo
var vida = 30:
    set(valor):
        vida = clampi(valor, 0, vida_max)
        if is_inside_tree():
            queue_redraw()
        if vida == 0 and estado != Estado.MUERTO:
            morir()

@onready var _sprite = $Sprite


# Las clases hijas sobrescriben estos metodos (polimorfismo)
func _configurar():
    pass


func atacar():
    pass


func _golpe_cargado():
    pass


func _ready():
    motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
    _configurar()
    vida = vida_max
    add_to_group("enemigos")
    collision_layer = 2
    collision_mask = 1
    var caja = RectangleShape2D.new()
    caja.size = tamano
    $Colision.shape = caja

    var d = "res://assets/%s_" % prefijo
    _sprite.sprite_frames = Util.frames({
        "caminar": {"archivos": [d + "caminar_0.png", d + "caminar_1.png"], "vel": 6.0, "bucle": true},
        "atacar": {"archivos": [d + "atacar_0.png", d + "atacar_1.png"], "vel": 5.0, "bucle": true},
        "morir": {"archivos": [d + "morir_0.png", d + "morir_1.png"], "vel": 4.0, "bucle": false},
    })
    _sprite.play("caminar")


# El enemigo esta INACTIVO hasta que la sala lo activa (cuando el jugador entra)
func activar():
    if estado != Estado.INACTIVO:
        return
    _punto_a = global_position
    _punto_b = global_position + Vector2(randf_range(-160.0, 160.0), randf_range(-120.0, 120.0))
    _punto_b.x = clampf(_punto_b.x, 64.0, Cfg.ANCHO - 64.0)
    _punto_b.y = clampf(_punto_b.y, 64.0, Cfg.ALTO - 64.0)
    estado = Estado.PATRULLANDO


func _jugador():
    return get_tree().get_first_node_in_group("jugador")


func _physics_process(delta):
    if estado == Estado.MUERTO:
        return
    _cd = maxf(0.0, _cd - delta)
    _flash = maxf(0.0, _flash - delta)
    _t_anim_ataque = maxf(0.0, _t_anim_ataque - delta)

    if _cargando:
        _t_carga -= delta
        velocity = Vector2.ZERO
        if _t_carga <= 0.0:
            _cargando = false
            _golpe_cargado()
        _animar()
        return

    var j = _jugador()
    if j == null or estado == Estado.INACTIVO:
        velocity = Vector2.ZERO
        _animar()
        return

    var dist = global_position.distance_to(j.global_position)
    match estado:
        Estado.PATRULLANDO:
            _patrullar()
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
            _t_anim_ataque = 0.3
            atacar()
            _cd = cooldown_ataque
            estado = Estado.PERSIGUIENDO
    move_and_slide()
    _animar()


func _patrullar():
    var destino = _punto_a
    if _hacia_b:
        destino = _punto_b
    if global_position.distance_to(destino) < 8.0 or get_slide_collision_count() > 0:
        _hacia_b = not _hacia_b
        destino = _punto_a
        if _hacia_b:
            destino = _punto_b
    velocity = (destino - global_position).normalized() * velocidad * 0.5


func _animar():
    var anim = "caminar"
    if _t_anim_ataque > 0.0 or _cargando:
        anim = "atacar"
    if anim != _anim:
        _anim = anim
        _sprite.play(anim)
    if absf(velocity.x) > 1.0:
        _sprite.flip_h = velocity.x < 0.0
    if _flash > 0.0:
        _sprite.modulate = Color(1.0, 0.5, 0.5)
    elif _cargando:
        _sprite.modulate = Color(1.0, 0.7, 0.3)
    else:
        _sprite.modulate = Color.WHITE


func recibir_danio(cantidad, origen = Vector2.ZERO):
    if estado == Estado.MUERTO:
        return
    Sonido.reproducir("golpe")
    vida -= cantidad
    _flash = 0.12
    if estado != Estado.MUERTO and origen != Vector2.ZERO:
        move_and_collide((global_position - origen).normalized() * 10.0)


func morir():
    estado = Estado.MUERTO
    remove_from_group("enemigos")
    $Colision.set_deferred("disabled", true)
    Sonido.reproducir("muerte")
    murio.emit(xp_otorgada)
    _sprite.modulate = Color.WHITE
    _sprite.play("morir")
    queue_redraw()
    get_tree().create_timer(0.6).timeout.connect(queue_free)


# Barra de vida sobre el enemigo
func _draw():
    if estado == Estado.MUERTO:
        return
    var ancho = tamano.x + 8.0
    var y = -alto_visual / 2.0 - 8.0
    draw_rect(Rect2(-ancho / 2.0, y, ancho, 4.0), Color(0.2, 0.0, 0.0))
    draw_rect(Rect2(-ancho / 2.0, y, ancho * float(vida) / float(vida_max), 4.0), Color(0.9, 0.1, 0.1))
