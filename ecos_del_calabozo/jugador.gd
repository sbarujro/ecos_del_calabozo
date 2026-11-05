class_name Jugador
extends CharacterBody2D
## El Caballero: movimiento, ataque, esquiva, vida, inventario y experiencia.

signal vida_cambiada(vida, vida_max)
signal xp_cambiada(xp, nivel, necesaria)
signal inventario_cambiado(inventario)
signal mensaje(texto)
signal jugador_murio

var velocidad = 200.0
var danio = 10
var nivel = 1
var xp = 0
var vida_max = 100
var mirando = Vector2.RIGHT
# Inventario: nombre del objeto -> cantidad (Dictionary)
var inventario = {"pocion": 0, "llave": 0, "moneda": 0}

var _muerto = false
var _cd_ataque = 0.0
var _cd_esquiva = 0.0
var _esquivando = 0.0
var _inmune = 0.0
var _t_ataque = 0.0
var _dir_esquiva = Vector2.RIGHT
var _anim = ""

# Encapsulamiento: la vida solo se modifica a traves de este set
var vida = 100:
    set(valor):
        vida = clampi(valor, 0, vida_max)
        vida_cambiada.emit(vida, vida_max)
        if vida == 0 and not _muerto:
            _muerto = true
            jugador_murio.emit()

@onready var _sprite = $Sprite
@onready var _area_ataque = $AreaAtaque
@onready var _camara = $Camara


func _ready():
    motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
    add_to_group("jugador")
    var caja = RectangleShape2D.new()
    caja.size = Vector2(24, 24)
    $Colision.shape = caja
    var golpe = RectangleShape2D.new()
    golpe.size = Vector2(52, 52)
    $AreaAtaque/Forma.shape = golpe

    var d = "res://assets/caballero_"
    _sprite.sprite_frames = Util.frames({
        "quieto": {"archivos": [d + "quieto_0.png"], "vel": 1.0, "bucle": true},
        "caminar": {"archivos": [d + "caminar_0.png", d + "caminar_1.png"], "vel": 8.0, "bucle": true},
        "atacar": {"archivos": [d + "atacar_0.png", d + "atacar_1.png"], "vel": 12.0, "bucle": false},
        "esquivar": {"archivos": [d + "esquivar_0.png"], "vel": 1.0, "bucle": true},
    })
    _sprite.play("quieto")

    # La camara sigue al jugador sin salirse de la sala
    _camara.limit_left = 0
    _camara.limit_top = 0
    _camara.limit_right = Cfg.ANCHO
    _camara.limit_bottom = Cfg.ALTO
    _camara.position_smoothing_enabled = true
    _camara.position_smoothing_speed = 8.0


func _physics_process(delta):
    _cd_ataque = maxf(0.0, _cd_ataque - delta)
    _cd_esquiva = maxf(0.0, _cd_esquiva - delta)
    _esquivando = maxf(0.0, _esquivando - delta)
    _inmune = maxf(0.0, _inmune - delta)
    _t_ataque = maxf(0.0, _t_ataque - delta)

    var dir = Vector2.ZERO
    if Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP):
        dir.y -= 1.0
    if Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN):
        dir.y += 1.0
    if Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT):
        dir.x -= 1.0
    if Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT):
        dir.x += 1.0
    if dir != Vector2.ZERO:
        dir = dir.normalized()
        mirando = dir

    if _esquivando > 0.0:
        velocity = _dir_esquiva * 600.0
    else:
        velocity = dir * velocidad
    move_and_slide()
    _actualizar_sprite(dir)


func _actualizar_sprite(dir):
    var anim = "quieto"
    if _esquivando > 0.0:
        anim = "esquivar"
    elif _t_ataque > 0.0:
        anim = "atacar"
    elif dir != Vector2.ZERO:
        anim = "caminar"
    if anim != _anim:
        _anim = anim
        _sprite.play(anim)
    if absf(mirando.x) > 0.1:
        _sprite.flip_h = mirando.x < 0.0
    if _inmune > 0.0 and int(_inmune * 20.0) % 2 == 0:
        _sprite.modulate = Color(1.0, 0.45, 0.45)
    else:
        _sprite.modulate = Color.WHITE


func _unhandled_input(event):
    if event is InputEventKey and event.pressed and not event.echo:
        match event.physical_keycode:
            KEY_SPACE:
                atacar()
            KEY_SHIFT:
                esquivar()


func atacar():
    if _cd_ataque > 0.0 or _esquivando > 0.0:
        return
    _cd_ataque = 0.5
    _t_ataque = 0.25
    Sonido.reproducir("espada")
    _golpear()


# El golpe se detecta con el Area2D "AreaAtaque", colocada en la direccion a la que mira el personaje
func _golpear():
    _area_ataque.position = mirando * 32.0
    await get_tree().physics_frame
    await get_tree().physics_frame
    for cuerpo in _area_ataque.get_overlapping_bodies():
        if cuerpo is Enemigo:
            cuerpo.recibir_danio(danio, global_position)


func esquivar():
    if _cd_esquiva > 0.0 or _esquivando > 0.0:
        return
    _cd_esquiva = 2.0
    _esquivando = 0.2
    _dir_esquiva = mirando


func recibir_danio(cantidad, _origen = Vector2.ZERO):
    if _inmune > 0.0 or _esquivando > 0.0:
        return
    _inmune = 0.5
    Sonido.reproducir("dano")
    vida -= cantidad


func usar_pocion():
    if vida >= vida_max:
        mensaje.emit("Tu vida ya está completa")
    elif gastar("pocion"):
        vida += 30
        Sonido.reproducir("recoger")
        mensaje.emit("Usaste una poción (+30 de vida)")
    else:
        mensaje.emit("No tienes pociones")


func recoger(objeto, cantidad = 1):
    inventario[objeto] = inventario.get(objeto, 0) + cantidad
    inventario_cambiado.emit(inventario)
    mensaje.emit("Recogiste: %s x%d" % [objeto, cantidad])


func gastar(objeto, cantidad = 1):
    if inventario.get(objeto, 0) < cantidad:
        return false
    inventario[objeto] -= cantidad
    inventario_cambiado.emit(inventario)
    return true


# XP necesaria para pasar del nivel n al n+1: 40 * n
func xp_necesaria():
    return 40 * nivel


func ganar_xp(cantidad):
    xp += cantidad
    while xp >= xp_necesaria():
        xp -= xp_necesaria()
        nivel += 1
        vida_max += 20
        danio += 2
        vida = vida_max
        Sonido.reproducir("nivel")
        mensaje.emit("¡Subiste al nivel %d!" % nivel)
    xp_cambiada.emit(xp, nivel, xp_necesaria())


func emitir_estado():
    vida_cambiada.emit(vida, vida_max)
    xp_cambiada.emit(xp, nivel, xp_necesaria())
    inventario_cambiado.emit(inventario)


func teletransportar(pos):
    global_position = pos
    velocity = Vector2.ZERO
    _camara.reset_smoothing()


func reiniciar():
    _muerto = false
    nivel = 1
    xp = 0
    vida_max = 100
    danio = 10
    inventario = {"pocion": 0, "llave": 0, "moneda": 0}
    vida = vida_max
    _inmune = 0.0
    _esquivando = 0.0
    _t_ataque = 0.0
    mirando = Vector2.RIGHT
    emitir_estado()
