#' @title Data simulation wrapper function
#'
#' @details
#' Wrapper function that calls data simulation functions to create a synthetic,
#' customizable database that reflects the inter-table relations of the GEMINI database.
#'
#' @description
#' A wrapper that coordinates table-specific simulation functions to generate
#' relational synthetic tables that reflect the inter-table structure of the GEMINI data.
#' Users specify which tables to generate and provide shared inputs such as the
#' number of encounters, hospitals, and the time period.
#' The function returns a list of simulated `data.table`s with inter-table
#' relationships handled automatically. Specifically, the `admdad` table is generated first
#' and provides the encounter IDs used as the primary key for subsequent table.
#' All tables are simulated to mirror their real-world linkage patterns to the
#' `admdad` table in GEMINI data.
#' Available tables include:
#' - `admdad`
#' - `ipscu`
#' - `er`
#' - `erdiagnosis`
#' - `ipdiagnosis`
#' - `locality_variables`
#' - `lab` *: currently simulates CBC or electrolyte tests only
#' - `radiology` *: currently simulates MRI, CT, and ultrasound imaging data only
#' - `erintervention` *: currently simulates intervention MRI
#' - `ipintervention` *: currently simulates interventions MRI and MAID only
#' - `transfusion`: transfusion information about blood product and issue date times
#' - `physicians`
#'
#' See [GEMINI Data Repository Dictionary](https://geminimedicine.ca/the-gemini-database/) for
#' table definitions and individual simulation function documentation for details.
#'
#' @param tables (`vector`)\cr A `character` vector listing the names of required data tables
#'
#' @param nid (`integer`)\cr The number of mock encounter IDs to simulate.
#'
#' @param n_hospitals (`integer`)\cr The number of mock hospital ID numbers to simulate.
#'
#' @param time_period (`vector`)\cr A numeric or character vector containing the data range of the data
#' by years or specific dates in either format: ("yyyy-mm-dd", "yyyy-mm-dd") or (yyyy, yyyy).
#' The start date and end date will be (yyyy-01-01 and yyyy-12-31) if (yyyy, yyyy)
#' is the date range format provided.
#'
#' @param ... Additional arguments that may be passed into data simulation functions.
#' These arguments are normally used to customize table outputs.
#'
#' @return (`list`)\cr A list containing `data.table` objects,
#' one per entry in the `tables` parameter where entries are valid GEMINI data tables.
#' May include: `admdad`, `ipscu`, `er`, `erdiagnosis`, `ipdiagnosis`, `locality_variables`,
#' `lab`, `radiology`, `erintervention`, `ipintervention`, `transfusion`, `physicians`
#'
#' @importFrom data.table data.table as.data.table
#' @import Rgemini
#'
#' @export
#'
#' @examples
#' simulate_data_tables(c("admdad", "ipscu", "er"))
#'
#' simulate_data_tables(c("admdad", "transfusion"), blood_product_list = c("4023915", "4137859"))
#'
#' simulate_data_tables(c("er", "erintervention", "erdiagnosis"), int_code = c("3AN40VA", "3SC40WC"))
#'
simulate_data_tables <- function(tables, nid = 1000, n_hospitals = 10, time_period = c(2015, 2023), ...) {
  # Check inputs: `tables`
  Rgemini:::check_input(tables, "character")
  tables <- tolower(tables)

  # additional arguments' storage to be passed into simulation functions
  args <- list(...)

  #### empty list to add simulated tables to ####
  results <- list()

  ### map each possible GEMINI data table to its simulation function ###
  function_map <- list(
    ipscu = dummy_ipscu,
    locality_variables = dummy_locality,
    erdiagnosis = dummy_diag, # ipdiagnosis flag = FALSE
    ipdiagnosis = dummy_diag, # ipdiagnosis flag = TRUE (default)
    erintervention = dummy_erintervention_mri,
    ipintervention = dummy_ipintervention_mri_maid,
    locality = dummy_locality,
    physicians = dummy_physicians,
    radiology = dummy_radiology,
    transfusion = dummy_transfusion,
    lab = dummy_lab_cbc_electrolyte,
    er = dummy_er
  )

  # subset cohort based on the proportion of admdad encounters that appear in SCU, ER, etc
  cohort_props <- data.table(
    table = c("ipscu", "er", "ipdiagnosis", "ipintervention", "transfusion", "radiology", "lab"),
    prop = c(0.2, 0.7, 1, 0.09, 0.1, 0.49, 0.83)
  )

  ### get admdad table ###
  # this is always included and added first as the cohort
  new_ipadmdad <- dummy_ipadmdad(
    nid = nid,
    n_hospitals = n_hospitals,
    time_period = time_period
  ) %>% data.table()
  results[["admdad"]] <- new_ipadmdad # add to the results list

  # remove `admdad` from `tables` if it's included
  tables <- tables[!tables %in% c("admdad")]
  ### a cohort is required for ER data ###
  # subset the `ipadmdad` cohort
  # this cohort is used for er-related tables
  er_cohort <- generate_id_hospital(
    cohort = new_ipadmdad, include_prop = cohort_props[table == "er", prop]
  )

  # Construct cohorts for all other tables after `er`
  # Every cohort is a subset of `new_ipadmdad`
  cohort_list <- list(
    ipscu = generate_id_hospital(
      cohort = new_ipadmdad, include_prop = cohort_props[table == "ipscu", prop]
    ),
    locality_variables = new_ipadmdad, # all of `ipadmdad`
    erdiagnosis = er_cohort, # include all of `er`
    ipdiagnosis = new_ipadmdad, # all of `ipadmdad`
    erintervention = generate_id_hospital(
      cohort = er_cohort, include_prop = 0.008
    ), # few encounters have MRI as interventions in ER
    ipintervention = generate_id_hospital(
      cohort = new_ipadmdad, include_prop = cohort_props[table == "ipintervention", prop]
    ),
    physicians = new_ipadmdad,
    radiology = generate_id_hospital(
      cohort = new_ipadmdad, include_prop = cohort_props[table == "radiology", prop]
    ),
    transfusion = generate_id_hospital(
      cohort = new_ipadmdad, include_prop = cohort_props[table == "transfusion", prop]
    ),
    lab = generate_id_hospital(cohort = new_ipadmdad, include_prop = cohort_props[table == "lab", prop]),
    er = er_cohort
  )

  #### loop through list of tables and simulate them with functions ####
  for (tab in tables) {
    # verify that the function for each requested table exists
    if (!tab %in% names(function_map)) {
      warning(sprintf("No function defined for variable '%s'", tab))
      next
    }
    # get function for this data table
    func <- function_map[[tab]]
    # find the arguments the function will accept
    func_formals <- names(formals(func))

    # pass in the cohort plus extra arguments
    args_to_pass <- c(
      args[intersect(names(args), func_formals)]
    )

    args_to_pass$cohort <- cohort_list[[tab]]

    # ip/er diagnosis needs a flag, TRUE or FALSE
    if (tab %in% c("ipdiagnosis", "erdiagnosis")) {
      args_to_pass$ipdiagnosis <- (tab == "ipdiagnosis")
    }

    results[[tab]] <- do.call(func, args_to_pass)
  }

  return(results)
}
