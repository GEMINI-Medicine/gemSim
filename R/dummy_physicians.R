#' @title
#' Generate simulated physicians data
#'
#' @description
#' This function creates a synthetic dataset with a subset of variables that
#' are contained in the GEMINI "physicians" table, as seen in
#' [GEMINI Data Repository Dictionary](https://geminimedicine.ca/the-gemini-database/).
#'
#'
#' @param nid (`integer`)\cr Number of unique encounter IDs to simulate.
#' Optional if `cohort` is provided.
#'
#' @param n_hospitals (`integer`)\cr Number of hospitals in simulated dataset.
#' Optional if `cohort` is provided.
#'
#' @param seed (`integer`)\cr Optional, a number to be used to set the seed for reproducible results.
#'
#' @param cohort (`data.frame or data.table`) Optional, an existing data table or data frame
#' similar to `admdad` in GEMINI with at least the following columns:
#' - `genc_id` (`integer`): Mock encounter ID; integers starting from 1
#' - `hospital_num` (`integer`): Mock hospital ID; integers starting from 1
#' If `cohort` is provided, `nid` and `n_hospitals` inputs are not used.
#'
#' @return (`data.table`)\cr A data.table object similar to the "physicians" table that contains the
#' following fields:
#' - `genc_id` (`integer`): Mock encounter ID; integers starting from 1 or from `cohort` if provided
#' - `hospital_num` (`integer`): Mock hospital ID number; integers starting from 1 or from `cohort` if provided
#' - `admitting_physician_gim` (`logical`): Whether the admitting physician attends a general medicine ward
#' - `discharging_physician_gim` (`logical`): Whether the discharging physician attends a general medicine ward
#' - `adm_phy_cpso_mapped` (`integer`): Synthetic mock CPSO number (with prefix 'SYN_') of admitting physician
#' - `mrp_cpso_mapped` (`integer`): Synthetic mock CPSO number (with prefix 'SYN_') of most responsible physician (MRP)
#' - `dis_phy_cpso_mapped` (`integer`): Synthetic mock CPSO number (with prefix 'SYN_') of discharging physician
#'
#' @examples
#' dummy_physicians(nid = 1000, n_hospitals = 10, seed = 1)
#' dummy_physicians(cohort = dummy_ipadmdad(), seed = 2)
#'
#' @import Rgemini
#' @import data.table
#' @importFrom dplyr group_by reframe
#' @importFrom magrittr %>%
#'
#' @export

