extends Node2D
## Escena principal: arma las salas, conecta las señales y controla el flujo del juego.

enum Pantalla { MENU, JUEGO, PAUSA, GAME_OVER, VICTORIA }

const ANCHO = 960
const ALTO = 540
const TOTAL_SALAS = 3

var _estado = Pantalla.MENU
var _sala_actual = 1
var _sala = null
var _puerta = null
var _jugador = null
var _hud = null
var _paredes = []


func _ready():
    _hud = HUD.new()
    add_child(_hud)

    _jugador = Jugador.new()
    add_child(_jugador)
    _jugador.vida_cambiada.connect(_hud.actualizar_vida)
    _jugador.xp_cambiada.connect(_hud.actualizar_xp)
    _jugador.inventario_cambiado.connect(_hud.actualizar_inventario)
    _jugador.mensaje.connect(_hud.mostrar_mensaje)
    _jugador.jugador_murio.connect(_on_jugador_murio)

    _cargar_sala(1)
    _jugador.emitir_estado()
    _congelar(true)
    _hud.mostrar_pantalla("ECOS DEL CALABOZO", "ENTER: Jugar        ESC: Salir\n\nControles\nMoverse: WASD o flechas\nAtacar: Espacio\nEsquivar: Shift\nInteractuar (puertas): E\nInventario: I        Usar poción: P\nPausa: Esc")


# ---------- Dibujo del fondo y las paredes ----------
func _draw():
    draw_rect(Rect2(0, 0, ANCHO, ALTO), Color.html("1b1b2b"))
    for cx in range(16):
        for cy in range(9):
            if (cx + cy) % 2 == 0:
                draw_rect(Rect2(cx * 60, cy * 60, 60, 60), Color.html("20203a"))
    for r in _paredes:
        draw_rect(r, Color.html("4a4a6a"))


# ---------- Construcción de las salas ----------
func _cargar_sala(n):
    _sala_actual = n
    if _sala != null:
        _sala.queue_free()
    _sala = Node2D.new()
    add_child(_sala)
    _paredes.clear()

    _crear_pared(Rect2(0, 0, ANCHO, 30))
    _crear_pared(Rect2(0, ALTO - 30, ANCHO, 30))
    _crear_pared(Rect2(0, 0, 30, ALTO))
    _crear_pared(Rect2(ANCHO - 30, 0, 30, 210))
    _crear_pared(Rect2(ANCHO - 30, 330, 30, 210))

    _puerta = Puerta.new()
    _puerta.position = Vector2(ANCHO - 15, 270)
    _puerta.mensaje.connect(_hud.mostrar_mensaje)
    _sala.add_child(_puerta)

    _jugador.velocity = Vector2.ZERO
    _jugador.global_position = Vector2(80, 270)

    match n:
        1:
            _agregar_enemigo(Goblin.new(), Vector2(600, 150))
            _agregar_enemigo(Goblin.new(), Vector2(650, 400))
            _agregar_objeto("pocion", Vector2(200, 120))
            _agregar_objeto("llave", Vector2(840, 450))
            _agregar_objeto("moneda", Vector2(500, 100))
            _agregar_objeto("moneda", Vector2(500, 440))
            _agregar_objeto("moneda", Vector2(300, 270))
        2:
            _agregar_enemigo(Goblin.new(), Vector2(450, 120))
            _agregar_enemigo(Goblin.new(), Vector2(450, 420))
            _agregar_enemigo(Goblin.new(), Vector2(700, 200))
            _agregar_enemigo(Goblin.new(), Vector2(700, 350))
            _agregar_objeto("cofre", Vector2(800, 100))
            _agregar_objeto("llave", Vector2(850, 440))
            _agregar_objeto("moneda", Vector2(250, 150))
            _agregar_objeto("moneda", Vector2(250, 390))
            _agregar_objeto("moneda", Vector2(600, 270))
        3:
            var orco = _agregar_enemigo(Orco.new(), Vector2(700, 270))
            orco.jefe_derrotado.connect(_on_jefe_derrotado)
            _agregar_objeto("pocion", Vector2(150, 120))
            _agregar_objeto("moneda", Vector2(480, 100))
            _agregar_objeto("moneda", Vector2(480, 440))

    _hud.actualizar_sala(n, TOTAL_SALAS)
    if _estado == Pantalla.JUEGO:
        _mostrar_objetivo()
    else:
        _sala.process_mode = Node.PROCESS_MODE_DISABLED
    queue_redraw()


