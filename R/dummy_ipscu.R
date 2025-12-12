#' @title
#' Sample SCU admission and discharge date times by genc_id.
#'
#' @description
#' The "ipscu" data table is a long format data table with multiple repeats for each genc_id.
#' SCU admission and discharge date times must be sampled in such a way that SCU stays occur between
#' inpatient admission and discharge dates and times, and that if a patient has multiple SCU stays,
#' they do not overlap. This is a helper function for `dummy_ipscu`.
#'
#' @param scu_cohort (`data.table`) The dummy data table requiring the addition of SCU admission and discharge
#' date time columns. It requires the following columns:
#' - `genc_occurrence` (`integer`): for each `genc_id`, its numbered appearance in the data table, i.e. 1, 2, 3, ...
#' - `genc_id` (`integer`): Mock encounter ID; integers starting from 1
#' - `hospital_num` (`integer`): Mock hospital ID number; integers starting from 1
#' If `use_ip_dates` is TRUE, it will also require the following columns:
#' - `admission_date_time` (`POSIXct`): the date and time of IP admission in YYYY-MM-DD HH:MM format
#' - `discharge_date_time` (`POSIXct`): the date and time of IP discharge in YYYY-MM-DD HH:MM format
#'
#' @param use_ip_dates (`logical`) Optional, whether the table `scu_cohort` contains information about inpatient
#' admission and discharge date times. If TRUE, the function will sample SCU data based on these date times and
#' if not, it will sample at random.
#'
#' @param start_date (`Date`) Optional, the earliest date in the range for the SCU admissions in the dummy data table.
#' It is not used if `use_ip_dates` is TRUE.
#'
#' @param end_date (`Date`) Optional, the latest date in the range for the SCU admissions in the dummy data table.
#' It is not used if `use_ip_dates` is TRUE.
#'
#' @param seed (`integer`) Optional, an integer for setting the seed for reproducible results.
#'
#' @return (`data.table`) A copy of the input, `scu_cohort`, will be returned.
#' It will contain the same fields, with the addition of:
#' - `scu_admit_date_time` (`character`): the date and time of admission to the SCU
#' - `scu_discharge_date_time` (`character`): the date and time of discharge from the SCU
#'
#' @import Rgemini
#' @import lubridate
#' @import data.table
#'
#' @export
#'
sample_scu_date_time <- function(scu_cohort, use_ip_dates = TRUE, start_date = NULL, end_date = NULL, seed = NULL) {
  if (!is.null(seed)) {
    set.seed(seed)
  }

  ## Check inputs ##
  if (use_ip_dates) {
    # if `scu_cohort` contains IP admission and discharge date times
    Rgemini:::check_input(scu_cohort,
      c("data.table"),
      colnames = c("genc_id", "hospital_num", "admission_date_time", "discharge_date_time"),
      coltypes = c("integer", "integer", "POSIXct", "POSIXct")
    )
  } else {
    # if `scu_cohort` does not have IP admission and discharge date times
    Rgemini:::check_input(scu_cohort,
      c("data.table"),
      colnames = c("genc_id", "hospital_num"),
      coltypes = c("integer", "integer")
    )
    Rgemini:::check_input(start_date, c("Date", "POSIXct", "POSIXt"))
    Rgemini:::check_input(end_date, c("Date", "POSIXct", "POSIXt"))

    if (start_date > end_date) {
      stop("Time period needs to end later than it starts")
    }
  }

  ####### Loop through the first, second, third, ... encounters of each genc_id #######
  for (i in 1:max(scu_cohort$genc_occurrence)) {
    if (i == 1) {
      # sample first repeat of genc_id
      n <- length(which(scu_cohort$genc_occurrence == i))
      ####### sample admission dates #######
      # use a delay (days) between IP and SCU admissions
      # zero-inflated log normal distribution
      days_after_admit <- round(rlnorm(n = n, meanlog = 1.12, sdlog = 1.21))
      days_after_admit[sample(1:n, round(0.55 * n))] <- 0
      if (use_ip_dates) {
        # if cohort contains admission and discharge date times, SCU admission is based on IP admission
        scu_admission_dates <- as.Date(scu_cohort[which(genc_occurrence == i), admission_date_time]) +
          ddays(days_after_admit)
      } else {
        # if no cohort, sample uniformly in the given Date range
        scu_admission_dates <- as.Date(round(runif(n,
          min = as.numeric(start_date),
          max = as.numeric(end_date)
        )))
      }
      ####### sample admission time in hours #######
      # this is the same whether cohort is provided or not
      # sample the skewed normal time, cut at 12am/24 hours
      scu_cohort[, scu_admit_time := sample_time_shifted(
        nrow = .N,
        xi = 11.9,
        omega = 8.5,
        alpha = 2.71,
        seed = seed
      )]
      # combine scu_admit_date with scu_admit_time for scu_admit_date_time
      scu_cohort[which(genc_occurrence == i), scu_admit_date_time := ymd(scu_admission_dates) + dhours(scu_admit_time)]
      # SCU admit date time is equal or after IP admission
      # if it is sampled to be earlier, resample
      if (use_ip_dates) {
        scu_cohort[
          genc_occurrence == i & scu_admit_date_time < admission_date_time,
          scu_admit_date_time := as.Date(admission_date_time) + ddays(1) + dhours(scu_admit_time)
        ]
        # make sure SCU admit < IP discharge
        # if not, set to admission_date_time
        scu_cohort[
          genc_occurrence == i & scu_admit_date_time >= discharge_date_time,
          scu_admit_date_time := admission_date_time
        ]
      }

      # get the length of stay in days, log normal distributed
      # add days and hours to scu_admit_date_time
      # obtains scu_discharge_date_time
      scu_cohort[genc_occurrence == i, scu_los := rlnorm(.N, meanlog = 0.78, sdlog = 1.21)]

      scu_cohort[genc_occurrence == i, scu_discharge_date_time := floor_date(
        scu_admit_date_time + ddays(scu_los),
        unit = "day"
      ) +
        dhours(sample_time_shifted(.N, xi = 11.70, omega = 6.09, alpha = 1.93, min = 5, max = 29))]

      # re-sample if SCU discharge < SCU admit
      while (nrow(scu_cohort[scu_discharge_date_time < scu_admit_date_time, ]) > 0) {
        scu_cohort[
          genc_occurrence == i & scu_discharge_date_time < scu_admit_date_time,
          scu_discharge_date_time := floor_date(
            scu_admit_date_time + ddays(scu_los),
            unit = "day"
          ) +
            dhours(sample_time_shifted(.N, xi = 11.70, omega = 6.09, alpha = 1.93, min = 5, max = 29))
        ]
      }

      # re-sample bad values where SCU discharge > IP discharge
      if (use_ip_dates) {
        scu_cohort[genc_occurrence == i, discharge_lim := as.numeric(difftime(
          discharge_date_time, scu_admit_date_time,
          units = "days"
        ))]
        while (nrow(scu_cohort[genc_occurrence == i & scu_discharge_date_time > discharge_date_time, ]) > 0) {
          scu_cohort[
            genc_occurrence == i &
              scu_discharge_date_time > discharge_date_time &
              discharge_lim <= 2,
            scu_discharge_date_time := discharge_date_time
          ]

          # re-sample the SCU LOS
          # truncate the log normal distribution to:
          # difftime: discharge_date_time - scu_admit_date_time (days)
          scu_cohort[genc_occurrence == i & scu_discharge_date_time > discharge_date_time, scu_los := rlnorm_trunc(
            .N,
            meanlog = 0.78, sdlog = 1.21, min = 0, max = discharge_lim
          )]

          scu_cohort[genc_occurrence == i & scu_discharge_date_time > discharge_date_time, scu_discharge_date_time := {
            round_date(scu_admit_date_time + ddays(floor(scu_los)), unit = "days") + dhours(
              sample_time_shifted(.N, xi = 11.70, omega = 6.09, alpha = 1.93, min = 5, max = 29)
            )
          }]
        }
      }
    } else { # when i >= 2
      # for all subsequent occurrences, add log normal time to previous discharge date times for admit date time
      # account for `discharge_date_time`
      if (use_ip_dates) {
        scu_cohort[which(genc_occurrence == i), scu_admit_date_time := {
          prev_time <- scu_cohort[
            genc_id == .BY$genc_id &
              genc_occurrence == (i - 1),
            scu_discharge_date_time
          ]
          # CASE 1: prev discharge is >= IP discharge → no more stays possible
          if (prev_time >= discharge_date_time) {
            discharge_date_time
          } else { # CASE 2
            # sample a diff in hours
            max_gap <- as.numeric(difftime(discharge_date_time, prev_time, units = "hours"))

            # direct admit OR sample a gap
            if (rbinom(.N, 1, 0.25) | prev_time == discharge_date_time) {
              prev_time
            } else {
              prev_time + dhours(
                rlnorm_trunc(
                  n = .N,
                  meanlog = 4.2, sdlog = 1.6,
                  min = 0,
                  max = max_gap
                )
              )
            }
          }
        }, by = genc_id]
      } else {
        # if no `cohort` then sample scu_discharge_date_time
        scu_cohort[which(genc_occurrence == i), scu_admit_date_time := {
          prev_time <- scu_cohort[
            genc_id == .BY$genc_id & genc_occurrence == (i - 1),
            scu_discharge_date_time
          ]

          # admit directly to the next SCU or have a gap in between
          ifelse(rbinom(.N, 1, 0.25),
            prev_time,
            prev_time + dhours(rlnorm(n = 1, meanlog = 4.2, sdlog = 1.6))
          )
        }, by = genc_id]
      }

      # add an SCU discharge date and time
      scu_cohort[which(genc_occurrence == i), scu_discharge_date_time := floor_date(scu_admit_date_time +
        ddays(rlnorm(.N, meanlog = 0.78, sdlog = 1.21)), unit = "day") +
        dhours(sample_time_shifted(.N, xi = 11.70, omega = 6.09, alpha = 1.93, min = 5, max = 29))]

      # ensure `scu_discharge_date_time` is after `scu_admit_date_time`
      scu_cohort[genc_occurrence == i &
        scu_discharge_date_time < scu_admit_date_time, scu_discharge_date_time :=
        round_date(scu_discharge_date_time, unit = "day") + ddays(1) +
        dhours(sample_time_shifted(.N, xi = 11.70, omega = 6.09, alpha = 1.93, min = 5, max = 29))]

      # re-sample invalid date time values again
      # if `scu_discharge_date_time` is after `discharge_date_time`
      if (use_ip_dates) {
        # difference between SCU admit and IP discharge
        scu_cohort[genc_occurrence == i, discharge_lim := as.numeric(difftime(
          discharge_date_time, scu_admit_date_time,
          units = "hours"
        ))]
        # avoid endless loops
        max_iter <- 20
        n_iter <- 0
        while (nrow(scu_cohort[scu_discharge_date_time > discharge_date_time, ]) > 0 && n_iter < max_iter) {
          # for very short stays, set to `scu_discharge_date_time` to `discharge_date_time`
          # avoids re-sampling in a very small range
          scu_cohort[
            genc_occurrence == i & scu_discharge_date_time > discharge_date_time & discharge_lim <= 2,
            scu_discharge_date_time := discharge_date_time
          ]

          scu_cohort[
            genc_occurrence == i & scu_discharge_date_time > discharge_date_time,
            scu_los := rlnorm_trunc(.N, meanlog = 0.78, sdlog = 1.21, min = 0, max = discharge_lim / 24)
          ]

          scu_cohort[
            genc_occurrence == i & scu_discharge_date_time > discharge_date_time,
            scu_discharge_date_time := round_date(scu_admit_date_time + ddays(floor(scu_los))) + dhours(
              sample_time_shifted(.N, xi = 11.70, omega = 6.09, alpha = 1.93, min = 5, max = 29)
            )
          ]
          n_iter <- n_iter + 1
        }
        scu_cohort <- scu_cohort[, -c("discharge_lim")]
      }
    }
  }
  # drop bad rows
  scu_cohort <- scu_cohort[!duplicated(scu_discharge_date_time) & scu_discharge_date_time < discharge_date_time, ]

  # convert all POSIXct variables to truncated strings without seconds
  if (use_ip_dates) {
    scu_cohort[, admission_date_time := substr(as.character(admission_date_time), 1, 16)]
    scu_cohort[, discharge_date_time := substr(as.character(discharge_date_time), 1, 16)]
  }
  scu_cohort[, scu_admit_date_time := substr(as.character(scu_admit_date_time), 1, 16)]
  scu_cohort[, scu_discharge_date_time := substr(as.character(scu_discharge_date_time), 1, 16)]
  # return scu_cohort without the scu_admit_time column
  return(scu_cohort[, -c("scu_admit_time", "scu_los")])
}

