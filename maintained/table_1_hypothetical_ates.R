# coppock_green_2015/maintained/table_1_hypothetical_ates.R
# Output: maintained/output/table_1_hypothetical_ates.csv
#         maintained/output/table_1_hypothetical_ates.tex
# Depends on: helpers.R
# Description: Table 1, a stipulated set of average treatment effects for 16
#   hypothetical experiments. These are the paper's illustrative premises rather
#   than estimates, so they are written down here once and read by everything
#   downstream instead of being retyped.

source(here::here("maintained", "helpers.R"))

table_1 <- tibble(
  pair = 1:8,
  lab_ate = c(2, 5, 3, 0, 2, 0.5, -2, -2),
  field_ate = c(0.5, 4, 3, 3, -1.5, 4, 1.5, 2),
  subjects = rep(c("A", "B"), each = 4),
  treatments = rep(c("T1", "T1", "T2", "T2"), 2),
  outcomes = rep(c("money", "effort", "money", "effort"), 2)
)

write_csv(table_1, here::here("maintained", "output", "table_1_hypothetical_ates.csv"))

table_1 |>
  mutate(across(c(lab_ate, field_ate), \(x) sprintf("%.1f", x))) |>
  kable(format = "latex", booktabs = TRUE, linesep = "",
        col.names = c("Pair", "Lab ATE", "Field ATE", "Subjects", "Treatments",
                      "Outcomes")) |>
  write_lines(here::here("maintained", "output", "table_1_hypothetical_ates.tex"))

print(table_1)
