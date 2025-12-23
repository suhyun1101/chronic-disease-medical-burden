library(readxl)
library(dplyr)
library(ggplot2)
library(survey)
library(tableone)


df <- read_excel(file.choose())
names(df)

ps_model <- glm(CD_total ~ SEX + MARR + EDU + DISA_YN + 
                  I_PHI1_YN + ECO1 + HS2_YN + HS1 + P1 + S3 + D1 + AGE + BMI + INCOME +
                  HEALTH_INS_2.0 + HEALTH_INS_3.0 + HEALTH_INS_4.0 + 
                  HEALTH_INS_5.0 + HEALTH_INS_6.0 + HEALTH_INS_8.0, 
                data = df, family = "binomial")
df$ps <- predict(ps_model, type = "response")

# IPTW 가중치 계산
df$weight <- ifelse(df$CD_total == 1, 1 / df$ps, 1 / (1 - df$ps))

# svydesign으로 가중치 적용된 데이터 생성
iptw_design <- svydesign(ids = ~1, data = df, weights = ~weight)

# 공변량 균형성 확인 (SMD 계산)
covariates <- c("SEX", "MARR", "EDU", "DISA_YN", 
                "I_PHI1_YN", "ECO1", "HS2_YN", "HS1", "P1", "S3", "D1", 
                "AGE", "BMI", "INCOME", "HEALTH_INS_2.0", "HEALTH_INS_3.0",
                "HEALTH_INS_4.0", "HEALTH_INS_5.0", "HEALTH_INS_6.0", "HEALTH_INS_8.0")
unadjusted_table <- CreateTableOne(vars = covariates, strata = "CD_total", data = df)
adjusted_table <- svyCreateTableOne(vars = covariates, strata = "CD_total", data = iptw_design)

# 결과 출력
print("Before weighting:")
print(unadjusted_table, smd = TRUE)
print("After weighting:")
print(adjusted_table, smd = TRUE)

#ate_model <- svyglm(overburden_yn ~ CD_total, design = iptw_design)

#summary(ate_model)

print("##### ATE Estimation using T-test #####")
ate_ttest_result <- svyttest(overburden_yn ~ CD_total, design = iptw_design)

# T-검정 결과 출력
print(ate_ttest_result)

# (전) 밀도
ggplot(df, aes(x = ps, linetype = factor(CD_total))) +
  geom_density() +
  labs(x = "Propensity score", y = "Density", linetype = "Treatment",
       title = "PS Overlap (Unweighted)") +
  theme_minimal()

# (후) 가중 밀도
ggplot(df, aes(x = ps, linetype = factor(CD_total), weight = weight)) +
  geom_density(adjust = 1.2) +
  labs(x = "Propensity score", y = "Weighted density", linetype = "Treatment",
       title = "PS Overlap (Weighted by IPTW)") +
  theme_minimal()

out_rate <- svyby(~overburden_yn, ~CD_total, iptw_design, svymean, vartype = "ci")
print(out_rate)

#신뢰구간 포함한 bar chart
ggplot(out_rate, aes(x = factor(CD_total), y = overburden_yn, fill = factor(CD_total))) +
  geom_col(width = 0.6) +
  geom_errorbar(aes(ymin = ci_l, ymax = ci_u), width = 0.2) +
  scale_y_continuous(labels = scales::percent_format(accuracy = 1)) +
  labs(x = "Chronic disease status", y = "Overburden rate (%)",
       title = "Outcome Rate by Chronic Disease (IPTW-weighted)") +
  theme_minimal()

library(cobalt)
bal.tab(CD_total ~ SEX + MARR + EDU + DISA_YN + I_PHI1_YN + 
          ECO1 + HS2_YN + HS1 + P1 + S3 + D1 + AGE + BMI + INCOME +
          HEALTH_INS_2.0 + HEALTH_INS_3.0 + HEALTH_INS_4.0 + 
          HEALTH_INS_5.0 + HEALTH_INS_6.0 + HEALTH_INS_8.0,
        data = df, weights = df$weight, method = "weighting")

love.plot(CD_total ~ SEX + MARR + EDU + DISA_YN + I_PHI1_YN + 
            ECO1 + HS2_YN + HS1 + P1 + S3 + D1 + AGE + BMI + INCOME +
            HEALTH_INS_2.0 + HEALTH_INS_3.0 + HEALTH_INS_4.0 + 
            HEALTH_INS_5.0 + HEALTH_INS_6.0 + HEALTH_INS_8.0,
          data = df, weights = df$weight,
          threshold = 0.1, abs = TRUE)
