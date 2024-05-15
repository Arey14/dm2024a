require("data.table")
require("rpart")
require("parallel")

PARAM <- list()
PARAM$semillas <- c(734471, 734473, 734477, 734479, 734497, 734537, 734543, 734549, 734557, 734567, 734627,734647,734653,734659, 734663, 734687, 734693, 734707, 734717, 734729)

# Precompute parameters
param_combinations <- expand.grid(
  vmax_depth = c(4, 6, 8, 10, 12, 14),
  vmin_split = c(1000, 800, 600, 400, 200, 100, 50, 20, 10),
  vmin_cp = c(0.001, 0.001, 0.1, 0.2, 0.3, 0.5)
)
param_combinations$vmin_bucket <- param_combinations$vmin_split / c(2, 3, 4, 5, 6)

# Load the dataset
dataset <- fread("../../../datasets/dataset_pequeno.csv")
dataset <- dataset[clase_ternaria != ""]

# Initialize result table outside the loop
tb_grid_search <- data.table(
  max_depth = integer(),
  min_split = integer(),
  ganancia_promedio = numeric()
)

# Define function to calculate average gain
calculate_average_gain <- function(semilla, param_basicos) {
  ganancia_promedio <- ArbolesMontecarlo(semilla, param_basicos)
  return(ganancia_promedio)
}

# Define the path for the output file
archivo_salida <- "./exp/HT2020/gridsearch.txt"

# Iterate over parameter combinations
for (i in 1:nrow(param_combinations)) {
  vmax_depth <- param_combinations$vmax_depth[i]
  vmin_split <- param_combinations$vmin_split[i]
  vmin_bucket <- param_combinations$vmin_bucket[i]
  vmin_cp <- param_combinations$vmin_cp[i]
  
  param_basicos <- list(
    "cp" = -vmin_cp,
    "minsplit" = vmin_split,
    "minbucket" = vmin_bucket,
    "maxdepth" = vmax_depth
  )
  
  ganancias <- mcmapply(
    calculate_average_gain,
    semillas = PARAM$semillas,
    MoreArgs = list(param_basicos),
    SIMPLIFY = FALSE,
    mc.cores = parallel::detectCores()
  )
  
  ganancia_promedio <- mean(unlist(ganancias))
  
  tb_grid_search <- rbind(
    tb_grid_search,
    data.table(
      max_depth = vmax_depth,
      min_split = vmin_split,
      ganancia_promedio = ganancia_promedio
    )
  )
  
  # Write results to disk every 10 iterations
  if (i %% 10 == 0) {
    fwrite(
      tb_grid_search,
      file = archivo_salida,
      sep = "\t",
      append = TRUE
    )
  }
}

# Write final results to disk
fwrite(
  tb_grid_search,
  file = archivo_salida,
  sep = "\t",
  append = TRUE
)
