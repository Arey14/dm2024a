library(data.table)
library(dplyr)

# Cargar Resultados Boruta
boruta01 <- readRDS('~/Desktop/boruta_result01.rds')
boruta05 <- readRDS('~/Desktop/boruta_result05.rds')
boruta10 <- readRDS('~/Desktop/boruta_result10.rds')
boruta25 <- readRDS('~/Desktop/boruta_result25.rds')
boruta50 <- readRDS('~/Desktop/boruta_result50.rds')

# Ver recuento de final decisions
table(boruta01$finalDecision)
table(boruta05$finalDecision)
table(boruta10$finalDecision)
table(boruta25$finalDecision)
table(boruta50$finalDecision)

# Extraigo columnas rejected
boruta01reject <- names(boruta01$finalDecision[boruta01$finalDecision == 'Rejected'])
boruta05reject <- names(boruta05$finalDecision[boruta05$finalDecision == 'Rejected'])
boruta10reject <- names(boruta10$finalDecision[boruta10$finalDecision == 'Rejected'])
boruta25reject <- names(boruta25$finalDecision[boruta25$finalDecision == 'Rejected'])
boruta50reject <- names(boruta50$finalDecision[boruta50$finalDecision == 'Rejected'])

# Remuevo la primera de la lista ya que es año mes y la necesito para el workflow
boruta01reject <- boruta01reject[2:length(boruta01reject)]
boruta05reject <- boruta05reject[2:length(boruta05reject)]
boruta10reject <- boruta10reject[2:length(boruta10reject)]
boruta25reject <- boruta25reject[2:length(boruta25reject)]
boruta50reject <- boruta50reject[2:length(boruta50reject)]

# Cargo dataset
dataset <- fread("~/Desktop/ITBA/Mineria de Datos/datasets/competencia_2024.csv.gz")

# Armo los nuevos datasets con las columnas eliminadas
mi_dataset_limpio01 <- dataset[, setdiff(names(dataset), boruta01reject), with=FALSE]
mi_dataset_limpio05 <- dataset[, setdiff(names(dataset), boruta05reject), with=FALSE]
mi_dataset_limpio10 <- dataset[, setdiff(names(dataset), boruta10reject), with=FALSE]
mi_dataset_limpio25 <- dataset[, setdiff(names(dataset), boruta25reject), with=FALSE]

# Exporto los nuevos datasets
fwrite(mi_dataset_limpio01, "~/Desktop/cleaned_dataset01.csv.gz")
fwrite(mi_dataset_limpio05, "~/Desktop/cleaned_dataset05.csv.gz")
fwrite(mi_dataset_limpio10, "~/Desktop/cleaned_dataset10.csv.gz")
fwrite(mi_dataset_limpio25, "~/Desktop/cleaned_dataset25.csv.gz")
