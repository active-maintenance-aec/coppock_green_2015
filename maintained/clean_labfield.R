# coppock_green_2015/maintained/clean_labfield.R
# Output: maintained/data/labfield_groups.rds
#         maintained/data/standardized_pairs.rds
#         maintained/data/jerit_pairs.rds
# Depends on: original_extracted/ (download_original.R), helpers.R
# Description: Read the deposited group-level frames, tidy the group means for
#   Figure 1 and Appendix Table 1, and compute the standardized treatment effects
#   for the 21 lab-field pairs behind Figures 2 and 3.

source(here::here("maintained", "helpers.R"))

load(here::here("original_extracted",
                "Coppock Green Lab Field Replication Archive",
                "labfieldframes.rdata"))

dir.create(here::here("maintained", "data"), showWarnings = FALSE)

# Study specifications ----
# One entry per lab-field study pair. label_col names the column holding the
# treatment condition labels, which the deposit spells three different ways.
# te_pairs lists the treatment effects the paper draws from the study: ti is the
# treated row, ci the control row, std_ci the row whose standard deviation
# standardizes the effect. Under the Cohen's d definition in Equation 1 of the
# paper, std_ci is always the control row of the comparison.
study_specs <- list(
  list(prefix = "erev", frame = erev.frame, label_col = "labels",
       study = "Erev, Bornstein, and Galili (1993)",
       te_pairs = list(list(label = "A", ti = 2, ci = 1, std_ci = 1))),
  list(prefix = "gneezy", frame = gneezy.frame, label_col = "field_labels",
       study = "Gneezy and Rustichini (2000)",
       te_pairs = list(list(label = "B1", ti = 2, ci = 1, std_ci = 1),
                       list(label = "B2", ti = 3, ci = 1, std_ci = 1))),
  list(prefix = "valentino", frame = valentino.frame, label_col = "labels",
       study = "Valentino, Traugott, and Hutchings (2002)",
       te_pairs = list(list(label = "C1", ti = 2, ci = 1, std_ci = 1),
                       list(label = "C2", ti = 3, ci = 1, std_ci = 1),
                       list(label = "C3", ti = 4, ci = 1, std_ci = 1))),
  list(prefix = "gender", frame = gender.frame, label_col = "field_labels",
       study = "Gneezy and Rustichini (2004)",
       te_pairs = list(list(label = "D1", ti = 3, ci = 1, std_ci = 1),
                       list(label = "D2", ti = 4, ci = 2, std_ci = 2))),
  list(prefix = "bill", frame = bill.frame, label_col = "labels",
       study = "Gneezy, Haruvy, and Yafe (2004)",
       te_pairs = list(list(label = "E1", ti = 2, ci = 1, std_ci = 1),
                       list(label = "E2", ti = 3, ci = 1, std_ci = 1))),
  list(prefix = "list", frame = list.frame, label_col = "labels",
       study = "List (2006)",
       te_pairs = list(list(label = "F", ti = 2, ci = 1, std_ci = 1))),
  list(prefix = "shang", frame = shang.frame, label_col = "labels",
       study = "Shang, Reed, and Croson (2008)",
       te_pairs = list(list(label = "G", ti = 2, ci = 1, std_ci = 1))),
  list(prefix = "rondeau", frame = rondeau.frame, label_col = "lab_labels",
       study = "Rondeau and List (2008)",
       te_pairs = list(list(label = "H1", ti = 2, ci = 1, std_ci = 1),
                       list(label = "H2", ti = 3, ci = 1, std_ci = 1),
                       list(label = "H3", ti = 4, ci = 1, std_ci = 1))),
  list(prefix = "winners", frame = winners.frame, label_col = "labels",
       study = "Harrison and List (2008)",
       te_pairs = list(list(label = "I", ti = 2, ci = 1, std_ci = 1))),
  list(prefix = "boly", frame = boly.frame, label_col = "labels",
       study = "Armantier and Boly (2013)",
       te_pairs = list(list(label = "J1", ti = 2, ci = 1, std_ci = 1),
                       list(label = "J2", ti = 3, ci = 1, std_ci = 1),
                       list(label = "J3", ti = 4, ci = 1, std_ci = 1))),
  list(prefix = "abeler", frame = abeler.frame, label_col = "labels",
       study = "Abeler and Marklein (2013)",
       te_pairs = list(list(label = "K", ti = 2, ci = 1, std_ci = 1)))
)

frames <- map(study_specs, \(s) normalize_frame(s$frame, s$prefix))
names(frames) <- map_chr(study_specs, \(s) s$prefix)

# Group means ----
# Long by context, one row per treatment condition per context. Feeds Figure 1
# and Appendix Table 1.
labfield_groups <- map2(
  study_specs, frames,
  function(spec, f) {
    labels <- as.character(f[[spec$label_col]])
    bind_rows(
      tibble(study = spec$study, context = "lab", label = labels,
             mean = f$lab_means, se = f$lab_ses, n = f$lab_ns,
             lower = f$lab_lowers, upper = f$lab_uppers),
      tibble(study = spec$study, context = "field", label = labels,
             mean = f$field_means, se = f$field_ses, n = f$field_ns,
             lower = f$field_lowers, upper = f$field_uppers)
    )
  }
) |>
  list_rbind()

write_rds(labfield_groups, here::here("maintained", "data", "labfield_groups.rds"))

