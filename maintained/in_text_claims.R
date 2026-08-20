# coppock_green_2015/maintained/in_text_claims.R
# Output: printed CLAIM lines only; no files
# Depends on: maintained/output/, maintained/data/, helpers.R
# Description: One block per numeric claim the published article makes, each
#   carrying the article's own sentence verbatim and then recomputing the number
#   from the pipeline's committed output. This is the second instrument: it never
#   reads ground_truth/coppock_green_2015_ground_truth.csv, it never refits a
#   model, and it reaches every quantity by its own path, so where it and
#   build_ground_truth.R disagree one of them is wrong.
#
#   Every block prints a line of the form
#
#       CLAIM <claim_id> = <value> || <label>
#
#   which is what build_ground_truth.R parses to check coverage against
#   ground_truth/published_claims.csv. The value is printed at the precision the
#   article prints, so it can be read against the page without re-rounding.
#
#   Two transcription conventions. The published PDF has no text layer for its
#   mathematical symbols, so the quotes below write Spearman's rho as "rho", the
#   multiplication sign as "x" and the binomial coefficient as "(21 choose 11)".
#   Quotes are the sentences the article prints today, however wrong; where a
#   sentence is wrong that is recorded in the ground truth and in the errata,
#   never by editing the quote.

source(here::here("maintained", "helpers.R"))
library(excheckr)

options(width = 200)

out <- function(f) read_csv(here::here("maintained", "output", f), show_col_types = FALSE)

t1 <- out("table_1_hypothetical_ates.csv")
t2 <- out("table_2_meta_regression.csv")
f1 <- out("figure_1_twelve_tiles.csv")
f1_notes <- out("figure_1_twelve_tiles_annotations.csv")
f2 <- out("figure_2_standardized_tes.csv")
f2_notes <- out("figure_2_standardized_tes_annotations.csv")
f3 <- out("figure_3_robustness.csv")
hypothetical <- out("text_hypothetical_correlations.csv")
jerit <- out("text_jerit_sensitivity.csv")
sample_sizes <- out("text_median_sample_sizes.csv")
disattenuation <- out("text_disattenuation.csv")
appendix <- out("text_appendix_table_check.csv")

groups <- read_rds(here::here("maintained", "data", "labfield_groups.rds"))

# The extraction and the errata spine, which between them state what to expect of every
# claim. Every column is read as character: corrected_values carries "0.30" and a reader
# left to guess would return 0.3 and destroy the precision the comparison depends on.
published <- read_csv(here::here("ground_truth", "published_claims.csv"),
                      col_types = cols(.default = col_character()))

errata <- read_csv(here::here("errata_entries.csv"),
                   col_types = cols(.default = col_character()))

# The scoring machinery comes from excheckr, which carries the verdict ladder, the
# typography parser and the four gates this file used to define for itself. What is
# passed here is what the package cannot know: the extraction, the errata spine, and
# the printed form. format = "id" is the CLAIM <id> = <value> || [verdict] <label>
# line build_ground_truth.R parses, and it must stay exactly that.
#
# The expectation is still derived, never typed at a call site. claim_start() reads it
# out of the two frames below, so every claim() call names a number and nothing else:
# published_claims.csv says what the article prints, errata_entries.csv says which of
# those a published note corrects and to what. An entry of any class other than
# quantity corrects a word, a label or a cross-reference and leaves every number where
# the article put it, so a claim it names is still expected to reproduce.
claim_start(published = published, errata = errata, format = "id")

# one: pull a single value out of an output file by a pattern that has to identify
# it uniquely. The assertion is what stops a widened output file from turning a
# scalar into a vector and a claim into a silently empty line.
one <- function(d, pattern) {
  hits <- d$value[str_detect(d$quantity, pattern)]
  stopifnot(length(hits) == 1, !is.na(hits))
  hits
}

study_pairs <- n_distinct(f1$study)
pooled_pairs <- nrow(f2)
pooled_rho <- one(f2_notes, "^pooled Spearman rho")

