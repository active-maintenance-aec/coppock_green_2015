# coppock_green_2015/maintained/figure_1_twelve_tiles.R
# Output: maintained/output/figure_1_twelve_tiles.pdf
#         maintained/output/figure_1_twelve_tiles.png
#         maintained/output/figure_1_twelve_tiles.csv
#         maintained/output/figure_1_twelve_tiles_annotations.csv
# Depends on: clean_labfield.R output, helpers.R
# Description: Figure 1, twelve panels putting each study's lab results on the
#   horizontal axis against its field results on the vertical. Eleven panels show
#   treatment group means with 95 percent confidence intervals; the Jerit,
#   Barabas and Clifford panel shows treatment effects, one per survey question.

source(here::here("maintained", "helpers.R"))

labfield_groups <- read_rds(here::here("maintained", "data", "labfield_groups.rds"))
jerit <- read_rds(here::here("maintained", "data", "jerit_pairs.rds"))

# Each panel keeps its own axis labels and limits, so the twelve are built
# separately and assembled with patchwork rather than faceted.
panel_specs <- tribble(
  ~study, ~title, ~x_label, ~y_label, ~x_limits, ~y_limits,
  "Erev, Bornstein, and Galili (1993)",
  "Erev, Bornstein, and Galili (1993)\ncompared with\nBornstein, Erev, and Rosen (1990)",
  "Lab Participation", "Field Kilos Picked Per Group", c(0, 1), c(0, 425),
  "Gneezy and Rustichini (2000)", "Gneezy and Rustichini (2000)",
  "Effort, Lab", "Effort, Field", c(0, 50), c(0, 350),
  "Valentino, Traugott, and Hutchings (2002)", "Valentino, Traugott, and Hutchings (2002)",
  "% lead for Bush, Lab", "% lead for Bush, Field", c(-0.5, 0.5), c(-0.5, 0.5),
  "Gneezy and Rustichini (2004)",
  "Gneezy and Rustichini (2004)\ncompared with Gneezy et al. (2003)",
  "Lab Average Mazes Completed", "Field Average Round 2 - Round 1 Speed",
  c(0, 20), c(-0.35, 0.35),
  "Gneezy, Haruvy, and Yafe (2004)", "Gneezy, Haruvy, and Yafe (2004)",
  "Units Purchased, Lab", "Cost of meal, Field", c(0, 6), c(0, 80),
  "List (2006)", "List (2006)",
  "Quality supplied in the Lab", "Quality supplied in the Field", c(0, 5), c(0, 5),
  "Shang, Reed, and Croson (2008)", "Shang, Reed, and Croson (2008)",
  "Hypothetical Donations in the Lab", "Actual Donations in the Field",
  c(0, 30), c(0, 200),
  "Rondeau and List (2008)", "Rondeau and List (2008):\nAverage Contributions",
  "Lab Average Contribution", "Field Average Contribution", c(0, 10), c(0, 4),
  "Harrison and List (2008)", "Harrison and List (2008)",
  "Average Seller Revenue, Lab", "Average Seller Revenue, Field", c(50, 150), c(0, 15),
  "Armantier and Boly (2013)", "Armantier and Boly (2013)",
  "Proportion taking the Bribe, Lab", "Proportion taking the Bribe, Field",
  c(0, 1), c(0, 1),
  "Abeler and Marklein (2013)", "Abeler and Marklein (2013)",
  "Lab Consumption", "Field Consumption", c(0, 25), c(0, 25)
)

group_means <- labfield_groups |>
  pivot_wider(id_cols = c(study, label), names_from = context,
              values_from = c(mean, lower, upper))

jerit_effects <- jerit |>
  transmute(study = "Jerit, Barabas, and Clifford (2013)", label = question,
            mean_lab = lab_ate, lower_lab = lab_ate_lower, upper_lab = lab_ate_upper,
            mean_field = field_ate, lower_field = field_ate_lower,
            upper_field = field_ate_upper)

gg_df <- bind_rows(group_means, jerit_effects)

write_csv(gg_df, here::here("maintained", "output", "figure_1_twelve_tiles.csv"))

tile <- function(spec) {
  ggplot(filter(gg_df, study == spec$study), aes(x = mean_lab, y = mean_field)) +
    geom_linerange(aes(ymin = lower_field, ymax = upper_field), color = "gray50") +
    geom_linerange(aes(xmin = lower_lab, xmax = upper_lab), color = "gray50") +
    geom_point(size = 1.4) +
    geom_text(aes(label = label), vjust = -0.9, size = 2.4) +
    coord_cartesian(xlim = spec$x_limits[[1]], ylim = spec$y_limits[[1]]) +
    labs(title = spec$title, x = spec$x_label, y = spec$y_label) +
    theme_bw(base_size = 9) +
    theme(plot.title = element_text(size = 8, hjust = 0.5))
}

# The two correlations printed inside the Jerit panel are values the figure states,
# so they are written out alongside the points rather than existing only as text
# baked into the image.
annotations <- tibble(
  quantity = c("Jerit Pearson correlation", "Jerit Spearman correlation"),
  value = c(cor(jerit$lab_ate, jerit$field_ate),
            cor(jerit$lab_ate, jerit$field_ate, method = "spearman"))
) |>
  mutate(printed = format(round(value, 2), nsmall = 2))

write_csv(annotations,
          here::here("maintained", "output", "figure_1_twelve_tiles_annotations.csv"))

jerit_labels <- str_glue(
  "Pearson Correlation = {annotations$printed[1]}\n",
  "Spearman Correlation = {annotations$printed[2]}"
)

jerit_tile <-
  ggplot(jerit_effects, aes(x = mean_lab, y = mean_field)) +
  geom_smooth(method = "lm", formula = y ~ x, se = FALSE, color = "red",
              linewidth = 0.5) +
  geom_linerange(aes(ymin = lower_field, ymax = upper_field), color = "gray50") +
  geom_linerange(aes(xmin = lower_lab, xmax = upper_lab), color = "gray50") +
  geom_point(size = 1.4) +
  annotate("text", x = Inf, y = -Inf, label = jerit_labels, hjust = 1.05,
           vjust = -0.4, size = 2.4) +
  labs(title = "Jerit, Barabas, and Clifford (2013)",
       x = "Treatment Effects in Lab", y = "Treatment Effects in Field") +
  theme_bw(base_size = 9) +
  theme(plot.title = element_text(size = 8, hjust = 0.5))

tiles <- map(seq_len(nrow(panel_specs)), \(i) tile(slice(panel_specs, i)))

g <- wrap_plots(c(tiles, list(jerit_tile)), ncol = 4)

ggsave(here::here("maintained", "output", "figure_1_twelve_tiles.pdf"),
       plot = g, width = 16, height = 12)
ggsave(here::here("maintained", "output", "figure_1_twelve_tiles.png"),
       plot = g, width = 16, height = 12, dpi = 200)

print(annotations)
