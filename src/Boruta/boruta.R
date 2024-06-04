library(data.table)
library(Boruta)
library(caret)

# Cargar tus datos
#data <- fread(file="~/buckets/b1/datasets/competencia_2024.csv.gz")
data <- fread(file="~/datasets/archivo.csv")

set.seed(734471)
indices <- createDataPartition(data$clase_ternaria, p = 0.9, list = FALSE)
#entrenamiento <- data[indices, ]
prueba <- data[-indices, ]

#años = c(202101, 202102, 202103)

#data2 = data[data$foto_mes %in% c(202101, 202102, 202103),]

#data2$clase_ternaria = ifelse(data2$clase_ternaria == "CONTINUA",0,1)

#summary(data2)


# Función para imputar con la mediana
impute_median <- function(x) {
  x[is.na(x)] <- median(x, na.rm = TRUE)
  return(x)
}

# Aplicar imputaciones
#data_imputed_median <- data.frame(lapply(data2, impute_median))


# Imputar los valores faltantes
#imputed_data <- missForest(data2,ntree = 20)

# Extraer el dataset imputado
#data_imputed <- imputed_data$ximp

# Visualizar los valores nulos
#missmap(data2)

# Imputar los valores nulos
#amelia_fit <- amelia(data2, m = 1, idvars = NULL)

# Seleccionar un dataset imputado
#imputed_data <- amelia_fit$imputations[[1]]

#fwrite(data_imputed_median, "~/datasets/archivo.csv")

boruta01 = Boruta(x = prueba,y = prueba$clase_ternaria, maxRuns = 50,pValue = 0.01)
saveRDS(boruta01, file = "~/datasets/boruta_result01.rds")
boruta05 = Boruta(x = prueba,y = prueba$clase_ternaria, maxRuns = 50,pValue = 0.05)
saveRDS(boruta05, file = "~/datasets/boruta_result05.rds")
boruta10 = Boruta(x = prueba,y = prueba$clase_ternaria, maxRuns = 50,pValue = 0.1)
saveRDS(boruta10, file = "~/datasets/boruta_result10.rds")
boruta25 = Boruta(x = prueba,y = prueba$clase_ternaria, maxRuns = 50,pValue = 0.25)
saveRDS(boruta25, file = "~/datasets/boruta_result25.rds")
boruta50 = Boruta(x = prueba,y = prueba$clase_ternaria, maxRuns = 50,pValue = 0.5)
saveRDS(boruta50, file = "~/datasets/boruta_result50.rds")
