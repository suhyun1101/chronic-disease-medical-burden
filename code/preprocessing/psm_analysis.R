# 1. 라이브러리 임포트 및 데이터 불러오기
library(MatchIt)
library(readxl)
library(dplyr)
library(ggplot2)
library(gridExtra)

# 데이터 로딩 (실행 시 파일 선택)
ecls <- read_excel(file.choose())

# 2. 변수 타입 변환 및 전처리 (변수 이름에서 특수문자 제거)
# R에서 다루기 편하도록 변수 이름의 '.'을 '_'로 변경합니다.
names(ecls) <- gsub("\\.0$", "", names(ecls))

cat_vars <- c("SEX", "MARR", "EDU", "DISA_YN", "I_PHI1_YN", "ECO1",
              "HS2_YN", "HS1", "P1", "S3", "D1",
              "HEALTH_INS_8", "HEALTH_INS_2", "HEALTH_INS_3",
              "HEALTH_INS_4", "HEALTH_INS_5", "HEALTH_INS_6")
cont_vars <- c("AGE", "BMI", "INCOME")

ecls <- ecls %>%
  mutate(across(all_of(cat_vars), as.factor)) %>%
  mutate(
    overburden_yn = as.factor(overburden_yn),
    CD_total = as.factor(CD_total)
  )

# 3. 분석에 사용할 공변량 목록 정의
all_covs <- c(
  "SEX", "MARR", "EDU", "DISA_YN", "I_PHI1_YN", "ECO1", "HS2_YN",
  "HS1", "P1", "S3", "D1", "AGE", "BMI", "INCOME",
  "HEALTH_INS_8","HEALTH_INS_2", "HEALTH_INS_3", "HEALTH_INS_4",
  "HEALTH_INS_5", "HEALTH_INS_6"
)

# 4. 성향 점수(PS) 모델 생성 및 계산 (한 번만 실행)
ps_formula <- as.formula(
  paste("CD_total ~", paste(all_covs, collapse = " + "))
)

m_ps <- glm(ps_formula, family = binomial(), data = ecls)

# 데이터프레임에 성향 점수 추가
ecls$pr_score <- predict(m_ps, type = "response")

# 4.5. 성향 점수 분포 시각화

# 1.
prs_df <- data.frame(
  pr_score = ecls$pr_score,
  CD_total_numeric = as.numeric(ecls$CD_total) - 1,
  CD_total_factor = ecls$CD_total                  
)

# 2. 첫 번째 그래프: 요청하신 `labs`를 사용한 분리된 히스토그램
labs <- paste("Actual type", c("CD_yes", "CD_no"))
prs_df %>%
  mutate(CD_total_labeled = ifelse(CD_total_numeric == 1, labs[1], labs[2])) %>%
  ggplot(aes(x = pr_score)) + 
  geom_histogram(color = "white", fill="#565656") +
  facet_wrap(~CD_total_labeled) + 
  labs(
    x = "probability of having CD",
    y = "count"
  ) +
  theme_bw()


# 3. 두 번째 그래프: 겹쳐진 밀도 그림
ggplot(prs_df, aes(x = pr_score, fill = CD_total_factor)) +
  geom_density(alpha = 0.7) +
  labs(
    title = "Overlapping Propensity Score Density Plots",
    x = "Propensity Score",
    y = "Density",
    fill = "Group" # 범례 제목을 'Group'으로 설정
  ) +
  theme_bw()

# 5. 공통 지원 영역(Common Support) 확인 및 Trimming
# 그룹별 성향 점수 최소/최대값 계산
common_support <- ecls %>%
  group_by(CD_total) %>%
  summarise(
    min_ps = min(pr_score),
    max_ps = max(pr_score)
  )

# 공통 지원 영역 계산
min_cs <- max(common_support$min_ps)
max_cs <- min(common_support$max_ps)
cat("공통 지원 영역: [", min_cs, ", ", max_cs, "]\n")

# 공통 지원 영역에 해당하는 데이터만 추출 (Trimming)
ecls_trimmed <- ecls %>%
  filter(pr_score >= min_cs & pr_score <= max_cs)

cat("Trimming 전 데이터 행 수:", nrow(ecls), "\n")
cat("Trimming 후 데이터 행 수:", nrow(ecls_trimmed), "\n")


# 6. (가장 중요) Trimming된 데이터에 맞춰 포뮬러 수정
# ecls_trimmed 데이터에서 값이 하나뿐인 변수 찾기
vars_to_remove <- all_covs[sapply(ecls_trimmed[all_covs], function(x) length(unique(x)) < 2)]

if (length(vars_to_remove) > 0) {
  cat("Trimming 후 다음 변수가 제외됩니다 (값이 1개뿐임):", paste(vars_to_remove, collapse = ", "), "\n")
  # 해당 변수들을 공변량 목록에서 제거
  all_covs_trimmed <- all_covs[!all_covs %in% vars_to_remove]
} else {
  all_covs_trimmed <- all_covs
}

