library(terra)
library(randomForest)
library(tidyverse)

# Step 1: Load raster stack of predictor layers
predictor_stack <- rast(list.files("data/final_indices/", pattern = ".tif$", full.names = TRUE))
names(predictor_stack) <- c("NDVI_Pre", "MSAVI_Pre", "CSI_Pre", 
                            "CSI_Post", "MIRBI_Post", "dVARI")  # match model

# Step 2: Convert raster to data frame for prediction
df_pred <- as.data.frame(predictor_stack, xy = TRUE, na.rm = FALSE)

# Step 3: Predict class for each pixel using trained RF model
# Remove NA rows to prevent prediction errors
na_mask <- complete.cases(df_pred[, -c(1, 2)])
df_pred_complete <- df_pred[na_mask, ]

# Apply RF prediction
predicted_classes <- predict(rf_model, newdata = df_pred_complete[, -c(1, 2)])

# Step 4: Insert predictions back into full grid
full_pred <- rep(NA, nrow(df_pred))
full_pred[na_mask] <- as.numeric(predicted_classes)

# Step 5: Create output raster of predicted burn severity classes
df_pred$Burn_Severity <- full_pred
burn_severity_raster <- rast(df_pred[, c("x", "y", "Burn_Severity")], type = "xyz")
crs(burn_severity_raster) <- crs(predictor_stack)

# Step 6: Export the raster
writeRaster(burn_severity_raster, "outputs/BurnSeverity_RF_Map.tif",
            overwrite = TRUE, wopt = list(gdal = c("COMPRESS=DEFLATE")))

# Optional: Visualise
plot(burn_severity_raster, col = c("green", "yellow", "orange", "red"),
     legend = TRUE, main = "Burn Severity Classification (RF)")
