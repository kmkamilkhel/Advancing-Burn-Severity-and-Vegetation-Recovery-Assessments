# Load required libraries
library(terra)
library(tidyverse)
library(exactextractr)  # Fast zonal stats
library(dplyr)

# Load rasters
ndvi_pre <- rast("outputs/NDVI_Jan2024.tif")
ndvi_post <- rast("outputs/NDVI_Oct2024.tif")
burn_severity <- rast("outputs/BurnSeverity_RF_Map.tif")
names(burn_severity) <- "Severity"

# Step 1: Define NDVI thresholds for vegetation classes
# Thresholds: < 0.1 = bare/non-veg, 0.1–0.3 = sparse, 0.3–0.5 = moderate, >0.5 = dense
reclass_matrix <- matrix(c(
  -Inf,  0.1,   1,  # Bare/Non-vegetated
   0.1,  0.3,   2,  # Sparse vegetation
   0.3,  0.5,   3,  # Moderate vegetation
   0.5,  Inf,   4   # Dense vegetation
), ncol = 3, byrow = TRUE)

# Reclassify NDVI rasters
ndvi_pre_class  <- classify(ndvi_pre, rcl = reclass_matrix)
ndvi_post_class <- classify(ndvi_post, rcl = reclass_matrix)

names(ndvi_pre_class) <- "NDVI_Pre_Class"
names(ndvi_post_class) <- "NDVI_Post_Class"

# Step 2: Stack with burn severity
stacked <- c(ndvi_pre_class, ndvi_post_class, burn_severity)

# Step 3: Convert to dataframe
df <- as.data.frame(stacked, xy = FALSE, na.rm = TRUE)
df <- df %>%
  rename(PreClass = NDVI_Pre_Class, PostClass = NDVI_Post_Class) %>%
  mutate(Severity = factor(Severity, levels = 1:4,
                           labels = c("Low", "Mod-Low", "Mod-High", "High")),
         PreClass = factor(PreClass, labels = c("Bare", "Sparse", "Moderate", "Dense")),
         PostClass = factor(PostClass, labels = c("Bare", "Sparse", "Moderate", "Dense")))

# Step 4: Calculate Area Metrics (per Severity × Vegetation class)
cell_area_ha <- res(ndvi_pre)[1] * res(ndvi_pre)[2] / 10000  # ha per cell (10x10m = 0.01 ha)

# Pre-fire area
area_pre <- df %>%
  group_by(Severity, PreClass) %>%
  summarise(N = n(), .groups = "drop") %>%
  mutate(Period = "Pre", Area_ha = N * cell_area_ha)

# Post-fire area
area_post <- df %>%
  group_by(Severity, PostClass) %>%
  summarise(N = n(), .groups = "drop") %>%
  mutate(Period = "Post", Area_ha = N * cell_area_ha)

# Combine
colnames(area_post)[2] <- "Class"
colnames(area_pre)[2] <- "Class"
area_all <- bind_rows(area_pre, area_post)

# Step 5: Calculate ΔA, % Change, and Proportion Change
area_wide <- pivot_wider(area_all, names_from = Period, values_from = Area_ha)
area_wide <- area_wide %>%
  mutate(Delta_Area = Post - Pre,
         Percent_Change = (Delta_Area / Pre) * 100,
         Pre = replace_na(Pre, 0), Post = replace_na(Post, 0))

# Step 6: Visualisation
ggplot(area_all, aes(x = Class, y = Area_ha, fill = Period)) +
  geom_bar(stat = "identity", position = "dodge") +
  facet_wrap(~Severity) +
  labs(title = "Vegetation Class Area (Pre vs Post) by Burn Severity",
       x = "Vegetation Class", y = "Area (ha)") +
  scale_fill_manual(values = c("darkgreen", "orange")) +
  theme_minimal()

# Line plot to show shift
area_shift <- area_all %>%
  group_by(Severity, Class, Period) %>%
  summarise(Area = sum(Area_ha), .groups = "drop")

ggplot(area_shift, aes(x = Period, y = Area, group = Class, color = Class)) +
  geom_line(size = 1.2) +
  geom_point(size = 2) +
  facet_wrap(~Severity) +
  labs(title = "Vegetation Class Shifts Across Fire Severity Levels",
       x = "Time Period", y = "Area (ha)") +
  theme_minimal()
