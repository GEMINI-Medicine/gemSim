#' @title
#' Simulate admdad data
#'
#' @description
#' This function creates a dummy dataset with a subset of variables that
#' are contained in the GEMINI "admdad" table (see details in
#' [GEMINI Data Repository Dictionary](https://geminimedicine.ca/the-gemini-database/)).
#'
#' The simulated encounter-level variables that are returned by this function
#' are currently: Admission date-time, discharge date-time, age, gender,
#' discharge disposition, transfer to an alternate level of care (ALC), and ALC
#' days. The distribution of these simulated variables roughly mimics the real
#' distribution of each variable observed in the GIM cohort from 2015-2022.
#' Admission date-time is simulated in conjunction with discharge date-time to
#' mimic realistic length of stay. All other variables are simulated
#' independently of each other, i.e., there is no correlation between age,
#' gender, discharge disposition etc. that may exist in the real data. One
#' exception to this is `number_of_alc_days`, which is only > 0 for entries
#' where `alc_service_transfer_flag == TRUE` and the length of ALC is capped at
#' the total length of stay.
#'
#' The function simulates patient populations that differ across hospitals. That
#' is, patient characteristics are simulated separately for each hospital, with
#' a different, randomly drawn distribution mean (i.e., random intercepts).
#' However, the degree of hospital-level variation simulated by this function
#' is arbitrary and does not reflect true differences between hospitals in the
#' real GEMINI dataset.
#'
#' @param nid (`integer`)\cr Total number of encounters (`genc_ids`) to be
#' simulated.
#'
#' @param n_hospitals (`integer`)\cr
#' Number of hospitals to be simulated. Total number of `genc_ids` will be split
#' up pseudo-randomly between hospitals to ensure roughly equal sample size at
#' each hospital.
#'
#' @param time_period (`vector`)\cr
#' A numeric vector containing the time period, specified as fiscal years
#' (starting in April each year). For example, `c(2015, 2019)` generates data
#' from 2015-04-01 to 2020-03-31.
#'
#' @param seed (`numeric`)\cr
#' Optional, a number to set the seed for reproducible results
#'
#' @return (`data.frame`)\cr A data.frame object similar to the "admdad" table
#' containing the following fields:
#' - `genc_id` (`integer`): Mock encounter ID; integers starting from 1
#' - `hospital_num` (`integer`): Mock hospital ID number; integers starting from 1
#' - `admission_date_time` (`character`): Date-time of admission in YYYY-MM-DD HH:MM format
#' - `discharge_date_time` (`character`): Date-time of discharge in YYYY-MM-DD HH:MM format
#' - `age` (`integer`): Patient age
#' - `gender` (`character`): Patient gender (F/M/O for Female/Male/Other)
#' - `discharge_disposition` (`integer`): All valid categories according to DAD
#' abstracting manual 2022-2023
#'    - 4: Home with Support/Referral
#'    - 5: Private Home
#'    - 8: Cadaveric Donor (does not exist in GEMINI data)
#'    - 9: Stillbirth (does not exist in GEMINI data)
#'    - 10: Transfer to Inpatient Care
#'    - 20: Transfer to ED and Ambulatory Care
#'    - 30: Transfer to Residential Care
#'    - 40: Transfer to Group/Supportive Living
#'    - 90: Transfer to Correctional Facility
#'    - 61: Absent Without Leave (AWOL)
#'    - 62: Left Against Medical Advice (LAMA)
#'    - 65: Did not Return from Pass/Leave
#'    - 66: Died While on Pass/Leave
#'    - 67: Suicide out of Facility (does not exist in GEMINI data)
#'    - 72: Died in Facility
#'    - 73: Medical Assistance in Dying (MAID)
#'    - 74: Suicide in Facility
#' - `alc_service_transfer_flag` (`character`): Variable indicating whether
#' patient was transferred to an alternate level of care (ALC) during their
#' hospital stay. Coding is messy and varies across sites. Possible values are:
#'    - Missing: `NA`, `""`
#'    - True: `"TRUE"/"true"/"T"`, `"y"/"Y"`, `"1"/"99"`, `"ALC"`
#'    - False: `"FALSE"/"false"`, `"N"`, `"0"`, `"non-ALC"`
#' Some entries with missing `alc_service_transfer_flag` can be inferred based
#' on value of `number_of_alc_days` (see below)
#' - `number_of_alc_days` (`integer`): Number of days spent in ALC (rounded to
#' nearest integer). If `number_of_alc_days = 0`, no ALC occurred;
#' if `number_of_alc_days > 0`, ALC occurred.
#' Note that days spent in ALC should usually be < length of
#' stay. However, due to the fact that ALC days are rounded up, it's possible
#' for `number_of_alc_days` to be larger than `los_days_derived`.
#'
#' @import data.table
#' @import Rgemini
#' @importFrom sn rsn
#' @importFrom MCMCpack rdirichlet
#' @importFrom lubridate ymd_hm dhours ddays
#' @export
#'
#' @examples
#' # Simulate 10,000 encounters from 10 hospitals for fiscal years 2018-2020.
#' admdad <- dummy_admdad(nid = 10000, n_hospitals = 10, time_period = c(2018, 2020))
#'
dummy_admdad <- function(nid = 1000,
                         n_hospitals = 10,
                         time_period = c(2015, 2023),
                         seed = NULL) {
  ############## CHECKS: for valid inputs: `n_id`, `n_hospitals`, `time_period`
  Rgemini:::check_input(list(nid, n_hospitals), "integer")
  Rgemini:::check_input(time_period, c("numeric", "character", "POSIXct"), length = 2)

  time_period <- as.character(time_period)

  # get start and end dates
  if (grepl("^[0-9]{4}$", time_period[1])) {
    # if the user only provided a year
    start_date <- convert_dt(paste0(time_period[1], "-01-01"), "ymd")
  } else {
    # convert to date while checking for the format
    # stop if the format is not correct
    tryCatch(
      {
        start_date <- convert_dt(time_period[1], "ymd")
      },
      warning = function(w) {
        stop(conditionMessage(w))
      }
    )
  }

  if (grepl("^[0-9]{4}$", time_period[2])) {
    # if the user only provided a year
    end_date <- convert_dt(paste0(time_period[2], "-12-31"), "ymd")
  } else {
    # convert to date while checking for the format
    # stop if the format is not correct
    tryCatch(
      {
        end_date <- convert_dt(time_period[2], "ymd")
      },
      warning = function(w) {
        stop(conditionMessage(w))
      }
    )
  }

  # Make sure `nid` is at least `n_hospitals`
  if (nid < n_hospitals) {
    stop("Invalid user input.
    Number of encounters `nid` should at least be equal to `n_hospitals`")
  }

  # set the seed if the input provided is not NULL
  if (!is.null(seed)) {
    set.seed(seed)
  }

  ############### PREPARE OUTPUT TABLE ###############
  ## create all combinations of hospitals and dates
  hosp_names <- as.integer(seq(1, n_hospitals, 1))
  hosp_assignment <- sample(hosp_names, nid, replace = TRUE)

  id_list <- 1:nid
  id_vector <- rep(id_list, times = rep(1, nid))
  site_vector <- rep(hosp_assignment, times = rep(1, nid))

  data <- data.table(genc_id = id_vector, hospital_num = site_vector, stringsAsFactors = FALSE)

  # turn year variable into actual date by randomly drawing date_time
  add_random_datetime <- function(n, start_date, end_date) {
    random_date <- as.Date(round(runif(n,
      min = as.numeric(as.Date(start_date)),
      max = as.numeric(as.Date(end_date))
    )))

    random_datetime <- format(as.POSIXct(random_date + dhours(sample_time_shifted(n,
      xi = 19.5, omega = 6.29, alpha = 0.20, seed = seed
    )), tz = "UTC"), format = "%Y-%m-%d %H:%M")

    return(random_datetime)
  }

  # create discharge_date_time first (because data are pulled by discharge)
  data[, discharge_date_time := add_random_datetime(.N, start_date, end_date)]

  ############### DEFINE VARIABLE DISTRIBUTIONS ###############
  ## AGE
  # create left-skewed distribution, truncated from 18-110
  age_distr <- function(nid = 10000, xi = 95, omega = 30, alpha = -10) {
    age <- rsn(nid, xi, omega, alpha)

    # truncate at [18, 110]
    age <- as.integer(age[age >= 18 & age <= 110])
  }


  ############### ADD VARIABLES CLUSTERED BY HOSPITAL ###############
  # Any encounter characteristics (e.g., age/gender/discharge disposition) are
  # simulated as being clustered by hospital (i.e., each hospital will be
  # simulated as random intercept, i.e., different location parameter)
  add_vars <- function(hosp_data) {
    n_enc <- nrow(hosp_data)

    ## AGE
    # create new age distribution for each hospital where location parameter xi
    # varies to create a random intercept by site
    age <- age_distr(xi = rnorm(1, 95, 5))
    hosp_data[, age := sample(age, n_enc, replace = TRUE)]

    ## Gender (F/M/Other)
    prob <- data.table(
      "gender" = c("F", "M", "O"),
      "p" = c(.501, .498, 0.001 + 1e-5)
    ) # add small constant to Os to ensure it's not rounded to 0 below
    # Introduce random hospital-level variability
    prob[, p := t(rdirichlet(1, alpha = prob$p / 0.005))] # 0.005 = level of variability
    hosp_data[, gender := sample(prob$gender, n_enc,
      replace = TRUE,
      prob$p / sum(prob$p)
    )]
    # make sure probs add up to 1 (see addition of constant above)

    ## DISCHARGE DISPOSITION
    prob <- data.table(
      "discharge_disposition" = c(4, 5, 8, 9, 10, 20, 30, 40, 61, 62, 65, 66, 67, 72, 73, 74, 90),
      "p" = c(
        .275, .386, 0, 0, .143, 0.002, .045, .040, .001 + 1e-5, .028, 0.001 + 1e-5, 0.001 + 1e-5,
        0, .079, .001 + 1e-5, 0.001 + 1e-5, .001
      )
    ) # add small constant to Os to ensure it's not rounded to 0 below
    prob[, p := t(rdirichlet(1, alpha = prob$p / 0.005))] # 0.005 = level of hospital-level variability
    hosp_data[, discharge_disposition := as.integer(sample(prob$discharge_disposition, n_enc,
      replace = TRUE, prob$p / sum(prob$p)
    ))] # make sure probs add up to 1 (see addition of constant above)

    ## Simulate LOS to derive discharge_date_time
    # create right-skewed distribution with randomly drawn offset by site]
    hosp_data[, los := {
      mean_hosp <- rnorm(1, mean = 1.27, sd = 0.11)
      rlnorm(.N, meanlog = mean_hosp, sdlog = 1.38)
    }, by = hospital_num] # hospital-level variation in distribution


    hosp_data[, admission_date_time := format(
      round_date(as.POSIXct(discharge_date_time, tz = "UTC") -
                   ddays(los), unit = "days") -
        dhours(sample_time_shifted(.N, xi = 11.37, omega = 4.79, alpha = 1.67, seed = seed)),
      format = "%Y-%m-%d %H:%M", tz = "UTC"
    )]


    # if `discharge_date_time` ends up before `admission_date_time`
    hosp_data[, los := as.numeric(difftime(ymd_hm(discharge_date_time), ymd_hm(admission_date_time), units = "days"))]
    hosp_data[los < 0, admission_date_time := format(ymd_hm(admission_date_time) - ddays(1), "%Y-%m-%d %H:%M")]
    # handle sampling edge case with negative los

    ## Alternate level of care (ALC) & days spent in ALC
    # ALC flag
    prob <- data.table(
      "alc_service_transfer_flag" = c("FALSE", "TRUE", NA),
      "p" = c(.85, .11, .04)
    )
    prob[, p := t(rdirichlet(1, alpha = prob$p / 0.05))] # 0.05 = level of variability
    hosp_data[, alc_service_transfer_flag := sample(prob$alc_service_transfer_flag, n_enc,
      replace = TRUE,
      prob$p / sum(prob$p)
    )] # make sure probs add up to 1 (see addition of constant above)

    # Days spent in ALC (as integer)
    # If ALC = FALSE, ALC days are either coded as 0 or NA (random across sites)
    hosp_data[alc_service_transfer_flag == "FALSE", number_of_alc_days := sample(c(0, NA), 1, prob = c(.8, .2))]
    # If ALC = TRUE, ALC days are drawn from uniform distribution between 0 and LOS
    # (divided by 1.5 because ALC should be < LOS)
    # Note: because ALC is rounded UP, this results in some entries where ALC > LOS
    # (especially for cases with short LOS); this mimics entries we find in our real data as well
    hosp_data[alc_service_transfer_flag == "TRUE", number_of_alc_days := ceiling(runif(.N, 0, ceiling(los / 1.5)))]
    # for cases where number_of_alc_days != NA,
    # alc_service_transfer_flag is NA anywhere from 0-100% by site (mostly 0 or 100, but some in-between),
    # so let's mimic that
    hosp_data[
      genc_id %in% hosp_data[!is.na(number_of_alc_days)][
        sample(.N, size = round(sample(c(0, .25, .50, .75, 1), prob = c(.59, .05, .05, .01, .3), 1) * .N)), "genc_id"
      ],
      alc_service_transfer_flag := NA
    ]

    # randomly recode values referring to FALSE/TRUE to simulate real messiness of ALC coding
    coding <- t(
      data.table(
        code1 = c("FALSE", "TRUE"),
        code2 = c("0", "1"),
        code3 = c("0", "99"),
        code4 = c("N", "Y"),
        code5 = c("n", "y"),
        code6 = c("false", "true"),
        code7 = c("non-ALC", "ALC"),
        code8 = c(NA, "Y")
      ) # this is intentional, some sites only code "true", everything else is missing...
    )
    code <- sample(seq_len(nrow(coding)), 1)

    hosp_data[alc_service_transfer_flag == FALSE, alc_service_transfer_flag := coding[code, 1]]
    hosp_data[alc_service_transfer_flag == TRUE, alc_service_transfer_flag := coding[code, 2]]
    # code missing as NA or "" (randomly per site)
    hosp_data[is.na(alc_service_transfer_flag), alc_service_transfer_flag := sample(c(NA, ""), 1, prob = c(.8, .2))]

    return(hosp_data)
  }


  # note: split data by hospital before running foverlaps to avoid working with massive tables
  cohort_hospitals <- split(data, data$hospital_num)
  data_all <- lapply(cohort_hospitals, add_vars)


  ##  Combine all
  data <- do.call(rbind, data_all)

  ## Select relevant output variables
  data <- data[order(genc_id), .(
    genc_id,
    hospital_num,
    admission_date_time,
    discharge_date_time,
    age,
    gender,
    discharge_disposition,
    alc_service_transfer_flag,
    number_of_alc_days
  )]

  # Return as data.frame (instead of data.table) as this is what SQL queries return
  data <- as.data.frame(data)

  return(data)
}
