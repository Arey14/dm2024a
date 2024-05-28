# Este script almacena definitivamente sus cinco semillas
# en el bucket, de forma que NO deba cargarlas en cada script

require( "data.table" )

# reemplazar aqui por SUS semillas 
mis_semillas <- c(734471, 734473, 734477, 734479, 734497, 734537, 734543, 734549, 734557, 734567, 734627,734647,734653,734659, 734663, 734687, 734693, 734707, 734717, 734729)

tabla_semillas <- as.data.table(list( semilla = mis_semillas ))

fwrite( tabla_semillas,
    file = "~/Desktop/ITBA/Mineria de Datos/dm2024a/src/workflow-01/Modelo Propios/buckets/b1/dataset/mis_semillas.txt",
    sep = "\t"
)
