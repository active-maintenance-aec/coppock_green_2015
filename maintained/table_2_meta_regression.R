# coppock_green_2015/maintained/table_2_meta_regression.R
# Output: maintained/output/table_2_meta_regression.csv
#         maintained/output/table_2_meta_regression.tex
# Depends on: table_1_hypothetical_ates.R output, helpers.R
# Description: Table 2, the meta-analytic regression of the 16 hypothetical
#   treatment effects of Table 1 on the four design features that generated them.

source(here::here("maintained", "helpers.R"))

table_1 <- read_csv(here::here("maintained", "output", "table_1_hypothetical_ates.csv"),
                    show_col_types = FALSE)

experiments <- table_1 |>
  pivot_longer(c(lab_ate, field_ate), names_to = "context", values_to = "ate") |>
  transmute(
    ate,
    subjects_a = subjects == "A",
    treatments_t1 = treatments == "T1",
    outcomes_effort = outcomes == "effort",
    contexts_field = context == "field_ate"
  )

fit <- lm_robust(ate ~ subjects_a + treatments_t1 + outcomes_effort + contexts_field,
                 data = experiments)

coef_labels <- c(
  subjects_aTRUE = "Subjects (A)",
  treatments_t1TRUE = "Treatments (T1)",
  outcomes_effortTRUE = "Outcomes (Effort)",
  contexts_fieldTRUE = "Contexts (Field)",
  `(Intercept)` = "Constant"
)

tidy(fit) |>
  arrange(match(term, names(coef_labels))) |>
  transmute(term = unname(coef_labels[term]), ols = estimate) |>
  write_csv(here::here("maintained", "output", "table_2_meta_regression.csv"))

# The published table reports point estimates only, so no uncertainty is shown.
modelsummary(
  list(OLS = fit),
  output = here::here("maintained", "output", "table_2_meta_regression.tex"),
  coef_map = coef_labels,
  statistic = NULL,
  gof_map = NA,
  fmt = 2,
  booktabs = TRUE
)

print(tidy(fit) |> select(term, estimate, std.error))
