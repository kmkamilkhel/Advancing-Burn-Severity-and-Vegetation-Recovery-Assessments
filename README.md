# Burn Severity and Vegetation Recovery Assessment – Yajiang Fire 2024

This repository contains the code and documentation for the analysis conducted in the study titled:

**"Advancing Burn Severity and Vegetation Recovery Assessments Using Remote Sensing and Machine Learning Approaches"**

The study focuses on the March 2024 forest fire in Yajiang County, Sichuan, China, using Sentinel-2 Level-2A imagery and a suite of spectral indices and machine learning techniques.

---

## 📁 Repository Structure

├── data/
│ └── final_indices/ # Raster layers exported from GEE (pre/post-fire indices)
├── outputs/
│ └── BurnSeverity_RF_Map.tif # Final burn severity classification map
│ └── NDVI_Jan2024.tif
│ └── NDVI_Oct2024.tif
│ └── kNDVI_Jan2024.tif
│ └── kNDVI_Oct2024.tif
├── scripts/
│ ├── 01_rf_model.R # Random Forest model training and evaluation
│ ├── 02_rf_prediction.R # Apply RF model to full area and map severity
│ ├── 03_stat_analysis.R # Statistical comparison: NDVI, kNDVI (Wilcoxon, Cohen's d, Cliff's Δ)
│ ├── 04_veg_class_dynamics.R# Vegetation class reclassification and area dynamics
├── README.md


---

## 🔍 Objective

To assess fire-induced changes in vegetation and quantify burn severity using:
- Pre- and post-fire Sentinel-2 indices
- Supervised Random Forest classification
- Statistical validation of vegetation change using NDVI and kNDVI
- Vegetation class dynamics across burn severity levels

---

## 📦 Methods Overview

### 1. Data Preprocessing (Google Earth Engine)
- Sentinel-2 L2A imagery filtered for **January** and **October 2024**
- Cloud and shadow masked using the Scene Classification Layer (SCL)
- Computation of NDVI and kNDVI (using RBF kernel)
- Exported as cloud-free composites at 10m resolution

### 2. Random Forest Classification (`scripts/01_rf_model.R`)
- Predictor indices: NDVI_Pre, MSAVI_Pre, CSI_Pre, CSI_Post, MIRBI_Post, dVARI
- Multicollinearity filtering via VIF and tolerance
- Class balancing, grid search tuning, 10-fold cross-validation
- Evaluation: confusion matrix, AUC, precision, recall, F1-score

### 3. Spatial Prediction (`scripts/02_rf_prediction.R`)
- Trained model applied to stacked predictor rasters
- Output: GeoTIFF map of burn severity classes (Low, Mod-Low, Mod-High, High)

### 4. Statistical Validation (`scripts/03_stat_analysis.R`)
- Wilcoxon Rank-Sum Test for pre- vs post-fire NDVI and kNDVI
- Effect size via Cohen’s d and Cliff’s Delta
- Boxplots for severity-wise comparison

### 5. Vegetation Class Dynamics (`scripts/04_veg_class_dynamics.R`)
- NDVI reclassified into 4 vegetation classes: Bare, Sparse, Moderate, Dense
- Area statistics computed pre- and post-fire per severity class
- ΔA (absolute), % Change, and Proportional change analysis
- Bar and line plots illustrating vegetation transitions

---

## 🧪 Software Requirements

- R 4.2 or higher
- R packages:
  - `terra`, `tidyverse`, `randomForest`, `caret`, `pROC`, `iml`
  - `effsize`, `rstatix`, `exactextractr`, `ggpubr`

---

## 📈 Output Highlights

- 🔥 **Burn Severity Map**: Based on pre-, post-, and differenced spectral indices
- 🌱 **NDVI & kNDVI Change Analysis**: Statistical tests and effect size interpretation
- 🌿 **Vegetation Class Transition**: Quantitative and visual metrics of fire impact

---

## 📄 Citation

If you use or adapt this code or methodology, please cite the study:

> *Mehmood, K., et al. (2024). Advancing Burn Severity and Vegetation Recovery Assessments Using Remote Sensing and Machine Learning Approaches. [Journal Name, Volume(Issue), Page Numbers]*

---

## 🔒 License

This repository is shared under the **MIT License**. See `LICENSE` file for details.

---

## 📬 Contact

For questions or collaboration inquiries, please contact:

**Kaleem Mehmood**  
Lecturer, Forest Sciences  
University of Swat, Pakistan  
*Email: kaleemmehmood73@gmail.com


