# coppock_green_2015/ground_truth/build_ground_truth.R
# Output: ground_truth/coppock_green_2015_ground_truth.csv,
#   ground_truth/float_coverage.csv
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

n_pairs <- pick(f2, "^pooled treatment effect pairs$")

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
    claim_id = str_glue("t1_pair{pair}_{if_else(cell == 'lab_ate', 'lab', 'field')}"),
    table_figure = "Table 1",
    claim = str_glue("Pair {pair}, {if_else(cell == 'lab_ate', 'lab', 'field')} ATE"),
    value_script = NA_real_,
    paper_printed = sprintf("%.1f", value_paper),
    value_rewrite,
    defect_locus = NA_character_,
    notes = "Stipulated premise of the paper's illustration, not an estimate; the deposited script types the same value but prints only the Table 2 regression"
  )

# Everything else ----
# claim_id ties a row to ground_truth/published_claims.csv, which is the
# extraction of every numeric token in the article. It is NA where a row records
# something the article does not state, such as the deposit's own copy of Online
# Appendix Table 1 or the evidence behind a qualitative claim.
gt <- bind_rows(
  table_1_rows,
  tribble(
    ~claim_id, ~table_figure, ~claim, ~value_script, ~paper_printed, ~value_rewrite, ~defect_locus, ~notes,

    "t2_subjects_a", "Table 2", "Subjects (A)", 2, "2.00",
      t2$ols[t2$term == "Subjects (A)"], NA, "",
    "t2_treatments_t1", "Table 2", "Treatments (T1)", 1, "1.00",
      t2$ols[t2$term == "Treatments (T1)"], NA, "",
    "t2_outcomes_effort", "Table 2", "Outcomes (Effort)", 1, "1.00",
      t2$ols[t2$term == "Outcomes (Effort)"], NA, "",
    "t2_contexts_field", "Table 2", "Contexts (Field)", 1, "1.00",
      t2$ols[t2$term == "Contexts (Field)"], NA, "",
    "t2_constant", "Table 2", "Constant", -0.9375, "-0.94",
      t2$ols[t2$term == "Constant"], NA, "",

    "t2_text_subjects", "Text, p. 120", "Units A-type subjects add, quoted into prose",
      2, "2", t2$ols[t2$term == "Subjects (A)"], NA,
      "The Table 2 coefficient restated in the text at whole units",
    "t2_text_treatments", "Text, p. 120", "Units treatment T1 adds, quoted into prose",
      1, "1", t2$ols[t2$term == "Treatments (T1)"], NA,
      "The Table 2 coefficient restated in the text at whole units",
    "t2_text_outcomes", "Text, p. 120", "Units the effort outcome adds, quoted into prose",
      1, "1", t2$ols[t2$term == "Outcomes (Effort)"], NA,
      "The Table 2 coefficient restated in the text at whole units",
    "t2_text_contexts", "Text, p. 120", "Units the field context adds, quoted into prose",
      1, "1", t2$ols[t2$term == "Contexts (Field)"], NA,
      "The Table 2 coefficient restated in the text at whole units",

    "t3_pairs", "Table 3", "Parallel lab-field study pairs", 12, "12", 12, NA,
      "Table 3 lists the twelve pairs by name and states no other quantity",

    "text_hypothetical_corr", "Text, p. 120", "Correlation across the eight hypothetical pairs",
      NA, "0.14", pick(hypothetical, "all 8 pairs"), NA,
      "No deposited script computes this; the rewrite adds text_hypothetical_correlations.R",
    "text_hypothetical_corr_restated", "Text, p. 121",
      "Correlation across the eight hypothetical pairs, restated a page later",
      NA, "0.14", pick(hypothetical, "all 8 pairs"), NA,
      "The same quantity as the row above, stated twice a page apart",
    "text_hypothetical_corr_reported", "Text, p. 121", "Correlation when Pairs 1 and 5 go unreported",
      NA, "0.76", pick(hypothetical, "Pairs 1 and 5 unreported"), NA,
      "No deposited script computes this; the rewrite adds text_hypothetical_correlations.R",

    "fig1_jerit_pearson", "Figure 1", "Jerit panel, Pearson correlation", 0.2110548191, "0.21",
      pick(f1, "Pearson"), NA,
      "The deposited script prints this value and then types it into the figure legend by hand",
    "fig1_jerit_spearman", "Figure 1", "Jerit panel, Spearman correlation", 0.2599631182, "0.26",
      pick(f1, "Spearman"), NA,
      "The deposited script prints this value and then types it into the figure legend by hand",

    "fig2_points", "Figure 2", "Pooled treatment effect pairs", 21, "21",
      pick(f2, "^pooled treatment effect pairs$"), NA, "",
    "fig2_rho", "Figure 2", "Rank-order correlation printed on the figure", 0.7275089698, "0.73",
      pick(f2, "^pooled Spearman rho"), NA,
      "The rewrite corrects the Gneezy and Rustichini (2004) female standardization; unchanged at the two decimal places the figure prints",
    "results_fig2_rho", "Text, p. 125", "Rank-order correlation in the sentence describing Figure 2",
      0.7275089698, "0.73", pick(f2, "^pooled Spearman rho"), NA,
      "The same quantity as the figure, stated in the text beside it",

    "abstract_spearman", "Abstract", "Rank-order correlation", 0.7275089698, "0.73",
      pick(f2, "^pooled Spearman rho"), NA, "The same quantity as Figure 2",
    "intro_spearman", "Introduction", "Rank-order correlation", 0.7275089698, "0.73",
      pick(f2, "^pooled Spearman rho"), NA,
      "The same quantity as the abstract, restated in the introduction",

    "fn5_all17_pairs", "Footnote 5", "Jerit candidate pairs", 17, "17",
      pick(jerit, "^Jerit candidates$"), NA, "",
    "fn5_min", "Footnote 5", "Lowest pooled rho across the candidates", 0.6995778219, "0.699",
      pick(jerit, "^minimum"), "archive",
      "The footnote truncates rather than rounds: the deposited script prints 0.6995778, which rounds to 0.700 at the three decimals the footnote uses. The rewrite's value moves further because the Gneezy and Rustichini (2004) female standardization correction shifts every pooled correlation",
    "fn5_max", "Footnote 5", "Highest pooled rho across the candidates", 0.7619357336, "0.762",
      pick(jerit, "^maximum"), "archive",
      "The Gneezy and Rustichini (2004) female standardization correction shifts every pooled correlation",
    "fn5_all17_rho", "Footnote 5", "Pooled rho including all 17 Jerit pairs", NA, "0.56",
      pick(jerit, "^pooled rho including all 17"), NA,
      "No deposited script computes this; the rewrite adds text_jerit_sensitivity.R",

    "fn6_sampled_combinations", "Footnote 6", "Combinations sampled where more than 50,000 exist",
      50000, "50000", max(f3$n_evaluated), NA, "",
    "fn6_cap_threshold", "Footnote 6", "Smallest number of dropped pairs at which the cap binds",
      NA, "7", n_pairs - max(f3$n_used[f3$n_used < n_pairs & f3$n_evaluated < f3$n_combinations]),
      "paper_internal",
      "The footnote says the 50,000 cap applied when more than any six pairs were dropped, which puts the smallest sampled case at seven. Dropping six leaves 54,264 combinations, so the cap already binds there, in the deposited code as well as in the rewrite",

    NA, "Figure 3", "Lowest 25th percentile across the combination sizes",
      min(sampler$rounding_sampler[sampler$statistic == "1st Qu."]), NA,
      min(f3$q25), NA,
      "Evidence for the interquartile band the article states in the text; the figure itself prints no numbers",
    NA, "Figure 3", "Highest 75th percentile across the combination sizes",
      max(sampler$rounding_sampler[sampler$statistic == "3rd Qu."]), NA,
      max(f3$q75), NA,
      "Evidence for the interquartile band the article states in the text; the figure itself prints no numbers",
    "results_iqr_band", "Figure 3", "Interquartile range stays within 0.6 to 0.8 across every combination size",
      as.numeric(min(sampler$rounding_sampler[sampler$statistic == "1st Qu."]) >= 0.6 &
                 max(sampler$rounding_sampler[sampler$statistic == "3rd Qu."]) <= 0.8),
      "1",
      as.numeric(min(f3$q25) >= 0.6 & max(f3$q75) <= 0.8), NA,
      "The article states that the interquartile range stays within the narrow band of about 0.6 to 0.8; 1 records that it does",
    "results_min_crosses_zero", "Figure 3", "Minimum correlation crosses zero when any ten pairs are dropped",
      as.numeric(min(sampler$rounding_sampler[sampler$statistic == "Min." &
                                              sampler$n_used == 11]) < 0),
      "1",
      as.numeric(f3$minimum[f3$n_used == 11] < 0), NA,
      "The article states that the minimum correlation crosses zero in the case of dropping any ten pairs; 1 records that it does",
    "results_max_reaches_one", "Figure 3", "Highest correlation when any ten pairs are dropped",
      max(sampler$rounding_sampler[sampler$statistic == "Max." & sampler$n_used == 11]),
      "1", max(f3$maximum[f3$n_used == 11]), NA,
      "The article says the maximum reaches one, which is a rough magnitude rather than a value, so this row records both numbers and returns no verdict",
    "results_median_constant", "Figure 3", "Distinct values of the median correlation, to two decimal places",
      n_distinct(round(sampler$rounding_sampler[sampler$statistic == "Median"], 2)),
      "1", n_distinct(round(f3$median, 2)), "paper_internal",
      "The text says the median correlation stays constant across all permutations, which implies one value. It is not constant in either run: the deposited procedure's median runs from 0.720 to 0.729 and the rewrite's from 0.719 to 0.739",
    "fig3_note_all_combinations", "Figure 3", "Every available combination is evaluated",
      NA, "1",
      as.numeric(all(f3$n_evaluated[f3$n_used != n_pairs] ==
                     f3$n_combinations[f3$n_used != n_pairs])),
      "paper_internal",
      "The Figure 3 note says the correlations are calculated under all possible combinations; footnote 6 says 50,000 are sampled wherever more exist, and 555,790 of the 2,097,150 available combinations were evaluated",
    NA, "Figure 3", "Largest change in a plotted summary value under the R 3.6 sampler",
      max(abs(sampler$difference)), NA, NA, NA,
      "A property of the environment rather than of either analysis; see text_sampler_reproducibility.csv",

    "disc_median_lab_n", "Discussion", "Median lab sample size per treatment condition", NA, "40",
      sample_sizes$median_n[sample_sizes$context == "lab"], NA,
      "No deposited script computes this; the rewrite adds text_median_sample_sizes.R",
    "disc_median_field_n", "Discussion", "Median field sample size per treatment condition", NA, "37.5",
      sample_sizes$median_n[sample_sizes$context == "field"], NA,
      "No deposited script computes this; the rewrite adds text_median_sample_sizes.R",
    "disc_raw_pearson", "Discussion", "Raw Pearson correlation across the 21 pairs", 0.642813994, "0.64",
      pick(disattenuation, "^raw Pearson"), "archive",
      "The Gneezy and Rustichini (2004) female standardization correction raises the pooled Pearson correlation",
    "disc_lab_reliability", "Discussion", "Lab reliability", 0.7833397739, "0.78",
      pick(disattenuation, "^lab reliability$"), "paper_internal",
      "Footnote 7 defines the reliability as the square of the correlation between two draws; Spearman's correction takes the correlation itself",
    "disc_field_reliability", "Discussion", "Field reliability", 0.8239761387, "0.82",
      pick(disattenuation, "^field reliability$"), "paper_internal",
      "The same definitional correction, compounded by the List (2006) field standard error the deposited script reads from the lab vector",
    "disc_disatt_numerator", "Discussion", "Raw Pearson correlation restated inside the disattenuation formula",
      0.642813994, "0.64", pick(disattenuation, "^raw Pearson"), "archive",
      "The same quantity as the preceding sentence, restated inside the formula",
    "disc_disatt_lab", "Discussion", "Lab reliability restated inside the disattenuation formula",
      0.7833397739, "0.78", pick(disattenuation, "^lab reliability$"), "paper_internal",
      "The same quantity as the preceding sentence, restated inside the formula",
    "disc_disatt_field", "Discussion", "Field reliability restated inside the disattenuation formula",
      0.8239761387, "0.82", pick(disattenuation, "^field reliability$"), "paper_internal",
      "The same quantity as the preceding sentence, restated inside the formula",
    "disc_disattenuated", "Discussion", "Disattenuated correlation", 0.8001159278, "0.80",
      pick(disattenuation, "^disattenuated correlation$"), "paper_internal",
      "Follows from the reliability definition and the two standardization corrections",

    NA, "Footnote 7", "Lab reliability under the published definition", 0.7833397739, "0.78",
      pick(disattenuation, "^lab reliability, squared"), NA,
      "The rewrite also reports the published definition, so the correction can be traced",
    NA, "Footnote 7", "Field reliability under the published definition", 0.8239761387, "0.82",
      pick(disattenuation, "^field reliability, squared"), NA,
      "The rewrite also reports the published definition, so the correction can be traced",
    NA, "Footnote 7", "Disattenuated correlation under the published definition", 0.8001159278, NA,
      pick(disattenuation, "^disattenuated correlation, squared"), NA,
      "Keeping footnote 7's squared reliability and fixing only the two indexing errors gives 0.81 rather than the published 0.80, because both raise the raw Pearson correlation. This row carries no value_paper: the article prints 0.80 once, and disc_disattenuated is the row that compares against it. Two rows holding the same published number both took an adverse verdict, so the same defect was counted twice and this one, having no claim_id, could not be cited by the entry that corrects it",

    NA, "Online Appendix Table 1", "Treatment condition rows",
      pick(appendix, "treatment condition rows"), NA,
      pick(appendix, "treatment condition rows"), NA,
      "The published appendix is the bibliography of studies considered for inclusion and does not contain this table, so its cells have no published counterpart; the rewrite is checked against meanstable.csv, the deposit's own copy of the table",
    NA, "Online Appendix Table 1", "Cells agreeing with the deposited meanstable.csv",
      pick(appendix, "cells compared"), NA,
      pick(appendix, "cells agreeing"), NA,
      "All 32 rows by 6 columns agree exactly",

    NA, "Online Appendix Table 2", "Descriptions of the twelve study pairs", NA, NA, NA, NA,
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

# A claim naming a rough magnitude gets no verdict, and needs its own precision,
# because formatting it to the page's precision destroys the evidence: a maximum
# of 0.98 printed to a page that says "one" reads as agreement.
approximate_precision <- c(results_max_reaches_one = 2L)

gt <- gt |>
  mutate(
    paper_id = "coppock_green_2015",
    claim_id = as.character(claim_id),
    claim = as.character(claim),
    approximate = claim_id %in% names(approximate_precision),
    match = if_else(approximate, NA_real_, agrees(value_script, paper_printed)),
    match_rewrite = if_else(approximate, NA_real_, agrees(value_rewrite, paper_printed)),
    # value_paper is committed as the string the article prints, not as a double.
    # Stored numerically it would come back as 0.8 where the article printed 0.80,
    # and the printed precision is the only typographic fact any comparison here
    # depends on.
    value_paper = paper_printed,
    defect_locus = if_else(match_rewrite == 0 & !is.na(match_rewrite),
                           replace_na(defect_locus, "unresolved"), NA_character_)
  )

stopifnot(all(!is.na(gt$defect_locus[!is.na(gt$match_rewrite) & gt$match_rewrite == 0])))

# Coverage, checked against the extraction and against the second instrument ----
# published_claims.csv is the hand-reviewed extraction of every numeric token in
# the article and the published appendix. value_paper is forced to character in
# every reader, here included: a column whose entries all look numeric is guessed
# as double, and that silently turns the article's 0.020 into 0.02 and destroys the
# printed precision the comparison depends on.
claims <- read_csv(here::here("ground_truth", "published_claims.csv"),
                   col_types = cols(.default = col_character(),
                                    value_paper = col_character())) |>
  mutate(needs_block = needs_block == "TRUE")

stopifnot(!any(duplicated(claims$claim_id)))

# Every pipeline and descriptive claim needs a ground-truth row, and every
# ground-truth claim_id must name a claim the article actually makes.
required_rows <- claims$claim_id[claims$claim_type %in% c("pipeline", "descriptive")]
missing_gt_rows <- setdiff(required_rows, gt$claim_id)
unknown_gt_ids <- setdiff(na.omit(gt$claim_id), claims$claim_id)
stopifnot(length(missing_gt_rows) == 0, length(unknown_gt_ids) == 0,
          !any(duplicated(na.omit(gt$claim_id))))

# Errata spine gate ----
# Every claim id an errata entry names has to exist here. A missing one is a typo or a
# claim that has since been renamed, and a published correction pointing at a row that is
# not in the table is a dangling reference the build should refuse to carry.
#
# The rule runs in BOTH directions, and only the forward one was ever run. Added
# 2026-08-19: an entry may not correct a claim that reproduces as published, and a
# difference the article is at fault for has to be accounted for by an entry.
errata_spine <- read_csv(here::here("errata_entries.csv"), show_col_types = FALSE,
                         col_types = cols(.default = col_character()))

spine_ids <- function(rows) {
  ids <- rows$claim_ids |> str_split(";") |> unlist() |> str_trim()
  ids[!is.na(ids) & ids != ""]
}

cited_claim_ids <- spine_ids(errata_spine)
published_corrections <- spine_ids(filter(errata_spine, class == "quantity"))

if (length(setdiff(cited_claim_ids, gt$claim_id)) > 0) {
  print(setdiff(cited_claim_ids, gt$claim_id))
}
stopifnot(length(setdiff(cited_claim_ids, gt$claim_id)) == 0)

# Every quantity the note corrects has to be a quantity that differs. in_text_claims.R
# asserts the same property from the other side, on the value it computes itself; this
# asserts it on the value recorded here, which is reached by a different path.
uncorrected <- gt |> filter(claim_id %in% published_corrections, match_rewrite != 0)
if (nrow(uncorrected) > 0) {
  print(uncorrected |> select(claim_id, claim, value_paper, value_rewrite, match_rewrite),
        n = nrow(uncorrected))
  stop("The errata note corrects claims that reproduce as published.")
}

# And every difference the article is at fault for has to be one an entry accounts for.
# defect_locus is read because a difference whose fault lies with the deposit or the
# environment is not something an erratum about the article could report.
unpublished <- gt |>
  filter(!is.na(claim_id), defect_locus == "paper_internal",
         (!is.na(match_rewrite) & match_rewrite == 0) | (!is.na(match) & match == 0),
         !claim_id %in% cited_claim_ids)
if (nrow(unpublished) > 0) {
  print(unpublished |> select(claim_id, table_figure, claim, value_paper, value_rewrite),
        n = nrow(unpublished))
  stop("Claims differ from the article through the article's own fault and no errata entry says so.")
}

# The second instrument is read as a program, not as text: a block that errors at
# runtime, or that ends in a bare expression and therefore prints nothing under
# source(), would satisfy any check that merely looked for its claim id in the file.
claims_log <- capture.output(
  source(here::here("maintained", "in_text_claims.R"), local = new.env())
)

printed <- str_match(claims_log, "^CLAIM (\\S+) = (\\S+) \\|\\| \\[(\\w+)\\] (.*)$")
printed <- tibble(claim_id = printed[, 2], printed_value = printed[, 3],
                  verdict = printed[, 4], label = printed[, 5]) |>
  filter(!is.na(claim_id))

# Every claim the second instrument ASSERTS has to be one this script also compared, and
# every claim it declines to assert has to be one this script can explain. The check is
# made at this grain rather than verdict by verdict because this builder carries an
# `approximate` flag where `coppock_green_2022` carries `comparable` plus a stochastic
# list, so the two vocabularies do not line up one to one. The claims file names five
# reasons for declining; this script has to have at least one for each.
unexplained_verdicts <- printed |>
  filter(!verdict %in% c("match", "corrected")) |>
  inner_join(select(gt, claim_id, value_paper, match_rewrite, approximate), by = "claim_id") |>
  filter(!approximate, !is.na(value_paper), !is.na(match_rewrite),
         !claim_id %in% cited_claim_ids)
if (nrow(unexplained_verdicts) > 0) {
  print(unexplained_verdicts, n = Inf, width = 200)
  stop("Claims the second instrument declines to assert are compared here with no exemption.")
}
stopifnot(all(printed$verdict %in% c("match", "corrected", "range", "derived", "absent",
                                     "hedged", "shape")))

declared <- claims$claim_id[claims$needs_block]
stopifnot(
  !any(duplicated(printed$claim_id)),
  nrow(printed) == length(declared),
  length(setdiff(declared, printed$claim_id)) == 0,
  length(setdiff(printed$claim_id, declared)) == 0
)

# Two instruments, compared value by value. build_ground_truth.R and
# in_text_claims.R reach each number by separate paths from the same outputs, so a
# disagreement between them is a finding in its own right.
cross_check <- printed |>
  inner_join(gt |> select(claim_id, paper_printed, value_rewrite, approximate),
             by = "claim_id") |>
  mutate(
    digits = if_else(approximate,
                     approximate_precision[claim_id],
                     printed_decimals(paper_printed)),
    gt_printed = if_else(is.na(value_rewrite), "NA",
                         sprintf(paste0("%.", digits, "f"), value_rewrite)),
    agrees = printed_value == gt_printed
  )

if (any(!cross_check$agrees)) print(cross_check |> filter(!agrees), n = Inf, width = 200)
stopifnot(length(setdiff(required_rows, cross_check$claim_id)) == 0,
          all(cross_check$agrees))

# Claim type, printed precision and location, carried from the extraction ----
# Every claim id here names an extraction row, so a row with one takes its claim type,
# its digits and its location from published_claims.csv. A row without one records
# something the article does not state as a number, and is a pipeline quantity whose
# precision is read off the string the article prints. The one digits override this
# script carries, for the approximate claim, has to be the one the extraction carries.
gt <- gt |>
  left_join(select(claims, claim_id, claim_type, digits, location), by = "claim_id") |>
  mutate(digits = as.integer(digits))

override_check <- tibble(claim_id = names(approximate_precision),
                         override = unname(approximate_precision)) |>
  left_join(select(gt, claim_id, digits), by = "claim_id")
if (any(override_check$override != override_check$digits)) {
  print(override_check)
  stop("A digits override in this script disagrees with the extraction.")
}

gt <- gt |>
  mutate(
    location = if_else(is.na(claim_id), table_figure, location),
    claim_type = if_else(is.na(claim_id), "pipeline", claim_type),
    digits = if_else(is.na(claim_id), excheckr::claim_digits(value_paper), digits)
  )

stopifnot(!anyNA(gt$location), !anyNA(gt$claim_type))

# Disposition: what became of each defect ----
# corrected_here is computed from the errata spine and never typed. Every row this
# repository attributes to a defect is named by an errata entry, so no judgment is
# recorded by hand; a row that is not stays NA until someone decides what became of it.
gt <- gt |>
  mutate(
    disposition = case_when(
      is.na(defect_locus) ~ NA_character_,
      !is.na(claim_id) & claim_id %in% cited_claim_ids ~ "corrected_here",
      .default = NA_character_
    ),
    disposition_reason = NA_character_
  )

undisposed <- gt |> filter(defect_locus == "paper_internal", is.na(disposition))
if (nrow(undisposed) > 0) {
  print(undisposed |> select(claim_id, location, claim), n = nrow(undisposed))
  stop(str_glue("{nrow(undisposed)} paper_internal rows carry no disposition."))
}
print(gt |> filter(!is.na(defect_locus)) |> count(defect_locus, disposition))

# Float coverage ----
# One row per published float. A table's published_numbers counts the cells it prints,
# as transcribed above; a figure's counts the numbers printed on its face, and its
# plotted count is what the article draws, read from the extraction's structural claims
# about the figure. A plotted quantity counts as reproduced when the second instrument
# scores the claim that counts it a match. The online appendix tables the text cites
# are not floats here, because the published appendix does not contain them.
face_cells <- tribble(
  ~float, ~pattern,
  "Table 1", "^t1_pair[0-9]+_(lab|field)$",
  "Table 2", "^t2_(subjects_a|treatments_t1|outcomes_effort|contexts_field|constant)$",
  "Figure 1", "^fig1_jerit_(pearson|spearman)$",
  "Figure 2", "^fig2_rho$"
)

cell_counts <- face_cells |>
  mutate(rows = map(pattern, \(p) filter(gt, str_detect(replace_na(claim_id, ""), p)))) |>
  transmute(
    float,
    published_numbers = map_int(rows, nrow),
    covered = map_int(rows, \(r) sum(!is.na(r$value_paper) & !is.na(r$value_rewrite))),
    reproduced_by_rewrite = map_int(rows, \(r) sum(r$match_rewrite == 1, na.rm = TRUE)),
    reproduced_by_archive = map_int(rows, \(r) {
      if (all(is.na(r$match))) NA_integer_ else sum(r$match == 1, na.rm = TRUE)
    })
  )

# What each figure draws, as products of the extraction's counts: Figure 1 a point per
# group mean or treatment effect in each of its twelve panels, Figure 2 a point per
# pooled pair, Figure 3 five summary series across its x-axis categories.
plotted_claims <- tribble(
  ~float, ~pattern,
  "Figure 1", "^fig1_points_",
  "Figure 2", "^fig2_points$",
  "Figure 3", "^fig3_(series|x_categories)$"
)

plotted_counts <- plotted_claims |>
  mutate(
    rows = map(pattern, \(p) {
      filter(claims, str_detect(claim_id, p)) |>
        left_join(select(printed, claim_id, verdict), by = "claim_id")
    }),
    terms = map(rows, \(r) as.integer(r$value_paper)),
    plotted = if_else(float == "Figure 3", map_int(terms, prod), map_int(terms, sum)),
    plotted_reproduced = pmap_int(list(float, rows, plotted), \(f, r, n) {
      if (f == "Figure 3") {
        if (all(r$verdict == "match")) n else 0L
      } else {
        sum(as.integer(r$value_paper[r$verdict == "match"]))
      }
    })
  ) |>
  select(float, plotted, plotted_reproduced)

float_notes <- c(
  "Table 3" = "Lists the twelve study pairs by name and purpose; prints no numbers.",
  "Figure 1" = "Prints the Pearson and Spearman correlations inside the Jerit, Barabas and Clifford panel; plotted counts the points across the twelve panels.",
  "Figure 2" = "Prints the pooled rank-order correlation on its face; plotted counts the 21 standardized pairs.",
  "Figure 3" = "Prints no numbers; plotted counts five summary series across 21 subset sizes. The sampled sizes cannot match the deposit draw for draw, for the reasons text_sampler_reproducibility.R measures."
)

float_coverage <- tibble(float = c("Table 1", "Table 2", "Table 3",
                                   "Figure 1", "Figure 2", "Figure 3")) |>
  left_join(cell_counts, by = "float") |>
  left_join(plotted_counts, by = "float") |>
  mutate(
    published_numbers = replace_na(published_numbers, 0L),
    covered = replace_na(covered, 0L),
    reproduced_by_rewrite = replace_na(reproduced_by_rewrite, 0L),
    reproduced_by_archive = if_else(float %in% cell_counts$float, reproduced_by_archive, 0L),
    note = unname(float_notes[float])
  ) |>
  select(float, published_numbers, covered, reproduced_by_rewrite, reproduced_by_archive,
         plotted, plotted_reproduced, note)

stopifnot(
  all(float_coverage$covered == float_coverage$published_numbers),
  all(is.na(float_coverage$plotted[str_starts(float_coverage$float, "Table")])),
  !anyNA(float_coverage$plotted[str_starts(float_coverage$float, "Figure")])
)

write_csv(float_coverage, here::here("ground_truth", "float_coverage.csv"))
print(float_coverage, n = nrow(float_coverage), width = 200)

# The ground truth, in the canonical column order ----
# holds is NA throughout: every claim with a truth value here is scored as a 0 or 1
# indicator against the article's 1, so its verdict is already in match and match_rewrite.
gt <- gt |>
  mutate(across(c(match, match_rewrite), as.logical), holds = NA) |>
  select(paper_id, claim_id, location, claim_type, claim, value_paper, digits,
         value_script, match, value_rewrite, match_rewrite, holds, defect_locus,
         disposition, disposition_reason, notes)

write_csv(gt, here::here("ground_truth", "coppock_green_2015_ground_truth.csv"))

print(gt |> select(claim_id, location, claim, value_script, value_paper, match,
                   value_rewrite, match_rewrite, defect_locus, disposition),
      n = nrow(gt), width = 200)
print(tibble(
  quantity = c("rows", "archive comparable", "archive matching",
               "rewrite comparable", "rewrite matching", "rewrite differing",
               "extraction rows", "extraction rows needing a block",
               "claims printed by in_text_claims.R",
               "claims compared across the two instruments"),
  value = c(nrow(gt), sum(!is.na(gt$match)), sum(gt$match == 1, na.rm = TRUE),
            sum(!is.na(gt$match_rewrite)), sum(gt$match_rewrite == 1, na.rm = TRUE),
            sum(gt$match_rewrite == 0, na.rm = TRUE),
            nrow(claims), length(declared), nrow(printed), nrow(cross_check))
))