# Abstract ----

# "Using a standardized format that calls attention to both the experimental
#  estimates and the statistical uncertainty surrounding them, the study analyzes
#  the overall pattern of lab-field correspondence, which is found to be quite
#  strong (Spearman's rho = 0.73)."
claim("abstract_spearman", pooled_rho,
      "pooled Spearman rank-order correlation across the 21 standardized lab-field pairs", digits = 2)

# Introduction ----

# Footnote 1: "Two of these studies are included in our set of 12, but the
#  remaining four failed to meet our inclusion criteria."
claim("fn1_study_pairs", study_pairs,
      "lab-field study pairs the article analyzes", digits = 0)

# "Our statistical results reveal a surprisingly high degree of correspondence
#  (Spearman's rho = 0.73) that is robust to the inclusion or exclusion of
#  particular studies."
claim("intro_spearman", pooled_rho,
      "the same pooled rank-order correlation, restated in the introduction", digits = 2)

# "We begin by describing and formalizing four key dimensions along which
#  experiments may vary."
claim("intro_key_dimensions", sum(t2$term != "Constant"),
      "design dimensions carried as predictors in the Table 2 meta-regression", digits = 0)

# Hypotheses about correspondence ----

# "Consider a research scenario in which there are two subject types (A and B),
#  two variants of the treatment (T1 and T2), two outcome measures (money and
#  effort) and two contexts (lab and field). Varying each dimension while holding
#  the others constant yields a set of 16 hypothetical experiments."
claim("theory_subject_types", n_distinct(t1$subjects),
      "distinct subject types in the hypothetical design", digits = 0)
claim("theory_treatment_variants", n_distinct(t1$treatments),
      "distinct treatment variants in the hypothetical design", digits = 0)
claim("theory_outcome_measures", n_distinct(t1$outcomes),
      "distinct outcome measures in the hypothetical design", digits = 0)
claim("theory_contexts", sum(c("lab_ate", "field_ate") %in% names(t1)),
      "distinct contexts in the hypothetical design", digits = 0)
claim("theory_hypothetical_experiments", nrow(t1) * 2,
      "hypothetical experiments: one lab and one field ATE for each row of Table 1", digits = 0)

# Table 1 title: "Average Treatment Effects in 16 Hypothetical Experiments"
claim("t1_title_experiments", nrow(t1) * 2,
      "hypothetical experiments named in the Table 1 title", digits = 0)

# "Within both lab and field, subjects, treatments and outcome measures can be
#  combined in eight unique arrangements. Each row of the table displays a
#  lab-field pair that holds these other experimental features constant."
claim("theory_unique_arrangements", nrow(t1),
      "unique arrangements of subjects, treatments and outcomes, one per Table 1 row", digits = 0)

# Table 1, the sixteen stipulated average treatment effects. These are the
# article's premises rather than estimates of anything, so what a block can check
# is that the pipeline carries the values Table 1 prints and that everything
# downstream reads them from one place.
for (i in seq_len(nrow(t1))) {
  claim(str_glue("t1_pair{t1$pair[i]}_lab"), t1$lab_ate[i],
        str_glue("Table 1, Pair {t1$pair[i]}, stipulated lab ATE"), digits = 1)
  claim(str_glue("t1_pair{t1$pair[i]}_field"), t1$field_ate[i],
        str_glue("Table 1, Pair {t1$pair[i]}, stipulated field ATE"), digits = 1)
}

# "The correlation between treatment effects in the lab and field serves as a
#  summary measure of correspondence. In this example, the correlation is weakly
#  positive (0.14)."
claim("text_hypothetical_corr", one(hypothetical, "all 8 pairs"),
      "Pearson correlation between the lab and field columns of Table 1", digits = 2)

# Table 2, "Meta-analytic Regression Predicting ATEs", which regresses the 16
# hypothetical effects on the four features that generated them.
claim("t2_subjects_a", t2$ols[t2$term == "Subjects (A)"],
      "Table 2, coefficient on Subjects (A)", digits = 2)
