# coppock_green_2015/maintained/text_median_sample_sizes.R
# Output: maintained/output/text_median_sample_sizes.csv
# Depends on: clean_labfield.R output, helpers.R
# Description: The Discussion's median sample size per treatment condition, taken
#   over the treatment conditions of the eleven studies that report group means.
#   Jerit, Barabas and Clifford is excluded because the deposit records treatment
#   effects for it rather than group sizes.

source(here::here("maintained", "helpers.R"))

labfield_groups <- read_rds(here::here("maintained", "data", "labfield_groups.rds"))

results <- labfield_groups |>
  summarize(groups = n(), median_n = median(n), mean_n = mean(n),
            .by = context)

write_csv(results, here::here("maintained", "output", "text_median_sample_sizes.csv"))

print(results)
