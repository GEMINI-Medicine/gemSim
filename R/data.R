#' CCI lookup table for MAID and MRI codes
#' @format A data table with the columns:
#' \describe{
#'  \item{intervention_code}{CCI intervention code}
#'  \item{maid}{TRUE if the code is a MAID code, FALSE otherwise}
#' }
#' @usage data(lookup_cci)
#' @keywords datasets
"lookup_cci"

#' StatCan dissemination area ID lookup
#' @format A data table with the columns:
#' \describe{
#'  \item{da21uid}{Dissemination area IDs in Canada}
#' }
#' @usage data(da21uid_statcan_v2021)
#' @keywords datasets
"da21uid_statcan_v2021"

#' Blood product lookup table for `dummy_transfusion` function.
#' @format A data table with the columns:
#' \describe{
#'  \item{blood_product_mapped_omop}{Mapped blood product codes}
#'  \item{blood_product_raw}{Raw names for blood product codes}
#'  \item{prob}{The relative proportion of each item}
#' }
#' It contains OMOP codes for blood products.
#' @usage data(blood_product_lookup)
#' @keywords datasets
"blood_product_lookup"