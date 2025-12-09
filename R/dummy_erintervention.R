#' @title
#' Generate simulated erintervention data
#'
#' @description
#' This function creates a dummy dataset with a subset of variables that
#' are contained in the GEMINI "erintervention" table, as seen in
#' [GEMINI Data Repository Dictionary](https://geminimedicine.ca/the-gemini-database/).
#'
#' This function simulates data with CCI codes detailing the type of intervention used in the emergency department.
#'
#' @param nid (`integer`)\cr Number of unique encounter IDs to simulate.
#' Encounter IDs may repeat, resulting in a data table with more rows than `nid`.
#' Ignored when `cohort` is provided.
#'
#' @param n_hospitals (`integer`)\cr Number of hospitals to simulate.
#' Ignored when `cohort` is provided.
#'
#' @param int_code (`character or vector`)\cr Optional, user-specified intervention codes to include in the returned
#' data table. It needs to be a valid MRI code.
#'
#' @param cohort (`data.frame or data.table`)\cr Optional, data frame or data table containing the fields:
#' - `genc_id` (`integer`): Mock encounter ID number
#' - `hospital_num` (`integer`): Mock hospital ID number
#' When `cohort` is not NULL, `nid` and `n_hospitals` are ignored.
#'
#' @param seed (`integer`)\cr Optional, a number to be used to set the seed for reproducible results
#'
#' @return (`data.table`)\cr A data.table object similar to the "ipintervention" table that contains the columns:
#' - `genc_id` (`integer`): Mock encounter ID number; integers starting from 1 or from `cohort`
#' - `hospital_num` (`integer`): Mock hospital ID number; integers starting from 1 or from `cohort`
#' - `intervention_code` (`character`): Valid CCI code(s) describing the services (procedures/intervention)
#' performed for or on behalf of the patient to improve health. For this simulation, it will be for an MRI.
#'
#' @examples
#' dummy_erintervention_mri(nid = 1000, int_code = c("3AN40VA", "3SC40WC"))
#' dummy_erintervention_mri(cohort = dummy_ipadmdad(), int_code = "3AN40VA")
#'
#' @import Rgemini
#' @import data.table
#' @importFrom magrittr %>%
#'
#' @export
#'
#' @examples
#' dummy_erintervention_mri(nid = 100, n_hospitals = 2, seed = 1)
#'
dummy_erintervention_mri <- function(
  nid = 1000, n_hospitals = 10, int_code = NULL, cohort = NULL, seed = NULL
) {
  ############## CHECKS: for valid inputs: `n_id`, `n_hospitals`, `cohort`
  if (is.null(cohort)) {
    # use `nid` and `n_hospitals` when `cohort` is NULL
    Rgemini:::check_input(list(nid, n_hospitals), "integer")
  } else {
    # check that `cohort` has the required columns and types
    Rgemini:::check_input(cohort,
      c("data.frame", "data.table"),
      colnames = c("genc_id", "hospital_num"),
      coltypes = c("integer", "integer")
    )
  }

  # get intervention code data
  lookup_cci_mri <- as.data.table(gemSim::lookup_cci %>% data.table())
  # filter out MAID codes
  lookup_cci_mri <- lookup_cci_mri[maid == FALSE, ]

  lookup_cci_mri[, intervention_code := trimws(intervention_code)]
  mri_codes <- unique(lookup_cci_mri$intervention_code)

  if (!is.null(seed)) {
    set.seed(seed)
  }

  if (!is.null(cohort)) {
    # if `cohort` is provided, use its `genc_id` and `hospital_num`
    cohort <- suppressWarnings(Rgemini::coerce_to_datatable(cohort))

    # each `genc_id` repeats an average of 1.9 times
    df1 <- generate_id_hospital(cohort = cohort, avg_repeats = 1.9, seed = seed)
    # only include the `genc_id` and `hospital_num` columns from `cohort`
    df1 <- df1[, c("genc_id", "hospital_num")]
  } else {
    # Generate a data table with `genc_id` and `hospital_num`
    df1 <- generate_id_hospital(nid = nid, n_hospitals = n_hospitals, avg_repeats = 1.9, seed = seed)
  }

  # if the user specifies intervention code(s), use it to sample
  if (is.character(int_code)) {
    # if it is a character, turn into a vector for sampling
    if (length(int_code) == 1 && !(is.na(int_code))) {
      int_code <- c(int_code)
    }
    if (any(!(int_code %in% lookup_cci_mri$intervention_code))) {
      stop("The provided CCI code was not valid. Stopping.")
    }
    df1[, intervention_code := sample(int_code, .N, replace = TRUE)]
  } else {
    # get sample most common codes for 90% of rows
    # remaining rows are filled with all other codes
    top_codes <- c("3SC40VA", "3AN40VA", "3SC40WC", "3ER40VA", "3AN40WC")
    top_props <- c(0.44, 0.2, 0.13, 0.13, 0.1)
    df1[, intervention_code := ifelse(rbinom(nrow(df1), 1, 0.9),
      sample(top_codes, nrow(df1), replace = TRUE, prob = top_props),
      sample(setdiff(mri_codes, top_codes), nrow(df1), replace = TRUE)
    )]
  }

  return(df1[order(df1$genc_id)])
}
