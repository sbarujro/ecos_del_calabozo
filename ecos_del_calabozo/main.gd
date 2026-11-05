extends Node2D
## Escena principal: crea el jugador y el HUD, carga las salas y controla el flujo del juego.

enum Fase { MENU, JUEGO, PAUSA, INVENTARIO, GAME_OVER, VICTORIA }

const ESCENA_JUGADOR = preload("res://jugador.tscn")
const ESCENA_SALA = preload("res://sala.tscn")
const ESCENA_HUD = preload("res://hud.tscn")
const ESCENA_MENU = preload("res://menu_principal.tscn")
const ESCENA_CONTROLES = preload("res://controles.tscn")
const ESCENA_PAUSA = preload("res://pausa.tscn")
const ESCENA_INVENTARIO = preload("res://inventario.tscn")
const ESCENA_GAME_OVER = preload("res://game_over.tscn")
const ESCENA_VICTORIA = preload("res://victoria.tscn")
const TOTAL_SALAS = 3

var _fase = Fase.MENU
var _sala_actual = 1
var _sala = null
var _jugador = null
var _hud = null
var _pantalla = null


func _ready():
    _hud = ESCENA_HUD.instantiate()
    add_child(_hud)

    _jugador = ESCENA_JUGADOR.instantiate()
    add_child(_jugador)
    # Las señales conectan al jugador con la interfaz sin acoplarlos
    _jugador.vida_cambiada.connect(_hud.actualizar_vida)
    _jugador.xp_cambiada.connect(_hud.actualizar_xp)
    _jugador.inventario_cambiado.connect(_hud.actualizar_inventario)
    _jugador.mensaje.connect(_hud.mostrar_mensaje)
    _jugador.jugador_murio.connect(_on_jugador_murio)

    _jugador.emitir_estado()
    Sonido.musica("sala")
    _ir_menu()


# ---------- Salas ----------
func _cargar_sala(n):
    _sala_actual = n
    if _sala != null:
        _sala.queue_free()
    _sala = ESCENA_SALA.instantiate()
    _sala.numero = n
    _sala.jugador = _jugador
    _sala.jefe_derrotado.connect(_on_jefe_derrotado)
    add_child(_sala)
    move_child(_sala, 0)
    _jugador.teletransportar(Vector2(100, 352))
    _hud.actualizar_sala(n, TOTAL_SALAS)
    _mostrar_objetivo()


func _mostrar_objetivo():
    match _sala_actual:
        1:
            _hud.mostrar_mensaje("Recoge la llave y abre la puerta con E")
        2:
            _hud.mostrar_mensaje("Una palanca (E) esconde un cofre. Consigue la llave")
        3:
            _hud.mostrar_mensaje("¡Derrota al Orco guardián! Soltará la llave de salida")


func _physics_process(_delta):
    if _fase != Fase.JUEGO or _sala == null:
        return
    var puerta = _sala.puerta
    if puerta != null and puerta.abierta and _jugador.global_position.x > Cfg.ANCHO - 20.0:
        if _sala_actual >= TOTAL_SALAS:
            _victoria()
        else:
            _cargar_sala(_sala_actual + 1)


# ---------- Eventos ----------
func _on_jefe_derrotado(posicion):
    if _sala != null:
        _sala.soltar_llave(posicion)
    _hud.mostrar_mensaje("¡Orco derrotado! Recoge la llave y abre la salida")


func _on_jugador_murio():
    call_deferred("_game_over")


func _game_over():
    _fase = Fase.GAME_OVER
    _congelar(true)
    Sonido.reproducir("derrota")
    _mostrar(ESCENA_GAME_OVER, "Monedas: %d     Nivel: %d" % [_jugador.inventario.get("moneda", 0), _jugador.nivel])


func _victoria():
    _fase = Fase.VICTORIA
    _congelar(true)
    Sonido.reproducir("victoria")
    _mostrar(ESCENA_VICTORIA, "Escapaste del calabozo\nMonedas: %d     Nivel: %d" % [_jugador.inventario.get("moneda", 0), _jugador.nivel])


# ---------- Fases, pausa y pantallas ----------
func _congelar(si):
    var modo = Node.PROCESS_MODE_INHERIT
    if si:
        modo = Node.PROCESS_MODE_DISABLED
    _jugador.process_mode = modo
    if _sala != null:
        _sala.process_mode = modo


func _mostrar(escena, texto = ""):
    _cerrar_pantalla()
    _pantalla = escena.instantiate()
    _pantalla.texto = texto
    _pantalla.accion.connect(_on_accion)
    add_child(_pantalla)


func _cerrar_pantalla():
    if _pantalla != null:
        _pantalla.queue_free()
        _pantalla = null


func _ir_menu():
    if _sala != null:
        _sala.queue_free()
        _sala = null
    _fase = Fase.MENU
    _hud.visible = false
    _jugador.visible = false
    _congelar(true)
    _mostrar(ESCENA_MENU)


func _reiniciar():
    _cerrar_pantalla()
    _fase = Fase.JUEGO
    _hud.visible = true
    _jugador.visible = true
    _jugador.reiniciar()
    _congelar(false)
    _cargar_sala(1)


func _reanudar():
    _cerrar_pantalla()
    _fase = Fase.JUEGO
    _congelar(false)


func _abrir_inventario():
    _fase = Fase.INVENTARIO
    _congelar(true)
    _mostrar(ESCENA_INVENTARIO, _texto_inventario())


func _texto_inventario():
    var inv = _jugador.inventario
    return "Vida: %d / %d\n\nPociones: %d\nLlaves: %d\nMonedas: %d" % [_jugador.vida, _jugador.vida_max, inv.get("pocion", 0), inv.get("llave", 0), inv.get("moneda", 0)]


func _on_accion(nombre):
    match nombre:
        "jugar", "reiniciar":
            _reiniciar()
        "controles":
            _mostrar(ESCENA_CONTROLES)
        "volver":
            _mostrar(ESCENA_MENU)
        "salir":
            get_tree().quit()
        "continuar", "cerrar":
            _reanudar()
        "menu":
            _ir_menu()
        "usar_pocion":
            _jugador.usar_pocion()
            if _pantalla != null and _pantalla.has_method("actualizar"):
                _pantalla.actualizar(_texto_inventario())


func _input(event):
    if not (event is InputEventKey and event.pressed and not event.echo):
        return
    var tecla = event.physical_keycode
    match _fase:
        Fase.JUEGO:
            if tecla == KEY_ESCAPE:
                _fase = Fase.PAUSA
                _congelar(true)
                _mostrar(ESCENA_PAUSA)
            elif tecla == KEY_I:
                _abrir_inventario()
        Fase.PAUSA:
            if tecla == KEY_ESCAPE:
                _reanudar()
        Fase.INVENTARIO:
            if tecla == KEY_I or tecla == KEY_ESCAPE:
                _reanudar()
