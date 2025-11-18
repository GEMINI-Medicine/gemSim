#' @title
#' Simulate ICD-10 Diagnosis Codes
#' @description
#' This function simulates ICD-10 diagnosis codes at random or by user specified pattern.
#'
#' @param n (`integer`)\cr Number of ICD codes to simulate.
#'
#' @param source (`string`)\cr The source of the ICD coding to sample from.
#' Default to "comorbidity" the 2011 version of ICD-10 codes implemented in
#' the R [comorbidity](https://ellessenne.github.io/comorbidity/index.html) package.
#' If `source` is `icd_lookup`, ICD-10-CA codes will be sampled from the
#' `lookup_icd10_ca_description` table in the GEMINI database,
#' see details in the [GEMINI Data Repository Dictionary](https://geminimedicine.ca/the-gemini-database/).
#'
#' @param dbcon (`DBIConnection`)\cr
#' A database connection to any GEMINI database. Required when `source` is `icd_lookup`.
#'
#' @param pattern (`string`)\cr A valid regex expression that specifies the
#' desired pattern that the returned ICD codes should be matched with.
#'
#' @return (`vector`)\cr A vector of ICD diagnostic codes.
#'
#' @export
#'
#' @examples
#' ### Simulate 100 ICD-10 codes based on the 2011 version.
#' \dontrun{
#' sample_icd(100, source = "comorbidity")
#' }
#'
#' ### Simulate 100 ICD-10 codes starting with "C2" or "E10" based on the 2011 version.
#' \dontrun{
#' sample_icd(100, source = "comorbidity", pattern = "^C2|^E10")
#' }
#'
#' ### Simulate 50 ICD-10-CA codes based on codes found in the `lookup_icd10_ca_description` table
#' \dontrun{
#' drv <- dbDriver("PostgreSQL")
#' dbcon <- DBI::dbConnect(drv,
#'   dbname = "db",
#'   host = "domain_name.ca",
#'   port = 1234,
#'   user = getPass("Enter user:"),
#'   password = getPass("password")
#' )
#' sample_icd(50, source = "icd_lookup", dbcon = dbcon)
#' }
#'
sample_icd <- function(n = 1, source = "comorbidity", dbcon = NULL, pattern = NULL) {
  switch(source,
    comorbidity = {
      comorb <- comorbidity::icd10_2011 %>% as.data.table()
      if (!is.null(pattern)) {
        comorb <- comorb[grepl(toupper(pattern), Code.clean)]
      }
      if (nrow(comorb) > 0) {
        sample(x = comorb$Code.clean, size = n, replace = TRUE)
      } else {
        stop("No matching diagnoses found for the specified pattern")
      }
    },
    icd_lookup = {
      if (!is.null(dbcon)) {
        lookup <- RPostgreSQL::dbGetQuery(
          dbcon,
          "SELECT diagnosis_code FROM lookup_icd10_ca_description where type != 'category'"
        ) %>% as.data.table()

        if (!is.null(pattern)) {
          lookup <- lookup[grepl(toupper(pattern), diagnosis_code)]
        }

        if (nrow(lookup) > 0) {
          sample(x = lookup$diagnosis_code, size = n, replace = TRUE)
        } else {
          stop("No matching diagnoses found for the
          specified pattern")
        }
      } else {
        stop("Invalid input for 'dbcon' argument. Database connection
        is required for sampling from `lookup_icd10_ca_to_ccsr` table\n")
      }
    }
  )
}


#' @title
#' Generate Simulated Diagnosis Data Table
#'
#' @description
#' This function generates simulated data table resembling `ipdiagnosis`
#' or `erdiagnosis` tables that can be used for testing or demonstration purposes.
#' It internally calls `sample_icd()` function to sample ICD-10 codes and
#' accepts arguments passed to `sample_icd()` for customizing the sampling scheme.
#'
#' @details
#' To ensure simulated table resembles "ip(er)diagnosis" table, the following characteristics are applied to fields:
#'
#' - `genc_id`: Numerical identification of encounters starting from 1.
#' The number of unique encounters is defined by `n`. The total number of rows is defined by `nrow`,
#'   where the number of rows for each encounter is random, but each encounter has at least one row.
#' - `hospital_num`: Numerical identification of hospitals from 1 to 5.
#' All rows of an encounter are linked to a single hospital
#' - `diagnosis_code`: "ipdiagnosis" table only. Simulated ICD-10 diagnosis codes.
#' Each encounter can be associated with multiple diagnosis codes in long format.
#' - `diagnosis_type`: "ipdiagnosis" table only.
#' The first row of each encounter is consistently assigned to the diagnosis type "M".
#' For the remaining rows, if `diagnosis_type` is specified by users,
#' diagnosis types are sampled randomly from values provided;
#' if `diagnosis_type` is NULL, diagnosis types are sampled from
#' ("1", "2", "3", "4", "5", "6", "9", "W", "X", and "Y"),
#' with sampling probability proportionate to their prevalence in the "ipdiagnosis" table.
#' - `diagnosis_cluster`: "ipdiagnosis" table only.
#' Proportionally sampled from values that have a prevalence of more than 1%
#' in the "diagnosis_cluster" field of the "ipdiagnosis" table, which are ("", "A", "B").
#' - `diagnosis_prefix`: "ipdiagnosis" table only.
#' Proportionally sampled from values that have a prevalence of more than 1%
#' in the "diagnosis_prefix" field of the "ipdiagnosis" table, which are ("", "N", "Q", "6").
#' - `er_diagnosis_code`: "erdiagnosis" table only.
#' Simulated ICD-10 diagnosis codes.
#' Each encounter can be associated with multiple diagnosis codes in long format.
#' - `er_diagnosis_type`: "erdiagnosis" table only.
#' Proportionally sampled from values that have a prevalence of more than 1%
#' in the "er_diagnosis_type" field of the "erdiagnosis" table, which are ("", "M", "9", "3", "O").
#'
#'
#' @note The following fields `(er)diagnosis_code`, `(er)diagnosis_type`, `diagnosis_cluster`, `diagnosis_prefix`
#' are simulated independently.
#' Therefore, the simulated combinations may not reflect the interrelationships of these fields in actual data.
#' For example, specific diagnosis codes may be associated with specific diagnosis types,
#' diagnosis clusters, or diagnosis prefix in reality.
#' However, these relationships are not maintained for the purpose of generating dummy data.
#' Users require specific linkages between these fields should consider customizing
#' the output data or manually generating the desired combinations.
#'
#' @param nid (`integer`)\cr Number of unique encounter IDs (`genc_id`) to simulate. Value must be greater than 0.
#'
#' @param n_hospitals (`integer`)\cr Number of hospitals to simulate in the resulting data table
#'
#' @param cohort (`data.frame`)\cr Optional, the administrative data frame containing `genc_id`
#' and `hospital_num` information to be used in the output. `cohort` takes precedence over parameters `nid` and
#' `n_hospitals`: when `cohort` is not NULL, `nid` and `n_hospitals` are ignored.
#'
#' @param ipdiagnosis (`logical`)\cr Default to "TRUE" and returns simulated "ipdiagnosis" table.
#' If FALSE, returns simulated "erdiagnosis" table.
#' See tables in [GEMINI Data Repository Dictionary](https://geminimedicine.ca/the-gemini-database/).
#'
#' @param diagnosis_type (`character vector`)\cr The type(s) of diagnosis to return.
#' Possible diagnosis types are
#' ("M", 1", "2", "3", "4", "5", "6", "9", "W", "X", and "Y"). Regardless of `diagnosis_type` input,
#' the `ipdiagnosis` table is defaulted to always return type "M" for the first row of each encounter.
#'
#' @param seed (`integer`)\cr Optional, a number to assign the seed to.
#'
#' @param ... Additional arguments for ICD code sampling scheme. See `sample_icd()` for details.
#'
#' @return (`data.table`)\cr A data table containing simulated data of
#' `genc_id`, `(er)_diagnosis_code`, `(er)_diagnosis_type`, `hospital_num`,
#' and other fields found in the respective diagnosis table.
#'
#' @export
#'
#' @examples
#'
#' ### Simulate an erdiagnosis table for 5 unique subjects with total 20 records:
#' \dontrun{
#' set.seed(1)
#' erdiag <- dummy_diag(nid = 50, n_hospitals = 2, ipdiagnosis = F)
#' }
#'
#' ### Simulate an erdiagnosis table including data from `cohort`
#' cohort <- dummy_ipadmdad()
#' erdiag <- dummy_diag(cohort = cohort)
#'
#' ### Simulate an ipdiagnosis table with diagnosis codes starting with "E11":
#' \dontrun{
#' set.seed(1)
#' ipdiag <- dummy_diag(nid = 50, n_hospitals = 20, ipdiagnosis = T, pattern = "^E11")
#' }
#'
#' ### Simulate a ipdiagnosis table with random diagnosis codes in diagnosis type 3 or 6 only:
#' \dontrun{
#' set.seed(1)
#' ipdiag <- dummy_diag(nid = 50, n_hospitals = 10, diagnosis_type = (c("3", "6"))) %>%
#'   filter(diagnosis_type != "M") # remove default rows with diagnosis_type="M" from each ID
#' }
#'
#' ### Simulate a ipdiagnosis table with ICD-10-CA codes:
#' \dontrun{
#' drv <- dbDriver("PostgreSQL")
#' dbcon <- DBI::dbConnect(drv,
#'   dbname = "db",
#'   host = "172.XX.XX.XXX",
#'   port = 1234,
#'   user = getPass("Enter user:"),
#'   password = getPass("password")
#' )
#'
#' set.seed(1)
#' ipdiag <- dummy_diag(nid = 5, n_hospitals = 2, ipdiagnosis = T, dbcon = dbcon, source = "icd_lookup")
#' }
#'
dummy_diag <- function(
  nid = 1000, n_hospitals = 10, cohort = NULL, ipdiagnosis = TRUE, diagnosis_type = NULL, seed = NULL, ...
) {
  if (!is.null(seed)) {
    set.seed(seed)
  }

  #### get data.tables with  `genc_id` and `hospital_num` ####
  # `ipdiagnosis`: average number of repeats is 9.05
  # `df1` and `df2` will be joined, so `df2` has 8.05 repeats on average
  # `df` has one repeat per genc_id
  # `erdiagnosis` has 3.92 repeats per genc_id on average
  # the average repeats in `df2` is 2.92 for `erdiagnosis`
  avg_repeats <- ifelse(ipdiagnosis, 8.05, 2.92)
  if (is.null(cohort)) {
    df2 <- generate_id_hospital(nid = nid, n_hospitals = n_hospitals, avg_repeats = avg_repeats, seed = seed)
  } else {
    cohort <- as.data.table(cohort)
    df2 <- generate_id_hospital(
      cohort = cohort,
      avg_repeats = avg_repeats,
      include_prop = 1,
      seed = seed
    )
    # only include the genc_id and hospital_num columns from `cohort`
    df2 <- df2[, c("genc_id", "hospital_num")]
  }

  # get all the unique genc_ids
  df1 <- df2 %>%
    distinct(genc_id, .keep_all = TRUE) %>%
    mutate(diagnosis_type = "M") # ensure each id has a type M diagnosis

  if (!is.null(diagnosis_type)) {
    df2[, diagnosis_type := sample(diagnosis_type, size = .N, replace = TRUE)]
  } else {
    df2[, diagnosis_type := sample(c("1", "2", "3", "4", "5", "6", "9", "W", "X", "Y"),
      size = .N, replace = TRUE,
      prob = c(0.43, 0.07, 0.40, 0.005, 0.0002, 0.002, 0.07, 0.02, 0.0006, 0.00003)
    )]
  }

  # total number of rows in dummy data table
  n_rows <- nrow(df1) + nrow(df2)

  ##### sample `diagnosis_codes` #####
  # combine `df1` with "M" diagnosis types and `df2` with other diagnosis types
  dummy_data <- rbind(df1, df2) %>%
    mutate(
      diagnosis_code = sample_icd(n = n_rows, ...),
      diagnosis_cluster = sample(c("", "A", "B"),
        size = n_rows,
        replace = TRUE,
        prob = c(0.92, 0.07, 0.01)
      ),
      diagnosis_prefix = sample(c("", "N", "Q", "6"),
        size = n_rows,
        replace = TRUE,
        prob = c(0.9, 0.05, 0.02, 0.01)
      )
    )

  if (ipdiagnosis == FALSE) {
    if (!is.null(diagnosis_type)) {
      er_diagnosis_type <- sample(diagnosis_type, size = n_rows, replace = TRUE)
    } else {
      er_diagnosis_type <- sample(c("", "M", "9", "3", "O"),
        size = n_rows, replace = TRUE, prob = c(0.53, 0.38, 0.06, 0.02, 0.01)
      )
    }
    dummy_data <- dummy_data %>%
      dplyr::select(-diagnosis_cluster, -diagnosis_prefix, -diagnosis_type) %>%
      mutate(er_diagnosis_type = er_diagnosis_type) %>%
      rename(er_diagnosis_code = diagnosis_code)
  }

  return(dummy_data[order(dummy_data$genc_id)])
}

#' @title
#' Simulate ipadmdad data
#'
#' @description
#' This function creates a dummy dataset with a subset of variables that
#' are contained in the GEMINI "ipadmdad" table (see details in
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
#' @param time_period (`numeric`)\cr
#' A numeric vector containing the time period, specified as fiscal years
#' (starting in April each year). For example, `c(2015, 2019)` generates data
#' from 2015-04-01 to 2020-03-31.
#'
#' @return (`data.frame`)\cr A data.frame object similar to the "ipadmdad" table
#' containing the following fields:
#' - `genc_id` (`integer`): GEMINI encounter ID
#' - `hospital_num` (`integer`): Hospital ID
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
#' @importFrom sn rsn
#' @importFrom MCMCpack rdirichlet
#' @importFrom lubridate ymd_hm
#' @import Rgemini
#' @export
#'
#' @examples
#' # Simulate 10,000 encounters from 10 hospitals for fiscal years 2018-2020.
#' ipadmdad <- dummy_ipadmdad(nid = 10000, n_hospitals = 10, time_period = c(2018, 2020))
#'
dummy_ipadmdad <- function(nid = 1000,
                           n_hospitals = 10,
                           time_period = c(2015, 2023),
                           seed = NULL) {
  ############### CHECKS: Make sure n is at least n_hospitals * length(time_period)
  if (nid < n_hospitals * length(time_period)) {
    stop("Invalid user input.
    Number of encounters `nid` should at least be equal to `n_hospitals` * `length(time_period)`")
  }

  # set the seed if the input provided is not NULL
  if (!is.null(seed)) {
    set.seed(seed)
  }

  ############### PREPARE OUTPUT TABLE ###############
  ## create all combinations of hospitals and fiscal years
  hospital_num <- seq(1, n_hospitals, 1)
  year <- seq(time_period[1], time_period[2], 1)

  data <- expand.grid(hospital_num = hospital_num, year = year) %>% data.table()

  # randomly draw number of encounters per hospital*year combo
  data[, n := rmultinom(1, nid, rep.int(1 / nrow(data), nrow(data)))]

  # blow up row number according to encounter per combo
  data <- data[rep(seq_len(nrow(data)), data$n), ]

  # turn year variable into actual date by randomly drawing date_time
  add_random_datetime <- function(year) {
    start_date <- paste0(year, "-04-01 00:00 UTC") # start each fisc year on Apr 1
    end_date <- paste0(year + 1, "-03-31 23:59 UTC") # end of fisc year

    random_date <- as.Date(round(runif(length(year),
      min = as.numeric(as.Date(start_date)),
      max = as.numeric(as.Date(end_date))
    )))

    random_datetime <- format(as.POSIXct(random_date + dhours(sample_time_shifted(length(year),
      xi = 19.5, omega = 6.29, alpha = 0.20
    )), tz = "UTC"), format = "%Y-%m-%d %H:%M")

    return(random_datetime)
  }

  data[, admission_date_time := add_random_datetime(year)]

  # add genc_id from 1-n
  data <- data[order(admission_date_time), ]
  data[, genc_id := seq(1, nrow(data), 1)]


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

    hosp_data[, discharge_date_time := format(
      round_date(as.POSIXct(admission_date_time, tz = "UTC") +
        ddays(los), unit = "days") +
        dhours(sample_time_shifted(.N, xi = 11.37, omega = 4.79, alpha = 1.67, max = 28, seed = seed)),
      format = "%Y-%m-%d %H:%M", tz = "UTC"
    )]

    # if `discharge_date_time` ends up before `admission_date_time`
    hosp_data[, los := as.numeric(difftime(ymd_hm(discharge_date_time), ymd_hm(admission_date_time), units = "days"))]
    hosp_data[los < 0, discharge_date_time := format(ymd_hm(discharge_date_time) + days(1), "%Y-%m-%d %H:%M")]
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


#' @title
#' Generated simulated lab data
#'
#' @description
#' Designed to mimic the most important elements of the GEMINI lab table as defined in the
#' [GEMINI Data Repository Dictionary](https://geminimedicine.ca/the-gemini-database/).
#'
#' @param id (`numeric`)\cr
#' A single identifier that is repeated to match the length of `value`.
#'
#' @param omop (`character`)\cr
#' Codes corresponding to OMOP concept identifiers.
#'
#' @param value (`numeric`)\cr
#' Simulated result values for each lab test measurement.
#'
#' @param unit (`character`)\cr
#' Units corresponding to the particular lab test as defined by `omop`. It is repeated to match the length of `value`.
#'
#' @param mintime (`character`)\cr
#' In the format yyyy-mm-dd hh:mm. Earliest recorded test performed time.
#'
#' @return (`data.table`)\cr
#' With the columns, `id`, `omop`, `value`, `unit`, and `collection_date_time` as described above.
#'
#' @export
#'
#' @examples
#' lab <- dummy_lab(1, 3024641, c(7, 8, 15, 30), "mmol/L", "2023-01-02 08:00")
#'
dummy_lab <- function(id, omop, value, unit, mintime) {
  res <- data.table(
    genc_id = rep(id, length(value)),
    test_type_mapped_omop = omop,
    result_value = value,
    result_unit = rep(unit, length(value)),
    collection_date_time = format(as.POSIXct(mintime, tz = "UTC") +
      sample(0:(24 * 60 * 60 - 1),
        size = length(value),
        replace = TRUE
      ), "%Y-%m-%d %H:%M")
  )
  return(res)
}


#' @title
#' Generated simulated administrative data
#'
#' @description
#' Designed to partially mimic the `admdad` table as defined in the
#' [GEMINI Data Repository Dictionary](https://geminimedicine.ca/the-gemini-database/).
#'
#' @param id (`numeric`)\cr
#' A single identifier that is repeated to match the length of `value`.
#'
#' @param admtime (`character`)\cr
#' In the format yyyy-mm-dd hh:mm. Corresponds to the admission time of the encounter.
#'
#' @return (`data.table`)\cr
#' With the columns `id` and `admission_date_time` as described above.
#'
#' @export
#'
#' @examples
#' admdad <- dummy_admdad(1, "2023-01-02 00:00")
#'
dummy_admdad <- function(id, admtime) {
  res <- data.table(
    genc_id = id,
    admission_date_time = format(as.POSIXct(admtime, tz = "UTC"), "%Y-%m-%d %H:%M")
  )
  return(res)
}

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
#'
#' @export
#'
dummy_lab <- function(nid = 1000, n_hospitals = 10, time_period = c(2015, 2023), cohort = NULL, seed = NULL) {
  ### check for valid inputs ###
  if (!is.null(cohort)) {
    # if `cohort` is provided, check for columns and their types
    check_input(cohort, c("data.table", "data.frame"),
      colnames = c("genc_id", "hospital_id", "admission_date_time", "discharge_date_time"),
      coltypes = c("integer", "integer", "", "")
    )

    # check for the date time format in admission and discharge date times
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
    # if `cohort` is included, get  `df1` based on it
    cohort <- as.data.table(cohort)

    cohort$admission_date_time <- as.POSIXct(cohort$admission_date_time,
      format = "%Y-%m-%d %H:%M",
      tz = "UTC"
    )

    cohort$discharge_date_time <- as.POSIXct(cohort$discharge_date_time,
      format = "%Y-%m-%d %H:%M",
      tz = "UTC"
    )

        # on average, the included encounters have 15.8 lab tests
        df1 <- generate_id_hospital(cohort = cohort, include_prop = 1, avg_repeats = 15.8, by_los = FALSE, seed = seed)

    ####### get `collection_date_time` #######
    # add sampled hours to `admission_date_time`
    df1[, collection_date_time := as.Date(round(runif(.N,
      min = as.Date(admission_date_time),
      max = as.Date(discharge_date_time)
    ))) +
      dhours(rsn_trunc(.N, 3.5, 7.1, 4.6, min_n = 0, max = 24, seed = seed))]

        # if `collection_date_time` is sampled to be later than `discharge+date_time`, re-sample
        while (length(which(df1$collection_date_time > df1$discharge_date_time))) {
            df1[collection_date_time > discharge_date_time, collection_date_time := as.Date(admission_date_time) +
            dhours(rsn_trunc(.N, 3.5, 7.1, 4.6, min_n = 0, max = 24))]
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
      dhours(rsn_trunc(.N, 3.5, 7.1, 4.6, min_n = 0, max_n = 24, seed = seed))]

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

  # sample test result for CBC
  # for CBC, sample separate distributions for < 25th quantile and > 25th quantile, around 87
  # lower: gamma, upper: johnson
  df1[test_type_mapped_omop == 3000963, result_value := ifelse(
    rbinom(.N, 1, 0.25),
    rgamma(.N, 59, 0.74),
    rjohnson_trunc(.N, min = 87, max = 260)
  )]

  # sample test result for electrolyte
  # t-distribution: shaped like normal distribution but with longer tail
  # truncate it so it includes outliers but no values that are too extreme
  df1[test_type_mapped_omop == 3019550, result_value := rt_trunc(.N, 3.62, 3.96, 137.64, 1, 416)]

  # remove seconds from date times
  df1[, collection_date_time := substr(as.character(collection_date_time), 1, 16)]

  # round result values and set to character
  df1[, result_value := as.character(round(result_value))]

  return(df1[order(df1$genc_id)])
}
