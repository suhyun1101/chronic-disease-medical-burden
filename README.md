# Causal Impact of Chronic Disease on Medical Overburden

This repository presents an empirical analysis of the **causal impact of chronic disease
on medical overburden** among economically active adults, using observational health
panel data and modern causal inference methods.

Medical overburden is defined as excessive out-of-pocket (OOP) medical expenditure
relative to income, which can impose substantial financial distress even among working
populations.  
Rather than focusing on descriptive associations, this study aims to **identify the causal
effect** of chronic disease status on the probability of experiencing medical overburden.

---

## Research Question
> **How does having a chronic disease affect the likelihood of experiencing medical
overburden among the economically active population?**

---

## Data
- **Source**: Korean Health Panel (KHP), 2020
- **Study population**:
  - Economically active adults aged 20–61
  - Individuals with positive income
- **Treatment**:
  - Chronic disease indicator (binary)
- **Outcome**:
  - Medical overburden, defined as cases where out-of-pocket medical expenditure
    exceeds **10% of total income**

Due to privacy and licensing restrictions, **raw microdata are not included** in this
repository.  
Detailed variable definitions, sample construction, and preprocessing steps are
documented in `data/README.md`.

---

## Empirical Strategy and Methods
To address confounding and selection bias inherent in observational health data, the
following causal inference approaches are employed:

- **Inverse Probability of Treatment Weighting (IPTW)**  
  - Primary method for estimating the Average Treatment Effect (ATE)
  - Stabilized weights and covariate balance diagnostics are applied

- **Propensity Score Matching (PSM)**  
  - Used as a robustness check for IPTW estimates

- **Causal Random Forest / Causal Regression Estimation (CRE)**  
  - Applied to explore potential heterogeneous treatment effects (HTE)

Results from different methods are compared to assess robustness and methodological
consistency.

---

## Repository Structure
```text
chronic-disease-medical-burden/
├─ code/
│  ├─ preprocessing/   # Data cleaning and variable construction
│  ├─ analysis/        # IPTW, PSM, CRE analyses
│  └─ tables/          # Descriptive statistics (Table 1)
│
├─ data/
│  ├─ raw/             # Raw data (excluded from GitHub)
│  └─ README.md        # Data documentation
│
├─ reference/          # Related academic literature
├─ reports/            # Final research report and presentation slides
└─ README.md

```

---

## Reproducibility and Transparency
Although the original KHP data cannot be shared publicly, all analytical procedures,
model specifications, and variable constructions are explicitly documented to ensure
transparency and reproducibility for researchers with authorized data access.

---

## Outputs
- Descriptive statistics of the study sample (Table 1)
- Estimated causal effects using IPTW, PSM, and CRE
- Final research report and presentation materials (see `reports/`)

---

## Author
**SuHyun Ju**  
B.A. Mathematics, B.A. Statistics (Double Major)  
Research interests: Causal Inference, Health Economics, Data Science
