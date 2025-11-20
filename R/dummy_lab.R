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
#'
#' @param n_hospitals (`integer`) Number of hospitals in simulated dataset
#'
#' @param time_period (`numeric`): Date range of data, by years or specific dates in either format:
#' ("yyyy-mm-dd", "yyyy-mm-dd") or (yyyy, yyyy)
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
#' @importFrom Rgemini check_input
#'
#' @export
#'
#' @examples
#' dummy_lab_cbc_electrolyte(10, 1, seed = 1)
#' dummy_lab_cbc_electrolyte(cohort = dummy_ipdmdad())
#'
dummy_lab_cbc_electrolyte <- function(
  nid = 1000, n_hospitals = 10, time_period = c(2015, 2023), cohort = NULL, seed = NULL
) {
  ### check for valid inputs ###
  if (!is.null(cohort)) {
    # if `cohort` is provided, check for columns and their types
    check_input(cohort, c("data.table", "data.frame"),
      colnames = c("genc_id", "hospital_id", "admission_date_time", "discharge_date_time"),
      coltypes = c("integer", "integer", "", "")
    )

    # check for the date time format in admission and discharge date times
    # all data need to be valid to convert into POSIXct objects
    if (!all(check_date_format(c(cohort$admission_date_time, cohort$discharge_date_time), check_time = TRUE))) {
      stop("An invalid IP admission and/or discharge date time input was provided in cohort.")
    }
  } else {
    # when `cohort` is not provided, `nid`, `n_hospitals`, and `time_period` need to be valid
    check_input(list(nid, n_hospitals), "integer")

    if (as.Date(time_period[1]) > as.Date(time_period[2])) {
      stop("Time period needs to end later than it starts")
    }
    if (nid < n_hospitals) {
      stop("Number of encounters must be greater than or equal to the number of hospitals")
    }
  }

  if (!is.null(seed)) {
    set.seed(seed)
  }

  # Sample from the t distribution truncated within a given range
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

  # Sample from the Johnson distribution truncated within a given range
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

  if (!is.null(cohort)) {
    # if `cohort` is included, get `df1` based on it
    cohort <- as.data.table(cohort)

    cohort$admission_date_time <- as.POSIXct(cohort$admission_date_time,
      format = "%Y-%m-%d %H:%M",
      tz = "UTC"
    )

    cohort$discharge_date_time <- as.POSIXct(cohort$discharge_date_time,
      format = "%Y-%m-%d %H:%M",
      tz = "UTC"
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
    while (length(which(df1$collection_date_time > df1$discharge_date_time))) {
      df1[collection_date_time > discharge_date_time, collection_date_time := as.Date(admission_date_time) +
        dhours(rsn_trunc(.N, 3.5, 7.1, 4.6, min = 0, max = 24))]
    }

    # only include the genc_id and hospital_num columns from `cohort`
    df1 <- df1[, c("genc_id", "hospital_num", "collection_date_time")]
  } else {
    # if the user doesn't input cohort, use the given `time_period`
    time_period <- as.character(time_period)

    # convert `time_period` into Date objects based on the formatting
    if (grepl("^\\d{4}$", time_period[1])) {
      start_date <- as.Date(paste0(time_period[1], "-01-01"))
    } else {
      start_date <- as.Date(time_period[1])
    }

    if (grepl("^\\d{4}$", time_period[1])) {
      end_date <- as.Date(paste0(time_period[2], "-01-01"))
    } else {
      end_date <- as.Date(time_period[2])
    }
    # get a long-form data table with an average of 15.8 repeats per `genc_id`
    df1 <- generate_id_hospital(nid, n_hospitals, avg_repeats = 15.8, seed = seed)

    # each encounter has a range when they have lab tests
    # a minimum and maximum date are sampled
    df1[, min_collection_date := as.Date(round(runif(1,
      min = as.numeric(start_date),
      max = as.numeric(end_date)
    ))), by = genc_id]

    df1[, num_id_repeats := .N, by = genc_id] # the number of repeats per `genc_id`

    # gap between the first and last lab collection date
    df1[, max_collection_date := min_collection_date +
      lubridate::days(round(rlnorm(1, meanlog = 1.45, sdlog = 1.17))),
    by = genc_id
    ]

    # ensure `max_collection_date` is before `end_date` from the user-provided `time_period`
    df1[as.numeric(max_collection_date) > as.numeric(end_date), max_collection_date := end_date]

    ####### `collection_date_time` #######
    # collection date times are within the specified window per genc_id
    # sample a date then add a skewed normal time
    df1[, collection_date_time := as.Date(round(runif(.N,
      min = as.numeric(min_collection_date),
      max = as.numeric(max_collection_date)
    ))) +
      dhours(rsn_trunc(.N, 3.5, 7.1, 4.6, min = 0, max = 24, seed = seed))]

    # Remove columns excluded from final output
    df1 <- df1[, -c("min_collection_date", "max_collection_date", "num_id_repeats")]
  }
  ### For the remaining variables, sample test types, codes, results ###
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
