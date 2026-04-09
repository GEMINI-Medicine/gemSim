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
#>   1:            9       1    2022-10-05 20:24        2022-10-07 00:58     TRUE
#>   2:            9       1    2022-10-09 22:11        2022-10-11 11:52     TRUE
#>   3:            4       2    2020-07-10 21:24        2020-07-11 16:15     TRUE
#>   4:            7       3    2020-01-05 09:36        2020-01-06 12:20    FALSE
#>   5:            1       4    2017-12-11 20:17        2017-12-13 21:25     TRUE
#>  ---                                                                          
#> 124:            5      94    2023-02-21 09:20        2023-03-03 18:45     TRUE
#> 125:            5      94    2023-03-03 21:52        2023-03-09 20:30     TRUE
#> 126:            5      94    2023-03-10 14:34        2023-03-11 14:30     TRUE
#> 127:            8      99    2016-03-03 20:10        2016-03-04 19:36     TRUE
#> 128:            8      99    2016-03-08 07:06        2016-03-08 17:27     TRUE
#>      scu_unit_number
#>                <num>
#>   1:              25
#>   2:              45
#>   3:              25
#>   4:              95
#>   5:              25
#>  ---                
#> 124:              45
#> 125:              25
#> 126:              25
#> 127:              20
#> 128:              45
dummy_ipscu(nid = 11, n_hospitals = 1, time_period = c("2020-01-01", "2021-01-01"), seed = 2)
#>     hospital_num genc_id scu_admit_date_time scu_discharge_date_time icu_flag
#>            <int>   <int>              <char>                  <char>   <lgcl>
#>  1:            1       1    2020-03-25 11:58        2020-03-26 18:49    FALSE
#>  2:            1       2    2020-10-02 18:07        2020-10-03 12:56     TRUE
#>  3:            1       3    2020-02-26 21:14        2020-02-28 10:32     TRUE
#>  4:            1       3    2020-02-28 20:34        2020-03-02 11:17     TRUE
#>  5:            1       3    2020-03-05 02:18        2020-03-06 21:09    FALSE
#>  6:            1       4    2020-05-18 04:43        2020-05-20 14:31     TRUE
#>  7:            1       5    2020-11-07 04:48        2020-11-08 15:39     TRUE
#>  8:            1       6    2020-12-20 08:29        2020-12-21 19:57     TRUE
#>  9:            1       7    2020-03-14 18:43        2020-03-16 13:57    FALSE
#> 10:            1       7    2020-03-16 22:56        2020-03-18 22:24     TRUE
#> 11:            1       7    2020-03-18 22:24        2020-03-22 18:48     TRUE
#> 12:            1       7    2020-03-22 23:42        2020-03-23 15:46     TRUE
#> 13:            1       8    2020-06-10 16:50        2020-06-10 21:25    FALSE
#> 14:            1       9    2020-01-24 19:18        2020-01-26 19:43    FALSE
#> 15:            1       9    2020-01-27 07:27        2020-01-28 18:10     TRUE
#> 16:            1      10    2020-08-29 07:24        2020-08-30 21:17     TRUE
#>     scu_unit_number
#>               <num>
#>  1:              90
#>  2:              35
#>  3:              60
#>  4:              60
#>  5:              93
#>  6:              10
#>  7:              50
#>  8:              60
#>  9:              93
#> 10:              10
#> 11:              35
#> 12:              50
#> 13:              95
#> 14:              90
#> 15:              10
#> 16:              10
```
