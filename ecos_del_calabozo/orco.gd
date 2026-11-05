class_name Orco
extends Enemigo
## Jefe final: lento y resistente, con ataque cargado que se puede esquivar.

signal jefe_derrotado(posicion)


func _configurar():
    vida_max = 120
    danio = 15
    velocidad = 90.0
    xp_otorgada = 150
    cooldown_ataque = 2.5
    rango_ataque = 56.0
    tamano = Vector2(44, 44)
    color = Color.html("2e7d32")


func atacar():
    # Ataque cargado: se pone naranja 1 segundo antes de golpear
    _cargando = true
    queue_redraw()
    await get_tree().create_timer(1.0).timeout
    if estado == Estado.MUERTO or not is_inside_tree():
        return
    var j = _jugador()
    if j != null and global_position.distance_to(j.global_position) <= rango_ataque + 20.0:
        j.recibir_danio(danio, global_position)
    _cargando = false
    queue_redraw()


func morir():
    super.morir()
    jefe_derrotado.emit(global_position)
