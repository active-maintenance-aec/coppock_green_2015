# coppock_green_2015/maintained/text_disattenuation.R
# Output: maintained/output/text_disattenuation.csv
# Depends on: clean_labfield.R output, helpers.R
# Description: The Discussion's disattenuated correlation. Two treatment effects
#   are drawn for each pair from the normal distribution implied by its estimate
#   and standard error; the correlation between the two draws estimates the
#   reliability of the measure; the observed correlation is divided by the
#   geometric mean of the two reliabilities.
#
#   Footnote 7 of the paper defines the reliability as the square of the
#   correlation between the two draws, and the archive implements exactly that.
#   Spearman's correction takes the reliability to be the correlation itself, so
#   both are computed here: the squared definition to reproduce the published
#   number, and the unsquared one, which is what the corrected figures rest on.

source(here::here("maintained", "helpers.R"))

standardized_pairs <- read_rds(here::here("maintained", "data", "standardized_pairs.rds"))

sims <- 10000

# The archive draws in the order lab, lab, field, field for each pair, then moves
# to the next pair and then to the next simulation. Handing rnorm its means in
# that same order reproduces the archive's random stream exactly, so these
# reliabilities are the same Monte Carlo draw rather than a second draw that
# happens to agree to two decimal places.
draw_means <- as.vector(rbind(standardized_pairs$lab_te, standardized_pairs$lab_te,
                              standardized_pairs$field_te, standardized_pairs$field_te))
draw_ses <- as.vector(rbind(standardized_pairs$lab_se, standardized_pairs$lab_se,
                            standardized_pairs$field_se, standardized_pairs$field_se))

set.seed(343)
draws <- array(
  rnorm(sims * length(draw_means), mean = rep(draw_means, sims),
        sd = rep(draw_ses, sims)),
  dim = c(4, nrow(standardized_pairs), sims)
)

simulated <- tibble(
  lab = apply(draws, 3, \(d) cor(d[1, ], d[2, ])),
  field = apply(draws, 3, \(d) cor(d[3, ], d[4, ]))
)

lab_reliability <- mean(simulated$lab)
field_reliability <- mean(simulated$field)
lab_reliability_squared <- mean(simulated$lab^2)
field_reliability_squared <- mean(simulated$field^2)

observed <- cor(standardized_pairs$lab_te, standardized_pairs$field_te)

results <- tibble(
  quantity = c("raw Pearson correlation, 21 pairs",
               "lab reliability",
               "field reliability",
               "disattenuated correlation",
               "lab reliability, squared definition of footnote 7",
               "field reliability, squared definition of footnote 7",
               "disattenuated correlation, squared definition of footnote 7",
               "simulations averaged for each reliability"),
  value = c(observed,
            lab_reliability,
            field_reliability,
            observed / sqrt(lab_reliability * field_reliability),
            lab_reliability_squared,
            field_reliability_squared,
            observed / sqrt(lab_reliability_squared * field_reliability_squared),
            sims)
) |>
  mutate(rounded = round(value, 2))

write_csv(results, here::here("maintained", "output", "text_disattenuation.csv"))

print(results)