claim("t2_treatments_t1", t2$ols[t2$term == "Treatments (T1)"],
      "Table 2, coefficient on Treatments (T1)", digits = 2)
claim("t2_outcomes_effort", t2$ols[t2$term == "Outcomes (Effort)"],
      "Table 2, coefficient on Outcomes (Effort)", digits = 2)
claim("t2_contexts_field", t2$ols[t2$term == "Contexts (Field)"],
      "Table 2, coefficient on Contexts (Field)", digits = 2)
claim("t2_constant", t2$ols[t2$term == "Constant"],
      "Table 2, constant", digits = 2)

# "On average, treatment effects are two units higher when A-type subjects are
#  used, one unit higher when treatment T1 is employed, one unit higher when
#  effort is the outcome variable and one unit higher in the field as opposed to
#  the lab."
#
# The same four coefficients as above, quoted from the table into prose at whole
# units. They are printed here again from the same source so that a divergence
# between the table and the sentence would show as two different claim lines.
claim("t2_text_subjects", t2$ols[t2$term == "Subjects (A)"],
      "units by which A-type subjects raise the ATE, as stated in the text", digits = 0)
claim("t2_text_treatments", t2$ols[t2$term == "Treatments (T1)"],
      "units by which treatment T1 raises the ATE, as stated in the text", digits = 0)
claim("t2_text_outcomes", t2$ols[t2$term == "Outcomes (Effort)"],
      "units by which the effort outcome raises the ATE, as stated in the text", digits = 0)
claim("t2_text_contexts", t2$ols[t2$term == "Contexts (Field)"],
      "units by which the field context raises the ATE, as stated in the text", digits = 0)

# "Stated differently, the reader must decide if a lab-field pair looks more like
#  Row 3 of Table 1 (3, 3) or more like a combination of the lab estimate from
#  Row 1 and the field estimate from Row 8 (2, 2)."
claim("text_row3_lab", t1$lab_ate[t1$pair == 3],
      "Table 1 Row 3 lab ATE, quoted into the text", digits = 0)
claim("text_row3_field", t1$field_ate[t1$pair == 3],
      "Table 1 Row 3 field ATE, quoted into the text", digits = 0)
claim("text_row1_lab", t1$lab_ate[t1$pair == 1],
      "Table 1 Row 1 lab ATE, quoted into the text", digits = 0)
claim("text_row8_field", t1$field_ate[t1$pair == 8],
      "Table 1 Row 8 field ATE, quoted into the text", digits = 0)

# "Suppose that a researcher conducted all eight pairs of experiments but failed
#  to report Pairs 1 and 5. The overall correlation between lab and field,
#  originally weakly positive (0.14), would appear to be much stronger (0.76)."
#
# The 0.14 is the same quantity as the one stated a page earlier, so both
# statements are printed rather than one, which is the only way a divergence
# between two pages could show up at all.
claim("text_hypothetical_corr_restated", one(hypothetical, "all 8 pairs"),
      "correlation across all eight pairs, restated on the following page", digits = 2)
claim("text_hypothetical_corr_reported", one(hypothetical, "Pairs 1 and 5 unreported"),
      "correlation across the six pairs left when Pairs 1 and 5 go unreported", digits = 2)

# Method ----

# "We whittled this sample of 80 articles down to 12 in three steps:"
claim("method_selected_pairs", study_pairs,
      "study pairs surviving the three inclusion steps", digits = 0)

# "Readers may find it useful to consult Online Appendix Table 2, which includes
#  a detailed description of our 12 study pairs, including the subject pools,
#  treatments, outcome measures and context of each experiment."
claim("method_appendix_table_2_pairs", study_pairs,
      "study pairs Online Appendix Table 2 is said to describe", digits = 0)

