# Arbol elemental con libreria  rpart
# Debe tener instaladas las librerias  data.table  ,  rpart  y  rpart.plot

# cargo las librerias que necesito
require("data.table")
require("rpart")
require("rpart.plot")

filename = paste(gsub(":", "-", Sys.time()),"_file.csv",sep="")

# Aqui se debe poner la carpeta de la materia de SU computadora local
setwd("~/Desktop/ITBA/Mineria de Datos/dm2024a/src/rpart/Modelos Propios/") # Establezco el Working Directory

# cargo el dataset
dataset <- fread("~/Desktop/ITBA/Mineria de Datos/datasets/dataset_pequeno.csv")
dim(dataset)
dtrain <- dataset[foto_mes == 202107] # defino donde voy a entrenar
dapply <- dataset[foto_mes == 202109] # defino donde voy a aplicar el modelo

dtrain[ ,v_rank := frank(ccomisiones_otras)/.N]
dapply[ ,v_rank := frank(ccomisiones_otras)/.N]

# genero el modelo,  aqui se construye el arbol
# quiero predecir clase_ternaria a partir de el resto de las variables
modelo <- rpart(
        formula = "clase_ternaria ~ . - ccomisiones_otras ",
        data = dtrain, # los datos donde voy a entrenar
        xval = 10,
        cp = -0.297554091501874, # esto significa no limitar la complejidad de los splits
        minsplit = 8000, # minima cantidad de registros para que se haga el split
        minbucket = 1596, # tamaño minimo de una hoja
        maxdepth = 20
) # profundidad maxima del arbol

# grafico el arbol
prp(modelo,
        extra = 101, digits = -5,
        branch = 1, type = 4, varlen = 0, faclen = 0
)


# aplico el modelo a los datos nuevos
prediccion <- predict(
        object = modelo,
        newdata = dapply,
        type = "prob"
)

# prediccion es una matriz con TRES columnas,
# llamadas "BAJA+1", "BAJA+2"  y "CONTINUA"
# cada columna es el vector de probabilidades

# agrego a dapply una columna nueva que es la probabilidad de BAJA+2
dapply[, prob_baja2 := prediccion[, "BAJA+2"]]

# solo le envio estimulo a los registros
#  con probabilidad de BAJA+2 mayor  a  1/40
dapply[, Predicted := as.numeric(prob_baja2 > 1 / 40)]

# genero el archivo para Kaggle
# primero creo la carpeta donde va el experimento
dir.create("./exp/")
dir.create("./exp/KA2001")

# solo los campos para Kaggle
fwrite(dapply[, list(numero_de_cliente, Predicted)],
        file = filename,
        sep = ","
)
