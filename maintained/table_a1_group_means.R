# coppock_green_2015/maintained/table_a1_group_means.R
# Output: maintained/output/table_a1_group_means.csv
#         maintained/output/table_a1_group_means.tex
# Depends on: clean_labfield.R output, helpers.R
# Description: Online Appendix Table 1, the group means, standard errors and
#   group sizes behind every panel of Figure 1.

source(here::here("maintained", "helpers.R"))

labfield_groups <- read_rds(here::here("maintained", "data", "labfield_groups.rds"))

table_a1 <- labfield_groups |>
  pivot_wider(id_cols = c(study, label), names_from = context,
              values_from = c(mean, se, n)) |>
  transmute(
    study,
    group = label,
    field_mean = round(mean_field, 2),
    field_se = round(se_field, 2),
    field_n = as.integer(n_field),
    lab_mean = round(mean_lab, 2),
    lab_se = round(se_lab, 2),
    lab_n = as.integer(n_lab)
  )

write_csv(table_a1, here::here("maintained", "output", "table_a1_group_means.csv"))

table_a1 |>
  select(-study) |>
  kable(format = "latex", booktabs = TRUE, linesep = "",
        col.names = c("Group", "Field Mean", "Field SE", "Field N",
                      "Lab Mean", "Lab SE", "Lab N")) |>
  pack_rows(index = table(fct_inorder(table_a1$study))) |>
  write_lines(here::here("maintained", "output", "table_a1_group_means.tex"))

print(table_a1, n = nrow(table_a1))
