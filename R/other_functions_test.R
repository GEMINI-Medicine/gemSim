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
#' @param int_code (`character`)\cr A string or character vector
#' of user-specified intervention codes to include in the returned data table.
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
#' - `blood_product_mapped_omop(`character`): Blood product name mapped by GEMINI following international standard.
#' - `blood_product_raw` (`character`): Type of blood product or component transfused as reported by hospital.
#' @examples
#' dummy_transfusion(nid = 1000, n_hospitals = 30, seed = 1)
#' dummy_transfusion(cohort = dummy_ipadmdad())
#' dummy_transfusion(nid = 100, n_hospitals = 1, blood_product_list = c("0", "35605159", "35615187"))
#'
#' @export
#'
dummy_transfusion <- function(
  nid = 1000, n_hospitals = 10, time_period = c(2015, 2023), cohort = NULL, blood_product_list = NULL, seed = NULL
) {
  ### input checks for varaible types and validity ###
  if (!is.null(cohort)) { # if `cohort` is provided
    check_input(cohort,
      c("data.frame", "data.table"),
      colnames = c("genc_id", "hospital_num", "admission_date_time", "discharge_date_time"),
      coltypes = c("integer", "integer", "", "")
    )

    if (!all(check_date_format(c(cohort$admission_date_time, cohort$discharge_date_time), check_time = TRUE))) {
      stop("An invalid IP admission and/or discharge date time input was provided in cohort.")
    }
  } else { # when `cohort` is not provided
    check_input(list(nid, n_hospitals), "integer")

    #  check if time_period is provided/has both start and end dates
    if (any(is.null(time_period)) || any(is.na(time_period)) || length(time_period) != 2) {
      stop("Please provide time_period") # check for date formatting
    } else if (!check_date_format(time_period[1]) || !check_date_format(time_period[2])) {
      stop("Time period is in the incorrect date format, please fix")
    }

    if (nid < n_hospitals) {
      stop("Number of encounters must be greater than or equal to the number of hospitals")
    }
  }

  if (!is.null(seed)) {
    set.seed(seed)
  }

  if (!is.null(cohort)) {
    # if cohort is provided, sample ordered and performed date time based on IP admission and discharge times
    cohort <- as.data.table(cohort)

    cohort$admission_date_time <- as.POSIXct(cohort$admission_date_time,
      format = "%Y-%m-%d %H:%M",
      tz = "UTC"
    )

    cohort$discharge_date_time <- as.POSIXct(cohort$discharge_date_time,
      format = "%Y-%m-%d %H:%M",
      tz = "UTC"
    )

    # on average, a genc_id has 4.9 transfusions
    df1 <- generate_id_hospital(cohort = cohort, avg_repeats = 4.9, seed = seed)
    nid <- uniqueN(df1$genc_id)
    n_hospitals <- uniqueN(df1$hospital_num)

    ##### Sample `issue_date_time` #####
    # uniformly sample a date between IP admission and discharge
    # add a time based on the skewed normal distribution
    df1[, issue_date_time := as.Date(round(runif(.N,
      min = as.Date(admission_date_time),
      max = as.Date(discharge_date_time)
    ))) +
      dhours(sample_time_shifted(.N, 8.7, 9.1, 2.7, max = 30, seed = seed))]

    # if `issue_date_time` < `admission_date_time`, re-sample
    while (nrow(df1[issue_date_time < admission_date_time, ] > 0)) {
      df1[issue_date_time < admission_date_time, issue_date_time := admission_date_time +
        dhours(rlnorm_trunc(.N, meanlog = 4.52, sdlog = 1.91, min = 0, max = 38500, seed = seed))]
      # add time to `admission_date_time`
    }

    # if `issue_date_time` > `discharge_date_time`, re-sample
    df1[issue_date_time > discharge_date_time, issue_date_time := as.Date(admission_date_time) +
      dhours(sample_time_shifted(.N, 8.7, 9.1, 2.7, max = 30, seed = seed))]

    # then set to discharge_date_time if re-sampling does not fix it
    df1[issue_date_time > discharge_date_time, issue_date_time := discharge_date_time]
  } else {
    # set up all required variables based on input if no cohort is provided
    # get the start and end dates
    time_period <- as.character(time_period)

    if (grepl("^[0-9]{4}$", time_period[1])) {
      start_date <- as.Date(paste0(time_period[1], "-01-01"))
    } else {
      start_date <- as.Date(time_period[1])
    }

    if (grepl("^[0-9]{4}$", time_period[2])) {
      end_date <- as.Date(paste0(time_period[2], "-01-01"))
    } else {
      end_date <- as.Date(time_period[2])
    }

    if (start_date > end_date) {
      stop("Time period needs to end later than it starts")
    }

    # create `data.table` with `genc_id` and `hospital_num`
    # average 4.9 repeats per `genc_id`
    df1 <- generate_id_hospital(nid = nid, n_hospitals = n_hospitals, avg_repeats = 4.9, seed = seed)

    ##### sample `issue_date_time` #####
    df1[, min_issue_date := as.Date(round(runif(
      1,
      min = as.numeric(start_date),
      max = as.numeric(end_date)
    ))), by = genc_id]

    # set range of time for repeated transfusions
    # for each hospital stay, transfusions should not be too spaced out
    df1[, max_issue_date := min_issue_date +
      lubridate::days(ceiling(rlnorm(1, meanlog = 0.59, sdlog = 1.99))), by = genc_id]

    # ensure that transfusions do not go beyond the end date
    df1[as.numeric(max_issue_date) > as.numeric(end_date), max_issue_date := end_date]

    # get all issued date times
    df1[, issue_date_time := as.Date(round(runif(.N,
      min = as.numeric(min_issue_date),
      as.numeric(max_issue_date)
    ))) +
      dhours(sample_time_shifted(.N, 8.7, 9.1, 2.7, max = 30, seed = seed))]
  }

  # remove seconds and turn into character
  df1[, issue_date_time := substr(as.character(issue_date_time), 1, 16)]

  ##### get `blood_product_mapped_omop` data from .Rda file #####
  # It maps the most common raw names of blood products to OMOP code
  # Also gets their average relative proportions
  blood_product_lookup <- Rgemini::blood_product_lookup %>%
    data.table()

  if (is.null(blood_product_list)) {
    all_blood_product <- blood_product_lookup$blood_product_mapped_omop

    # each hospital does 1-16 types of unique blood products
    # used truncated skewed normal to get this number
    df1[, n_products := floor(rsn_trunc(1, 12.5, 4.7, -1.9, 1, 16)), by = hospital_num]

    # hospital-level variation: set the top 1-2 types of transfusions per hospital
    # for other transfusions, sample randomly from the assigned set
    df1[, first_code := sample(c("4022173", "4023915", "4137859"),
      1,
      replace = TRUE, prob = c(0.7, 0.05, 0.25)
    ), by = hospital_num]

    # proportion of the most common code within a hospital
    df1[, prop_first := runif(1, 0.55, 1), by = hospital_num]

    df1[n_products == 1, prop_first := 1]

    # proportion of the second most common code
    df1[, sum_first_second := ifelse(prop_first[1] == 1,
      1,
      rsn_trunc(1, 0.94, 0.13, -2.1, prop_first[1], 1)
    ), by = hospital_num]

    second_codes <- data.table(
      codes = c("4137859", "35615187", "4022171", "4023915", "4130829", "4130829"),
      probs = c(0.1, 0.03, 0.1, 0.6, 0.1, 0.07)
    )

    df1[, second_code := {
      available <- setdiff(second_codes$codes, first_code)
      prob <- second_codes$probs[match(available, second_codes$codes)]
      sample(available, 1, prob = prob, replace = TRUE)
    }, by = hospital_num]

    # for hospitals with only one blood product type or more
    df1[, prop_second := ifelse(n_products >= 2, max(sum_first_second - prop_first, 0), 0), by = hospital_num]

    df1[n_products == 2, prop_second := 1 - prop_first]

    # get all other blood products by hospital
    # based on probabilities from the actual data table
    df1[, other_product := lapply(
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
    df1[, blood_product_mapped_omop := ifelse(rbinom(1, 1, prop_first),
      first_code,
      ifelse(rbinom(1, 1, prop_second),
        second_code,
        sample(c(second_code, "4022173"), 1)
      )
    ), by = genc_id]

    # fill remaining codes
    # ~0.04 have the remaining codes
    df1[genc_id %in% sample(unique(genc_id), round(0.05 * nid)), blood_product_mapped_omop := lapply(
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

    df1[, genc_occurrence := seq_len(.N), by = genc_id]

    # a proportion of 0.05 of genc_id have multiple types of transfusions
    # account for this by another round of random sampling by `genc_id`
    df1[genc_id %in% sample(
      unique(genc_id), round(0.05 * nid)
    ) & genc_occurrence > 1, blood_product_mapped_omop := sample(
      setdiff(all_blood_product, blood_product_mapped_omop), .N,
      replace = TRUE
    )]

    # assign some 0 and NA
    df1[hospital_num %in% sample(
      unique(hospital_num), round(n_hospitals / 30)
    ), blood_product_mapped_omop := ifelse(rbinom(.N, 1, 0.05), "0", blood_product_mapped_omop)]

    # NA for 1/30 hospitals
    df1[hospital_num %in% sample(
      unique(hospital_num), round(n_hospitals / 30)
    ), blood_product_mapped_omop := ifelse(rbinom(.N, 1, 0.01), NA, blood_product_mapped_omop)]

    # a few hospitals have one unique code
    df1[hospital_num %in% sample(
      unique(hospital_num), round(n_hospitals / 15)
    ), blood_product_mapped_omop := "4137859"]

    df1[hospital_num %in% sample(
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
    df1[, blood_product_mapped_omop := sample(blood_product_list, .N, replace = TRUE)]

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

  ##### get `blood_product_mapped_raw` #####
  # set blood_product_raw by joining `df1` with the lookup table
  df1 <- left_join(df1, blood_product_lookup, by = join_by(blood_product_mapped_omop))
  df1[blood_product_mapped_omop == "0", blood_product_raw := "FAR"]
  df1[is.na(blood_product_mapped_omop), blood_product_raw := NA]

  return(df1[
    order(df1$genc_id),
    c("genc_id", "hospital_num", "issue_date_time", "blood_product_mapped_omop", "blood_product_raw")
  ]) # only include relevant columns in the final output
}

#' @title
#' Generate simulated radiology data
#'
#' @description
#' This function creates a dummy dataset with a subset of variables that
#' are contained in the GEMINI "radiology" table, as seen in
#' [GEMINI Data Repository Dictionary](https://geminimedicine.ca/the-gemini-database/).
#'
#' This function only simulates modalities used in Our Practice Report (OPR) - CT, MRI,
#' Ultrasound. It does not cover all modalities seen in the actual "radiology" data table.
#'
#' @param nid (`integer`)\cr Number of unique encounter IDs to simulate.
#' Encounter IDs may repeat to simulate multiple radiology tests,
#' resulting in a data table with more rows than `nid`.
#' This input is optional if `cohort` is provided.
#'
#' @param n_hospitals(`integer`)\cr The number of hospitals to simulate.
#' This optional is optional if `cohort` is provided.
#'
#' @param time_period (`vector`)\cr A numeric or character vector containing the data range of the data
#' by years or specific dates in either format: ("yyyy-mm-dd", "yyyy-mm-dd") or (yyyy, yyyy)
#' The start date and end date will be (yyyy-01-01 and yyyy-12-31) if (yyyy, yyyy)
#' is the date range format provided. Optional when `cohort` is provided.
#'
#' @param cohort  (`data.frame or data.table`)\cr Optional, data frame or data table with the following columns:
#' - `genc_id` (`integer`): Mock encounter ID number
#' - `hospital_num` (`integer`): Mock hospital ID number
#' - `admission_date_time` (`character`): Date and time of IP admission in YYYY-MM-DD HH:MM format
#' - `discharge_date_time` (`character`): Date and time of IP discharge in YYYY-MM-DD HH:MM format.
#' When `cohort` is not NULL, `nid`, `n_hospitals`, and `time_period` are ignored.
#'
#' @param seed (`integer`)\cr Optional, a number to be used to set the seed for reproducible results.
#'
#' @return (`data.table`)\cr A `data.table` object similar that contains the following fields:
#' - `genc_id` (`integer`): Mock encounter ID number; integers starting from 1 or from `cohort` if provided
#' - `hospital_id` (`integer`): Mock hospital ID number; integers starting from 1 or from `cohort` if provided
#' - `modality_mapped` (`character`): Imaging modality: either MRI, CT, or Ultrasound.
#' - `ordered_date_time` (`character`): The date and time the radiology test was ordered
#' - `performed_date_time` (`character`): The date and time the radiology test was performed
#' @examples
#' cohort <- dummy_ipadmdad()
#' dummy_radiology(cohort = cohort)
#' dummy_radiology(nid = 1000, n_hospitals = 10, time_period = c(2020, 2023))
#'
#' @export

dummy_radiology <- function(
  nid = 1000, n_hospitals = 10, time_period = c(2015, 2023), cohort = NULL, seed = NULL
) {
  ####### checks for valid inputs #######
  if (!is.null(cohort)) { # if `cohort` is provided
    check_input(cohort,
      c("data.frame", "data.table"),
      colnames = c("genc_id", "hospital_num", "admission_date_time", "discharge_date_time"),
      coltypes = c("integer", "integer", "", "")
    )
    if (!all(check_date_format(c(cohort$admission_date_time, cohort$discharge_date_time), check_time = TRUE))) {
      stop("An invalid IP admission and/or discharge date time input was provided in cohort.")
    }
  } else { # when `cohort` is not provided
    check_input(list(nid, n_hospitals), "integer")

    #  check if time_period is provided/has both start and end dates
    if (any(is.null(time_period)) || any(is.na(time_period)) || length(time_period) != 2) {
      stop("Please provide time_period") # check for date formatting
    } else if (!check_date_format(time_period[1]) || !check_date_format(time_period[2])) {
      stop("Time period is in the incorrect date format, please fix")
    }

    if (nid < n_hospitals) {
      stop("Number of encounters must be greater than or equal to the number of hospitals")
    }
  }

  if (!is.null(seed)) {
    set.seed(seed)
  }

  if (!is.null(cohort)) {
    ####### if `cohort` is provided, create `df1` based on it #######
    cohort <- as.data.table(cohort)
    cohort$admission_date_time <- as.POSIXct(cohort$admission_date_time,
      format = "%Y-%m-%d %H:%M",
      tz = "UTC"
    )

    cohort$discharge_date_time <- as.POSIXct(cohort$discharge_date_time,
      format = "%Y-%m-%d %H:%M",
      tz = "UTC"
    )

    cohort$los <- as.numeric(difftime(
      cohort$discharge_date_time,
      cohort$admission_date_time,
      units = "hours"
    ))

    # generate `df1` based on `cohort`
    df1 <- generate_id_hospital(cohort = cohort, include_prop = 1, avg_repeats = 4.5, seed = seed)

    nid <- uniqueN(df1$genc_id)
    n_hospitals <- uniqueN(df1$hospital_num)

    ####### sample the gap between IP admission and ordered date time #######
    # in days
    admit_order_gap <- round(rlnorm(nrow(df1), meanlog = 0.817, sdlog = 1.215) - 0.8)

    ####### Set the `ordered_date_time` #######
    # get ordered date
    df1[, ordered_date := as.Date(admission_date_time) + ddays(admit_order_gap)]

    # sample ordered time
    df1[, ordered_time := sample_time_shifted(.N, xi = 7.9, omega = 8.8, alpha = 4.5, min = 4, max = 30, seed = seed)]

    ####### get ordered date time by combining ordered date and time #######
    df1[, ordered_date_time := ordered_date + dhours(ordered_time)]

    # ensure that `ordered_date_time` is not after `discharge_date_time`
    # re-sample bad values
    while (nrow(df1[ordered_date_time >= discharge_date_time, ]) > 0) {
      df1[
        ordered_date_time >= discharge_date_time,
        ordered_date_time := as.Date(admission_date_time) +
          dhours(sample_time_shifted(.N, xi = 7.9, omega = 8.8, alpha = 4.5, min = 4, max = 30))
      ]
    }

    # sample gap between ordered and performed date time, in hours
    # maximum perform gap is the difference between IP discharge and `ordered_date_time`
    # this prevents `perform_date_time` from being after `discharge_date_time`
    df1[, max_perform_gap := as.numeric(
      difftime(discharge_date_time, ordered_date_time, units = "hours")
    )]

    df1[, perform_gap := rlnorm_trunc(
      .N,
      meanlog = 1.3, sdlog = 1.9, min = 0, max = max_perform_gap
    )]

    df1[sample(nrow(df1), round(0.06 * nrow(df1))), perform_gap := 0] # set some values to 0

    ####### Get performed date time by adding `perform_gap` to `ordered_date_time` #######
    df1[, performed_date_time := ordered_date_time + dhours(perform_gap)]

    # performed date time should not be after discharge
    # re-sample it if performed > discharge was sampled previously
    df1[performed_date_time > discharge_date_time, performed_date_time := ordered_date_time +
      dhours(
        rlnorm_trunc(
          .N,
          meanlog = 1.3, sdlog = 1.9, min = 0, max = as.numeric(
            difftime(discharge_date_time, ordered_date_time, units = "hours")
          )
        )
      )]

    df1[performed_date_time > discharge_date_time, performed_date_time := discharge_date_time]

    df1[, ordered_date_time := substr(as.character(ordered_date_time), 1, 16)]
    df1[, performed_date_time := substr(as.character(performed_date_time), 1, 16)]
  } else {
    ####### if `cohort` is not provided, use parameters to get `df1` #######
    # check that `time_period` is valid
    time_period <- as.character(time_period)

    # get the start and end date
    if (grepl("^[0-9]{4}$", time_period[1])) {
      start_date <- as.Date(paste0(time_period[1], "-01-01"))
    } else {
      start_date <- as.Date(time_period[1])
    }

    if (grepl("^[0-9]{4}$", time_period[2])) {
      end_date <- as.Date(paste0(time_period[2], "-01-01"))
    } else {
      end_date <- as.Date(time_period[2])
    }

    if (start_date > end_date) {
      stop("Time period needs to end later than it starts")
    }

    # get a data table with hospital ID and encounter ID
    df1 <- generate_id_hospital(nid, n_hospitals, avg_repeats = 4.5, seed = seed)
    df1[, num_id_repeat := .N, by = genc_id]

    ####### sample `ordered_date_time` #######
    # get ordered time
    df1[, ordered_time := sample_time_shifted(
      nrow = nrow(df1), xi = 7.9, omega = 8.8, alpha = 4.5, min = 4, max = 30, seed = seed
    )]

    # for each `genc_id`, sample a minimum and maximum ordered date
    # this is the time range where they will have radiology scans
    df1[, min_ordered_date := as.Date(round(runif(1,
      min = as.numeric(start_date),
      max = as.numeric(end_date)
    ))), by = genc_id]

    # set time range for ordered date times
    # ensure it is not greater than `end_date`
    df1[, max_ordered_date := as.Date(min_ordered_date) +
      ddays(ceiling(rlnorm(1, meanlog = 1.33, sdlog = 1.66))),
    by = genc_id
    ]

    # Get a longer range of values for genc_id with more repeats
    df1[num_id_repeat >= 4, max_ordered_date := as.Date(min_ordered_date) +
      ddays(ceiling(rlnorm(1, meanlog = 2.27, sdlog = 1.36))),
    by = genc_id
    ]

    # ensure `max_ordered_date` it does not exceed `end_date`
    df1[max_ordered_date > end_date, max_ordered_date := end_date]
    # protect from `min_ordered_date` being after `max_ordered_date`
    # set it to either the median date range or start date in the range
    df1[min_ordered_date > max_ordered_date, min_ordered_date := max(start_date, min_ordered_date + 4)]

    # uniformly sample an ordered date during the range
    df1[, ordered_date := as.Date(round(
      runif(.N, min = as.numeric(min_ordered_date), max = as.numeric(max_ordered_date))
    ))]

    # get `ordered_date_time` by comibining the date and time
    df1[, ordered_date_time := ymd(df1$ordered_date) + dhours(ordered_time)]

    ####### Sample `performed_date_time` #######
    # based on `ordered_date_time`
    # sample delay time (hours) between ordered and performed
    # add a delay time to `ordered_date_time`
    df1[, perform_gap := ifelse(rbinom(.N, 1, 0.06),
      0,
      rlnorm(.N, meanlog = 1.3, sdlog = 1.9)
    )]

    df1[, performed_date_time := ordered_date_time + dhours(perform_gap)]

    # remove seconds from date times and turn it into a string
    df1[, ordered_date_time := substr(as.character(ordered_date_time), 1, 16)]
    df1[, performed_date_time := substr(as.character(performed_date_time), 1, 16)]
  }

  ####### Get `modality_mapped` #######
  # probabilities of included modalities
  prob <- data.table(
    "modality_mapped" = c("CT", "MRI", "Ultrasound"),
    "p" = c(0.6, 0.1, 0.3)
  )
  # Introduce random hospital-level variability in modality proportions
  # 0.005 = level of variability
  df1[, p := list(list(as.numeric(t(rdirichlet(1, alpha = prob$p / 0.005))))), by = hospital_num]

  df1[, modality_mapped := sapply(p, function(v) {
    base::sample(prob$modality_mapped, 1, replace = TRUE, prob = v / (sum(v)))
  })]

  # hospitals without MRI
  # In real data, not all hospitals have an MRI machine on site.
  # Randomly select hospitals without MRI (~10%) and replace modality with CT and Ultrasound
  hosp_no_mri <- sample(unique(df1$hospital_num), round(n_hospitals * 0.1), replace = FALSE)

  df1[hospital_num %in% hosp_no_mri, p_no_mri := as.numeric(runif(1, 0.55, 0.75)), by = hospital_num]
  df1[hospital_num %in% hosp_no_mri, modality_mapped := sample(
    c("CT", "Ultrasound"),
    .N,
    prob = c(.SD[1, p_no_mri], 1 - .SD[1, p_no_mri]),
    replace = TRUE
  ),
  by = hospital_num
  ]

  # return final data table with only required columns
  return(df1[order(df1$genc_id), c("genc_id", "hospital_num", "ordered_date_time", "performed_date_time", "modality_mapped")])
}

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
#' @param dbcon (`DBIConnection`)\cr
#'  A connection to the GEMINI database, used to access the 2021 Canadian census dissemination codes.
#' It is required when `da21uid` is missing. If `da21uid` is provided, then this input is ignored.
#'
#' @param nid (`integer`)\cr Number of unique encounter IDs to simulate. In this data table, each ID occurs once.
#' It is optional when `cohort` is provided.
#'
#' @param n_hospitals (`integer`)\cr Number of hospitals in simulated dataset.
#' It is optional when `cohort` is provided.
#'
#' @param da21uid (`integer` or `vector`)\cr Allows the user to customize which dissemination area ID to include in
#' the output. It is required when `dbcon` is missing. It can be an integer or an integer vector.
#' If included, the `dbcon` is not used.
#'
#' @param seed (`integer`)\cr Optional, a number to be used to set the seed for reproducible results.
#'
#' @param cohort (`data.frame or data.table`) Optional, an existing data frame or data table similar to `admdad` in
#' GEMINI with at least the following columns:
#' - `genc_id` (`integer`): Mock encounter ID
#' - `hospital_num` (`integer`): Mock hospital ID
#' If `cohort` is provided, `nid` and `n_hospital` inputs are not used.
#'
#' @return (`data.table`)\cr
#' A data.table object similar to the "locality_variables" table that contains the following fields:
#' - `genc_id` (`integer`): Mock encounter ID; integers starting from 1 or from `cohort` if provided
# - `hospital_num` (`integer`): Mock hospital ID; integers starting from 1 or from `cohort` if provided
#' - `da21uid` (`integer`): Dissemination area ID based on 2021 Canadian census data using PCCF Version 8A
#'
#' @import DBI
#'
#' @export

dummy_locality <- function(dbcon = NULL, nid = 1000, n_hospitals = 10, cohort = NULL, da21uid = NULL, seed = NULL) {
  ### check inputs
  if (is.null(dbcon) && is.null(da21uid)) {
    stop("A DB connection or list of dissemination codes is required.")
  }

  if (!is.null(da21uid)) {
    check_input(da21uid, "integer")
  } else {
    check_input(dbcon, c("DBI", "dbcon", "PostgreSQL"))
  }

  if (is.numeric(seed)) {
    set.seed(seed)
  }

  if (!is.null(cohort)) {
    # check for correct columns in `cohort` if it is provided
    check_input(cohort,
      c("data.frame", "data.table"),
      colnames = c("genc_id", "hospital_num"),
      coltypes = c("integer", "integer")
    )
  } else {
    # if `cohort` is not provided, check inputs that will be used
    check_input(list(nid, n_hospitals), "integer")

    if (nid < n_hospitals) {
      stop("Number of encounters must be greater than or equal to the number of hospitals")
    }
  }

  if (!is.null(cohort)) {
    # set up `df1` if `cohort` is included
    cohort <- as.data.table(cohort)
    df1 <- generate_id_hospital(cohort = cohort, include_prop = 1, avg_repeats = 1, seed = seed)
    nid <- uniqueN(df1$genc_id)
    n_hospitals <- uniqueN(df1$hospital_num)

    # only include the `genc_id` and `hospital_num` columns from `cohort`
    df1 <- df1[, c("genc_id", "hospital_num")]
  } else {
    # generate a cohort from nid and n_hospitals
    df1 <- generate_id_hospital(nid, n_hospitals, avg_repeats = 1, seed = seed)
  }

  if (!is.null(da21uid)) {
    # if the user provided ID, use those
    # if user provided one ID, fill the column with that
    # otherwise, randomly sample from the list
    df1[, da21uid := {
      if (length(da21uid) == 1) {
        rep(da21uid, .N)
      } else {
        sample(da21uid, .N, replace = TRUE)
      }
    }]
  } else {
    # otherwise sample from the database
    # get dissemination code lookup table from database
    lookup_statcan_v2021 <- dbGetQuery(dbcon, "SELECT da21uid FROM lookup_statcan_v2021") %>% data.table()

    # extract Ontario dissemination codes to resemble GEMINI data characteristics - these IDs start with 35
    ontario_id <- subset(
      lookup_statcan_v2021,
      lookup_statcan_v2021$da21uid < 3.6e7 & lookup_statcan_v2021$da21uid >= 3.5e7
    )$da21uid

    # to mimic how locality IDs are clustered by hospital, set a range for min and max ID for each hospital
    df1[, c("min_id", "max_id") := {
      repeat {
        min_pick <- sample(ontario_id, 1)
        candidates <- ontario_id[ontario_id > min_pick]
        if (length(candidates) > 0) break # ensure min_id < max_id
      }
      list(min_pick, sample(candidates, 1))
    }, by = hospital_num]

    # sample dissemination ID within the range per hospital
    df1[, da21uid := mapply(function(x, y) {
      sample(ontario_id[ontario_id >= x & ontario_id <= y], 1, replace = TRUE)
    }, min_id, max_id)]

    # insert a small proportion (0.3%) of cases located outside of Ontario
    # sample from da21uid outside of Ontario
    n_edge <- round(0.003 * nrow(df1))
    rows_edge <- sample(seq_len(nrow(df1)), n_edge)

    df1[rows_edge, da21uid := sample(setdiff(lookup_statcan_v2021, ontario_id),
      .N,
      replace = TRUE
    )]

    # inject 2% rate of missingness in da21uid
    df1[, da21uid := ifelse(rbinom(.N, 1, 0.02), NA, da21uid)]

    # remove extra columns and return
    df1 <- df1[, -c("min_id", "max_id")]
  }
  return(df1[order(df1$genc_id)])
}

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
#' - `adm_phy_cpso_mapped` (`integer`): Unique hash of admitting physician CPSO Number
#' - `mrp_cpso_mapped` (`integer`): Unique hash of most responsible physician (MRP) CPSO Number
#' - `dis_phy_cpso_mapped` (`integer`): Unique hash of discharging physician CPSO Number
#'
#' @examples
#' dummy_physicians(nid = 1000, n_hospitals = 10, seed = 1)
#' dummy_physicians(cohort = dummy_ipadmdad(), seed = 2)
#'
#' @export

dummy_physicians <- function(nid = 1000, n_hospitals = 10, cohort = NULL, seed = NULL) {
  if (!is.null(seed)) {
    set.seed(seed)
  }

  ####### checks for valid inputs #######
  if (!is.null(cohort)) { # if `cohort` is provided
    check_input(cohort,
      c("data.frame", "data.table"),
      colnames = c("genc_id", "hospital_num"),
      coltypes = c("integer", "integer")
    )
  } else { # when `cohort` is not provided
    check_input(list(nid, n_hospitals), "integer")

    if (nid < n_hospitals) {
      stop("Number of encounters must be greater than or equal to the number of hospitals")
    }
  }

  if (!is.null(cohort)) {
    # if `cohort` is provided, use its `genc_id` and `hospital_num`
    cohort <- as.data.table(cohort)
    df1 <- generate_id_hospital(cohort = cohort, include_prop = 1, avg_repeats = 1, seed = seed)

    nid <- length(unique(df1$genc_id))
    n_hospitals <- length(unique(df1$hospital_num))

    # only include the genc_id and hospital_num columns from `cohort`
    df1 <- df1[, c("genc_id", "hospital_num")]
  } else {
    # no repeating genc_id in physicians data table
    df1 <- generate_id_hospital(nid, n_hospitals, avg_repeats = 1, seed = seed)
  }

  # Function that samples a value from a given vector with replacement
  sample_from_col <- function(dat) {
    return(sample(dat, 1, replace = TRUE))
  }

  # set the NA proportions per hospital per variable
  # sampling creates hospital-level variation
  # each row is a different hopsital
  hosp_na_prop <- df1 %>%
    group_by(
      hospital_num
    ) %>%
    reframe(
      admitting_phy_gim_NA = runif(1, 0, 1),
      discharging_phy_gim_NA = runif(1, 0, 1),
      adm_phy_cpso_mapped_NA = rbeta(1, 0.2, 1.1),
      dis_phy_cpso_mapped_NA = rbeta(1, 0.25, 2.7),
      mrp_cpso_mapped_NA = rbeta(1, 0.4, 11.2),
      admitting_phy_gim_NA = runif(1, 0, 1),
      admitting_phy_gim_Y = runif(1, 0, 1),
      discharging_phy_gim_NA = runif(1, 0, 1),
      discharging_phy_gim_Y = runif(1, 0, 1),
    ) %>%
    data.table()

  # edit `adm_phy_cpso_mapped` and `dis_phy_cpso_mapped`
  # hospitals with highest adm also have highest dis NA proportion
  # artificially add some counts of proportion 1.0 NA
  na_order_adm <- order(hosp_na_prop[["adm_phy_cpso_mapped_NA"]], decreasing = TRUE)
  hosp_na_prop[["dis_phy_cpso_mapped_NA"]][na_order_adm[1:round(0.15 * n_hospitals)]] <- jitter(
    hosp_na_prop[["dis_phy_cpso_mapped_NA"]][na_order_adm[1:round(0.15 * n_hospitals)]],
    factor = 0.1
  )

  hosp_na_prop[["adm_phy_cpso_mapped_NA"]][na_order_adm[1:round(0.07 * n_hospitals)]] <- 1
  hosp_na_prop[["dis_phy_cpso_mapped_NA"]][na_order_adm[1:round(0.07 * n_hospitals)]] <- 1

  # sample all physician numbers
  # each hospital has about 280 physicians on average
  # multiply this average by n_hospitals to get the total set of physicians across all hospitals
  sample_cpso <- round(runif(280 * n_hospitals, min = 1e4, max = 3e5))

  # sample a set of unique physicians for each hospital
  hosp_na_prop$n_physicians <- rsn_trunc(n_hospitals, 470, 220, -1.6, 1, 650)
  hosp_na_prop[, phy_set := sapply(n_physicians, function(x) sample(sample_cpso, x, replace = TRUE))]

  # merge df1, the output data table, with hospital information
  df1 <- merge(df1, hosp_na_prop, by = "hospital_num", all.x = TRUE)

  # now sample all variables
  ####### `admitting_physician_gim` #######
  df1[, admitting_physician_gim := ifelse(rbinom(.N, 1, admitting_phy_gim_Y), "y", "n")]

  # sample the NAs in admitting_physician_gim
  df1[, admitting_physician_gim := ifelse(rbinom(
    .N, 1,
    admitting_phy_gim_NA
  ), NA, admitting_physician_gim)]

  ####### `discharging_physician_gim` #######
  df1[, discharging_physician_gim := ifelse(rbinom(.N, 1, discharging_phy_gim_Y), "y", "n")]

  # sample the NAs in discharging_physician_gim
  df1[, discharging_physician_gim := ifelse(rbinom(
    .N, 1,
    discharging_phy_gim_NA
  ), NA, discharging_physician_gim)]

  ####### `adm_phy_cpso_mapped` #######
  # Set adm physician
  df1[, adm_phy_cpso_mapped := sapply(phy_set, sample_from_col)]

  ####### `mrp_cpso_mapped` #######
  # 0.36 of encounters have mrp = adm
  df1[, mrp_cpso_mapped := ifelse(rbinom(.N, 1, 0.36),
    adm_phy_cpso_mapped, sapply(setdiff(phy_set, adm_phy_cpso_mapped), sample_from_col)
  )]

  ####### `dis_phy_cpso_mapped` #######
  # 0.3 of encounters have adm = mrp = dis overall
  # when adm = mrp, 0.9 of encounters have adm = mrp = dis
  df1[adm_phy_cpso_mapped == mrp_cpso_mapped, dis_phy_cpso_mapped := ifelse(rbinom(.N, 1, 0.9),
    adm_phy_cpso_mapped,
    sapply(setdiff(phy_set, adm_phy_cpso_mapped), sample_from_col)
  )]

  # when adm != mrp, 0.84 of dis = mrp and dis != adm always
  # these will cover all cases of relations between adm, mrp, and dis
  df1[adm_phy_cpso_mapped != mrp_cpso_mapped, dis_phy_cpso_mapped := ifelse(rbinom(.N, 1, 0.87),
    mrp_cpso_mapped,
    sapply(setdiff(phy_set, c(mrp_cpso_mapped)), sample_from_col)
  )]

  return(df1[
    order(df1$genc_id), # return only with required columns
    c(
      "genc_id", "hospital_num", "admitting_physician_gim", "discharging_physician_gim", "adm_phy_cpso_mapped",
      "mrp_cpso_mapped"
    )
  ])
}