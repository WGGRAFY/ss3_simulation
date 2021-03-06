#install
install.packages("here")
remotes::install_github("r4ss/r4ss", ref = "development")
require(r4ss)
require(here)
remotes::install_github("ss3sim/ss3sim",
                        ref = "noest", build_vignettes = TRUE,
                        dependencies = TRUE)
devtools::load_all(paste0(substr(here(), 1, 15), "ss3sim"))
require(ss3sim)
require(purrr)
require(dplyr)
require(tidyr)
require(ggplot2)


#look for ss.exe
system.file("bin", package = "ss3sim")
ss3sim_dir <- paste0(substr(here(), 1, 32), "ss3sim")
### Creating scenarios
# Scenario are based on:
# 1)	Age/size selective sampling
# 2)	Cohort and initial size effects
# 3)	Time-varying maturation
# 4)	Density-dependent growth effects
# 5)	Fishing rate

### What do we need? length at age information


 source(here("helper_functions.R"))
    #Read in the values for L at a max

    input <- lapply(here(paste0("om/G", c("M", "F"), "3-pet.csv")),
    read.csv, header = FALSE)
    input[[2]]$Fval <- scale(input[[2]]$V1)
    setwd(here("om"))

    # 1. Change in VBk (monotonic trend, decadal) (cases 1-2)
    # 2. Change in VB L inf  (monotonic trend, decadal)(cases 3-4)
    # 3. Change in maturation parameters (A50, L50) (TODO)
    # 4. CV of size at age  (TODO)
    # 5. Sample size of survey per year (TODO)
    # 6. Sample size of fishery data (TODO)
    # 7. Selectivity  (TODO)
    # 8. Level of recruitment variation (CV of recruitment) (TODO)
    # 9. Level of fishing pressure (TODO)
    # 10. CV of survey index (TODO)
    df <- make_data_in(tv_Linf = "1")
    df <- make_data_in(tv_Linf = "2", tv_k = "2")

    iterations <- 1


    arg_list <- setup_scenarios(df)
    #need to set em_dir = NA in each element of the arg_list
    for (j in seq_len(length(arg_list))) {
      arg_list[[j]]$em_dir <- NA
    }
    # Remove the ss3sim_base

    tryCatch({
      unlink(df[, "scenarios"], recursive = TRUE)
      out <- lapply(arg_list, function(x) {
      do.call("ss3sim_base", c(x, list(iterations = iterations)))
    })
    }, error = unlink(df[, "scenarios"], recursive = TRUE)
    )

    output_paths <- file.path("om", df[, "scenarios"])

    #Compare output OM and EM
    r_om <- r4ss::SS_output(here(output_path, "om"),
                            verbose = FALSE, printstats = FALSE, covar = FALSE)
    #Compare output EM
    r_em <- r4ss::SS_readdat(here(output_path, "em", "ss3.dat"),
                            verbose = FALSE)
    r4ss::SS_plots(r_om)

    #EM data file has the simulated comps we need
    em_dat <- r4ss::SS_readdat_3.30(here(df[1, "scenarios"], "1/em/ss3.dat"))

    # slightly modified version (much shortened)
    length_sims_monotonic_2 <- turn_ss_out_to_data_beta(em_dat, flt = 2)
    length_sims_regime_big_2 <- turn_ss_out_to_data_beta(em_dat, flt = 2)


    ggplot(length_sims_monotonic_2, aes(x = Yr, y = Lbin_lo)) + 
    facet_wrap(.~Age) + geom_point() + theme_bw() + ylim(c(50,170))
ggsave("linf_monotonic_opp_flt2.png")