# "From these data, we calculated treatment effects and 95 percent confidence
#  intervals using normal approximations."
#
# The deposit stores the interval bounds rather than the level, so the level is
# recovered from the bounds: the narrowest interval in the group data is exactly
# 1.9600 standard errors wide on each side, which is the two-sided normal
# critical value for 95 percent. The wider ones run out to 2.201 standard errors,
# which is what a t interval gives at these group sizes.
half_widths <- (groups$upper - groups$lower) / (2 * groups$se)
claim("method_ci_level", 100 * (2 * pnorm(min(half_widths)) - 1),
      str_glue("confidence level implied by the narrowest deposited interval, ",
               "{sprintf('%.4f', min(half_widths))} standard errors wide; the widest is ",
               "{sprintf('%.3f', max(half_widths))}"), digits = 0)

# "The 12 pairs we selected are displayed in Table 3."
claim("method_table3_pairs", study_pairs,
      "study pairs Table 3 lists", digits = 0)

# Results ----

# "We present the results of these 12 close comparisons in Figure 1. With the
#  exception of the Jerit, Barabas and Clifford study, these graphs present
#  treatment group means and 95 percent confidence intervals."
claim("results_comparisons", study_pairs,
      "close comparisons presented in Figure 1", digits = 0)
claim("results_ci_level", 100 * (2 * pnorm(min(half_widths)) - 1),
      "confidence level of the intervals drawn in Figure 1, recovered from the same bounds", digits = 0)

# "Taken together, these 12 studies demonstrate a reasonably strong correlation
#  between group means in the lab and group means in the field."
claim("results_studies_demonstrate", study_pairs,
      "studies said to demonstrate a reasonably strong correlation", digits = 0)

# "In order to provide some measure of this correlation, we combined the 12
#  studies to form a single dataset."
claim("results_studies_combined", study_pairs,
      "studies combined to form a single dataset", digits = 0)

# Figure 1, "12 Lab-field comparisons". The panels print no values, so what each
# one asserts is the number of points it draws. Eleven panels plot treatment
# group means and the twelfth plots the Jerit, Barabas and Clifford treatment
# effects, one per survey question.
fig1_keys <- tribble(
  ~key, ~study,
  "erev", "Erev, Bornstein, and Galili (1993)",
  "gneezy2000", "Gneezy and Rustichini (2000)",
  "valentino", "Valentino, Traugott, and Hutchings (2002)",
  "gneezy2004", "Gneezy and Rustichini (2004)",
  "bill", "Gneezy, Haruvy, and Yafe (2004)",
  "list", "List (2006)",
  "shang", "Shang, Reed, and Croson (2008)",
  "rondeau", "Rondeau and List (2008)",
  "winners", "Harrison and List (2008)",
  "boly", "Armantier and Boly (2013)",
  "abeler", "Abeler and Marklein (2013)",
  "jerit", "Jerit, Barabas, and Clifford (2013)"
)

for (i in seq_len(nrow(fig1_keys))) {
  points <- sum(f1$study == fig1_keys$study[i])
  stopifnot(points > 0)
  claim(str_glue("fig1_points_{fig1_keys$key[i]}"), points,
        str_glue("points plotted in the Figure 1 panel for {fig1_keys$study[i]}"), digits = 0)
}

# The Jerit, Barabas and Clifford panel of Figure 1 prints two correlations on its
# face: "Pearson Correlation = 0.21" and "Spearman Correlation = 0.26".
claim("fig1_jerit_pearson", one(f1_notes, "Pearson"),
      "Pearson correlation printed inside the Jerit, Barabas and Clifford panel", digits = 2)
claim("fig1_jerit_spearman", one(f1_notes, "Spearman"),
      "Spearman correlation printed inside the Jerit, Barabas and Clifford panel", digits = 2)

# Footnote 5: "When constructing an overall assessment of lab-field
#  correspondence, we included only a single treatment effect pair from the
#  Jerit, Barabas and Clifford study. Which pair we included caused slight changes
#  in the overall correlation, ranging from 0.699 to 0.762."
claim("fn5_all17_pairs", one(jerit, "^Jerit candidates$"),
      "Jerit, Barabas and Clifford treatment effect pairs available for inclusion", digits = 0)
