# coppock_green_2015/ground_truth/build_ground_truth.R
# Output: ground_truth/coppock_green_2015_ground_truth.csv
# Depends on: maintained/output/ (run run_all.R first)
# Description: Assemble the ground truth table. Every value_paper entry was read
#   from the published article and is used only as a comparison target; no
#   published number is an input to any computation here or anywhere in
#   maintained/. Every value_rewrite entry is read back out of maintained/output/,
#   so the table cannot drift from the pipeline. value_script is what the deposited
#   scripts print when run on a current R installation.

library(here)
library(tidyverse)

here::i_am("ground_truth/build_ground_truth.R")

out <- function(f) read_csv(here::here("maintained", "output", f), show_col_types = FALSE)

t1 <- out("table_1_hypothetical_ates.csv")
t2 <- out("table_2_meta_regression.csv")
f1 <- out("figure_1_twelve_tiles_annotations.csv")
f2 <- out("figure_2_standardized_tes_annotations.csv")
f3 <- out("figure_3_robustness.csv")
hypothetical <- out("text_hypothetical_correlations.csv")
jerit <- out("text_jerit_sensitivity.csv")
sample_sizes <- out("text_median_sample_sizes.csv")
disattenuation <- out("text_disattenuation.csv")
appendix <- out("text_appendix_table_check.csv")
sampler <- out("text_sampler_reproducibility.csv")

# pick: one value out of an output file, by a pattern that has to identify it
# uniquely. The assertion is what keeps a widened output file from silently
# turning a scalar into a vector and a ground truth row into a list column.
pick <- function(d, pattern) {
  hits <- d$value[str_detect(d$quantity, pattern)]
  stopifnot(length(hits) == 1)
  hits
}

# Table 1, the stipulated hypothetical effects ----
# The 16 entries of Table 1 are premises rather than estimates, so the rewrite
# writes them down and everything downstream reads them back. That makes the
# article's own table the only check on them, which is what these rows are. The
# deposited script types the same values but prints only the Table 2 regression,
# so there is nothing to put in value_script.
paper_table_1 <- tribble(
  ~pair, ~lab_ate, ~field_ate,
  1,  2.0,  0.5,
  2,  5.0,  4.0,
  3,  3.0,  3.0,
  4,  0.0,  3.0,
  5,  2.0, -1.5,
  6,  0.5,  4.0,
  7, -2.0,  1.5,
  8, -2.0,  2.0
)

table_1_rows <- paper_table_1 |>
  pivot_longer(-pair, names_to = "cell", values_to = "value_paper") |>
  left_join(
    t1 |>
      select(pair, lab_ate, field_ate) |>
      pivot_longer(-pair, names_to = "cell", values_to = "value_rewrite"),
    by = c("pair", "cell")
  ) |>
  transmute(
    table_figure = "Table 1",
    claim = str_glue("Pair {pair}, {if_else(cell == 'lab_ate', 'lab', 'field')} ATE"),
    value_script = NA_real_,
    paper_printed = sprintf("%.1f", value_paper),
    value_rewrite,
    defect_locus = NA_character_,
    notes = "Stipulated premise of the paper's illustration, not an estimate; the deposited script types the same value but prints only the Table 2 regression"
  )

