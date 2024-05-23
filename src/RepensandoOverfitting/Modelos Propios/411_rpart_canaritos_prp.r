# limpio la memoria
rm( list=ls() )  # remove all objects
gc()             # garbage collection

require("data.table")
require("rpart")
require("rpart.plot")

setwd("~/Desktop/ITBA/Mineria de Datos/dm2024a/src/RepensandoOverfitting/Modelos Propios" )  # establezco la carpeta donde voy a trabajar
# cargo el dataset
dataset <- fread( "~/Desktop/ITBA/Mineria de Datos/datasets/dataset_pequeno.csv")

dir.create("./exp/", showWarnings = FALSE)
dir.create("./exp/CN4110/", showWarnings = FALSE)
# Establezco el Working Directory DEL EXPERIMENTO
setwd("~/Desktop/ITBA/Mineria de Datos/dm2024a/src/RepensandoOverfitting/Modelos Propios/exp/CN4110/")

# uso esta semilla para los canaritos
set.seed(734471)


# agrego los siguientes canaritos
for( i in 1:200 ) dataset[ , paste0("canarito", i ) :=  runif( nrow(dataset)) ]


# Usted utilice sus mejores hiperparamatros
# yo utilizo los encontrados por Elizabeth Murano
 modelo  <- rpart(formula= "clase_ternaria ~ .",
               data= dataset[ foto_mes==202107,],
               model = TRUE,
               xval = 0,
               cp = -0.1,
               minsplit =  800,
               minbucket = 133,
               maxdepth = 6 )

pdf(file = "./arbol_canaritos.pdf", width=28, height=4)
prp(modelo, extra=101, digits=5, branch=1, type=4, varlen=0, faclen=0)
dev.off()

