#' @title
#' Generate simulated lab data
#'
#' @description
#'  This function creates a dummy dataset with a subset of variables that
#' are contained in the GEMINI "lab" table, as seen in
#' [GEMINI Data Repository Dictionary](https://geminimedicine.ca/the-gemini-database/).
#'
#' This function will return: collection date time, information about the test type, test code, and test result value.
#' It is a long format data table.
#'
#' @param nid (`integer`) Number of unique encounter IDs to simulate. In this data table, each ID occurs once.
#' It is ignored if `cohort` is provided.
#'
#' @param n_hospitals (`integer`) Number of hospitals in simulated dataset.
#' It is ignored if `cohort` is provided
#'
#' @param time_period (`numeric`): Date range of data, by years or specific dates in either format:
#' ("yyyy-mm-dd", "yyyy-mm-dd") or (yyyy, yyyy).
#' It is ignored if `cohort` is provided.
#'
#' @param cohort (`data.frame or data.table`)\cr Optional, a data frame or data table with columns:
#' - `genc_id` (`integer`): Mock encounter ID numbers
#' - `hospital_num` (`integer`): Mock hospital ID numbers
#' - `admission_date_time` (`character`): Date and time of IP admission in YYYY-MM-DD HH:MM format
#' - `discharge_date_time` (`character`): Date and time of IP discharge in YYYY-MM-DD HH:MM format.
#' When `cohort` is not NULL, `nid`, `n_hospitals`, and `time_period` are ignored.
#'
#' @param seed (`integer`) Optional, a number for setting the seed to get reproducible results.
#'
#' @return (`data.table`)\cr A data.table object similar to the "lab" table that contains the following fields:
#' - `genc_id` (`integer`): Mock encounter ID; integers starting from 1 or as seen in `cohort`
#' - `hospital_num` (`integer`): Mock hospital ID; integers starting from 1 or as seen in `cohort`
#' - `test_type_mapped_omop` (`character`):	Test name and code mapped by GEMINI following international standard
#' - `test_name_raw` (`character`): Test name as reported by hospital
#' - `test_code_raw` (`character`): Test code as reported by hospital, either 3000963 (CBC) or 3019550 (electrolyte)
#' - `result_value` (`character`): Test results
#' - `collection_date_time` (`character`):	Date and time when the sample was collected
#'
#' @importFrom SuppDists rJohnson
#' @importFrom lubridate dhours days
#' @importFrom MCMCpack rdirichlet
#' @import Rgemini
#'
#' @export
#'
#' @examples
#' dummy_lab_cbc_electrolyte(nid = 10, n_hospitals = 1, seed = 1)
#' dummy_lab_cbc_electrolyte(cohort = dummy_ipadmdad())
#'
dummy_lab_cbc_electrolyte <- function(
  nid = 1000, n_hospitals = 10, time_period = c(2015, 2023), cohort = NULL, seed = NULL
) {
  ### check for valid inputs ###
  if (!is.null(cohort)) {
    # if `cohort` is provided, check for columns and their types
    Rgemini:::check_input(cohort, c("data.table", "data.frame"),
      colnames = c("genc_id", "hospital_num", "admission_date_time", "discharge_date_time"),
      coltypes = c("integer", "integer", "", "")
    )
  } else {
    # when `cohort` is not provided create one
    cohort <- dummy_ipadmdad(nid, n_hospitals, time_period, seed = seed)
  }

  if (!is.null(seed)) {
    set.seed(seed)
  }

  # Internal function to sample from the t distribution truncated within a given range
  # Samples a numeric vector as per the params and returns it
  # This is used to sample "electrolyte" tests result values
  # Params:
  # - `n` (`integer`): length of final vector
  # - `df` (`integer`): degrees of freedom
  # - `sd` (`numeric`): standard deviation
  # - `mean` (`numeric`): mean
  # - `min` (`numeric`): minimum
  # - `max` (`numeric`): maximum
  rt_trunc <- function(n, df, sd, mean, min, max) {
    res <- rt(n, df = df) * sd + mean
    while (sum(res < min) + sum(res > max) > 0) {
      n2 <- sum(res < min) + sum(res > max)
      res[c(res < min | res > max)] <- rt(n2, df = df) * sd + mean
    }
    return(res)
  }

  # Internal function to sample from the Johnson distribution truncated within a given range
  # Samples a numeric vector as per the params and returns it
  # This is used to sample `result_value` when the test type is CBC
  # Params:
  # - `n` (`integer`): length of final vector
  # - `min` (`numeric`): minimum
  # - `max` (`numeric`): maximum
  rjohnson_trunc <- function(n, min, max) {
    fit_j_cbc <- list( # the parameters of the distribution of lab results for CBC
      gamma = 0,
      delta = 1.21,
      xi = -7.7,
      lambda = 189,
      type = "SB"
    )

    res <- rJohnson(n, fit_j_cbc)

    while (sum(res < min) + sum(res > max) > 0) {
      n2 <- sum(res < min) + sum(res > max)
      res[res < min | res > max] <- rJohnson(n2, fit_j_cbc)
    }
    return(res)
  }

  # if `cohort` is included, get `df1` based on it
  cohort <- suppressWarnings(Rgemini::coerce_to_datatable(cohort))

  # Convert admission and discharge date times to POSIXct
  # It will stop and raise error if any formats are invalid
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

  # on average, each `genc_id` has 15.8 lab tests
  df1 <- generate_id_hospital(cohort = cohort, avg_repeats = 15.8, by_los = FALSE, seed = seed)

  ####### get `collection_date_time` #######
  # add sampled hours to `admission_date_time`
  df1[, collection_date_time := as.Date(round(runif(.N,
    min = as.Date(admission_date_time),
    max = as.Date(discharge_date_time)
  ))) +
    dhours(rsn_trunc(.N, 3.5, 7.1, 4.6, min = 0, max = 24, seed = seed))]

  # if `collection_date_time` is sampled to be later than `discharge_date_time`, re-sample
  while (nrow(df1[collection_date_time > discharge_date_time, ])) {
    df1[collection_date_time > discharge_date_time, collection_date_time := as.Date(admission_date_time) +
      dhours(rsn_trunc(.N, 3.5, 7.1, 4.6, min = 0, max = 24))]
  }

  # only include the genc_id and hospital_num columns from `cohort`
  df1 <- df1[, c("genc_id", "hospital_num", "collection_date_time")]

  ### Remaining variables: test types, OMOP test codes, results ###
  ### get `test_name_raw` ###
  # First sample test type
  # CBC is 3000963 and electrolyte is 3019550
  df1[, test_type_mapped_omop := sample(c(3000963, 3019550),
    size = .N,
    prob = c(rdirichlet(1, alpha = c(0.47, 0.53) / 0.005)),
    replace = TRUE
  )]

  ####### Sample raw test names and codes for CBC #######
  # List of names from most to least common
  test_names_cbc <- c(
    "HEMOGLOBIN", "Hemoglobin", "HGB", "CBC", "Hb", "Haemoglobin*", "Haemoglobin", "tHb Arterial  POC (GEMS IL)",
    "Haemoglobin COOX    Do not report D Mazer", "POCT Blood Gas Arterial", "Hemoglobin,Gas", "Total Haemoglobin",
    "Blood Gas, Venous", "Total Hemoglobin,POC", "CBC RRL", "Blood Gas, Arterial", "POCT Blood Gas Venous", "HB",
    "Total Hemoglobin", "Hematocrit", "Hemoglobin, POCT", "Hemoglobin - POCT", "Haemoglobin - POCT",
    "HEMOGLOBIN - POCT"
  )

  # sample probabilities of getting raw test names
  probs <- sort(rlnorm(length(test_names_cbc), meanlog = -5.7, sdlog = 2.8),
    decreasing = TRUE
  )

  probs <- probs / sum(probs) # normalize so it adds to 1

  df1[test_type_mapped_omop == 3000963, test_name_raw := sample(test_names_cbc, .N, replace = TRUE, prob = probs)]

  ####### Sample raw test names and codes for electrolyte #######
  # List of names from most to least common
  test_names_electrolyte <- c(
    "SODIUM", "Sodium", "Sodium,Serum,Plasma", "Electrolytes, Plasma", "Anion Gap", "Sodium - Serum/Plasma",
    "Sodium plasma", "Sodium Arterial POC (GEMS IL)", "POCT Blood Gas Arterial", "Sodium,Gas", "Sodium, Plasma",
    "Electrolytes, Creatinine, Glucose Profile", "Sodium,Point of Care", "Sodium blood", "Sodium, Arterial",
    "Electrolytes, Creatinine, Profile", "Electrolytes, Creatinine, Glucose Profile RRL",
    "Sodium                     O.R. Arterial", "Blood Gas, Arterial", "POCT Blood Gas Venous", "Sodium, Plasma RRL",
    "Sodium, Venous", "WHOLE BLOOD SODIUM", "Electrolytes, Plasma RRL", "Sodium - Ven.", "Sodium serum",
    "Sodium                     O.R. Venous", "SODIUM,POINT OF CARE"
  )

  # sample probabilities of getting raw test names
  probs <- sort(rlnorm(length(test_names_electrolyte), meanlog = -5.7, sdlog = 2.3), decreasing = TRUE)
  probs <- probs / sum(probs) # normalize so it adds to 1

  df1[test_type_mapped_omop == 3019550, test_name_raw := sample(
    test_names_electrolyte, .N,
    replace = TRUE, prob = probs
  )]

  ####### get test_code_raw #######
  # Sample for CBC first
  # CBC test codes from most to least common
  test_code_raw_cbc <- c(
    NA, "HGB", "", "Hb", "100.06", "400.0025", "Hemoglobin", "HBCX1",
    "HBAPC", "HBTOT", "VHBG", "AHBG", "MVHGB", "ORHCV", "HEMOC"
  )

  # sample for CBC raw test codes
  probs <- sort(rlnorm(length(test_code_raw_cbc), meanlog = -6.3, sdlog = 2.0), decreasing = TRUE)
  probs <- probs / sum(probs) # normalize to sum to 1

  df1[test_type_mapped_omop == 3000963, test_code_raw := sample(
    test_code_raw_cbc, .N,
    replace = TRUE, prob = probs
  )]

  # Next, sample for electrolyte
  # Electrolyte test codes from most to least common
  test_code_raw_electrolyte <- c(
    NA, "", "Sodium", "200.051", "NAPL", "100.005", "NAAPC", "NAW", "NAART", "ORNA", "NAV", "210.2397",
    "PANAA", "ANAA", "VNA", "PVNA", "NAS", "ORNAV", "MVNA", "PMNA"
  )

  # sample for electrolyte raw test codes
  probs <- sort(rlnorm(length(test_code_raw_electrolyte), meanlog = -5.3, sdlog = 3.0), decreasing = TRUE)
  probs <- probs / sum(probs) # normalize to sum to 1

  df1[test_type_mapped_omop == 3019550, test_code_raw := sample(
    test_code_raw_electrolyte, .N,
    replace = TRUE, prob = probs
  )]

  ####### sample the `result_values` based on test type #######

  ### sample test result for CBC ###
  # for CBC, sample separate distributions for < 25th quantile and > 25th quantile, around 87
  # lower: gamma, upper: johnson
  df1[test_type_mapped_omop == 3000963, result_value := ifelse(
    rbinom(.N, 1, 0.25),
    rgamma(.N, 59, 0.74),
    rjohnson_trunc(.N, min = 87, max = 260)
  )]

  ### sample test result for electrolyte ###
  # t-distribution: shaped like normal distribution but with longer tail
  # truncate it so it includes outliers but no values that are too extreme
  df1[test_type_mapped_omop == 3019550, result_value := rt_trunc(.N, 3.62, 3.96, 137.64, 1, 416)]

  # remove seconds from date times
  df1[, collection_date_time := substr(as.character(collection_date_time), 1, 16)]

  # round result values and set it to character type
  df1[, result_value := as.character(round(result_value))]

  return(df1[order(df1$genc_id)])
}
