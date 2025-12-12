#' @title
#' Generate simulated radiology data
#'
#' @description
#' This function creates a dummy dataset with a subset of variables that
#' are contained in the GEMINI "radiology" table, as seen in
#' [GEMINI Data Repository Dictionary](https://geminimedicine.ca/the-gemini-database/).
#'
#' This function only simulates modalities used in the MyPractice and OurPractice Reports: CT, MRI,
#' Ultrasound. It does not cover all modalities seen in the actual "radiology" data table.
#'
#' @param nid (`integer`)\cr Number of unique encounter IDs to simulate.
#' Encounter IDs may repeat to simulate multiple radiology tests,
#' resulting in a data table with more rows than `nid`.
#' Alternatively, if users provide a `cohort` input, the function will instead
#' simulate radiology data for all `genc_ids` in the user-defined cohort table.
#'
#' @param n_hospitals (`integer`)\cr The number of hospitals to simulate.
#' Alternatively, if users provide a `cohort` input, the function will instead simulate
#' radiology data for all `hospital_nums` in the user-defined cohort table
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
#' When a `cohort` input is provided, `nid`, `n_hospitals`, and `time_period` are ignored.
#'
#' @param seed (`integer`)\cr Optional, a number to be used to set the seed for reproducible results.
#'
#' @return (`data.table`)\cr A `data.table` object similar that contains the following fields:
#' - `genc_id` (`integer`): Mock encounter ID number; integers starting from 1 or from `cohort` if provided
#' - `hospital_num` (`integer`): Mock hospital ID number; integers starting from 1 or from `cohort` if provided
#' - `modality_mapped` (`character`): Imaging modality: either MRI, CT, or Ultrasound.
#' - `ordered_date_time` (`character`): The date and time the radiology test was ordered
#' - `performed_date_time` (`character`): The date and time the radiology test was performed
#' @examples
#' cohort <- dummy_ipadmdad()
#' dummy_radiology(cohort = cohort)
#' dummy_radiology(nid = 1000, n_hospitals = 10, time_period = c(2020, 2023))
#'
#' @import Rgemini
#' @importFrom data.table data.table as.data.table
#' @importFrom lubridate ddays dhours
#' @importFrom MCMCpack rdirichlet
#'
#' @export
#'
dummy_radiology <- function(
  nid = 1000, n_hospitals = 10, time_period = c(2015, 2023), cohort = NULL, seed = NULL
) {
  ####### checks for valid inputs #######
  if (!is.null(cohort)) { # if `cohort` is provided
    Rgemini:::check_input(cohort,
      c("data.frame", "data.table"),
      colnames = c("genc_id", "hospital_num", "admission_date_time", "discharge_date_time"),
      coltypes = c("integer", "integer", "", "")
    )
  } else {
    ####### if `cohort` is not provided, create it #######
    Rgemini:::check_input(list(nid, n_hospitals), "integer")

    cohort <- dummy_ipadmdad(nid = nid, n_hospitals = n_hospitals, time_period = time_period, seed = seed)
    # include only required columns
    cohort <- cohort[, c("genc_id", "hospital_num", "admission_date_time", "discharge_date_time")]
  }

  if (!is.null(seed)) {
    set.seed(seed)
  }

  # convert `cohort` to `data.table`
  cohort <- suppressWarnings(Rgemini::coerce_to_datatable(cohort))
  # convert date times
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

  # generate `df_sim` based on `cohort`
  df_sim <- generate_id_hospital(cohort = cohort, include_prop = 1, avg_repeats = 4.5, seed = seed)

  nid <- uniqueN(df_sim$genc_id)
  n_hospitals <- uniqueN(df_sim$hospital_num)

  ####### sample the gap between IP admission and ordered date time #######
  # in days
  admit_order_gap <- round(rlnorm(nrow(df_sim), meanlog = 0.817, sdlog = 1.215) - 0.8)

  ####### Set the `ordered_date_time` #######
  # get ordered date
  df_sim[, ordered_date := as.Date(admission_date_time) + ddays(admit_order_gap)]

  # sample ordered time
  df_sim[, ordered_time := sample_time_shifted(.N, xi = 7.9, omega = 8.8, alpha = 4.5, min = 4, max = 30, seed = seed)]

  ####### get ordered date time by combining ordered date and time #######
  df_sim[, ordered_date_time := ordered_date + dhours(ordered_time)]

  # ensure that `ordered_date_time` is not after `discharge_date_time`
  # re-sample bad values
  max_iter <- 20
  iter <- 0
  while (nrow(df_sim[ordered_date_time >= discharge_date_time, ]) > 0 && iter < max_iter) {
    df_sim[
      ordered_date_time >= discharge_date_time,
      ordered_date_time := as.Date(admission_date_time) +
        dhours(sample_time_shifted(.N, xi = 7.9, omega = 9.0, alpha = 5.2, min = 4, max = 30, seed = seed))
    ]
    iter <- iter + 1 # protect from infinite loop
  }

  # remaining bad values
  df_sim[
    ordered_date_time >= discharge_date_time,
    ordered_date_time := admission_date_time
  ]

  # sample gap between ordered and performed date time, in hours
  # maximum perform gap is the difference between IP discharge and `ordered_date_time`
  # this prevents `perform_date_time` from being after `discharge_date_time`
  df_sim[, max_perform_gap := as.numeric(
    difftime(discharge_date_time, ordered_date_time, units = "hours")
  )]

  df_sim[, perform_gap := rlnorm_trunc(
    .N,
    meanlog = 1.3, sdlog = 1.9, min = 0, max = max_perform_gap, seed = seed
  )]

  df_sim[sample(nrow(df_sim), round(0.06 * nrow(df_sim))), perform_gap := 0] # set some values to 0

  ####### Get performed date time by adding `perform_gap` to `ordered_date_time` #######
  df_sim[, performed_date_time := ordered_date_time + dhours(perform_gap)]

  # performed date time should not be after discharge
  # re-sample it if performed > discharge was sampled previously
  df_sim[performed_date_time > discharge_date_time, performed_date_time := ordered_date_time +
    dhours(
      rlnorm_trunc(
        .N,
        meanlog = 1.3, sdlog = 1.9, min = 0, max = min(
          as.numeric(
            difftime(discharge_date_time, ordered_date_time, units = "hours"), 6 * 30.4 * 24
          ) # set the max to 6 months gap
        ),
        seed = seed
      )
    )]

  df_sim[performed_date_time > discharge_date_time, performed_date_time := discharge_date_time]

  df_sim[, ordered_date_time := substr(as.character(ordered_date_time), 1, 16)]
  df_sim[, performed_date_time := substr(as.character(performed_date_time), 1, 16)]

  ####### Get `modality_mapped` #######
  # probabilities of included modalities
  prob <- data.table(
    "modality_mapped" = c("CT", "MRI", "Ultrasound"),
    "p" = c(0.6, 0.1, 0.3)
  )
  # Introduce random hospital-level variability in modality proportions
  # 0.005 = level of variability
  df_sim[, p := list(list(as.numeric(t(rdirichlet(1, alpha = prob$p / 0.005))))), by = hospital_num]

  df_sim[, modality_mapped := sapply(p, function(v) {
    base::sample(prob$modality_mapped, 1, replace = TRUE, prob = v / (sum(v)))
  })]

  # hospitals without MRI
  # In real data, not all hospitals have an MRI machine on site.
  # Randomly select hospitals without MRI (~10%) and replace modality with CT and Ultrasound
  hosp_no_mri <- sample(unique(df_sim$hospital_num), round(n_hospitals * 0.1), replace = FALSE)

  df_sim[hospital_num %in% hosp_no_mri, p_no_mri := as.numeric(runif(1, 0.55, 0.75)), by = hospital_num]
  df_sim[hospital_num %in% hosp_no_mri, modality_mapped := sample(
    c("CT", "Ultrasound"),
    .N,
    prob = c(.SD[1, p_no_mri], 1 - .SD[1, p_no_mri]),
    replace = TRUE
  ),
  by = hospital_num
  ]

  # return final data table with only required columns
  return(df_sim[
    order(df_sim$genc_id),
    c("genc_id", "hospital_num", "ordered_date_time", "performed_date_time", "modality_mapped")
  ])
}
