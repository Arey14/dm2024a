# esqueleto de grid search
# se espera que los alumnos completen lo que falta
#   para recorrer TODOS cuatro los hiperparametros

rm(list = ls()) # Borro todos los objetos
gc() # Garbage Collection

require("data.table")
require("rpart")
require("parallel")

PARAM <- list()
# reemplazar por las propias semillas
PARAM$semillas <- c(734471, 734473, 734477, 734479, 734497)

#------------------------------------------------------------------------------
# particionar agrega una columna llamada fold a un dataset
#  que consiste en una particion estratificada segun agrupa
# particionar( data=dataset, division=c(70,30), agrupa=clase_ternaria, seed=semilla)
#   crea una particion 70, 30

particionar <- function(data, division, agrupa = "", campo = "fold", start = 1, seed = NA) {
  if (!is.na(seed)) set.seed(seed)

  bloque <- unlist(mapply(function(x, y) {
    rep(y, x)
  }, division, seq(from = start, length.out = length(division))))

  data[, (campo) := sample(rep(bloque, ceiling(.N / length(bloque))))[1:.N],
    by = agrupa
  ]
}
#------------------------------------------------------------------------------

ArbolEstimarGanancia <- function(semilla, param_basicos) {
  # particiono estratificadamente el dataset
  particionar(dataset, division = c(7, 3), agrupa = "clase_ternaria", seed = semilla)

  # genero el modelo
  # quiero predecir clase_ternaria a partir del resto
  modelo <- rpart("clase_ternaria ~ .",
    data = dataset[fold == 1], # fold==1  es training,  el 70% de los datos
    xval = 0,
    control = param_basicos
  ) # aqui van los parametros del arbol

  # aplico el modelo a los datos de testing
  prediccion <- predict(modelo, # el modelo que genere recien
    dataset[fold == 2], # fold==2  es testing, el 30% de los datos
    type = "prob"
  ) # type= "prob"  es que devuelva la probabilidad

  # prediccion es una matriz con TRES columnas,
  #  llamadas "BAJA+1", "BAJA+2"  y "CONTINUA"
  # cada columna es el vector de probabilidades


  # calculo la ganancia en testing  qu es fold==2
  ganancia_test <- dataset[
    fold == 2,
    sum(ifelse(prediccion[, "BAJA+2"] > 0.025,
      ifelse(clase_ternaria == "BAJA+2", 117000, -3000),
      0
    ))
  ]

  # escalo la ganancia como si fuera todo el dataset
  ganancia_test_normalizada <- ganancia_test / 0.3

  return(ganancia_test_normalizada)
}
#------------------------------------------------------------------------------

ArbolesMontecarlo <- function(semillas, param_basicos) {
  # la funcion mcmapply  llama a la funcion ArbolEstimarGanancia
  #  tantas veces como valores tenga el vector  PARAM$semillas
  ganancias <- mcmapply(ArbolEstimarGanancia,
    semillas, # paso el vector de semillas
    MoreArgs = list(param_basicos), # aqui paso el segundo parametro
    SIMPLIFY = FALSE,
    mc.cores = 5 # en Windows este valor debe ser 1
  )

  ganancia_promedio <- mean(unlist(ganancias))

  return(ganancia_promedio)
}
#------------------------------------------------------------------------------
#------------------------------------------------------------------------------

# Aqui se debe poner la carpeta de la computadora local
#setwd("exp/") # Establezco el Working Directory
# cargo los datos 

# cargo los datos
dataset <- fread("Desktop/ITBA/Mineria de Datos/datasets/dataset_pequeno.csv")

# trabajo solo con los datos con clase, es decir 202107
dataset <- dataset[clase_ternaria != ""]

# genero el archivo para Kaggle
# creo la carpeta donde va el experimento
# HT  representa  Hiperparameter Tuning
dir.create("./exp/", showWarnings = FALSE)
dir.create("./exp/HT2020/", showWarnings = FALSE)
archivo_salida <- "./exp/HT2020/gridsearch.txt"

# genero la data.table donde van los resultados del Grid Search
tb_grid_search <- data.table( max_depth = integer(),
                              min_split = integer(),
                              ganancia_promedio = numeric() )


# itero por los loops anidados para cada hiperparametro

# Pre-calculate vmin_bucket values
calculate_vmin_bucket <- function(vmin_split) {
  seq.int(vmin_split  %/%2, vmin_split %/% 6, length.out = 5)
}

# Generate combinations of parameters
param_combinations <- expand.grid(
  vmax_depth = c(4, 6, 8, 10, 12, 14),
  vmin_split = c(1000, 800, 600, 400, 200, 100, 50, 20, 10),
  vmin_cp = c(0.1, 0.2, 0.3, 0.5)
)

# Pre-allocate memory for the result data frame
tb_grid_search <- data.frame(vmin_cp = numeric(0),vmax_depth = numeric(0), vmin_split = numeric(0), vmin_bucket = numeric(0), ganancia_promedio = numeric(0))

for (i in 1:nrow(param_combinations)) {
  vmax_depth <- param_combinations$vmax_depth[i]
  vmin_split <- param_combinations$vmin_split[i]
  vmin_cp <- param_combinations$vmin_cp[i]
  vmin_bucket_values <- calculate_vmin_bucket(vmin_split)
  
  for (vmin_bucket in vmin_bucket_values) {
    param_basicos <- list(
      "cp" = -vmin_cp,
      "minsplit" = vmin_split,
      "minbucket" = vmin_bucket,
      "maxdepth" = vmax_depth
    )
    
    ganancia_promedio <- ArbolesMontecarlo(PARAM$semillas, param_basicos)
    
    # Add the result to the data frame
    tb_grid_search <- rbind(tb_grid_search, data.frame(vmin_cp,vmax_depth, vmin_split, vmin_bucket, ganancia_promedio))
    
    # Write to file every iteration of outer loop
    fwrite(
      tb_grid_search,
      file = archivo_salida,
      sep = "\t"
    )
    
    # Sleep for a couple of seconds
    Sys.sleep(2)
  }
}
