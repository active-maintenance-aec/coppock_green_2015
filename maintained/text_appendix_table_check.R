# coppock_green_2015/maintained/text_appendix_table_check.R
# Output: maintained/output/text_appendix_table_check.csv
# Depends on: table_a1_group_means.R output, original_extracted/, helpers.R
# Description: The published appendix to this article is the bibliography of
#   studies considered for inclusion; it does not contain Online Appendix Table 1,
#   so that table's cells have no published counterpart to check against. The
#   deposit does carry the archive's own copy of the table, meanstable.csv, and
#   this script checks the rewrite's version against it cell by cell at the
#   rounding the table prints.

source(here::here("maintained", "helpers.R"))

table_a1 <- read_csv(here::here("maintained", "output", "table_a1_group_means.csv"),
                     show_col_types = FALSE)

deposited <- read_csv(here::here("original_extracted",
                                 "Coppock Green Lab Field Replication Archive",
                                 "meanstable.csv"),
                      show_col_types = FALSE)

# The deposited table carries an unnamed row-number column and spells its columns
# with dots; align the names and the row order before comparing.
deposited_long <- deposited |>
  transmute(
    row = row_number(),
    group = as.character(labels),
    field_mean = field.means, field_se = field.ses, field_n = field.ns,
    lab_mean = lab.means, lab_se = lab.ses, lab_n = lab.ns
  ) |>
  pivot_longer(-c(row, group), names_to = "column", values_to = "deposited")

rewrite_long <- table_a1 |>
  mutate(row = row_number()) |>
  select(row, group, field_mean, field_se, field_n, lab_mean, lab_se, lab_n) |>
  pivot_longer(-c(row, group), names_to = "column", values_to = "rewrite")

cells <- deposited_long |>
  left_join(rewrite_long, by = c("row", "group", "column")) |>
  mutate(agrees = abs(deposited - rewrite) < 1e-9)

results <- tibble(
  quantity = c("treatment condition rows",
               "cells compared",
               "cells agreeing with the deposited meanstable.csv",
               "largest absolute disagreement"),
  value = c(nrow(table_a1),
            nrow(cells),
            sum(cells$agrees),
            max(abs(cells$deposited - cells$rewrite)))
)

write_csv(results, here::here("maintained", "output", "text_appendix_table_check.csv"))

print(results)
if (any(!cells$agrees)) print(cells |> filter(!agrees), n = Inf)