# 최종 매칭에 사용할 포뮬러 생성
match_formula <- as.formula(
  paste("CD_total ~", paste(all_covs_trimmed, collapse = " + "))
)


# 7. 매칭 알고리즘 실행
mod_match <- matchit(match_formula,method = "nearest",caliper = 0.1,data = ecls_trimmed)

# 8. 매칭 결과 요약 및 시각화
summary(mod_match, standardize = TRUE)
plot(mod_match, type = "density", interactive = FALSE) # interactive=FALSE 옵션 추가

# 9. 매칭된 데이터 추출
dta_m <- match.data(mod_match)
cat("매칭 후 데이터 행 수:", nrow(dta_m), "\n")

# 9.5. (추가) 매칭 전후 성향점수 분포 비교 시각화

# 1. '매칭 전' 데이터 준비 (ecls_trimmed 사용)
before_matching_df <- ecls_trimmed %>%
  select(pr_score, CD_total) %>%
  mutate(
    weights = 1,  # 매칭 전에는 모든 데이터의 가중치가 1
    status = "Before Matching"
  )

# 2. '매칭 후' 데이터 준비 (dta_m 사용)
# 매칭 후 데이터에서 성향점수는 'distance' 변수입니다.
after_matching_df <- dta_m %>%
  select(distance, CD_total, weights) %>%
  rename(pr_score = distance) %>% # 이름 통일
  mutate(status = "After Matching")

# 3. 두 데이터프레임 결합
combined_df <- bind_rows(before_matching_df, after_matching_df) %>%
  mutate(status = factor(status, levels = c("Before Matching", "After Matching")))

# 4. 겹쳐진 밀도 그림으로 시각화 (매칭 전/후 패널 분리)
ggplot(combined_df, aes(x = pr_score, fill = CD_total)) +
  geom_density(aes(weight = weights), alpha = 0.7) +
  facet_wrap(~ status, ncol = 1) +
  labs(
    title = "Propensity Score Distribution Before and After Matching",
    x = "Propensity Score",
    y = "Density",
    fill = "Group"
  ) +
  theme_bw()

# 10. 시각적 공변량 균형 검사 (변수 이름 수정)
fn_bal <- function(dta, variable) {
  
  # 기본 플롯 생성 (y축 변수는 numeric으로 변환)
  p <- ggplot(dta, aes(x = distance, y = as.numeric(!!sym(variable)), color = CD_total)) +
    geom_point(alpha = 0.2, size = 1.3) +
    xlab("Propensity score") +
    ylab(variable) +
    theme_bw()
  
  # ★★★ 변수가 연속형(numeric)일 때만 부드러운 곡선(geom_smooth) 추가 ★★★
  if (is.numeric(dta[[variable]])) {
    p <- p + geom_smooth(method = "loess", se = FALSE)
  }
  
  return(p)
}
# 1. 의미에 따라 변수 그룹 나누기 (변수명은 데이터에 맞게 가감)
# 그룹1: 인구사회학적 특성
demographic_vars <- c("AGE", "SEX", "MARR", "EDU", "INCOME", "ECO1", "DISA_YN")

# 그룹2: 건강 행태 및 상태
health_vars <- c("BMI", "HS1", "HS2_YN", "P1", "S3", "D1")

# 그룹3: 의료보장 형태
insurance_vars <- c("I_PHI1_YN", "HEALTH_INS_2", "HEALTH_INS_3", "HEALTH_INS_4", "HEALTH_INS_5", "HEALTH_INS_6", "HEALTH_INS_8")

# 실제 매칭에 사용된 변수들만 남기기 (중요!)
demographic_vars <- intersect(demographic_vars, all_covs_trimmed)
health_vars <- intersect(health_vars, all_covs_trimmed)
insurance_vars <- intersect(insurance_vars, all_covs_trimmed)


# 2. 그룹별로 플롯 생성 및 출력
# 그룹1 출력
plot_list_demo <- lapply(demographic_vars, function(var) fn_bal(dta_m, var))
grid.arrange(grobs = plot_list_demo, ncol = 2, top = "Balance: Socio-demographic Factors")

# 그룹2 출력
plot_list_health <- lapply(health_vars, function(var) fn_bal(dta_m, var))
grid.arrange(grobs = plot_list_health, ncol = 2, top = "Balance: Health Behaviors & Status")

# 그룹3 출력 (변수가 있을 경우)
if (length(insurance_vars) > 0) {
  plot_list_ins <- lapply(insurance_vars, function(var) fn_bal(dta_m, var))
  grid.arrange(grobs = plot_list_ins, ncol = 2, top = "Balance: Insurance Types")
}

# 11. 매칭 후 결과 분석 (t-test)
dta_m$overburden_numeric <- as.numeric(as.character(dta_m$overburden_yn))

t_test_result <- with(dta_m, t.test(overburden_numeric ~ CD_total))
print(t_test_result)