# Everything else ----
gt <- bind_rows(
  table_1_rows,
  tribble(
    ~table_figure, ~claim, ~value_script, ~paper_printed, ~value_rewrite, ~defect_locus, ~notes,

    "Table 2", "Subjects (A)", 2, "2.00", t2$ols[t2$term == "Subjects (A)"], NA, "",
    "Table 2", "Treatments (T1)", 1, "1.00", t2$ols[t2$term == "Treatments (T1)"], NA, "",
    "Table 2", "Outcomes (Effort)", 1, "1.00", t2$ols[t2$term == "Outcomes (Effort)"], NA, "",
    "Table 2", "Contexts (Field)", 1, "1.00", t2$ols[t2$term == "Contexts (Field)"], NA, "",
    "Table 2", "Constant", -0.9375, "-0.94", t2$ols[t2$term == "Constant"], NA, "",

    "Table 3", "Parallel lab-field study pairs", 12, "12", 12, NA,
      "Table 3 lists the twelve pairs by name and states no other quantity",

    "Text, p. 121", "Correlation across the eight hypothetical pairs", NA, "0.14",
      pick(hypothetical, "all 8 pairs"), NA,
      "No deposited script computes this; the rewrite adds text_hypothetical_correlations.R",
    "Text, p. 121", "Correlation when Pairs 1 and 5 go unreported", NA, "0.76",
      pick(hypothetical, "Pairs 1 and 5 unreported"), NA,
      "No deposited script computes this; the rewrite adds text_hypothetical_correlations.R",

    "Figure 1", "Jerit panel, Pearson correlation", 0.2110548191, "0.21",
      pick(f1, "Pearson"), NA,
      "The deposited script prints this value and then types it into the figure legend by hand",
    "Figure 1", "Jerit panel, Spearman correlation", 0.2599631182, "0.26",
      pick(f1, "Spearman"), NA,
      "The deposited script prints this value and then types it into the figure legend by hand",

    "Figure 2", "Pooled treatment effect pairs", 21, "21",
      pick(f2, "^pooled treatment effect pairs$"), NA, "",
    "Figure 2", "Rank-order correlation printed on the figure", 0.7275089698, "0.73",
      pick(f2, "^pooled Spearman rho"), NA,
      "The rewrite corrects the Gneezy and Rustichini (2004) female standardization; unchanged at the two decimal places the figure prints",

    "Abstract", "Rank-order correlation", 0.7275089698, "0.73",
      pick(f2, "^pooled Spearman rho"), NA, "The same quantity as Figure 2",

    "Footnote 5", "Jerit candidate pairs", 17, "17", pick(jerit, "^Jerit candidates$"), NA, "",
    "Footnote 5", "Lowest pooled rho across the candidates", 0.6995778219, "0.699",
      pick(jerit, "^minimum"), "archive",
      "The footnote truncates rather than rounds: the deposited script prints 0.6995778, which rounds to 0.700 at the three decimals the footnote uses. The rewrite's value moves further because the Gneezy and Rustichini (2004) female standardization correction shifts every pooled correlation",
    "Footnote 5", "Highest pooled rho across the candidates", 0.7619357336, "0.762",
      pick(jerit, "^maximum"), "archive",
      "The Gneezy and Rustichini (2004) female standardization correction shifts every pooled correlation",
    "Footnote 5", "Pooled rho including all 17 Jerit pairs", NA, "0.56",
      pick(jerit, "^pooled rho including all 17"), NA,
      "No deposited script computes this; the rewrite adds text_jerit_sensitivity.R",

    "Footnote 6", "Combinations sampled where more than 50,000 exist", 50000, "50000", 50000, NA, "",

    "Figure 3", "Lowest 25th percentile across the combination sizes",
      min(sampler$rounding_sampler[sampler$statistic == "1st Qu."]), NA,
      min(f3$q25), NA,
      "The figure prints no numbers, so this value has no published counterpart of its own; the band it falls in is tested by the row below",
    "Figure 3", "Highest 75th percentile across the combination sizes",
      max(sampler$rounding_sampler[sampler$statistic == "3rd Qu."]), NA,
      max(f3$q75), NA,
      "The figure prints no numbers, so this value has no published counterpart of its own; the band it falls in is tested by the row below",
    "Figure 3", "Interquartile range stays within 0.6 to 0.8 across every combination size",
      as.numeric(min(sampler$rounding_sampler[sampler$statistic == "1st Qu."]) >= 0.6 &
                 max(sampler$rounding_sampler[sampler$statistic == "3rd Qu."]) <= 0.8),
      "1",
      as.numeric(min(f3$q25) >= 0.6 & max(f3$q75) <= 0.8), NA,
      "The article states that the interquartile range stays within the narrow band of about 0.6 to 0.8; 1 records that it does",
    "Figure 3", "Minimum correlation crosses zero when any ten pairs are dropped",
      as.numeric(min(sampler$rounding_sampler[sampler$statistic == "Min." &
                                              sampler$n_used == 11]) < 0),
      "1",
      as.numeric(f3$minimum[f3$n_used == 11] < 0), NA,
      "The article states that the minimum correlation crosses zero in the case of dropping any ten pairs; 1 records that it does",
    "Figure 3", "Distinct values of the median correlation, to two decimal places",
      n_distinct(round(sampler$rounding_sampler[sampler$statistic == "Median"], 2)),
      "1", n_distinct(round(f3$median, 2)), "paper_internal",
      "The text says the median correlation stays constant across all permutations, which implies one value. It is not constant in either run: the deposited procedure's median runs from 0.720 to 0.729 and the rewrite's from 0.719 to 0.739",
    "Figure 3", "Largest change in a plotted summary value under the R 3.6 sampler",
      max(abs(sampler$difference)), NA, NA, NA,
      "A property of the environment rather than of either analysis; see text_sampler_reproducibility.csv",

    "Discussion", "Median lab sample size per treatment condition", NA, "40",
      sample_sizes$median_n[sample_sizes$context == "lab"], NA,
      "No deposited script computes this; the rewrite adds text_median_sample_sizes.R",
    "Discussion", "Median field sample size per treatment condition", NA, "37.5",
      sample_sizes$median_n[sample_sizes$context == "field"], NA,
      "No deposited script computes this; the rewrite adds text_median_sample_sizes.R",
    "Discussion", "Raw Pearson correlation across the 21 pairs", 0.642813994, "0.64",
      pick(disattenuation, "^raw Pearson"), "archive",
      "The Gneezy and Rustichini (2004) female standardization correction raises the pooled Pearson correlation",
    "Discussion", "Lab reliability", 0.7833397739, "0.78",
      pick(disattenuation, "^lab reliability$"), "paper_internal",
      "Footnote 7 defines the reliability as the square of the correlation between two draws; Spearman's correction takes the correlation itself",
    "Discussion", "Field reliability", 0.8239761387, "0.82",
      pick(disattenuation, "^field reliability$"), "paper_internal",
      "The same definitional correction, compounded by the List (2006) field standard error the deposited script reads from the lab vector",
    "Discussion", "Disattenuated correlation", 0.8001159278, "0.80",
      pick(disattenuation, "^disattenuated correlation$"), "paper_internal",
      "Follows from the reliability definition and the two standardization corrections",
    "Footnote 7", "Lab reliability under the published definition", 0.7833397739, "0.78",
      pick(disattenuation, "^lab reliability, squared"), NA,
      "The rewrite also reports the published definition, so the correction can be traced",
    "Footnote 7", "Field reliability under the published definition", 0.8239761387, "0.82",
      pick(disattenuation, "^field reliability, squared"), NA,
      "The rewrite also reports the published definition, so the correction can be traced",
    "Footnote 7", "Disattenuated correlation under the published definition", 0.8001159278, "0.80",
      pick(disattenuation, "^disattenuated correlation, squared"), "archive",
      "Keeping footnote 7's squared reliability and fixing only the two indexing errors gives 0.81 rather than the published 0.80, because both raise the raw Pearson correlation",

    "Online Appendix Table 1", "Treatment condition rows",
      pick(appendix, "treatment condition rows"), NA,
      pick(appendix, "treatment condition rows"), NA,
      "The published appendix is the bibliography of studies considered for inclusion and does not contain this table, so its cells have no published counterpart; the rewrite is checked against meanstable.csv, the deposit's own copy of the table",
    "Online Appendix Table 1", "Cells agreeing with the deposited meanstable.csv",
      pick(appendix, "cells compared"), NA,
      pick(appendix, "cells agreeing"), NA,
      "All 32 rows by 6 columns agree exactly",

    "Online Appendix Table 2", "Descriptions of the twelve study pairs", NA, NA, NA, NA,
      "The table is prose rather than numbers, the published appendix is the bibliography of studies considered for inclusion and does not contain it, and no deposited script produces it"
  )
)