claim("fn5_min", one(jerit, "^minimum"),
      "lowest pooled rank-order correlation across the 17 candidate pairs", digits = 3)
claim("fn5_max", one(jerit, "^maximum"),
      "highest pooled rank-order correlation across the 17 candidate pairs", digits = 3)

# Footnote 5, continued: "We believe that including all 17 pairs gives the Jerit,
#  Barabas and Clifford study too much weight, but doing so reduces the rank-order
#  correlation to 0.56."
claim("fn5_all17_rho", one(jerit, "^pooled rho including all 17"),
      "pooled rank-order correlation when all 17 Jerit pairs are included", digits = 2)

# Table 3, "12 Parallel Lab-Field Study Pairs"
claim("t3_pairs", study_pairs,
      "parallel lab-field study pairs listed in Table 3", digits = 0)

# "Figure 2 shows our results. Treatment effects in the lab and treatment effects
#  in the field show a upward-sloping relationship, with a rank-order correlation
#  of 0.73."
claim("results_fig2_rho", pooled_rho,
      "rank-order correlation stated in the sentence describing Figure 2", digits = 2)

# "As we move rightward from the center of the graph, we take our 21 observed
#  pairs and first duplicate any single pair, then any two pairs, and so on out to
#  any ten pairs."
claim("results_observed_pairs", pooled_pairs,
      "observed lab-field pairs entering the robustness exercise", digits = 0)
claim("results_max_dropped", max(f3$n_used) - pooled_pairs,
      "largest number of pairs removed or duplicated", digits = 0)

# "we label the x-axis as ranging from (21 choose 11) to (21 choose 31)"
claim("results_xaxis_low", min(f3$n_used),
      "smallest number of pairs used, the lower term of the leftmost x-axis label", digits = 0)
claim("results_xaxis_high", max(f3$n_used),
      "largest number of pairs used, the lower term of the rightmost x-axis label", digits = 0)
claim("results_xaxis_centre", pooled_pairs,
      "pairs used at the centre category, where nothing is removed or duplicated", digits = 0)

# "we are appending X combinations to our 21 observed pairs."
claim("results_appended_pairs", pooled_pairs,
      "observed pairs to which the duplicated combinations are appended", digits = 0)

# "On the y-axis of Figure 3, we plot the five-number summary of the set of
#  rank-order correlations."
summary_columns <- c("minimum", "q25", "median", "q75", "maximum")
claim("results_five_number", sum(summary_columns %in% names(f3)),
      "summary statistics plotted for each combination size", digits = 0)

# Footnote 6: "When dropping more than any six pairs, we randomly sampled 50,000
#  of the possible combinations."
#
# The removal side of the exercise keeps 21 - k of the 21 pairs, so the number of
# available combinations at k dropped pairs is 21 choose 21 - k. The cap starts to
# bind at the smallest k where fewer combinations were evaluated than exist.
capped <- f3 |>
  filter(n_used < pooled_pairs, n_evaluated < n_combinations) |>
  filter(n_used == max(n_used))
stopifnot(nrow(capped) == 1)
smallest_capped <- pooled_pairs - capped$n_used
claim("fn6_cap_threshold", smallest_capped,
      str_glue("smallest number of dropped pairs at which the cap binds: dropping ",
               "{smallest_capped} leaves {format(capped$n_combinations, big.mark = ',')} ",
               "combinations, of which {format(capped$n_evaluated, big.mark = ',')} were evaluated"), digits = 0)
claim("fn6_sampled_combinations", max(f3$n_evaluated),
      "combinations evaluated at each capped subset size", digits = 0)

# Figure 2, "Standardized treatment effects across all lab-field pairs", which
# prints one letter per pair and the rank-order correlation in a box.
claim("fig2_points", pooled_pairs,
      "labelled points plotted in Figure 2", digits = 0)
