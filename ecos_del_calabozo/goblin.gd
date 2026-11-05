class_name Goblin
extends Enemigo
## Enemigo comun: debil y rapido, golpea de inmediato.


func _configurar():
    vida_max = 30
    danio = 5
    velocidad = 120.0
    xp_otorgada = 20
    cooldown_ataque = 1.0
    rango_ataque = 34.0
    tamano = Vector2(22, 22)
    color = Color.html("4caf50")


func atacar():
    var j = _jugador()
    if j != null:
        j.recibir_danio(danio, global_position)
