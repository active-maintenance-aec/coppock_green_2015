# coppock_green_2015/run_all.R
# Runs the whole reproduction in order: fetch and verify the deposited archive,
# tidy it, then every published table and figure, then the in-text quantities.
# Every script is self-contained and can also be run on its own, except that the
# cleaning script has to have run at least once first.

library(here)
here::i_am("run_all.R")

# Deposited archive ----
# Downloads from Dataverse on a fresh clone; verifies checksums either way.
source(here::here("download_original.R"))

# Cleaning ----
source(here::here("maintained", "clean_labfield.R"))

# Tables ----
# Table 2 reads Table 1's output, so it runs after it.
source(here::here("maintained", "table_1_hypothetical_ates.R"))
source(here::here("maintained", "table_2_meta_regression.R"))
source(here::here("maintained", "table_a1_group_means.R"))

# Figures ----
# Figure 3 evaluates the rank-order correlation across 555,790 subsets of the 21
# pairs, which takes about eleven seconds.
source(here::here("maintained", "figure_1_twelve_tiles.R"))
source(here::here("maintained", "figure_2_standardized_tes.R"))
source(here::here("maintained", "figure_3_robustness.R"))

# In-text quantities ----
source(here::here("maintained", "text_hypothetical_correlations.R"))
source(here::here("maintained", "text_jerit_sensitivity.R"))
source(here::here("maintained", "text_median_sample_sizes.R"))
source(here::here("maintained", "text_disattenuation.R"))
source(here::here("maintained", "text_appendix_table_check.R"))

# Computational reproducibility of the deposited archive ----
# Asks a question about the archive rather than about the rewrite, so it runs the
# archive's own Figure 3 procedure under the sampler of its day and under the
# current one. It changes the sampler, so it restores it before returning. Running
# the enumeration twice makes this the slowest script here, at about 22 seconds.
source(here::here("maintained", "text_sampler_reproducibility.R"))

# Ground truth ----
# Reads every value_rewrite back out of maintained/output/, so it has to run last.
# It also runs in_text_claims.R under capture.output as its coverage gate, so that
# file necessarily runs twice per pipeline: once silently for the gate, and once
# below for the readable log.
source(here::here("ground_truth", "build_ground_truth.R"))

# In-text claims ----
# The second instrument. One block per numeric claim the article makes, each
# recomputing the number from maintained/output/ by its own path.
source(here::here("maintained", "in_text_claims.R"))

# Deposited archive, again ----
# The check at the top of this file is a precondition: it says original/ was intact
# before anything ran. Nothing above writes to original/, and this second pass is what
# demonstrates it rather than assuming it. Nothing is downloaded; the files are already
# present and are re-checked against the manifest on checksum, byte size and membership.
source(here::here("download_original.R"))