claim("fig2_rho", pooled_rho,
      "rank-order correlation printed on the face of Figure 2", digits = 2)

# Figure 2 note: "each point represents a standardized lab-field treatment effect
#  pair. A = Erev, Bornstein and Galili (1993) and Bornstein, Erev and Rosen
#  (1990); ... L = Jerit, Barabas and Clifford (2013)."
claim("fig2_note_studies", n_distinct(str_remove(f2$point_label, "[0-9]+$")),
      "study letters defined in the Figure 2 note", digits = 0)

# "On the y-axis of Figure 3, we plot the five-number summary of the set of
#  rank-order correlations. Unsurprisingly, the median correlation stays constant
#  across all permutations."
#
# A claim that a series is constant is a claim that it takes one value. It takes
# three at two decimal places, so the individual medians are printed alongside the
# count rather than a verdict.
claim("results_median_constant", n_distinct(round(f3$median, 2)),
      str_glue("distinct values of the median correlation at two decimal places, ",
               "running from {sprintf('%.3f', min(f3$median))} to {sprintf('%.3f', max(f3$median))} ",
               "across the {nrow(f3)} combination sizes"), digits = 0)
print(f3 |> select(n_used, median) |> mutate(median_2dp = round(median, 2)), n = nrow(f3))

# "even crossing zero and reaching one in the case of dropping any ten pairs."
smallest_subset <- f3 |> filter(n_used == min(n_used))
claim("results_min_crosses_zero", as.numeric(smallest_subset$minimum < 0),
      str_glue("1 if the minimum correlation is below zero when ten pairs are dropped; ",
               "the minimum is {sprintf('%.3f', smallest_subset$minimum)}"), digits = 0)
claim("results_max_reaches_one", smallest_subset$maximum,
      "highest correlation when ten pairs are dropped, against an article that says it reaches one", digits = 2)

# "A striking feature of this graph, however, is that the interquartile range
#  stays within the narrow band of about 0.6 to 0.8."
#
# The band is hedged with "about", so the two endpoints are thresholds. The
# quartiles that have to sit inside them are printed with the verdict.
claim("results_iqr_band",
      as.numeric(min(f3$q25) >= 0.6 & max(f3$q75) <= 0.8),
      str_glue("1 if every 25th percentile is at least 0.6 and every 75th percentile at most 0.8; ",
               "the lowest 25th percentile is {sprintf('%.3f', min(f3$q25))} and the highest ",
               "75th percentile is {sprintf('%.3f', max(f3$q75))}"), digits = 0)

# Figure 3, "Rank-order correlation of standardized treatment effects in lab and
# field". The figure prints no estimates: what it asserts is five series across
# 21 x-axis categories labelled with binomial coefficients.
claim("fig3_series", sum(summary_columns %in% names(f3)),
      "series plotted in Figure 3, one per summary statistic", digits = 0)
claim("fig3_x_categories", nrow(f3),
      "x-axis categories of Figure 3", digits = 0)
claim("fig3_binomial_top", pooled_pairs,
      "upper term of every binomial coefficient labelling the x-axis", digits = 0)
claim("fig3_x_low", min(f3$n_used),
      "lower term of the leftmost binomial coefficient on the x-axis", digits = 0)
claim("fig3_x_high", max(f3$n_used),
      "lower term of the rightmost binomial coefficient on the x-axis", digits = 0)

# Figure 3 note: "we calculate the rank-order correlations of the 21 treatment
#  effect pairs included in the meta-analysis, under all possible combinations
#  duplicating or removing any 1, 2, 3... or 10 of them."
claim("fig3_note_pairs", pooled_pairs,
      "treatment effect pairs named in the Figure 3 note", digits = 0)
claim("fig3_note_max_dropped", max(f3$n_used) - pooled_pairs,
      "largest number of pairs duplicated or removed, named in the Figure 3 note", digits = 0)

