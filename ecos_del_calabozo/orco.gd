class_name Orco
extends Enemigo
## Jefe final: lento y resistente, con ataque cargado que se puede esquivar.

signal jefe_derrotado(posicion)


func _configurar():
    prefijo = "orco"
    vida_max = 120
    danio = 15
    velocidad = 90.0
    xp_otorgada = 150
    cooldown_ataque = 2.5
    rango_ataque = 60.0
    tamano = Vector2(44, 44)
    alto_visual = 48


# Ataque cargado: el orco se pone naranja 1 segundo antes de golpear
func atacar():
    _cargando = true
    _t_carga = 1.0
    Sonido.reproducir("rugido")


func _golpe_cargado():
    var j = _jugador()
    if j != null and global_position.distance_to(j.global_position) <= rango_ataque + 20.0:
        j.recibir_danio(danio, global_position)


func morir():
    super.morir()
    jefe_derrotado.emit(global_position)
