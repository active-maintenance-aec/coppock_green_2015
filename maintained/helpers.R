# coppock_green_2015/maintained/helpers.R
# Output: none
# Depends on: nothing
# Description: Packages and the two summary-statistic estimators the paper uses.
#   Sourced by every other script.

library(here)
library(tidyverse)
library(estimatr)
library(knitr)
library(kableExtra)
library(modelsummary)
library(patchwork)

# Anchors paths when a script in maintained/ is run on its own rather than through
# run_all.R.
here::i_am("maintained/helpers.R")

options(modelsummary_format_numeric_latex = "plain")

# The deposit's data file gives group means, SDs and sizes rather than individual
# records, so treatment effects are built from summary statistics.

# t_tester: Welch two-sample t test from summary statistics.
# s1, n1, x1 describe the treated group; s2, n2, x2 the control group.
# Returns c(estimate, ci_lower, ci_upper, se).
t_tester <- function(s1, s2, n1, n2, x1, x2) {
  se <- sqrt(s1^2 / n1 + s2^2 / n2)
  df <- se^4 / (((s1^2 / n1)^2 / (n1 - 1)) + ((s2^2 / n2)^2 / (n2 - 1)))
  t_crit <- qt(0.975, df)
  estimate <- x1 - x2
  c(estimate, estimate - t_crit * se, estimate + t_crit * se, se)
}

# prop_tester: difference in proportions from two 0/1 vectors.
# The interval comes from prop.test, which is what the archive used; the standard
# error is the usual unpooled binomial one.
# Returns c(estimate, ci_lower, ci_upper, se).
prop_tester <- function(x, y) {
  p_x <- mean(x)
  p_y <- mean(y)
  estimate <- p_x - p_y
  se <- sqrt(p_x * (1 - p_x) / length(x) + p_y * (1 - p_y) / length(y))
  test <- prop.test(c(sum(x), sum(y)), c(length(x), length(y)))
  c(estimate, test$conf.int[1], test$conf.int[2], se)
}

# binary_group: rebuild a group's 0/1 outcome vector from its size and its mean.
# Armantier and Boly's outcome is binary, so the group mean and group size in the
# deposit determine the individual records exactly.
binary_group <- function(n, mean) {
  n_ones <- round(n * mean)
  c(rep(0, n - n_ones), rep(1, n_ones))
}

# normalize_frame: strip a frame's study prefix and turn dots into underscores, so
# that erev.frame's "erev.lab.means" and gneezy.frame's "gneezy.lab.means" both
# become "lab_means" and one set of code can read every frame.
normalize_frame <- function(frame, prefix) {
  frame |>
    rename_with(\(nm) str_remove(nm, paste0("^", prefix, "\\."))) |>
    rename_with(\(nm) str_replace_all(nm, "\\.", "_")) |>
    as_tibble()
}
