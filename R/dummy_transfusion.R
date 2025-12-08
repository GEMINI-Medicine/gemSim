#' @title
#' Generate simulated transfusion data
#'
#' @description
#' This function creates a dummy dataset with a subset of variables that
#' are contained in the GEMINI "transfusion" table, as seen in
#' [GEMINI Data Repository Dictionary](https://geminimedicine.ca/the-gemini-database/).
#'
#' @param nid (`integer`)\cr The number of unique mock encounter IDs to simulate.
#' Encounter IDs may repeat, resulting in a data table with more rows than `nid`. Optional if `cohort` is provided.
#'
#' @param n_hospitals (`integer`)\cr The number of hospitals to simulate, optional if `cohort` is provided.
#'
#' @param time_period (`vector`)\cr A numeric or character vector containing the data range of the data
#' by years or specific dates in either format: ("yyyy-mm-dd", "yyyy-mm-dd") or (yyyy, yyyy).
#' The start date and end date will be (yyyy-01-01 and yyyy-12-31) if (yyyy, yyyy)
#' is the date range format provided. Not used when `cohort` is provided.
#'
#' @param cohort (`data.frame or data.table`)\cr Optional, a data frame or data table with columns:
#' - `genc_id` (`integer`): Mock encounter ID number
#' - `hospital_num` (`integer`): Mock hospital ID number
#' - `admission_date_time` (`character`): Date and time of IP admission in YYYY-MM-DD HH:MM format.
#' - `discharge_date_time` (`character`): Date and time of IP discharge in YYYY-MM-DD HH:MM format.
#' When `cohort` is not NULL, `nid`, `n_hospitals`, and `time_period` are ignored.
#'
#' @param blood_product_list (`character`)\cr Either a string or a character vector
#' to sample for the variable `blood_product_mapped_omop`.
#' Items must be real blood product OMOP codes or it will not be used and a warning will be raised.
#'
#' @param seed (`integer`)\cr Optional, a number to be used to set the seed for reproducible results.
#'
#' @return (`data.table`)\cr A data.table object similar to the "transfusion" table with the following fields:
#' - `genc_id` (`integer`): Mock encounter ID number; integers starting from 1 or from `cohort`
#' - `hospital_num` (`integer`): Mock hospital ID number; integers starting from 1 or from `cohort`
#' - `issue_date_time` (`character`): The date and time the transfusion was issued, in the format ("yy-mm-dd hh:mm")
#' - `blood_product_mapped_omop` (`character`): Blood product name mapped by GEMINI following international standard.
#' - `blood_product_raw` (`character`): Type of blood product or component transfused as reported by hospital.
#' @examples
#' dummy_transfusion(nid = 1000, n_hospitals = 30, seed = 1)
#' dummy_transfusion(cohort = dummy_ipadmdad())
#' dummy_transfusion(nid = 100, n_hospitals = 1, blood_product_list = c("0", "35605159", "35615187"))
#'
#' @import Rgemini
#' @import data.table
#' @importFrom lubridate dhours ddays
#' @importFrom magrittr %>%
#'
#' @export
#'
dummy_transfusion <- function(
  nid = 1000, n_hospitals = 10, time_period = c(2015, 2023), cohort = NULL, blood_product_list = NULL, seed = NULL
) {
  if (!is.null(seed)) {
    set.seed(seed)
  }

  ### input checks for variable types and validity ###
  if (!is.null(cohort)) { # if `cohort` is provided
    Rgemini:::check_input(cohort,
      c("data.frame", "data.table"),
      colnames = c("genc_id", "hospital_num", "admission_date_time", "discharge_date_time"),
      coltypes = c("integer", "integer", "", "")
    )

    nid <- uniqueN(cohort$genc_id)
    n_hospitals <- uniqueN(cohort$hospital_num)
  } else { # when `cohort` is not provided
    # `dummy_ipadmdad()` checks inputs
    cohort <- dummy_ipadmdad(nid, n_hospitals, time_period, seed)
  }

  # convert to `data.table`
  cohort <- suppressWarnings(Rgemini::coerce_to_datatable(cohort))

  tryCatch(
    {
      cohort$admission_date_time <- Rgemini::convert_dt(cohort$admission_date_time, "ymd HM")
    },
    warning = function(w) {
      stop(conditionMessage(w))
    }
  )

  tryCatch(
    {
      cohort$discharge_date_time <- Rgemini::convert_dt(cohort$discharge_date_time, "ymd HM")
    },
    warning = function(w) {
      stop(conditionMessage(w))
    }
  )

  # on average, a genc_id has 4.9 transfusions
  df_sim <- generate_id_hospital(cohort = cohort, avg_repeats = 4.9, seed = seed)

  ##### Sample `issue_date_time` #####
  # uniformly sample a date between IP admission and discharge
  # add a time based on the skewed normal distribution
  df_sim[, issue_date_time := as.Date(round(runif(.N,
    min = as.Date(admission_date_time),
    max = as.Date(discharge_date_time)
  ))) +
    dhours(sample_time_shifted(.N, 8.7, 9.1, 2.7, max = 30, seed = seed))]

  # if `issue_date_time` < `admission_date_time`, re-sample
  while (nrow(df_sim[issue_date_time < admission_date_time, ]) > 0) {
    df_sim[issue_date_time < admission_date_time, issue_date_time := admission_date_time +
      dhours(rlnorm_trunc(.N, meanlog = 4.52, sdlog = 1.91, min = 0, max = 38500, seed = seed))]
    # add time to `admission_date_time`
  }

  # if `issue_date_time` > `discharge_date_time`, re-sample
  df_sim[issue_date_time > discharge_date_time, issue_date_time := as.Date(admission_date_time) +
    dhours(sample_time_shifted(.N, 8.7, 9.1, 2.7, max = 30, seed = seed))]

  # then set to discharge_date_time if re-sampling does not fix it
  df_sim[issue_date_time > discharge_date_time, issue_date_time := discharge_date_time]

  # remove seconds and turn into character
  df_sim[, issue_date_time := substr(as.character(issue_date_time), 1, 16)]

  ##### get `blood_product_mapped_omop` data from .Rda file #####
  # It maps the most common raw names of blood products to OMOP code
  # Also gets their average relative proportions
  blood_product_lookup <- as.data.table(blood_product_lookup)

  if (is.null(blood_product_list)) {
    all_blood_product <- blood_product_lookup$blood_product_mapped_omop

    # each hospital does 1-16 types of unique blood products
    # used truncated skewed normal to get this number
    df_sim[, n_products := floor(rsn_trunc(1, 12.5, 4.7, -1.9, 1, 16)), by = hospital_num]

    # hospital-level variation: set the top 1-2 types of transfusions per hospital
    # for other transfusions, sample randomly from the assigned set
    df_sim[, first_code := sample(c("4022173", "4023915", "4137859"),
      1,
      replace = TRUE, prob = c(0.7, 0.05, 0.25)
    ), by = hospital_num]

    # proportion of the most common code within a hospital
    df_sim[, prop_first := runif(1, 0.55, 1), by = hospital_num]

    df_sim[n_products == 1, prop_first := 1]

    # proportion of the second most common code
    df_sim[, sum_first_second := ifelse(prop_first[1] == 1,
      1,
      rsn_trunc(1, 0.94, 0.13, -2.1, prop_first[1], 1)
    ), by = hospital_num]

    second_codes <- data.table(
      codes = c("4137859", "35615187", "4022171", "4023915", "4130829", "4130829"),
      probs = c(0.1, 0.03, 0.1, 0.6, 0.1, 0.07)
    )

    df_sim[, second_code := {
      available <- setdiff(second_codes$codes, first_code)
      prob <- second_codes$probs[match(available, second_codes$codes)]
      sample(available, 1, prob = prob, replace = TRUE)
    }, by = hospital_num]

    # for hospitals with only one blood product type or more
    df_sim[, prop_second := ifelse(n_products >= 2, max(sum_first_second - prop_first, 0), 0), by = hospital_num]

    df_sim[n_products == 2, prop_second := 1 - prop_first]

    # get all other blood products by hospital
    # based on probabilities from the actual data table
    df_sim[, other_product := lapply(
      n_products,
      function(x) {
        list(sample(
          setdiff(all_blood_product, c(
            first_code,
            second_code
          )),
          max(0, x - 2),
          prob = blood_product_lookup[blood_product_mapped_omop %in% (
            setdiff(all_blood_product, c(first_code, second_code)))]$prob,
          replace = FALSE
        ))
      }
    ), by = hospital_num]

    # sample a large proportion of the most common
    # then for some of the rest, get second most common
    # other codes are filled with the top 90% + of codes
    # most genc_id only get one type of transfusion
    df_sim[, blood_product_mapped_omop := ifelse(rbinom(1, 1, prop_first),
      first_code,
      ifelse(rbinom(1, 1, prop_second),
        second_code,
        sample(c(second_code, "4022173"), 1)
      )
    ), by = genc_id]

    # fill remaining codes
    # ~0.04 have the remaining codes
    df_sim[genc_id %in% sample(unique(genc_id), round(0.05 * nid)), blood_product_mapped_omop := lapply(
      other_product,
      function(x) {
        ifelse(identical(x, character(0)), first_code,
          sample(
            x,
            1, # use accurate proportions but normalize to sum to 1
            prob = blood_product_lookup[blood_product_mapped_omop %in% x]$prob /
              sum(blood_product_lookup[blood_product_mapped_omop %in% x]$prob)
          )
        )
      }
    ), by = genc_id]

    df_sim[, genc_occurrence := seq_len(.N), by = genc_id]

    # a proportion of 0.05 of genc_id have multiple types of transfusions
    # account for this by another round of random sampling by `genc_id`
    df_sim[genc_id %in% sample(
      unique(genc_id), round(0.05 * nid)
    ) & genc_occurrence > 1, blood_product_mapped_omop := sample(
      setdiff(all_blood_product, blood_product_mapped_omop), .N,
      replace = TRUE
    )]

    # assign some 0 and NA
    df_sim[hospital_num %in% sample(
      unique(hospital_num), round(n_hospitals / 30)
    ), blood_product_mapped_omop := ifelse(rbinom(.N, 1, 0.05), "0", blood_product_mapped_omop)]

    # NA for 1/30 hospitals
    df_sim[hospital_num %in% sample(
      unique(hospital_num), round(n_hospitals / 30)
    ), blood_product_mapped_omop := ifelse(rbinom(.N, 1, 0.01), NA, blood_product_mapped_omop)]

    # a few hospitals have one unique code
    df_sim[hospital_num %in% sample(
      unique(hospital_num), round(n_hospitals / 15)
    ), blood_product_mapped_omop := "4137859"]

    df_sim[hospital_num %in% sample(
      unique(hospital_num), round(n_hospitals / 30)
    ), blood_product_mapped_omop := "4022173"]
  } else {
    # if given a string for blood_product_list, turn it into a vector for sampling
    if (length(blood_product_list) == 1 && !(is.na(blood_product_list))) {
      blood_product_list <- c(blood_product_list)
    }

    # coerce `blood_product_list` to character
    blood_product_list <- as.character(blood_product_list)

    # verify the validity of user-entered blood products
    invalid <- setdiff(blood_product_list, blood_product_lookup$blood_product_mapped_omop)

    if (length(invalid) > 0) {
      warning(paste(
        "User input contains at least one invalid blood product OMOP code:",
        paste(invalid, collapse = ", ")
      ))
    }

    # if the blood_product_mapped_omop is given by the user, sample from that list
    df_sim[, blood_product_mapped_omop := sample(blood_product_list, .N, replace = TRUE)]

    # create a new lookup table based on user-provided values
    given_product_table <- data.table("blood_product_mapped_omop" = blood_product_list)

    # get `blood_product_raw` by joining with input `blood_product_mapped_omop`
    blood_product_lookup <- left_join(
      given_product_table, blood_product_lookup,
      by = join_by(blood_product_mapped_omop)
    )

    # if the given blood_product_mapped_omop is not in the original lookup table, fill it with this message:
    blood_product_lookup[is.na(blood_product_raw), blood_product_raw := "Invalid blood product OMOP provided"]
  }

  ##### get `blood_product_raw` #####
  # set blood_product_raw by joining `df_sim` with the lookup table
  df_sim <- left_join(df_sim, blood_product_lookup, by = join_by(blood_product_mapped_omop))
  df_sim[blood_product_mapped_omop == "0", blood_product_raw := "FAR"]
  df_sim[is.na(blood_product_mapped_omop), blood_product_raw := NA]

  return(df_sim[
    order(df_sim$genc_id),
    c("genc_id", "hospital_num", "issue_date_time", "blood_product_mapped_omop", "blood_product_raw")
  ]) # only include relevant columns in the final output
}
