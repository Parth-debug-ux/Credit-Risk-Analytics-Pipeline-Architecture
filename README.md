# End-to-End Credit Risk Analytics & Pipeline Architecture

## 📌 Project Overview
This repository hosts a production-grade, end-to-end credit risk analytics pipeline designed to ingest, process, and model consumer loan portfolios. The architecture seamlessly orchestrates data flow across an enterprise tech stack—moving from raw data warehousing to predictive machine learning inference, culminating in an interactive executive policy simulator. 

The primary business objective is to quantify individual default probabilities, stratify portfolio risk, and provide decision-makers with a simulated environment to optimize credit approval thresholds against financial returns.

---

## 🛠️ Enterprise Architecture & Tech Stack
* **Data Warehousing & ETL:** SQL Server — Architecture built using staging schemas and highly optimized SQL scripts for structural data transformations.
* **Programming Language:** Python (v3.x)
* **Core Libraries:**
  * *Data Wrangling:* Pandas, NumPy
  * *Machine Learning:* XGBoost, Scikit-learn (Logistic Regression)
  * *Data Quality:* Scipy, Statsmodels
* **Business Intelligence & Analytics:** Power BI — Used for building the dimensional star schema model and the dynamic executive dashboard.

---

## 📈 Portfolio Impact & Key Metrics
* **Data Throughput:** Successfully processed and transformed a portfolio of **32,000+ historical loan records**.
* **Data Quality Engineering:** Formulated programmatic data imputation strategies to resolve severe data anomalies across **4,000+ records** (specifically targeting critical missing features: interest rates and employment lengths) while preserving underlying statistical distributions.
* **Risk Stratification:** Programmatically segmented the entire portfolio into **4 unique risk tiers** based on predictive scoring to drive tailored credit underwriting strategies.

---

## 🚀 Technical Deep Dive & Implementation

### 1. Database Infrastructure & Star Schema Modeling
* Designed a relational database layout within SQL Server incorporating staging environments to isolate raw data ingestion from analytical layers.
* Transformed the relational data into a high-performance **Star Schema** optimization structure in Power BI, mapping granular loan facts to business dimensions for fast, sub-second query performance.

### 2. Predictive Risk Modeling (PD Estimation)
* Developed and optimized binary classification models using **XGBoost** and **Logistic Regression** to estimate the continuous **Probability of Default (PD)** for each applicant.
* Evaluated models strictly against **ROC-AUC** metrics to ensure exceptional discriminatory power between default and non-default classes before portfolio tier stratification.

### 3. Executive Strategy Dashboard & Policy Simulator
* Engineered a dynamic executive-level dashboard tracking core risk KPIs including **Expected Financial Loss (EL)** and **Total Capital Exposure**.
* Built a custom **Policy Parameter Simulator** inside Power BI, enabling risk officers to simulate real-time shifts in credit approval thresholds and directly visualize the projected impact on overall portfolio returns and default rates.

---

## 📂 Project Repository Structure
```text
├── database/               # SQL scripts for database creation, staging, and ETL logic
├── notebooks/              # Jupyter notebooks containing EDA, data imputation tests, and ML modeling
├── src/                    # Production Python scripts for data pipelines and automated inference
│   ├── data_preprocessing.py
│   ├── model_training.py
│   └── inference_pipeline.py
├── dashboard/              # Power BI Dashboard template files (.pbix) and layout schemas
├── requirements.txt        # Environment dependencies
└── README.md               # Project documentation
