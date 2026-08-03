# coppock_green_2015/maintained/figure_3_robustness.R
# Output: maintained/output/figure_3_robustness.pdf
#         maintained/output/figure_3_robustness.png
#         maintained/output/figure_3_robustness.csv
# Depends on: clean_labfield.R output, helpers.R
# Description: Figure 3, the five-number summary of the rank-order correlation
#   under every way of removing 1 to 10 of the 21 pairs and every way of
#   duplicating 1 to 10 of them. Where a combination count exceeds 50,000, the
#   paper samples 50,000 of them, so this script is seeded.

source(here::here("maintained", "helpers.R"))

standardized_pairs <- read_rds(here::here("maintained", "data", "standardized_pairs.rds"))

set.seed(343)

n_pairs <- nrow(standardized_pairs)
max_combinations <- 50000
lab <- standardized_pairs$lab_te
field <- standardized_pairs$field_te

# combinations: every way of choosing k of the n pairs, capped at 50,000 by
# random sampling when there are more than that.
combinations <- function(n, k) {
  all <- combn(n, k)
  if (ncol(all) > max_combinations) all[, sample(ncol(all), max_combinations)] else all
}

five_number <- function(rho) {
  tibble(minimum = min(rho), q25 = quantile(rho, 0.25), median = median(rho),
         q75 = quantile(rho, 0.75), maximum = max(rho))
}

# Removing k pairs leaves every subset of size n - k.
# n_combinations is how many subsets of that size exist and n_evaluated how many
# were actually used, so the point at which the 50,000 cap starts to bind is
# readable off the output rather than only from the code.
removing <- function(k) {
  kept <- combinations(n_pairs, n_pairs - k)
  rho <- apply(kept, 2, \(i) cor(lab[i], field[i], method = "spearman"))
  five_number(rho) |>
    mutate(n_used = n_pairs - k, n_combinations = choose(n_pairs, n_pairs - k),
           n_evaluated = ncol(kept), .before = 1)
}

# Duplicating k pairs appends a copy of each chosen pair to the full set.
duplicating <- function(k) {
  extra <- combinations(n_pairs, k)
  rho <- apply(extra, 2, \(i) cor(c(lab, lab[i]), c(field, field[i]),
                                  method = "spearman"))
  five_number(rho) |>
    mutate(n_used = n_pairs + k, n_combinations = choose(n_pairs, k),
           n_evaluated = ncol(extra), .before = 1)
}

observed <- five_number(cor(lab, field, method = "spearman")) |>
  mutate(n_used = n_pairs, n_combinations = 1, n_evaluated = 1, .before = 1)

gg_df <- bind_rows(map(1:10, removing), observed, map(1:10, duplicating)) |>
  arrange(n_used)

write_csv(gg_df, here::here("maintained", "output", "figure_3_robustness.csv"))

plot_df <- gg_df |>
  pivot_longer(c(minimum, q25, median, q75, maximum),
               names_to = "statistic", values_to = "rho") |>
  mutate(
    statistic = factor(statistic,
                       levels = c("maximum", "q75", "median", "q25", "minimum"),
                       labels = c("Maximum", "75th Percentile", "Median",
                                  "25th Percentile", "Minimum")),
    n_used = factor(n_used)
  )

# The five series converge on the same narrow band through most of the range, so
# there is no point at which a direct label can be attached without colliding with
# its neighbours. This is the case a legend exists for, and it is what the
# published figure uses.
g <-
  ggplot(plot_df, aes(x = n_used, y = rho, shape = statistic, fill = statistic)) +
  geom_vline(xintercept = which(levels(plot_df$n_used) == as.character(n_pairs)),
             linetype = "dashed", color = "gray70") +
  geom_point(size = 2.2) +
  annotate("text", x = c(6.5, 15.5), y = -0.45,
           label = c("Pairs are Removed", "Pairs are Duplicated"), size = 3) +
  scale_shape_manual(values = c(2, 17, 19, 25, 6)) +
  scale_fill_manual(values = c("white", "black", "black", "black", "white")) +
  scale_y_continuous(limits = c(-1, 1)) +
  labs(
    title = "Rank Order Correlation of Standardized Treatment Effects in Lab and Field",
    x = "Lab-Field Pairs used in Calculation",
    y = "Rank Order Correlation Coefficient",
    shape = NULL, fill = NULL
  ) +
  theme_bw(base_size = 11) +
  theme(legend.position = "inside",
        legend.position.inside = c(0.12, 0.16),
        legend.background = element_blank(),
        legend.key = element_blank(),
        axis.text.x = element_text(angle = 90, vjust = 0.5, size = 8))

ggsave(here::here("maintained", "output", "figure_3_robustness.pdf"),
       plot = g, width = 9, height = 7)
ggsave(here::here("maintained", "output", "figure_3_robustness.png"),
       plot = g, width = 9, height = 7, dpi = 200)

print(gg_df)
