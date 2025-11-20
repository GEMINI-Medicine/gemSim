#' @title
#' Generate simulated ipintervention data
#'
#' @description
#' This function creates a dummy dataset with a subset of variables that
#' are contained in the GEMINI "ipintervention" table, as seen in
#' [GEMINI Data Repository Dictionary](https://geminimedicine.ca/the-gemini-database/).
#'
#' This function simulates data with CCI codes detailing the type of intervention that occurred in an inpatient stay.
#'
#' @param dbcon (`DBIConnection`)\cr
#' A database connection to a GEMINI database, required to look up intervention codes.
#' Required when `int_code` is missing, otherwise not used if `int_code` is provided.
#'
#' @param nid (`integer`)\cr Number of unique encounter IDs to simulate.
#' Encounter IDs may repeat, resulting in a data table with more rows than `nid`.
#' It is not used if `cohort` is provided.
#'
#' @param int_code (`character`)\cr Optional, user-specified intervention codes to include in the returned data table.
#' Required when `dbcon` is missing.
#'
#' @param cohort (`data.frame or data.table`)\cr Optional, data frame or data table containing the columns:
#' - `genc_id` (`integer`): Mock encounter ID number
#' - `hospital_num` (`integer`): Mock hospital ID number
#' When `cohort` is not NULL, `nid` and `n_hospitals` are ignored.
#'
#' @param seed (`integer`)\cr Optional, a number to be used to set the seed for reproducible results
#'
#' @return (`data.table`)\cr A data.table object similar to the "ipintervention" table that contains the columns:
#' - `genc_id` (`integer`): Mock encounter ID number; integers starting from 1 or provided from `cohort`
#' - `hospital_id` (`integer`): Mock hospital ID number; integers starting from 1 or provided from `cohort`
#' - `intervention_code` (`character`): A valid CCI code(s) describing the services (procedures/intervention)
#' performed for or on behalf of the patient to improve health.
#' For this simulation, it will either be for an MRI or medical assistance in dying (MAID)
#'
#' @examples
#' dummy_ipintervention_mri_maid(nid = 1000, int_code = c("3AN40VA", "3SC40WC"))
#' dummy_ipintervention_mri_maid(nid = 1000, int_code = "3SC40WC")
#'
#' @importFrom Rgemini check_input
#'
#' @export
#'
dummy_ipintervention_mri_maid <- function(
  dbcon = NULL, nid = 1000, n_hospitals = 10, cohort = NULL, int_code = NULL, seed = NULL
) {
  ############## CHECKS: for valid inputs: `n_id`, `n_hospitals`, `cohort`
  if (is.null(cohort)) {
    # use `nid` and `n_hospitals` when `cohort` is NULL
    check_input(list(nid, n_hospitals), "integer")
  } else {
    # check that `cohort` has the required columns and types
    check_input(cohort,
      c("data.frame", "data.table"),
      colnames = c("genc_id", "hospital_num"),
      coltypes = c("integer", "integer")
    )
  }

  if (!is.null(dbcon)) {
    # get intervention codes from db connection
    lookup_cci <- dbGetQuery(dbcon, "SELECT * FROM lookup_cci
      WHERE intervention_code ~ '^3..40'
      OR intervention_code IN ('1ZZ35HAP7','1ZZ35HAP1','1ZZ35HAN3')") %>% data.table()
  } else if (is.null(int_code)) {
    stop("DB connection or intervention code list is required")
  }

  if (!is.null(seed)) {
    set.seed(seed)
  }

  if (!is.null(cohort)) {
    # get `genc_id` and `hospital_num` based on `cohort` if provided
    cohort <- as.data.table(cohort)

    df1 <- generate_id_hospital(cohort = cohort, avg_repeats = 1.2, seed = seed)

    # Only include the `genc_id` and `hospital_num` columns from `cohort`
    # In case other columns exist
    df1 <- df1[, c("genc_id", "hospital_num")]
  } else {
    # generate a data table with average of 1.2 repeats per `genc_id`
    df1 <- generate_id_hospital(nid, n_hospitals, avg_repeats = 1.2, seed = seed)
  }

  #### Sample Intervention Codes ####
  # If the user specifies intervention code(s), use it to sample intervention codes
  if (is.character(int_code)) {
    # If it is a character, turn `int_code` into a vector for sampling
    if (length(int_code) == 1 && !(is.na(int_code))) {
      int_code <- c(int_code)
    }
    df1[, intervention_code := sample(int_code, .N, replace = TRUE)]
  } else {
    # use the lookup CCI table to sample MRI and MAID codes
    maid_codes <- c("1ZZ35HAN3", "1ZZ35HAP1", "1ZZ35HAP7")
    mri_codes <- trimws(setdiff(unique(lookup_cci$intervention_code), maid_codes))

    # get sample most common codes for 90% of rows
    # remaining rows are filled with all other codes
    common_codes <- c(
      "3AN40VA", "3AN40WC", "3SC40VA", "3ER40VA", "3SC40WC", "3OT40VA", "3OT40WC", "3ER40WC",
      "3AN40WA", "3VZ40VA", "3JX40WC"
    )
    props <- c(0.3, 0.18, 0.14, 0.1, 0.07, 0.06, 0.05, 0.04, 0.03, 0.02, 0.01)

    int_codes <- ifelse(rbinom(nrow(df1), 1, 0.9),
      base::sample(common_codes, nrow(df1), replace = TRUE, prob = props),
      base::sample(setdiff(mri_codes, common_codes), nrow(df1), replace = TRUE)
    )

    df1[, intervention_code := int_codes]

    # number of times each genc_id repeats
    df1[, num_id_repeats := .N, by = genc_id]

    # 0.0051 of encounters have all 3 MAID codes
    # sample this from the genc_id that repeat enough times
    maid_set <- sample(unique(df1[num_id_repeats >= 3, genc_id]), round(0.0051 * uniqueN(df1$genc_id)))

    idx <- df1[genc_id %in% maid_set, .I[1:min(.N, 3)], by = genc_id]$V1

    # set their intervention codes
    df1[idx, intervention_code := rep(c("1ZZ35HAN3", "1ZZ35HAP1", "1ZZ35HAP7"), length.out = length(idx))]

    # get the remaining MAID
    # set 0.015 proportion of encounters to have MAID codes
    # subtract the rows that are already MAID
    df1[
      base::sample(seq_len(nrow(df1)), round(0.015 * nrow(df1)) - length(maid_set * 3)),
      intervention_code := base::sample(maid_codes, .N, prob = rep(1 / 3, 3), replace = TRUE)
    ]

    df1 <- df1[, -c("num_id_repeats")]
  }

  return(df1[order(df1$genc_id)])
}
