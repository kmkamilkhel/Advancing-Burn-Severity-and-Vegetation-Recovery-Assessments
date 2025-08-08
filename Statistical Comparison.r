# Load required libraries
library(tidyverse)
library(effsize)    # For Cliff’s Delta
library(effsize2)   # Alternative Cliff's Delta (if preferred)
library(rstatix)    # For Cohen's d
library(ggpubr)     # For boxplot visualisation

# Load pre- and post-fire NDVI/kNDVI rasters
ndvi_pre  <- rast("outputs/NDVI_Jan2024.tif")
ndvi_post <- rast("outputs/NDVI_Oct2024.tif")
kndvi_pre  <- rast("outputs/kNDVI_Jan2024.tif")
kndvi_post <- rast("outputs/kNDVI_Oct2024.tif")

# Load classified burn severity map (output from RF)
burn_severity <- rast("outputs/BurnSeverity_RF_Map.tif")

# Ensure same extent, resolution, and CRS
stacked <- c(ndvi_pre, ndvi_post, kndvi_pre, kndvi_post, burn_severity)
names(stacked) <- c("NDVI_Pre", "NDVI_Post", "kNDVI_Pre", "kNDVI_Post", "Severity")

# Convert to dataframe
df <- as.data.frame(stacked, xy = FALSE, na.rm = TRUE)
df$Severity <- as.factor(df$Severity)

# Compute differenced NDVI and kNDVI
df <- df %>%
  mutate(dNDVI = NDVI_Post - NDVI_Pre,
         dkNDVI = kNDVI_Post - kNDVI_Pre)

# --- Wilcoxon Rank-Sum Test ---
wilcox_ndvi <- wilcox.test(df$NDVI_Pre, df$NDVI_Post, paired = FALSE)
wilcox_kndvi <- wilcox.test(df$kNDVI_Pre, df$kNDVI_Post, paired = FALSE)

print(wilcox_ndvi)
print(wilcox_kndvi)

# --- Cohen's d ---
cohen_ndvi <- cohens_d(df, x = "NDVI_Pre", y = "NDVI_Post", paired = FALSE)
cohen_kndvi <- cohens_d(df, x = "kNDVI_Pre", y = "kNDVI_Post", paired = FALSE)

print(cohen_ndvi)
print(cohen_kndvi)

# --- Cliff’s Delta ---
cliff_ndvi <- cliff.delta(df$NDVI_Pre, df$NDVI_Post)
cliff_kndvi <- cliff.delta(df$kNDVI_Pre, df$kNDVI_Post)

print(cliff_ndvi)
print(cliff_kndvi)

# --- Visualisation: Boxplots by Severity Class ---

# Melt data for plotting
df_long <- df %>%
  pivot_longer(cols = c(NDVI_Pre, NDVI_Post, kNDVI_Pre, kNDVI_Post),
               names_to = "Index", values_to = "Value")

# Label severity
severity_labels <- c("1" = "Low", "2" = "Mod-Low", "3" = "Mod-High", "4" = "High")
df_long$Severity <- factor(df_long$Severity, levels = c("1", "2", "3", "4"),
                           labels = severity_labels)

# Plot NDVI
ggplot(df_long %>% filter(Index %in% c("NDVI_Pre", "NDVI_Post")),
       aes(x = Severity, y = Value, fill = Index)) +
  geom_boxplot() +
  scale_fill_manual(values = c("forestgreen", "orange")) +
  labs(title = "NDVI across Burn Severity Classes (Pre vs Post)",
       x = "Burn Severity", y = "NDVI") +
  theme_minimal()

# Plot kNDVI
ggplot(df_long %>% filter(Index %in% c("kNDVI_Pre", "kNDVI_Post")),
       aes(x = Severity, y = Value, fill = Index)) +
  geom_boxplot() +
  scale_fill_manual(values = c("steelblue", "darkred")) +
  labs(title = "kNDVI across Burn Severity Classes (Pre vs Post)",
       x = "Burn Severity", y = "kNDVI") +
  theme_minimal()