#' @title
#' Generate simulated ipscu data.
#'
#' @description
#' This function creates a dummy dataset with a subset of variables that
#' are contained in the GEMINI "ipscu" table, as seen in
#' [GEMINI Data Repository Dictionary](https://geminimedicine.ca/the-gemini-database/).
#'
#'
#' @param nid (`integer`)\cr Number of unique encounter IDs to simulate.
#' Encounter IDs may repeat due to repeat visits being simulated,
#' resulting in a data table with more rows than `nid`.
#'
#' @param time_period (`vector`)\cr A numeric or character vector containing the data range of the data
#' by years or specific dates in either format: ("yyyy-mm-dd", "yyyy-mm-dd") or (yyyy, yyyy).
#' The start date and end date will be (yyyy-01-01 and yyyy-12-31) if (yyyy, yyyy)
#' is the date range format provided. Optional when `cohort` is provided.
#'
#' @param n_hospitals (`integer`)\cr Number of hospitals in simulated dataset.
#'
#' @param seed (`integer`)\cr Optional, a number to be used to set the seed for reproducible results.
#'
#' @param cohort (`data.frame or data.table`)\cr Optional, data frame with the following columns:
#' - `genc_id` (`integer`): Mock encounter ID number
#' - `hospital_num` (`integer`): Mock hospital ID number
#' - `admission_date_time` (`character`): Date and time of IP admission in YYYY-MM-DD HH:MM format
#' - `discharge_date_time` (`character`): Date and time of IP discharge in YYYY-MM-DD HH:MM format.
#' When `cohort` is not NULL, `nid`, `n_hospitals`, and `time_period` are ignored.
#'
#' @return (`data.table`)\cr A data.table object similar to the "ipscu" table that contains the following fields:
#' - `genc_id` (`integer`): Mock encounter ID; integers starting from 1 or from `cohort`
#' - `hospital_num` (`integer`): Mock hospital ID number; integers starting from 1 or from `cohort`
#' - `scu_admit_date_time` (`character`): Date and time of SCU admission in YYYY-MM-DD HH:MM format
#' - `scu_discharge_date_time` (`character`): Date and time of SCU discharge in YYYY-MM-DD HH:MM format
#' - `icu_flag` (`logical`): Flag specifying whether the encounter was admitted to the ICU or not.
#'    This refers to to SCU unit numbers excluding the step down units of 90, 93, and 95.
#' - `scu_unit_number`(`integer`): Code identifying the type of special care unit where the patient receives
#'    critical care, according to DAD abstracting manual 2025-2026
#'   - 10: Medical Intensive Care Nursing Unit
#'   - 20: Surgical Intensive Care Nursing Unit
#'   - 25: Trauma Intensive Care Nursing Unit
#'   - 30: Combined Medical/Surgical Intensive Care Nursing Unit
#'   - 35: Burn Intensive Care Nursing Unit
#'   - 40: Cardiac Intensive Care Nursing Unit Surgery (CCU)
#'   - 45: Coronary Intensive Care Nursing Unit Medical (CCU)
#'   - 50: Neonatal Intensive Care Nursing Unit Undifferentiated/General
#'   - 60: Neurosurgery Intensive Care Nursing Unit
#'   - 80: Respirology Intensive Care Nursing Unit
#'   - 90: Step-Down Medical Unit
#'   - 93: Combined Medical/Surgical Step-Down Unit
#'   - 95: Step-Down Surgical Unit
#'
#' @import Rgemini
#' @import data.table
#' @import lubridate
#'
#' @export
#'
#' @examples
#' dummy_ipscu(nid = 100, n_hospitals = 10, time_period = c(2015, 2023), seed = 1)
#' dummy_ipscu(nid = 11, n_hospitals = 1, time_period = c("2020-01-01", "2021-01-01"), seed = 2)
#'
dummy_ipscu <- function(nid = 1000, n_hospitals = 10, time_period = c(2015, 2023), cohort = NULL, seed = NULL) {
  if (is.numeric(seed)) {
    set.seed(seed)
  }

  ## Check inputs and create cohorts ##
  if (!is.null(cohort)) {
    # if `cohort` is provided, check the columns
    Rgemini:::check_input(cohort,
      c("data.frame", "data.table"),
      colnames = c("genc_id", "hospital_num", "admission_date_time", "discharge_date_time"),
      coltypes = c("integer", "integer", "", "")
    )
  } else {
    # create a cohort
    # `dummy_ipadmdad()` checks inputs
    # create a cohort
    cohort <- dummy_ipadmdad(nid = nid, n_hospitals = n_hospitals, time_period = time_period, seed = seed)

    # include only required columns
    cohort <- cohort[, c("genc_id", "hospital_num", "admission_date_time", "discharge_date_time")]
  }

  cohort <- suppressWarnings(Rgemini::coerce_to_datatable(cohort))

  # create a new data table based on `cohort`
  # this step also converts cohort's admission and discharge date times into POSIXct
  df_sim <- generate_id_hospital(
    cohort = cohort,
    include_prop = 1,
    avg_repeats = 1.4,
    by_los = TRUE,
    seed = seed
  )

  # adjust `nid` and `n_hospitals`
  nid <- uniqueN(df_sim$genc_id)
  n_hospitals <- uniqueN(df_sim$hospitals)

  # Number each SCU stay per genc_id
  df_sim[, genc_occurrence := seq_len(.N), by = genc_id]

  ####### sample SCU admit and discharge date times #######
  df_sim <- sample_scu_date_time(scu_cohort = df_sim, use_ip_dates = TRUE, seed = seed)

  # keep only relevant columns
  df_sim <- df_sim[, c("genc_id", "hospital_num", "scu_admit_date_time", "scu_discharge_date_time")]

  # set remaining columns of the data.table
  # it will be the same regardless of whether cohort exists or not

  ####### set icu_flag #######
  # add hospital-level variation for the ICU flag:
  # all TRUE (no encounters go to the step down unit),
  # or low or higher FALSE proportions (FALSE goes to the step down unit)
  hosp_class <- data.table("hospital_num" = unique(df_sim$hospital_num))
  probs <- c(all_true = 0.35, low_false = 0.15, high_false = 0.5)
  hosp_class[, category := sample(c("all_true", "low_false", "high_false"), .N, replace = TRUE, prob = probs)]

  ####### determine SCU numbers in each hospital #######
  all_scu_num <- c(10, 20, 25, 30, 35, 40, 45, 50, 60, 80)
  # select a different subset of varying length for each hospital
  # each hospital has 3-10 unique SCU numbers
  hosp_class[, scu_set := lapply(
    hospital_num,
    function(x) {
      base::sample(
        all_scu_num,
        rsn_trunc(n = 1, xi = 1.5, omega = 3, alpha = 4.5, min = 3, max = 10, seed = seed)
      )
    }
  )]

  # set the range for FALSE proportion in icu_flag
  # when icu_flag = FALSE, the patient is in the step down unit
  # classifications: all true, low, or high proportion of FALSE
  # low: FALSE proportion ranges from 0.0001-0.01
  # high: FALSE proportion ranges from 0.02 to 0.6
  range_table <- data.table(
    category = c("all_true", "low_false", "high_false"),
    min_val = c(0.0, 0.0001, 0.02),
    max_val = c(0.0, 0.01, 0.6)
  )

  # merge SCU set and ICU flag classification tables
  # get a table with each hospital's SCU unit numbers and ICU flag proportion ranges
  hosp_class <- merge(hosp_class, range_table, by = "category", all.x = TRUE)
  hosp_class[, prop_false := runif(.N, min_val, max_val)]

  # merge hospital classification with existing ipscu data for sampling
  df_sim <- merge(df_sim, hosp_class, by = "hospital_num", all.x = TRUE)
  # sample binomially for the ICU flag
  df_sim[, icu_flag := ifelse(rbinom(.N, 1, prop_false), FALSE, TRUE)]

  # sample SCU number in `df_sim`
  df_sim[, scu_unit_number := sapply(scu_set, function(v) sample(v, 1))]

  # if icu_flag FALSE, replace SCU unit number with a step down unit number
  df_sim[icu_flag == FALSE, scu_unit_number := base::sample(c(90, 93, 95), .N, replace = TRUE)]

  # drop unneeded columns and return data.table
  df_sim <- df_sim[, -c("category", "min_val", "max_val", "prop_false", "scu_set")]

  return(df_sim[order(df_sim$genc_id)])
}
