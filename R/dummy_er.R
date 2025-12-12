#' @title
#' Generate simulated ER data.
#'
#' @description
#'  This function creates a dummy dataset with a subset of variables that
#' are contained in the GEMINI "er" table, as seen in
#' [GEMINI Data Repository Dictionary](https://geminimedicine.ca/the-gemini-database/).
#'
#' This function will return one triage date time for each encounter ID.
#'
#' @param nid (`integer`) Number of unique encounter IDs to simulate. In this data table, each ID occurs once.
#' Optional when `cohort` is provided.
#'
#' @param n_hospitals (`integer`) Number of hospitals in the simulated dataset. Optional when `cohort` is provided.
#'
#' @param time_period (`vector`)\cr A numeric or character vector containing the data range of the data
#' by years or specific dates in either format: ("yyyy-mm-dd", "yyyy-mm-dd") or (yyyy, yyyy).
#' The start date and end date will be (yyyy-01-01 and yyyy-12-31) if (yyyy, yyyy)
#' is the date range format provided. Optional when `cohort` is provided.
#'
#' @param cohort (`data.frame or data.table`): Optional, a data frame with the following columns:
#' - `genc_id` (`integer`): Mock encounter ID
#' - `hospital_num` (`integer`): Mock hospital ID number
#' - `admission_date_time` (`character`): The date and time of admission to the hospital with format "%Y-%m-%d %H:%M"
#' - `discharge_date_time` (`character`): The date and time of discharge from the hospital with format "%Y-%m-%d %H:%M"
#' When `cohort` is not NULL, `nid`, `n_hospitals`, and `time_period` are ignored.
#'
#' @param seed (`integer`) Optional, a number for setting the seed to get reproducible results.
#'
#' @return (`data.table`) A data.table object similar to the "er" table that contains the following fields:
#' - `genc_id` (`integer`): Mock encounter ID; integers starting from 1 or from `cohort` if provided
#' - `hospital_num` (`integer`): Mock hospital ID; integers starting from 1 or from `cohort` if provided
#' - `triage_date_time` (`character`): The date and time of triage with format "%Y-%m-%d %H:%M"
#'
#' @importFrom data.table data.table as.data.table
#' @importFrom lubridate ddays dhours
#' @import Rgemini
#' @export
#'
#' @examples
#' cohort <- dummy_ipadmdad()
#' dummy_er(cohort = cohort, seed = 1)
#' dummy_er(nid = 10, n_hospitals = 1, seed = 2)
dummy_er <- function(nid = 1000, n_hospitals = 10, time_period = c(2015, 2023), cohort = NULL, seed = NULL) {
  if (!is.null(seed)) {
    set.seed(seed)
  }

  ## Check inputs ##
  if (!is.null(cohort)) { # if `cohort` is provided
    Rgemini:::check_input(cohort,
      c("data.frame", "data.table"),
      colnames = c("genc_id", "hospital_num", "admission_date_time", "discharge_date_time"),
      coltypes = c("integer", "integer", "", "")
    )

    # update the parameters
    nid <- uniqueN(cohort$genc_id)
    n_hospitals <- uniqueN(cohort$hospital_num)
  } else { # when `cohort` is not provided
    # create a cohort
    cohort <- dummy_ipadmdad(nid, n_hospitals, time_period, seed)
  }

  ##### update `cohort` data types
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

  # get the `data.table` for simulation
  # one repeat per `genc_id`
  df_sim <- generate_id_hospital(cohort = cohort, avg_repeats = 1, seed = seed)

  ##### sample `triage_date_time` by adding to IP admit time #####
  # the output of `rsn` will be negative
  # triage occurs before inpatient admissions
  df_sim[, triage_date := floor_date(admission_date_time - ddays(rsn_trunc(
    .N,
    xi = 0.098, omega = 0.285, alpha = 4.45, min = 0, max = 370
  )), unit = "day")]

  # log normal distribution of `triage_date_time`
  df_sim[, triage_time_hour := rlnorm_trunc(.N, meanlog = 2.69, sdlog = 0.38, min = 4, max = 30, seed = seed)]

  # move times > 24 hours to 12am and after (early AM)
  df_sim[, triage_time_hour := ifelse(triage_time_hour < 24, triage_time_hour, triage_time_hour - 24)]

  df_sim[, triage_date_time := triage_date + dhours(triage_time_hour)]

  df_sim[, admission_time := as.numeric(format(admission_date_time, "%H")) +
    as.numeric(format(admission_date_time, "%M")) / 60 +
    as.numeric(format(admission_date_time, "%S")) / 3600]

  # re-sample bad values where triage comes up after admission
  while (nrow(df_sim[triage_date_time > admission_date_time, ]) > 0) {
    df_sim[triage_date_time > admission_date_time, triage_date := floor_date(
      admission_date_time - ddays(rsn_trunc(.N,
        xi = 0.098, omega = 0.285, alpha = 4.45, min = 0, max = 370
      )),
      unit = "day"
    )]

    df_sim[triage_date_time > admission_date_time, triage_time_hour := rlnorm_trunc(
      .N,
      meanlog = 2.69, sdlog = 0.38, min = 4, max = 30
    )]

    # move times > 24 hours to 12am and after
    df_sim[triage_date_time > admission_date_time, triage_time_hour := ifelse(
      triage_time_hour < 24, triage_time_hour, triage_time_hour - 24
    )]

    df_sim[triage_date_time > admission_date_time, triage_date_time := triage_date + dhours(triage_time_hour)]
  }

  # turn date times into a string and remove seconds
  df_sim[, triage_date_time := substr(as.character(triage_date_time), 1, 16)]

  # keep only the relevant columns and return
  df_sim <- df_sim[, c("genc_id", "hospital_num", "triage_date_time")]

  return(df_sim[order(df_sim$genc_id)])
}
