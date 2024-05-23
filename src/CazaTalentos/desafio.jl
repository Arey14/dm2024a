using CSV
using DataFrames
using Random
using Statistics

# Definir funciones
function ftirar(prob, qty)
    return sum(rand(qty) .< prob)
end

# Variables globales
GLOBAL_jugadores = Float64[]
GLOBAL_tiros_total = 0

# Función para inicializar el gimnasio
function gimnasio_init()
    jugadores = [rand(501:599) / 1000; 0.7]
    return jugadores
end

# Función para realizar tiros
function gimnasio_tirar(jugadores, pids, pcantidad)
    tiros_total = 0
    res = [ftirar(jugadores[pid], pcantidad) for pid in pids]
    tiros_total += length(pids) * pcantidad
    return res, tiros_total
end

# Función para obtener el veredicto
function gimnasio_veredicto(jugadores, pid)
    acierto = jugadores[pid] == 0.7 ? 1 : 0
    return acierto
end

# Cargar el archivo CSV y seleccionar las últimas 20000 semillas
semilla = CSV.read("P-1000000.csv", DataFrame)
ultimas_semillas = semilla[!, "n"][end-9999:end]

# Lista de valores a probar para tiros1, tiros2 y quantile
valores_tiros1 = 80:10:80
valores_tiros2 = 60:10:60
valores_tiros3 = 300:20:300
valores_quantile_ronda2 = [0.66]
valores_quantile_ronda3 = [0.5]

# Inicializar listas para almacenar resultados
resultados_aciertos = Dict()
resultados_tiros = Dict()

# Iterar sobre los valores de los parámetros
for tiros1 in valores_tiros1
    for tiros2 in valores_tiros2
        for tiros3 in valores_tiros3
            for quantile_val_ronda2 in valores_quantile_ronda2
                for quantile_val_ronda3 in valores_quantile_ronda3

                    # Inicializar acumuladores para los resultados
                    total_aciertos = 0
                    total_tiros = 0

                    # Iterar sobre las semillas
                    for i in ultimas_semillas
                        Random.seed!(i)
                        jugadores = gimnasio_init()
                        
                        # Crear la planilla del cazatalentos
                        planilla_cazatalentos = DataFrame(id = 1:100, tiros1 = 0, aciertos1 = 0, tiros2 = 0, aciertos2 = 0, tiros3 = 0, aciertos3 = 0)

                        # Ronda 1
                        ids_juegan1 = 1:100
                        planilla_cazatalentos[ids_juegan1, :tiros1] .= tiros1
                        resultado1, tiros_total1 = gimnasio_tirar(jugadores, ids_juegan1, tiros1)
                        planilla_cazatalentos[ids_juegan1, :aciertos1] .= resultado1

                        # Ronda 2
                        p_quantile_ronda2 = quantile(planilla_cazatalentos[ids_juegan1, :aciertos1], quantile_val_ronda2)
                        ids_juegan2 = planilla_cazatalentos[planilla_cazatalentos.aciertos1 .>= p_quantile_ronda2, :id]
                        planilla_cazatalentos[ids_juegan2, :tiros2] .= tiros2
                        resultado2, tiros_total2 = gimnasio_tirar(jugadores, ids_juegan2, tiros2)
                        planilla_cazatalentos[ids_juegan2, :aciertos2] .= resultado2

                        # Ronda 3
                        p_quantile_ronda3 = quantile(planilla_cazatalentos[ids_juegan2, :aciertos2], quantile_val_ronda3)
                        ids_juegan3 = planilla_cazatalentos[planilla_cazatalentos.aciertos2 .>= p_quantile_ronda3, :id]
                        planilla_cazatalentos[ids_juegan3, :tiros3] .= tiros3
                        resultado3, tiros_total3 = gimnasio_tirar(jugadores, ids_juegan3, tiros3)
                        planilla_cazatalentos[ids_juegan3, :aciertos3] .= resultado3

                        # El cazatalentos toma una decisión
                        pos_mejor = argmax(planilla_cazatalentos.aciertos3)
                        id_mejor = planilla_cazatalentos[pos_mejor, :id]

                        # Veredicto final
                        acierto = gimnasio_veredicto(jugadores, id_mejor)

                        total_aciertos += acierto
                        total_tiros += tiros_total1 + tiros_total2 + tiros_total3
                    end

                    # Almacenar resultados en listas
                    key = string(tiros1, "-", tiros2, "-", tiros3, "-", quantile_val_ronda2, "-", quantile_val_ronda3)
                    resultados_aciertos[key] = total_aciertos / length(ultimas_semillas)
                    resultados_tiros[key] = total_tiros / length(ultimas_semillas)
                end
            end
        end
    end
end

# Convertir los resultados a DataFrames y guardar en CSV
df_aciertos = DataFrame(name = keys(resultados_aciertos), value = values(resultados_aciertos))
df_tiros = DataFrame(name = keys(resultados_tiros), value = values(resultados_tiros))
df_resultados = innerjoin(df_aciertos, df_tiros, on = :name)
CSV.write("final4.csv", df_resultados)

# Mostrar el resultado total
println("Promedio de aciertos ", total_aciertos / length(ultimas_semillas))
println("Promedio de tiros totales:", total_tiros / length(ultimas_semillas))

