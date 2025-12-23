# 1. 필수 패키지 로드
library(gtsummary)
library(tidyverse)
library(readxl)
library(gt)

# 2. 데이터 불러오기
df <- read_excel(file.choose())

# 3. (수정) 데이터 클리닝 및 전처리
# 변수 이름에서 '.0'과 같은 불필요한 문자 제거
names(df) <- gsub("\\.0$", "", names(df))

df_cleaned <- df %>%
  mutate(
    # 범주형 변수 라벨링 (기존과 동일)
    CD_total = factor(CD_total, levels = c(0, 1), labels = c("만성질환 없음", "만성질환 보유")),
    SEX = factor(SEX, levels = c(0, 1), labels = c("여성", "남성")),
    MARR = factor(MARR, levels = c(0, 1), labels = c("미혼", "기혼")),
    EDU = factor(EDU, levels = c(0, 1), labels = c("고졸 미만", "고졸 이상")),
    DISA_YN = factor(DISA_YN, levels = c(0, 1), labels = c("아니오", "예")),
    I_PHI1_YN = factor(I_PHI1_YN, levels = c(0, 1), labels = c("미가입", "가입")),
    ECO1 = factor(ECO1, levels = c(0, 1), labels = c("비취업", "취업")),
    HS2_YN = factor(HS2_YN, levels = c(0, 1), labels = c("아니오", "예")),
    HS1 = factor(HS1, levels = c(0, 1), labels = c("아니오", "예")),
    P1 = factor(P1, levels = c(0, 1), labels = c("아니오", "예")),
    S3 = factor(S3, levels = c(0, 1), labels = c("비흡연", "현재 흡연")),
    D1 = factor(D1, levels = c(0, 1), labels = c("월 2회 미만", "월 2회 이상")),
    
    # (핵심 수정) 나뉘어진 HEALTH_INS 변수들을 하나로 합치기
    HEALTH_INS = case_when(
      HEALTH_INS_2 == 1 ~ "건보: 직장피부양자",
      HEALTH_INS_3 == 1 ~ "건보: 지역세대주",
      HEALTH_INS_4 == 1 ~ "건보: 지역세대",
      HEALTH_INS_5 == 1 ~ "의료급여 1,2종 세대주",
      HEALTH_INS_6 == 1 ~ "의료급여 세대원",
      HEALTH_INS_8 == 1 ~ "미가입",
      TRUE ~ "직장가입자(본인)" # HEALTH_INS 관련 변수가 모두 0인 경우
    ) %>% factor(levels = c(
      "직장가입자(본인)", "건보: 직장피부양자", "건보: 지역세대주",
      "건보: 지역세대", "의료급여 1,2종 세대주", "의료급여 세대원", "미가입"
    ))
  ) %>%
  # (수정) 최종 분석에 사용할 변수 선택 (INCOME 추가, HEALTH_INS 개별 변수 제외)
  select(
    CD_total, AGE, BMI, SEX, MARR, EDU, HEALTH_INS, ECO1, I_PHI1_YN,
    DISA_YN, HS1, S3, D1, P1, HS2_YN, overburden_yn, INCOME
  )

# 4. (수정) Table 1 생성
table1 <- df_cleaned %>%
  # tbl_summary 안에서 변수를 다시 선택할 필요 없이 바로 사용
  tbl_summary(
    by = CD_total,
    statistic = list(all_continuous() ~ "{mean} ± {sd}", all_categorical() ~ "{n} ({p}%)"),
    digits = all_continuous() ~ 1,
    # (수정) INCOME 변수 라벨 추가
    label = list(
      AGE ~ "연령 (세)", 
      BMI ~ "체질량지수 (kg/m²)", 
      SEX ~ "성별", 
      MARR ~ "혼인상태",
      EDU ~ "교육수준", 
      HEALTH_INS ~ "의료보장 형태", 
      ECO1 ~ "경제활동 상태",
      I_PHI1_YN ~ "민간의료보험 가입", 
      DISA_YN ~ "장애 유무", 
      HS1 ~ "스트레스 인지",
      S3 ~ "현재 흡연 여부", 
      D1 ~ "음주 빈도", 
      P1 ~ "규칙적 운동",
      HS2_YN ~ "우울감 경험", 
      overburden_yn ~ "의료비 과부담 여부",
      INCOME ~ "개인 소득" # 라벨 추가
    ),
    missing_text = "결측치"
  ) %>%
  add_overall() %>%
  add_p(test = list(all_categorical() ~ "chisq.test")) %>%
  modify_header(label = "**특성**") %>%
  modify_spanning_header(c("stat_1", "stat_2") ~ "**만성질환 보유 여부**") %>%
  bold_labels() %>%
  bold_p(t = 0.05)

# 5. 표 확인 및 저장
table1

 table1 %>%
   as_gt() %>%
   gtsave("Table1_final.png", vwidth = 2500)

