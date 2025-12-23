# Causal Impact of Chronic Disease on Medical Burden

This project investigates the causal effect of chronic disease on medical overburden
among economically active adults using causal inference methods.

Medical overburden is defined as excessive out-of-pocket (OOP) medical expenditure
relative to income, which can lead to financial distress even among working populations.
This study aims to estimate the causal impact of chronic disease status on the probability
of experiencing medical overburden, beyond simple correlations.

---

## Research Question
How does having a chronic disease affect the likelihood of experiencing medical
overburden among the economically active population?

---

## Data
- **Source**: Korean Health Panel (KHP), 2020
- **Sample**:
  - Economically active adults (age 20–61)
  - Positive income
- **Outcome**:
  - Medical overburden, defined as cases where out-of-pocket medical
    expenditure exceeds **10% of total income**

- **Treatment**:
  - Chronic disease indicator (binary)

Raw data are not included in this repository due to privacy and licensing restrictions.
See `data/README.md` for detailed data documentation.

---

## Methods
To address confounding and selection bias, this study employs multiple causal inference
approaches:

- **Inverse Probability of Treatment Weighting (IPTW)**  
  - Main method for estimating the Average Treatment Effect (ATE)
- **Propensity Score Matching (PSM)**  
  - Used as a robustness check for IPTW results
- **Causal Random Forest / Causal Regression Estimation (CRE)**  
  - Applied to explore heterogeneous treatment effects (HTE)

---

## Repository Structure
```text
chronic-disease-medical-burden/
 ├─ code/        # Analysis scripts (IPTW, PSM, CRE, descriptive tables)
 ├─ data/        # Data documentation (no raw data)
 ├─ reference/   # Related literature
 └─ reports/     # Final report and presentation