func _crear_pared(rect):
    _paredes.append(rect)
    var cuerpo = StaticBody2D.new()
    cuerpo.position = rect.position + rect.size / 2.0
    var forma = CollisionShape2D.new()
    var caja = RectangleShape2D.new()
    caja.size = rect.size
    forma.shape = caja
    cuerpo.add_child(forma)
    _sala.add_child(cuerpo)


func _agregar_enemigo(e, pos):
    e.position = pos
    e.murio.connect(_on_enemigo_murio)
    _sala.add_child(e)
    e.activar()
    return e


func _agregar_objeto(tipo, pos):
    var o = Objeto.new()
    o.tipo = tipo
    o.position = pos
    _sala.add_child(o)


func _mostrar_objetivo():
    if _sala_actual == TOTAL_SALAS:
        _hud.mostrar_mensaje("¡Derrota al Orco guardián! Soltará la llave de salida")
    else:
        _hud.mostrar_mensaje("Recoge la llave y abre la puerta con E")


# ---------- Eventos del juego ----------
func _physics_process(_delta):
    if _estado != Pantalla.JUEGO:
        return
    if _puerta != null and _puerta.abierta and _jugador.global_position.x > ANCHO - 25:
        if _sala_actual >= TOTAL_SALAS:
            _victoria()
        else:
            _cargar_sala(_sala_actual + 1)


func _on_enemigo_murio(xp, _posicion):
    _jugador.ganar_xp(xp)


func _on_jefe_derrotado(posicion):
    call_deferred("_agregar_objeto", "llave", posicion)


func _on_jugador_murio():
    call_deferred("_game_over")


func _game_over():
    _estado = Pantalla.GAME_OVER
    _congelar(true)
    _hud.mostrar_pantalla("GAME OVER", "Monedas: %d     Nivel: %d\n\nENTER para reintentar" % [_jugador.inventario.get("moneda", 0), _jugador.nivel])


func _victoria():
    _estado = Pantalla.VICTORIA
    _congelar(true)
    _hud.mostrar_pantalla("¡VICTORIA!", "Escapaste del calabozo\nMonedas: %d     Nivel: %d\n\nENTER para jugar de nuevo" % [_jugador.inventario.get("moneda", 0), _jugador.nivel])


# ---------- Estados y pausa ----------
func _congelar(si):
    var modo = Node.PROCESS_MODE_INHERIT
    if si:
        modo = Node.PROCESS_MODE_DISABLED
    _jugador.process_mode = modo
    if _sala != null:
        _sala.process_mode = modo


func _reiniciar():
    _estado = Pantalla.JUEGO
    _hud.ocultar_pantalla()
    _jugador.reiniciar()
    _congelar(false)
    _cargar_sala(1)


func _input(event):
    if not (event is InputEventKey and event.pressed and not event.echo):
        return
    var tecla = event.physical_keycode
    match _estado:
        Pantalla.MENU:
            if tecla == KEY_ENTER or tecla == KEY_KP_ENTER:
                _reiniciar()
            elif tecla == KEY_ESCAPE:
                get_tree().quit()
        Pantalla.JUEGO:
            if tecla == KEY_ESCAPE:
                _estado = Pantalla.PAUSA
                _congelar(true)
                _hud.mostrar_pantalla("PAUSA", "ESC: continuar\nR: reiniciar")
            elif tecla == KEY_I:
                _hud.alternar_inventario()
        Pantalla.PAUSA:
            if tecla == KEY_ESCAPE:
                _estado = Pantalla.JUEGO
                _hud.ocultar_pantalla()
                _congelar(false)
            elif tecla == KEY_R:
                _reiniciar()
        Pantalla.GAME_OVER, Pantalla.VICTORIA:
            if tecla == KEY_ENTER or tecla == KEY_KP_ENTER:
                _reiniciar()
