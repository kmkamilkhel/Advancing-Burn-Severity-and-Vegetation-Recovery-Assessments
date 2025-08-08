# Load required packages
library(terra)
library(tidyverse)
library(caret)
library(randomForest)
library(car)           # for VIF
library(pROC)          # for AUC
library(iml)           # for SHAP values

# Step 1: Load the raster stack (already preprocessed and exported from GEE)
# Assume all rasters (predictors + severity class) are in a single folder
rasters <- list.files("data/final_indices/", pattern = ".tif$", full.names = TRUE)
r_stack <- rast(rasters)
names(r_stack) <- c("NDVI_Pre", "MSAVI_Pre", "CSI_Pre",
                    "CSI_Post", "MIRBI_Post", "dVARI", "SeverityClass")

# Convert to data frame and remove NAs
df <- as.data.frame(r_stack, xy = TRUE, na.rm = TRUE)
df$SeverityClass <- as.factor(df$SeverityClass)

# Step 2: Check multicollinearity
vif_result <- vif(lm(as.numeric(SeverityClass) ~ ., data = df[,-c(1,2)]))
vif_result <- sort(vif_result, decreasing = TRUE)
print(vif_result)

# Remove predictors with VIF > 10 (if any)
selected_vars <- names(vif_result[vif_result < 10])
df_rf <- df[, c(selected_vars, "SeverityClass")]

# Step 3: Equal random sampling for class balance
set.seed(123)
min_n <- min(table(df_rf$SeverityClass))
df_balanced <- df_rf %>%
  group_by(SeverityClass) %>%
  sample_n(min_n) %>%
  ungroup()

# Step 4: Train-test split (70/30)
set.seed(123)
trainIndex <- createDataPartition(df_balanced$SeverityClass, p = 0.7, list = FALSE)
trainData <- df_balanced[trainIndex, ]
testData  <- df_balanced[-trainIndex, ]

# Step 5: Grid search tuning for RF
control <- trainControl(method = "cv", number = 10)
tuneGrid <- expand.grid(mtry = c(2, 3, 4))

set.seed(123)
rf_model <- train(SeverityClass ~ ., data = trainData,
                  method = "rf",
                  tuneGrid = tuneGrid,
                  trControl = control,
                  ntree = 500,
                  importance = TRUE)

# Step 6: Prediction and evaluation
pred <- predict(rf_model, newdata = testData)
conf_mat <- confusionMatrix(pred, testData$SeverityClass)
print(conf_mat)

# Calculate AUC for each class
probs <- predict(rf_model, newdata = testData, type = "prob")
multiclass.roc(testData$SeverityClass, probs)

# Step 7: Feature importance
importance_df <- as.data.frame(varImp(rf_model)$importance)
print(importance_df)

# Step 8: SHAP analysis using iml
X <- trainData %>% select(-SeverityClass)
y <- trainData$SeverityClass
predictor <- Predictor$new(rf_model, data = X, y = y, type = "prob")

shap <- Shapley$new(predictor, x.interest = X[1, ])
plot(shap)

# Global variable importance via SHAP
imp <- FeatureImp$new(predictor, loss = "ce")
plot(imp)
