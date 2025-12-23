library(readxl)
library(writexl)
library(dplyr)
library(CRE)

#uploading excel file
df <- read_excel(file.choose())

y <- df$overburden_yn
z <- df$CD_total
x <- df[, c("INCOME", "SEX", "MARR", "EDU","DISA_YN", "HEALTH_INS_2.0",	"HEALTH_INS_3.0",	"HEALTH_INS_4.0",	
            "HEALTH_INS_5.0", "HEALTH_INS_6.0", "HEALTH_INS_8.0", "I_PHI1_YN", "ECO1", "HS2_YN", "HS1", "P1", 
            "S3", "D1", "AGE", "BMI")]

# 3.2. method_params
method_params <- list(
  ratio_dis = 0.7,
  ite_method = "cf",
  learner_ps = "SL.glmnet",
  learner_y  = "SL.xgboost"
)

# 3.3. hyper_params (복합 규칙 생성을 위해 조정)
hyper_params <- list(
  intervention_vars = c("SEX", "MARR", "EDU", "DISA_YN", "I_PHI1_YN", "HS2_YN", "HS1", "P1", "S3", "D1", "AGE", "BMI", 
                        "HEALTH_INS_2.0",	"HEALTH_INS_3.0",	"HEALTH_INS_4.0",	"HEALTH_INS_5.0", "HEALTH_INS_6.0", "HEALTH_INS_8.0"),
  ntrees = 10000,
  node_size = 5, 
  max_rules = 10000,
  max_depth = 5, 
  t_decay = 0.01,
  t_ext = 0.01,
  t_corr = 1,
  stability_selection = "no",
  B = 200, 
  subsample = 0.5,
  offset = NULL,
  cutoff = 0.7, 
  pfer = 1
)

# CRE 실행
set.seed(238)
cre_results <- cre(y, z, x, method_params, hyper_params)

# Result
# 결과 요약
summary(cre_results)

# 시각화
plot(cre_results)