# The note says every possible combination is used; footnote 6 says 50,000 are
# sampled wherever more exist. Only one of the two can be right.
all_combinations <- f3 |> filter(n_used != pooled_pairs)
claim("fig3_note_all_combinations",
      as.numeric(all(all_combinations$n_evaluated == all_combinations$n_combinations)),
      str_glue("1 if every available combination was evaluated; ",
               "{format(sum(all_combinations$n_evaluated), big.mark = ',')} of ",
               "{format(sum(all_combinations$n_combinations), big.mark = ',')} were"), digits = 0)

# Discussion ----

# "In the collection of 12 studies we examined, seven of the lab studies involved
#  undergraduate subjects."
claim("disc_studies_examined", study_pairs,
      "studies in the examined collection", digits = 0)
claim("disc_undergraduate_labs", NA_real_,
      "no counterpart in the deposit: the deposited frames carry group means, sizes and standard deviations, and no subject-pool attribute, and the published appendix is the bibliography rather than Online Appendix Table 2", digits = 0, expect = "absent")

# "In six of the lab studies, subjects encountered an abstract rendering of a
#  real-life situation, such as the exchange of tokens meant to simulate the
#  division of a restaurant bill."
claim("disc_abstract_labs", NA_real_,
      "no counterpart in the deposit: no attribute records how abstract a study's rendering was", digits = 0, expect = "absent")

# "In all 12 of the lab studies and nine of the field studies, outcomes were
#  measured immediately after subjects encountered the treatment."
claim("disc_immediate_labs", study_pairs,
      "lab studies in the collection; the timing attribute itself is not recorded in the deposit", digits = 0)
claim("disc_immediate_fields", NA_real_,
      "no counterpart in the deposit: no attribute records when a field study measured its outcomes", digits = 0, expect = "absent")

# "The pattern is all the more striking given the small samples used in several of
#  the studies. In the 12 pairs of lab-field comparisons, the median sample size
#  per treatment condition was 40 for the lab and 37.5 for the field."
claim("disc_pairs", study_pairs,
      "pairs of lab-field comparisons behind the median sample sizes", digits = 0)
claim("disc_median_lab_n", sample_sizes$median_n[sample_sizes$context == "lab"],
      str_glue("median lab sample size per treatment condition, over ",
               "{sample_sizes$groups[sample_sizes$context == 'lab']} conditions"), digits = 0)
claim("disc_median_field_n", sample_sizes$median_n[sample_sizes$context == "field"],
      str_glue("median field sample size per treatment condition, over ",
               "{sample_sizes$groups[sample_sizes$context == 'field']} conditions"), digits = 1)

# "The raw Pearson correlation among the 21 treatment effect pairs is 0.64. The
#  reliabilities for the lab and field treatment effects are 0.78 and 0.82,
#  respectively."
claim("disc_pairs_pearson", pooled_pairs,
      "treatment effect pairs entering the raw Pearson correlation", digits = 0)
claim("disc_raw_pearson", one(disattenuation, "^raw Pearson"),
      "raw Pearson correlation among the 21 standardized pairs", digits = 2)
claim("disc_lab_reliability", one(disattenuation, "^lab reliability$"),
      "reliability of the lab treatment effects, as the correlation between two simulated draws", digits = 2)
claim("disc_field_reliability", one(disattenuation, "^field reliability$"),
      "reliability of the field treatment effects, as the correlation between two simulated draws", digits = 2)

# "The disattenuated correlation is found to be 0.64/sqrt(0.78 x 0.82) = 0.80,
#  further attesting to the strength of lab-field correspondence in published
#  work."
#
# The three inputs of that formula are the three quantities of the preceding
# sentence, so they are printed again here. Printing them once would leave the
# formula's own numbers unchecked, which is exactly the shape in which a restated
# quantity drifts.
claim("disc_disatt_numerator", one(disattenuation, "^raw Pearson"),
      "numerator of the disattenuation formula, the raw Pearson correlation", digits = 2)
claim("disc_disatt_lab", one(disattenuation, "^lab reliability$"),
      "first reliability inside the disattenuation formula", digits = 2)
