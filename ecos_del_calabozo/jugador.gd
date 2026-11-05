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
var _flash_ataque = 0.0
var _dir_esquiva = Vector2.RIGHT

# Encapsulamiento: la vida solo se modifica a traves de este set
var vida = 100:
    set(valor):
        vida = clampi(valor, 0, vida_max)
        vida_cambiada.emit(vida, vida_max)
        if vida == 0 and not _muerto:
            _muerto = true
            jugador_murio.emit()


func _ready():
    motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
    add_to_group("jugador")
    var forma = CollisionShape2D.new()
    var caja = RectangleShape2D.new()
    caja.size = Vector2(24, 24)
    forma.shape = caja
    add_child(forma)


func _physics_process(delta):
    _cd_ataque = maxf(0.0, _cd_ataque - delta)
    _cd_esquiva = maxf(0.0, _cd_esquiva - delta)
    _esquivando = maxf(0.0, _esquivando - delta)
    _inmune = maxf(0.0, _inmune - delta)
    _flash_ataque = maxf(0.0, _flash_ataque - delta)

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
    queue_redraw()


func _unhandled_input(event):
    if event is InputEventKey and event.pressed and not event.echo:
        match event.physical_keycode:
            KEY_SPACE:
                atacar()
            KEY_SHIFT:
                esquivar()
            KEY_P:
                usar_pocion()


func atacar():
    if _cd_ataque > 0.0 or _esquivando > 0.0:
        return
    _cd_ataque = 0.5
    _flash_ataque = 0.12
    var centro = global_position + mirando * 32.0
    for e in get_tree().get_nodes_in_group("enemigos"):
        if e.global_position.distance_to(centro) <= 45.0:
            e.recibir_danio(danio, global_position)


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
    vida -= cantidad


func usar_pocion():
    if vida >= vida_max:
        mensaje.emit("Tu vida ya está completa")
    elif gastar("pocion"):
        vida += 30
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
        mensaje.emit("¡Subiste al nivel %d!" % nivel)
    xp_cambiada.emit(xp, nivel, xp_necesaria())


func emitir_estado():
    vida_cambiada.emit(vida, vida_max)
    xp_cambiada.emit(xp, nivel, xp_necesaria())
    inventario_cambiado.emit(inventario)


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
    emitir_estado()


func _draw():
    var c = Color.html("42a5f5")
    if _esquivando > 0.0:
        c = Color(0.7, 0.9, 1.0, 0.5)
    elif _inmune > 0.0 and int(_inmune * 20.0) % 2 == 0:
        c = Color.WHITE
    draw_rect(Rect2(-12, -12, 24, 24), c)
    draw_rect(Rect2(mirando * 8.0 - Vector2(3, 3), Vector2(6, 6)), Color.html("0d47a1"))
    if _flash_ataque > 0.0:
        draw_rect(Rect2(mirando * 32.0 - Vector2(22, 22), Vector2(44, 44)), Color(1, 1, 1, 0.45))
