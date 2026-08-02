# coppock_green_2015/maintained/text_sampler_reproducibility.R
# Output: maintained/output/text_sampler_reproducibility.csv
# Depends on: original_extracted/ (download_original.R), helpers.R
# Description: The computational reproducibility check for Figure 3, which asks a
#   question about the deposited archive rather than about the rewrite. R 3.6.0
#   replaced the sampler behind sample(), and the archive's Figure 3 script draws
#   50,000 of the available subsets at ten of its twenty sizes, so an analysis
#   written in 2014 cannot be re-run faithfully under the current default.
#   RNGkind(sample.kind = "Rounding") restores the sampler of the day.
#
#   This script runs the archive's own procedure on the archive's own deposited
#   standardized effects, once under each sampler, and reports how far apart the
#   two answers are. The rewrite keeps the modern sampler, because it is the code
#   we would write now; where the two differ, the difference belongs to the
#   environment rather than to either analysis.

source(here::here("maintained", "helpers.R"))

load(here::here("original_extracted",
                "Coppock Green Lab Field Replication Archive",
                "setoftwelve.rdata"))

lab <- setof12$s.lab.tes
field <- setof12$s.field.tes
n_pairs <- length(lab)
max_combinations <- 50000

# The archive's Figure 3 loop, in the archive's own order ----
# Order matters. The two combn calls and the two sample calls happen once per
# iteration, removal before duplication, and each draw shifts the stream for
# everything after it, so any other order yields different subsets under either
# sampler and makes the comparison meaningless. At iteration i the archive keeps
# 10 + i of the 21 pairs on the removal side and appends i duplicates on the other.
# The archive summarises with summary(), which rounds to four significant digits;
# that rounding is kept here so this is the archive's answer rather than a tidier
# one.
archive_figure_3 <- function() {
  set.seed(343)
  map(1:10, function(i) {
    kept <- combn(n_pairs, 10 + i)
    extra <- combn(n_pairs, i)
    if (ncol(kept) > max_combinations) {
      kept <- kept[, sample(seq_len(ncol(kept)), max_combinations)]
    }
    if (ncol(extra) > max_combinations) {
      extra <- extra[, sample(seq_len(ncol(extra)), max_combinations)]
    }
    rho_kept <- apply(kept, 2, \(k) cor(lab[k], field[k], method = "spearman"))
    rho_extra <- apply(extra, 2, \(k) cor(c(lab, lab[k]), c(field, field[k]),
                                          method = "spearman"))
    bind_rows(
      tibble(n_used = 10 + i, statistic = names(summary(rho_kept)),
             value = as.numeric(summary(rho_kept))),
      tibble(n_used = n_pairs + i, statistic = names(summary(rho_extra)),
             value = as.numeric(summary(rho_extra)))
    )
  }) |>
    list_rbind() |>
    filter(statistic != "Mean") |>
    arrange(n_used)
}

# Under the sampler of 2014 ----
# on.exit does not reliably restore the sampler at the top level of a sourced file,
# and run_all.R sources this in the middle of a sequence, so it is restored
# explicitly and the restoration is asserted.
old_kind <- RNGkind()
suppressWarnings(RNGkind(sample.kind = "Rounding"))
rounding <- archive_figure_3()
suppressWarnings(RNGkind(sample.kind = old_kind[3]))
stopifnot(RNGkind()[3] == old_kind[3])

# Under the current sampler ----
rejection <- archive_figure_3()

comparison <- rounding |>
  rename(rounding_sampler = value) |>
  left_join(rejection |> rename(rejection_sampler = value),
            by = c("n_used", "statistic")) |>
  mutate(difference = rejection_sampler - rounding_sampler)

write_csv(comparison,
          here::here("maintained", "output", "text_sampler_reproducibility.csv"))

print(tibble(
  quantity = c("subset sizes summarised",
               "largest absolute difference between the two samplers",
               "summary values differing by 0.005 or more"),
  value = c(n_distinct(comparison$n_used),
            max(abs(comparison$difference)),
            sum(abs(comparison$difference) >= 0.005))
))
print(comparison, n = nrow(comparison))
