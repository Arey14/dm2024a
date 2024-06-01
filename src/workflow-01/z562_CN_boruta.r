# limpio la memoria
rm(list = ls(all.names = TRUE)) # remove all objects
gc(full = TRUE) # garbage collection

require("data.table")
require("yaml")
require("Rcpp")
require("Boruta")

# cargo la libreria
args <- commandArgs(trailingOnly=TRUE)
source(paste0(args[1], "/src/lib/action_lib.r"))

#------------------------------------------------------------------------------
# Función adaptada para usar Boruta
SeleccionarCaracteristicasConBoruta <- function(dataset, seed, p_value) {
  cat("Inicio SeleccionarCaracteristicasConBoruta()\n")
  set.seed(seed)
  
  # Crear la variable clase01
  dataset[, clase01 := 0L]
  dataset[get(envg$PARAM$dataset_metadata$clase) %in% envg$PARAM$train$clase01_valor1, clase01 := 1L]
  
  # Separar las características de la clase
  features <- setdiff(colnames(dataset), c(campitos, "clase01"))
  
  # Crear el modelo Boruta
  boruta_model <- Boruta(x = dataset[, features, with = FALSE], 
                         y = dataset$clase01, 
                         doTrace = 2, 
                         pValue = p_value)
  
  # Obtener las características importantes
  boruta_features <- getSelectedAttributes(boruta_model, withTentative = F)
  
  # Mantener solo las características seleccionadas
  selected_features <- c(boruta_features, campitos, "mes")
  
  cat("Características seleccionadas:\n")
  print(selected_features)
  
  # Eliminar las características no seleccionadas
  dataset <- dataset[, ..selected_features]
  
  cat("Fin SeleccionarCaracteristicasConBoruta()\n")
  
  return(dataset)
}

#------------------------------------------------------------------------------
# Aqui empieza el programa
cat("z562_CN_boruta.r  START\n")
action_inicializar()

envg$PARAM$Boruta$seed <- envg$PARAM$semilla
envg$PARAM$Boruta$p_value <- envg$PARAM$p_value

# Cargo el dataset donde voy a entrenar
envg$PARAM$dataset <- paste0("./", envg$PARAM$input, "/dataset.csv.gz")
envg$PARAM$dataset_metadata <- read_yaml(paste0("./", envg$PARAM$input, "/dataset_metadata.yml"))

cat("lectura del dataset\n")
action_verificar_archivo(envg$PARAM$dataset)
cat("Iniciando lectura del dataset\n")
dataset <- fread(envg$PARAM$dataset)
cat("Finalizada lectura del dataset\n")

GrabarOutput()

campitos <- c(envg$PARAM$dataset_metadata$primarykey,
              envg$PARAM$dataset_metadata$entity_id,
              envg$PARAM$dataset_metadata$periodo,
              envg$PARAM$dataset_metadata$clase)
campitos <- unique(campitos)

cat("ordenado del dataset\n")
setorderv(dataset, envg$PARAM$dataset_metadata$primarykey)

envg$OUTPUT$Boruta$ncol_antes <- ncol(dataset)
dataset <- SeleccionarCaracteristicasConBoruta(dataset, envg$PARAM$Boruta$seed, envg$PARAM$Boruta$p_value)
envg$OUTPUT$Boruta$ncol_despues <- ncol(dataset)
GrabarOutput()

cat("escritura del dataset\n")
cat("Iniciando grabado del dataset\n")
fwrite(dataset, file = "dataset.csv.gz", logical01 = TRUE, sep = ",")
cat("Finalizado grabado del dataset\n")

cat("escritura de metadata\n")
write_yaml(envg$PARAM$dataset_metadata, file = "dataset_metadata.yml")

tb_campos <- as.data.table(list(
  "pos" = 1:ncol(dataset),
  "campo" = names(sapply(dataset, class)),
  "tipo" = sapply(dataset, class),
  "nulos" = sapply(dataset, function(x) {
    sum(is.na(x))
  }),
  "ceros" = sapply(dataset, function(x) {
    sum(x == 0, na.rm = TRUE)
  })
))
fwrite(tb_campos, file = "dataset.campos.txt", sep = "\t")

cat("Fin del programa\n")

envg$OUTPUT$dataset$ncol <- ncol(dataset)
envg$OUTPUT$dataset$nrow <- nrow(dataset)

envg$OUTPUT$time$end <- format(Sys.time(), "%Y%m%d %H%M%S")
GrabarOutput()

action_finalizar(archivos = c("dataset.csv.gz", "dataset_metadata.yml"))
cat("z562_CN_boruta.r  END\n")