claim("disc_disatt_field", one(disattenuation, "^field reliability$"),
      "second reliability inside the disattenuation formula", digits = 2)
claim("disc_disattenuated", one(disattenuation, "^disattenuated correlation$"),
      "observed correlation divided by the geometric mean of the two reliabilities", digits = 2)

# Footnote 7: "The reliabilities were estimated using a simulation technique in
#  which hypothetical treatment effects are drawn from the normal distributions
#  implied by the estimated treatment effects and their standard errors. The
#  estimated reliability is the square of the correlation between two treatment
#  effect draws. We use the average of 10,000 estimated reliabilities for both lab
#  and field to disattenuate the raw correlation."
#
# The definition is the claim here. Under it the lab reliability is 0.78, which is
# what the article reports and what the deposited code computes; under the
# reliability of classical test theory, the correlation itself, it is 0.88. Both
# are printed so the definition can be read off the numbers.
claim("fn7_reliability_squared", one(disattenuation, "^lab reliability, squared"),
      str_glue("lab reliability under footnote 7's squared definition, against ",
               "{sprintf('%.2f', one(disattenuation, '^lab reliability$'))} under the ",
               "correlation itself, which is what disattenuation requires"), digits = 2)
claim("fn7_simulations", one(disattenuation, "^simulations averaged"),
      "simulated reliabilities averaged for each of lab and field", digits = 0)

# Published appendix ----

# "In Figure 1 below, laboratory results are plotted on the x-axis and field
#  results are plotted on the y-axis. ... The numeric data used to generate these
#  charts may be found in Online Appendix Table 1."
#
# The appendix published with the article is the bibliography of studies
# considered for inclusion, and contains neither of the two online appendix tables
# the text refers to. There is therefore no published counterpart for the cells of
# Online Appendix Table 1, and the rewrite's version is checked against the
# deposit's own copy of the table instead.
claim("appendix_table_1_absent", 0,
      str_glue("rows of Online Appendix Table 1 in the published appendix; ",
               "the rewrite's {one(appendix, 'treatment condition rows')} rows give ",
               "{one(appendix, 'cells compared')} cells, of which ",
               "{one(appendix, 'cells agreeing')} agree with the deposited meanstable.csv"), digits = 0)

# "Fuller descriptions of each study can be found in Online Appendix Table 2."
claim("appendix_table_2_absent", 0,
      str_glue("rows of Online Appendix Table 2 in the published appendix; the table is ",
               "prose, no deposited script produces it, and the {study_pairs} study names ",
               "are all the pipeline carries"), digits = 0)

# Gates ----
# The verdicts above are assertions only if something reads them. assert_claims() is
# what reads them, and the four checks it runs are together the property this file
# exists to hold: every quantity the article prints is either reproduced here or
# corrected by a published erratum, and nothing is quietly in neither state.
#
#   1. No claim ended on a failing verdict (MISMATCH, STALE, DRIFT or MISSING).
#   2. Every claim a quantity erratum names was printed, and printed as corrected. An
#      entry naming a claim this file does not cover is a correction nothing checks.
#   3. The claims printed are exactly those the extraction declares need a block, which
#      is the one gate a failing verdict cannot substitute for: a claim that is never
#      printed has no verdict to fail. build_ground_truth.R runs this gate too, and it
#      is kept here as well so the file stands up when run on its own.
#   4. The verdict counts partition the claims, so an exemption cannot fall out of the
#      accounting unnoticed.
#
# A DRIFT has two causes and they are fixed in opposite directions: the pipeline has
# moved off the value the note publishes, or errata.qmd has not been re-rendered since
# it last moved. Re-render before investigating.
assert_claims()

# The exemptions are counted, never merely allowed. A claim scored [range], [hedged],
# [derived], [absent] or [shape] is one this file declines to assert, and a file that
# let that set grow in silence would report the same clean run whether it checked every
# claim or none.
invisible(claim_summary())