# Agreement at the precision the article prints ----
# Each value_paper is carried as the string the article prints, because the number
# alone does not record its own precision: 0.80 and 0.8 are the same double, and
# reading the precision off the double would compare a two-decimal published value
# at a tolerance of 0.05.
printed_decimals <- function(txt) {
  if_else(str_detect(txt, "\\."), nchar(str_remove(txt, "^[^.]*\\.")), 0L)
}

agrees <- function(value, target_printed) {
  target <- parse_double(target_printed)
  case_when(
    is.na(value) | is.na(target) ~ NA_real_,
    abs(value - target) <= 0.5 * 10^(-printed_decimals(target_printed)) ~ 1,
    .default = 0
  )
}

gt <- gt |>
  mutate(
    paper_id = "coppock_green_2015",
    claim = as.character(claim),
    match = agrees(value_script, paper_printed),
    match_rewrite = agrees(value_rewrite, paper_printed),
    value_paper = parse_double(paper_printed),
    defect_locus = if_else(match_rewrite == 0 & !is.na(match_rewrite),
                           replace_na(defect_locus, "unresolved"), NA_character_)
  ) |>
  select(paper_id, table_figure, claim, value_script, value_paper, match,
         value_rewrite, match_rewrite, defect_locus, notes)

stopifnot(all(!is.na(gt$defect_locus[!is.na(gt$match_rewrite) & gt$match_rewrite == 0])))

write_csv(gt, here::here("ground_truth", "coppock_green_2015_ground_truth.csv"))

print(gt |> select(table_figure, claim, value_script, value_paper, match,
                   value_rewrite, match_rewrite),
      n = nrow(gt), width = 200)
print(tibble(
  quantity = c("rows", "archive comparable", "archive matching",
               "rewrite comparable", "rewrite matching", "rewrite differing"),
  value = c(nrow(gt), sum(!is.na(gt$match)), sum(gt$match == 1, na.rm = TRUE),
            sum(!is.na(gt$match_rewrite)), sum(gt$match_rewrite == 1, na.rm = TRUE),
            sum(gt$match_rewrite == 0, na.rm = TRUE))
))