# Standardized treatment effects, ten studies with continuous outcomes ----
# Equations 1 and 2 of the paper: the effect and its standard error are both
# divided by the control group standard deviation.
standardized_te <- function(f, pair) {
  lab <- t_tester(f$lab_sds[pair$ti], f$lab_sds[pair$ci],
                  f$lab_ns[pair$ti], f$lab_ns[pair$ci],
                  f$lab_means[pair$ti], f$lab_means[pair$ci])
  field <- t_tester(f$field_sds[pair$ti], f$field_sds[pair$ci],
                    f$field_ns[pair$ti], f$field_ns[pair$ci],
                    f$field_means[pair$ti], f$field_means[pair$ci])
  tibble(
    point_label = pair$label,
    lab_te = lab[1] / f$lab_sds[pair$std_ci],
    lab_lower = lab[2] / f$lab_sds[pair$std_ci],
    lab_upper = lab[3] / f$lab_sds[pair$std_ci],
    lab_se = lab[4] / f$lab_sds[pair$std_ci],
    field_te = field[1] / f$field_sds[pair$std_ci],
    field_lower = field[2] / f$field_sds[pair$std_ci],
    field_upper = field[3] / f$field_sds[pair$std_ci],
    field_se = field[4] / f$field_sds[pair$std_ci]
  )
}

# Armantier and Boly's outcome is whether a subject took a bribe, so its effects
# are differences in proportions rather than differences in means. The individual
# 0/1 records follow from the group sizes and means in the deposit.
standardized_prop_te <- function(f, pair) {
  lab_treated <- binary_group(f$lab_ns[pair$ti], f$lab_means[pair$ti])
  lab_control <- binary_group(f$lab_ns[pair$ci], f$lab_means[pair$ci])
  field_treated <- binary_group(f$field_ns[pair$ti], f$field_means[pair$ti])
  field_control <- binary_group(f$field_ns[pair$ci], f$field_means[pair$ci])
  lab <- prop_tester(lab_treated, lab_control)
  field <- prop_tester(field_treated, field_control)
  tibble(
    point_label = pair$label,
    lab_te = lab[1] / f$lab_sds[pair$std_ci],
    lab_lower = lab[2] / f$lab_sds[pair$std_ci],
    lab_upper = lab[3] / f$lab_sds[pair$std_ci],
    lab_se = lab[4] / f$lab_sds[pair$std_ci],
    field_te = field[1] / f$field_sds[pair$std_ci],
    field_lower = field[2] / f$field_sds[pair$std_ci],
    field_upper = field[3] / f$field_sds[pair$std_ci],
    field_se = field[4] / f$field_sds[pair$std_ci]
  )
}

non_jerit <- map2(
  study_specs, frames,
  function(spec, f) {
    estimator <- if (spec$prefix == "boly") standardized_prop_te else standardized_te
    map(spec$te_pairs, \(pair) estimator(f, pair)) |>
      list_rbind() |>
      mutate(study = spec$study, .before = 1)
  }
) |>
  list_rbind()

# Jerit, Barabas, and Clifford ----
# This study contributes 17 treatment effects rather than group means, one per
# survey question. Its frame already carries the effects and their standard
# errors, so they only need standardizing.
jerit <- normalize_frame(jerit.frame, "jerit") |>
  transmute(
    question = questions,
    lab_te = lab_ates / lab_sds_control,
    lab_lower = lab_lowers / lab_sds_control,
    lab_upper = lab_uppers / lab_sds_control,
    lab_se = lab_ates_ses / lab_sds_control,
    field_te = field_ates / field_sds_control,
    field_lower = field_lowers / field_sds_control,
    field_upper = field_uppers / field_sds_control,
    field_se = field_ates_ses / field_sds_control,
    lab_ate = lab_ates,
    lab_ate_lower = lab_lowers,
    lab_ate_upper = lab_uppers,
    field_ate = field_ates,
    field_ate_lower = field_lowers,
    field_ate_upper = field_uppers
  )

write_rds(jerit, here::here("maintained", "data", "jerit_pairs.rds"))

# The paper includes one Jerit pair in the pooled set, the one that puts the
# overall rank-order correlation at its median across the 17 candidates.
jerit_candidate_rho <- map_dbl(
  seq_len(nrow(jerit)),
  \(i) cor(c(non_jerit$lab_te, jerit$lab_te[i]),
           c(non_jerit$field_te, jerit$field_te[i]),
           method = "spearman")
)

jerit_median <- which(jerit_candidate_rho == median(jerit_candidate_rho))

# Two of the 17 candidates give exactly the same pooled correlation, so the median
# is only guaranteed to name one candidate as long as no tie lands on it.
stopifnot(length(jerit_median) == 1)

# The 21 pooled pairs ----
point_levels <- c("A", "B1", "B2", "C1", "C2", "C3", "D1", "D2", "E1", "E2",
                  "F", "G", "H1", "H2", "H3", "I", "J1", "J2", "J3", "K", "L")

jerit_pooled_row <- jerit |>
  slice(jerit_median) |>
  transmute(study = "Jerit, Barabas, and Clifford (2013)", point_label = "L",
            lab_te, lab_lower, lab_upper, lab_se,
            field_te, field_lower, field_upper, field_se)

standardized_pairs <- bind_rows(non_jerit, jerit_pooled_row) |>
  arrange(match(point_label, point_levels))

write_rds(standardized_pairs, here::here("maintained", "data", "standardized_pairs.rds"))

print(tibble(
  quantity = c("study pairs", "pooled treatment effect pairs",
               "Jerit candidates", "Jerit median candidate",
               "pooled Spearman rho"),
  value = c(length(study_specs) + 1, nrow(standardized_pairs),
            nrow(jerit), jerit_median,
            cor(standardized_pairs$lab_te, standardized_pairs$field_te,
                method = "spearman"))
))
