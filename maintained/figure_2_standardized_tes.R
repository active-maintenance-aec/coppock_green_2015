# coppock_green_2015/maintained/figure_2_standardized_tes.R
# Output: maintained/output/figure_2_standardized_tes.pdf
#         maintained/output/figure_2_standardized_tes.png
#         maintained/output/figure_2_standardized_tes.csv
#         maintained/output/figure_2_standardized_tes_annotations.csv
# Depends on: clean_labfield.R output, helpers.R
# Description: Figure 2, the 21 pooled lab-field pairs on a common standardized
#   scale, with the rank-order correlation that summarizes them.

source(here::here("maintained", "helpers.R"))

gg_df <- read_rds(here::here("maintained", "data", "standardized_pairs.rds"))

write_csv(gg_df, here::here("maintained", "output", "figure_2_standardized_tes.csv"))

spearman_rho <- cor(gg_df$lab_te, gg_df$field_te, method = "spearman")

# The figure states the rank-order correlation and the number of pairs it covers,
# so both are written out rather than existing only as text baked into the image.
annotations <- tibble(
  quantity = c("pooled Spearman rho, 21 pairs", "pooled treatment effect pairs"),
  value = c(spearman_rho, nrow(gg_df))
)

write_csv(annotations,
          here::here("maintained", "output", "figure_2_standardized_tes_annotations.csv"))

g <-
  ggplot(gg_df, aes(x = lab_te, y = field_te)) +
  geom_abline(slope = 1, intercept = 0, linetype = "dashed", color = "lightgray") +
  geom_linerange(aes(ymin = field_lower, ymax = field_upper), color = "gray55") +
  geom_linerange(aes(xmin = lab_lower, xmax = lab_upper), color = "gray55") +
  geom_text(aes(label = point_label), size = 3.5) +
  annotate("text", x = 2, y = -0.5, hjust = 0, size = 3.5,
           label = str_glue("Rank-Order Correlation: {format(round(spearman_rho, 2), nsmall = 2)}")) +
  coord_cartesian(xlim = c(-1, 3.5), ylim = c(-1, 3.5)) +
  labs(
    title = "Standardized Treatment Effects across all Lab-Field Pairs",
    x = "Lab Standardized Treatment Effects",
    y = "Field Standardized Treatment Effects"
  ) +
  theme_bw(base_size = 12)

ggsave(here::here("maintained", "output", "figure_2_standardized_tes.pdf"),
       plot = g, width = 9, height = 9)
ggsave(here::here("maintained", "output", "figure_2_standardized_tes.png"),
       plot = g, width = 9, height = 9, dpi = 200)

print(annotations)
