# Simulate admdad data

This function creates a dummy dataset with a subset of variables that
are contained in the GEMINI "admdad" table (see details in [GEMINI Data
Repository Dictionary](https://geminimedicine.ca/the-gemini-database/)).

The simulated encounter-level variables that are returned by this
function are currently: Admission date-time, discharge date-time, age,
gender, discharge disposition, transfer to an alternate level of care
(ALC), and ALC days. The distribution of these simulated variables
roughly mimics the real distribution of each variable observed in the
GEMINI GIM cohort. Admission date-time is simulated in conjunction with
discharge date-time to mimic realistic length of stay. All other
variables are simulated independently of each other, i.e., there is no
correlation between age, gender, discharge disposition etc. that may
exist in the real data. One exception to this is `number_of_alc_days`,
which is only \> 0 for entries where `alc_service_transfer_flag == TRUE`
and the length of ALC is capped at the total length of stay.

The function simulates patient populations that differ across hospitals.
That is, patient characteristics are simulated separately for each
hospital, with a different, randomly drawn distribution mean (i.e.,
random intercepts). However, the degree of hospital-level variation
simulated by this function is arbitrary and does not reflect true
differences between hospitals in the real GEMINI dataset.

## Usage

``` r
dummy_admdad(
  nid = 1000,
  n_hospitals = 10,
  time_period = c(2015, 2023),
  seed = NULL
)
```

## Arguments

- nid:

  (`integer`)  
  Total number of encounters (`genc_ids`) to be simulated.

- n_hospitals:

  (`integer`)  
  Number of hospitals to be simulated. Total number of `genc_ids` will
  be split up pseudo-randomly between hospitals to ensure roughly equal
  sample size at each hospital.

- time_period:

  (`integer` or `character`)  
  A vector containing the time period of simulated discharge dates. If
  specified as a numeric vector (e.g., `c(2015, 2019)`), the function
  will interpret these as calendar years (starting on Jan 1 and ending
  on Dec 31). Users may provide character inputs in `ymd` format to
  specify more granular start and end dates (e.g.,
  `c("2015-07-01", "2019-06-30"`).

- seed:

  (`numeric`)  
  Optional, a number to set the seed for reproducible results

## Value

(`data.frame`)  
A data.frame object similar to the "admdad" table containing the
following fields:

- `genc_id` (`integer`): Mock encounter ID; integers starting from 1

- `hospital_num` (`integer`): Mock hospital ID number; integers starting
  from 1

- `admission_date_time` (`character`): Date-time of admission in
  YYYY-MM-DD HH:MM format

- `discharge_date_time` (`character`): Date-time of discharge in
  YYYY-MM-DD HH:MM format

- `age` (`integer`): Patient age

- `gender` (`character`): Patient gender (F/M/O for Female/Male/Other)

- `discharge_disposition` (`integer`): All valid categories according to
  DAD abstracting manual 2022-2023

  - 4: Home with Support/Referral

  - 5: Private Home

  - 8: Cadaveric Donor (does not exist in GEMINI data)

  - 9: Stillbirth (does not exist in GEMINI data)

  - 10: Transfer to Inpatient Care

  - 20: Transfer to ED and Ambulatory Care

  - 30: Transfer to Residential Care

  - 40: Transfer to Group/Supportive Living

  - 90: Transfer to Correctional Facility

  - 61: Absent Without Leave (AWOL)

  - 62: Left Against Medical Advice (LAMA)

  - 65: Did not Return from Pass/Leave

  - 66: Died While on Pass/Leave

  - 67: Suicide out of Facility (does not exist in GEMINI data)

  - 72: Died in Facility

  - 73: Medical Assistance in Dying (MAID)

  - 74: Suicide in Facility

- `alc_service_transfer_flag` (`character`): Variable indicating whether
  patient was transferred to an alternate level of care (ALC) during
  their hospital stay. Coding is messy and varies across sites. Possible
  values are:

  - Missing: `NA`, `""`

  - True: `"TRUE"/"true"/"T"`, `"y"/"Y"`, `"1"/"99"`, `"ALC"`

  - False: `"FALSE"/"false"`, `"N"`, `"0"`, `"non-ALC"` Some entries
    with missing `alc_service_transfer_flag` can be inferred based on
    value of `number_of_alc_days` (see below)

- `number_of_alc_days` (`integer`): Number of days spent in ALC (rounded
  to nearest integer). If `number_of_alc_days = 0`, no ALC occurred; if
  `number_of_alc_days > 0`, ALC occurred. Note that days spent in ALC
  should usually be \< length of stay. However, due to the fact that ALC
  days are rounded up, it's possible for `number_of_alc_days` to be
  larger than `los_days_derived`.

## Examples

``` r
# Simulate 10,000 encounters from 10 hospitals for fiscal years 2018-2020.
admdad <- dummy_admdad(nid = 10000, n_hospitals = 10, time_period = c(2018, 2020))
```