dummy_physicians <- function(nid = 1000, n_hospitals = 10, cohort = NULL, seed = NULL) {
  ####### checks for valid inputs #######
  if (!is.null(cohort)) { # if `cohort` is provided
    Rgemini:::check_input(cohort,
      c("data.frame", "data.table"),
      colnames = c("genc_id", "hospital_num"),
      coltypes = c("integer", "integer")
    )
  } else { # when `cohort` is not provided
    Rgemini:::check_input(list(nid, n_hospitals), "integer")

    if (nid < n_hospitals) {
      stop("Number of encounters must be greater than or equal to the number of hospitals")
    }
  }

  if (!is.null(cohort)) {
    # if `cohort` is provided, use its `genc_id` and `hospital_num`
    cohort <- suppressWarnings(Rgemini::coerce_to_datatable(cohort))
    df_sim <- generate_id_hospital(cohort = cohort, include_prop = 1, avg_repeats = 1, seed = seed)

    nid <- length(unique(df_sim$genc_id))
    n_hospitals <- length(unique(df_sim$hospital_num))

    # only include the genc_id and hospital_num columns from `cohort`
    df_sim <- df_sim[, c("genc_id", "hospital_num")]
  } else {
    # no repeating genc_id in physicians data table
    # generate a cohort with `genc_id` and `hospital_num`
    df_sim <- generate_id_hospital(nid, n_hospitals, avg_repeats = 1, seed = seed)
  }

  # Function that samples a value from a given vector with replacement
  sample_from_col <- function(dat) {
    return(sample(dat, 1, replace = TRUE))
  }

  # set the NA proportions per hospital per variable
  # sampling creates hospital-level variation
  # each row is a different hopsital
  hosp_na_prop <- df_sim %>%
    group_by(
      hospital_num
    ) %>%
    reframe(
      adm_phy_cpso_mapped_NA = rbeta(1, 0.2, 1.1),
      dis_phy_cpso_mapped_NA = rbeta(1, 0.25, 2.7),
      mrp_cpso_mapped_NA = rbeta(1, 0.4, 11.2),
      admitting_phy_gim_NA = runif(1, 0, 1),
      admitting_phy_gim_Y = runif(1, 0, 1),
      discharging_phy_gim_NA = runif(1, 0, 1),
      discharging_phy_gim_Y = runif(1, 0, 1),
    ) %>%
    data.table()

  # edit `admitting_phy_gim` and `discharging_phy_gim`
  # artificially add some counts of NA with proportion approximately 0.33
  # 0.33 of hospitals have all NA for these variables
  hosp_sample <- sample(unique(df_sim$hospital_num), round(n_hospitals * 0.33))
  hosp_na_prop[hospital_num %in% hosp_sample, admitting_phy_gim_NA := 1]
  hosp_na_prop[hospital_num %in% hosp_sample, discharging_phy_gim_NA := 1]

  # NA proportions between admitting and discharging GIM are similar per hospital
  hosp_na_prop[, admitting_phy_gim_NA := sort(hosp_na_prop$admitting_phy_gim_NA)]
  hosp_na_prop[, discharging_phy_gim_NA := sort(hosp_na_prop$discharging_phy_gim_NA)]

  ### `adm_phy_cpso_mapped` and `dis_phy_cpso_mapped`
  # randomly set 7% of hospitals to have all NA values
  # set the highest hospitals to 1.0 proportion since they are already highest in NA
  na_order_adm <- order(hosp_na_prop[, adm_phy_cpso_mapped_NA], decreasing = TRUE)

  hosp_na_prop[na_order_adm[1:round(0.07 * n_hospitals)], adm_phy_cpso_mapped_NA := 1]
  hosp_na_prop[na_order_adm[1:round(0.07 * n_hospitals)], dis_phy_cpso_mapped_NA := 1]

  # for `mrp_cpso_mapped`, let 0.1 of hospitals have no NA values
  # select the lowest existing values to keep the result similar to the distribution
  hosp_na_prop[na_order_adm[1:round(0.1 * n_hospitals)], mrp_cpso_mapped_NA := 0]

  # sample all physician numbers
  # each hospital has about 280 physicians on average
  # multiply this average by n_hospitals to get the total set of physicians across all hospitals
  sample_cpso <- paste0("SYN_", round(runif(280 * n_hospitals, min = 1e4, max = 3e5)))

  # sample a set of unique physicians for each hospital
  hosp_na_prop$n_physicians <- rsn_trunc(n_hospitals, 470, 220, -1.6, 1, 650)
  hosp_na_prop[, phy_set := sapply(n_physicians, function(x) sample(sample_cpso, x, replace = TRUE))]

  # merge `df_sim`, the output data table, with hospital information
  df_sim <- merge(df_sim, hosp_na_prop, by = "hospital_num", all.x = TRUE)

  # now sample all variables
  ####### `admitting_physician_gim` #######
  df_sim[, admitting_physician_gim := ifelse(rbinom(.N, 1, admitting_phy_gim_Y), "y", "n")]

  # sample the NAs in admitting_physician_gim
  df_sim[, admitting_physician_gim := ifelse(rbinom(
    .N, 1,
    admitting_phy_gim_NA
  ), NA, admitting_physician_gim)]

  ####### `discharging_physician_gim` #######
  df_sim[, discharging_physician_gim := ifelse(rbinom(.N, 1, discharging_phy_gim_Y), "y", "n")]

  # sample the NAs in discharging_physician_gim
  df_sim[, discharging_physician_gim := ifelse(rbinom(
    .N, 1,
    discharging_phy_gim_NA
  ), NA, discharging_physician_gim)]

  ####### `adm_phy_cpso_mapped` #######
  # Set adm physician
  df_sim[, adm_phy_cpso_mapped := sapply(phy_set, sample_from_col)]

  ####### `mrp_cpso_mapped` #######
  # 0.36 of encounters have mrp = adm
  df_sim[, mrp_cpso_mapped := ifelse(rbinom(.N, 1, 0.36),
    adm_phy_cpso_mapped, sapply(setdiff(phy_set, adm_phy_cpso_mapped), sample_from_col)
  )]

  ####### `dis_phy_cpso_mapped` #######
  # when adm = mrp, 0.9 of encounters have adm = mrp = dis
  df_sim[adm_phy_cpso_mapped == mrp_cpso_mapped, dis_phy_cpso_mapped := ifelse(rbinom(.N, 1, 0.9),
    adm_phy_cpso_mapped,
    sapply(setdiff(phy_set, adm_phy_cpso_mapped), sample_from_col)
  )]

  # when adm != mrp, 0.87 of dis = mrp and dis != adm always
  # these will cover all cases of relations between adm, mrp, and dis
  df_sim[adm_phy_cpso_mapped != mrp_cpso_mapped, dis_phy_cpso_mapped := ifelse(rbinom(.N, 1, 0.87),
    mrp_cpso_mapped,
    sapply(setdiff(phy_set, c(mrp_cpso_mapped)), sample_from_col)
  )]

  return(df_sim[
    order(df_sim$genc_id), # return only with required columns
    c(
      "genc_id", "hospital_num", "admitting_physician_gim", "discharging_physician_gim", "adm_phy_cpso_mapped",
      "mrp_cpso_mapped"
    )
  ])
}
