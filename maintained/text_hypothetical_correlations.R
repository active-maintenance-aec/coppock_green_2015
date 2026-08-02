# coppock_green_2015/maintained/text_hypothetical_correlations.R
# Output: maintained/output/text_hypothetical_correlations.csv
# Depends on: table_1_hypothetical_ates.R output, helpers.R
# Description: The two correlations the paper quotes from its Table 1 example:
#   the correlation across all eight hypothetical pairs, and the correlation that
#   would be seen if Pairs 1 and 5 went unreported.

source(here::here("maintained", "helpers.R"))

table_1 <- read_csv(here::here("maintained", "output", "table_1_hypothetical_ates.csv"),
                    show_col_types = FALSE)

reported <- table_1 |> filter(!pair %in% c(1, 5))

results <- tibble(
  quantity = c("Pearson correlation, all 8 pairs",
               "Pearson correlation, Pairs 1 and 5 unreported"),
  value = c(cor(table_1$lab_ate, table_1$field_ate),
            cor(reported$lab_ate, reported$field_ate))
) |>
  mutate(rounded = round(value, 2))

write_csv(results, here::here("maintained", "output", "text_hypothetical_correlations.csv"))

print(results)
