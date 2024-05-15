# Arbol elemental con libreria  rpart
# Debe tener instaladas las librerias  data.table  ,  rpart  y  rpart.plot

# cargo las librerias que necesito
require("data.table")
require("rpart")
require("rpart.plot")

filename = paste(gsub(":", "-", Sys.time()),"_file.csv",sep="")

# Aqui se debe poner la carpeta de la materia de SU computadora local
#setwd("Desktop/ITBA/Mineria de Datos/dm2024a/") # Establezco el Working Directory

# cargo el dataset
dataset <- fread("../../../dm2024a/src/rpart/exp/HT2020/gridsearch1.csv")

dtrain <- dataset # defino donde voy a entrenar

# genero el modelo,  aqui se construye el arbol
# quiero predecir clase_ternaria a partir de el resto de las variables
modelo <- rpart(
        formula = "ganancia_promedio ~ .",
        data = dtrain, # los datos donde voy a entrenar
        xval = 10,
        cp = -0.1, # esto significa no limitar la complejidad de los splits
        minsplit = 100, # minima cantidad de registros para que se haga el split
        minbucket = 50, # tamaño minimo de una hoja
        maxdepth = 6
) # profundidad maxima del arbol


# grafico el arbol
prp(modelo,
        extra = 101, digits = -5,
        branch = 1, type = 4, varlen = 0, faclen = 0
)
