# Generate simulated ipscu data.

This function creates a dummy dataset with a subset of variables that
are contained in the GEMINI "ipscu" table, as seen in [GEMINI Data
Repository Dictionary](https://geminimedicine.ca/the-gemini-database/).

## Usage

``` r
dummy_ipscu(
  nid = 1000,
  n_hospitals = 10,
  time_period = c(2015, 2023),
  cohort = NULL,
  seed = NULL
)
```

## Arguments

- nid:

  (`integer`)  
  Number of unique encounter IDs to simulate. Encounter IDs may repeat
  due to repeat visits being simulated, resulting in a data table with
  more rows than `nid`.

- n_hospitals:

  (`integer`)  
  Number of hospitals in simulated dataset.

- time_period:

  (`vector`)  
  A numeric or character vector containing the data range of the data by
  years or specific dates in either format: ("yyyy-mm-dd", "yyyy-mm-dd")
  or (yyyy, yyyy). The start date and end date will be (yyyy-01-01 and
  yyyy-12-31) if (yyyy, yyyy) is the date range format provided.
  Optional when `cohort` is provided.

- cohort:

  (`data.frame or data.table`)  
  Optional, data frame with the following columns:

  - `genc_id` (`integer`): Mock encounter ID number

  - `hospital_num` (`integer`): Mock hospital ID number

  - `admission_date_time` (`character`): Date and time of IP admission
    in YYYY-MM-DD HH:MM format

  - `discharge_date_time` (`character`): Date and time of IP discharge
    in YYYY-MM-DD HH:MM format. When `cohort` is not NULL, `nid`,
    `n_hospitals`, and `time_period` are ignored.

- seed:

  (`integer`)  
  Optional, a number to be used to set the seed for reproducible
  results.

## Value

(`data.table`)  
A data.table object similar to the "ipscu" table that contains the
following fields:

- `genc_id` (`integer`): Mock encounter ID; integers starting from 1 or
  from `cohort`

- `hospital_num` (`integer`): Mock hospital ID number; integers starting
  from 1 or from `cohort`

- `scu_admit_date_time` (`character`): Date and time of SCU admission in
  YYYY-MM-DD HH:MM format

- `scu_discharge_date_time` (`character`): Date and time of SCU
  discharge in YYYY-MM-DD HH:MM format

- `icu_flag` (`logical`): Flag specifying whether the encounter was
  admitted to the ICU or not. This refers to to SCU unit numbers
  excluding the step down units of 90, 93, and 95.

- `scu_unit_number`(`integer`): Code identifying the type of special
  care unit where the patient receives critical care, according to DAD
  abstracting manual 2025-2026

  - 10: Medical Intensive Care Nursing Unit

  - 20: Surgical Intensive Care Nursing Unit

  - 25: Trauma Intensive Care Nursing Unit

  - 30: Combined Medical/Surgical Intensive Care Nursing Unit

  - 35: Burn Intensive Care Nursing Unit

  - 40: Cardiac Intensive Care Nursing Unit Surgery (CCU)

  - 45: Coronary Intensive Care Nursing Unit Medical (CCU)

  - 50: Neonatal Intensive Care Nursing Unit Undifferentiated/General

  - 60: Neurosurgery Intensive Care Nursing Unit

  - 80: Respirology Intensive Care Nursing Unit

  - 90: Step-Down Medical Unit

  - 93: Combined Medical/Surgical Step-Down Unit

  - 95: Step-Down Surgical Unit

## Examples

``` r
dummy_ipscu(nid = 100, n_hospitals = 10, time_period = c(2015, 2023), seed = 1)
#>      hospital_num genc_id scu_admit_date_time scu_discharge_date_time icu_flag
#>             <int>   <int>              <char>                  <char>   <lgcl>
#>   1:            4       2    2020-07-08 12:44        2020-07-08 16:38     TRUE
#>   2:            4       2    2020-07-09 02:50        2020-07-09 19:38     TRUE
#>   3:            7       3    2019-12-27 13:30        2019-12-28 11:36     TRUE
#>   4:            7       3    2019-12-30 05:24        2020-01-05 20:35     TRUE
#>   5:            7       3    2020-01-06 06:34        2020-01-06 08:08     TRUE
#>  ---                                                                          
#> 109:            8      96    2018-09-13 07:21        2018-09-15 15:10     TRUE
#> 110:            8      96    2018-09-16 09:03        2018-09-17 17:36     TRUE
#> 111:            5      97    2016-11-09 14:11        2016-11-10 16:04    FALSE
#> 112:            5      97    2016-11-11 22:35        2016-11-18 14:22    FALSE
#> 113:            5      97    2016-11-19 01:39        2016-11-19 20:07     TRUE
#>      scu_unit_number
#>                <num>
#>   1:              45
#>   2:              25
#>   3:              25
#>   4:              20
#>   5:              45
#>  ---                
#> 109:              20
#> 110:              45
#> 111:              93
#> 112:              93
#> 113:              25
dummy_ipscu(nid = 11, n_hospitals = 1, time_period = c("2020-01-01", "2021-01-01"), seed = 2)
#>     hospital_num genc_id scu_admit_date_time scu_discharge_date_time icu_flag
#>            <int>   <int>              <char>                  <char>   <lgcl>
#>  1:            1       1    2020-03-26 11:58        2020-03-28 20:15     TRUE
#>  2:            1       3    2020-02-27 21:14        2020-02-29 10:32     TRUE
#>  3:            1       3    2020-02-29 10:32        2020-02-29 17:57     TRUE
#>  4:            1       3    2020-03-03 08:57        2020-03-05 10:16     TRUE
#>  5:            1       4    2020-05-19 04:43        2020-05-21 14:31     TRUE
#>  6:            1       4    2020-05-22 02:15        2020-05-22 12:13     TRUE
#>  7:            1       4    2020-05-22 12:13        2020-05-24 21:59     TRUE
#>  8:            1       6          2020-12-21        2020-12-21 19:57     TRUE
#>  9:            1       7    2020-03-15 18:43        2020-03-17 13:57     TRUE
#> 10:            1       7    2020-03-17 23:59        2020-03-19 10:42     TRUE
#> 11:            1       7    2020-03-19 10:42        2020-03-20 16:26     TRUE
#> 12:            1       7    2020-03-20 20:40        2020-03-21 16:21     TRUE
#> 13:            1       8    2020-06-11 16:50        2020-06-11 21:25     TRUE
#> 14:            1       9    2020-01-25 19:18        2020-01-27 18:49     TRUE
#> 15:            1       9    2020-01-28 03:29        2020-01-28 09:22     TRUE
#>     scu_unit_number
#>               <num>
#>  1:              50
#>  2:              50
#>  3:              35
#>  4:              10
#>  5:              60
#>  6:              60
#>  7:              10
#>  8:              50
#>  9:              35
#> 10:              35
#> 11:              35
#> 12:              60
#> 13:              60
#> 14:              10
#> 15:              35
```
