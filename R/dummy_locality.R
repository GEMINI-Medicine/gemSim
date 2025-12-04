#' @title
#' Generate simulated locality variables data
#'
#' @description
#' This function creates a synthetic dataset with a subset of variables that
#' are contained in the GEMINI "locality-variables" table, as seen in
#' [GEMINI Data Repository Dictionary](https://geminimedicine.ca/the-gemini-database/).
#'
#' Specifically, the function simulates dissemination area IDs (da21uid) based on Canadian census data for a
#' user-specified set of mock encounter and hospital IDs. To mimic GEMINI data characteristics, the majority
#' of simulated area IDs are drawn from Ontario and are clustered by hospital.
#'
#' @param nid (`integer`)\cr Number of unique encounter IDs to simulate. In this data table, each ID occurs once.
#' It is optional when `cohort` is provided.
#'
#' @param n_hospitals (`integer`)\cr Number of hospitals in simulated dataset.
#' It is optional when `cohort` is provided.
#'
#' @param da21uid (`integer` or `vector`)\cr Optional, allows the user to customize which dissemination area ID(s)
#' to include in the output.
#'
#' @param seed (`integer`)\cr Optional, a number to be used to set the seed for reproducible results.
#'
#' @param cohort (`data.frame or data.table`) Optional, an existing data frame or data table similar to `admdad` in
#' GEMINI with at least the following columns:
#' - `genc_id` (`integer`): Mock encounter ID, integers starting from 1 or from `cohort`
#' - `hospital_num` (`integer`): Mock hospital ID, integers starting from 1 or from `cohort`
#' If `cohort` is provided, `nid` and `n_hospital` inputs are not used.
#'
#' @return (`data.table`)\cr
#' A data.table object similar to the "locality_variables" table that contains the following fields:
#' - `genc_id` (`integer`): Mock encounter ID; integers starting from 1 or from `cohort` if provided
# - `hospital_num` (`integer`): Mock hospital ID; integers starting from 1 or from `cohort` if provided
#' - `da21uid` (`integer`): Dissemination area ID based on 2021 Canadian census data using PCCF Version 8A
#'
#' @import Rgemini
#' @import data.table
#'
#' @export
#'
#' @examples
#' \dontrun{
#' dummy_locality(nid = 1000, n_hospitals = 10)
#' }
dummy_locality <- function(nid = 1000, n_hospitals = 10, cohort = NULL, da21uid = NULL, seed = NULL) {
  ### check inputs
  if (!is.null(da21uid)) {
    Rgemini:::check_input(da21uid, "integer")
  }

  if (is.numeric(seed)) {
    set.seed(seed)
  }

  if (!is.null(cohort)) {
    # check for correct columns in `cohort` if it is provided
    Rgemini:::check_input(cohort,
      c("data.frame", "data.table"),
      colnames = c("genc_id", "hospital_num"),
      coltypes = c("integer", "integer")
    )
  } else {
    # if `cohort` is not provided, check inputs that will be used
    Rgemini:::check_input(list(nid, n_hospitals), "integer")

    if (nid < n_hospitals) {
      stop("Number of encounters must be greater than or equal to the number of hospitals")
    }
  }

  if (!is.null(cohort)) {
    # set up `df_sim` if `cohort` is included
    cohort <- suppressWarnings(Rgemini::coerce_to_datatable(cohort))
    df_sim <- generate_id_hospital(cohort = cohort, include_prop = 1, avg_repeats = 1, seed = seed)
    nid <- uniqueN(df_sim$genc_id)
    n_hospitals <- uniqueN(df_sim$hospital_num)

    # only include the `genc_id` and `hospital_num` columns from `cohort`
    df_sim <- df_sim[, c("genc_id", "hospital_num")]
  } else {
    # generate a cohort from nid and n_hospitals
    df_sim <- generate_id_hospital(nid, n_hospitals, avg_repeats = 1, seed = seed)
  }

  if (!is.null(da21uid)) {
    # if the user provided ID, use those
    # if user provided one ID, fill the column with that
    # otherwise, randomly sample from the list
    df_sim[, da21uid := {
      if (length(da21uid) == 1) {
        rep(da21uid, .N)
      } else {
        sample(da21uid, .N, replace = TRUE)
      }
    }]
  } else {
    # otherwise sample from the database
    # get dissemination code lookup table from RDA
    lookup_statcan_v2021 <- Rgemini::da21uid_statcan_v2021 %>% data.table()
    lookup_statcan_v2021[, da21uid := as.numeric(trimws(da21uid))]

    # extract Ontario dissemination codes to resemble GEMINI data characteristics - these IDs start with 35
    ontario_id <- lookup_statcan_v2021[da21uid < 3.6e7 & da21uid >= 3.5e7, da21uid]

    # to mimic how locality IDs are clustered by hospital, set a range for min and max ID for each hospital
    df_sim[, c("min_id", "max_id") := {
      repeat {
        min_pick <- sample(ontario_id, 1)
        candidates <- ontario_id[ontario_id > min_pick]
        if (length(candidates) > 0) break # ensure min_id < max_id
      }
      list(min_pick, sample(candidates, 1))
    }, by = hospital_num]

    # sample dissemination ID within the range per hospital
    df_sim[, da21uid := mapply(function(x, y) {
      sample(ontario_id[ontario_id >= x & ontario_id <= y], 1, replace = TRUE)
    }, min_id, max_id)]

    # insert a small proportion (0.3%) of cases located outside of Ontario
    # sample from da21uid outside of Ontario
    n_edge <- round(0.003 * nrow(df_sim))
    rows_edge <- sample(seq_len(nrow(df_sim)), n_edge)

    df_sim[rows_edge, da21uid := sample(setdiff(lookup_statcan_v2021$da21uid, ontario_id),
      .N,
      replace = TRUE
    )]

    # inject 2% rate of missingness in `da21uid`
    df_sim[, da21uid := ifelse(rbinom(.N, 1, 0.02), NA, da21uid)]

    # remove extra columns and return
    df_sim <- df_sim[, -c("min_id", "max_id")]
  }
  return(df_sim[order(df_sim$genc_id)])
}
