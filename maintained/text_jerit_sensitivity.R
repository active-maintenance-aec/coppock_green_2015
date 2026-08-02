# coppock_green_2015/maintained/text_jerit_sensitivity.R
# Output: maintained/output/text_jerit_sensitivity.csv
# Depends on: clean_labfield.R output, helpers.R
# Description: Footnote 5. Only one of the Jerit, Barabas and Clifford pairs
#   enters the pooled set of 21; this script reports the full range of pooled
#   rank-order correlations across the 17 possible choices, which one is the
#   median case, and what pooling all 17 at once would give instead.

source(here::here("maintained", "helpers.R"))

standardized_pairs <- read_rds(here::here("maintained", "data", "standardized_pairs.rds"))
jerit <- read_rds(here::here("maintained", "data", "jerit_pairs.rds"))

non_jerit <- standardized_pairs |> filter(point_label != "L")

candidate_rho <- map_dbl(
  seq_len(nrow(jerit)),
  \(i) cor(c(non_jerit$lab_te, jerit$lab_te[i]),
           c(non_jerit$field_te, jerit$field_te[i]),
           method = "spearman")
)

all_seventeen_rho <- cor(c(non_jerit$lab_te, jerit$lab_te),
                         c(non_jerit$field_te, jerit$field_te),
                         method = "spearman")

results <- tibble(
  quantity = c("Jerit candidates",
               "minimum pooled rho across candidates",
               "maximum pooled rho across candidates",
               "median pooled rho across candidates",
               "candidate chosen (median case)",
               "pooled rho including all 17 Jerit pairs",
               "pairs pooled when all 17 are included"),
  value = c(nrow(jerit),
            min(candidate_rho),
            max(candidate_rho),
            median(candidate_rho),
            which(candidate_rho == median(candidate_rho)),
            all_seventeen_rho,
            nrow(non_jerit) + nrow(jerit))
)

write_csv(results, here::here("maintained", "output", "text_jerit_sensitivity.csv"))

print(results)
print(tibble(candidate = seq_along(candidate_rho), question = jerit$question,
             pooled_rho = candidate_rho), n = nrow(jerit))
