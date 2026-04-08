# Generate simulated lab data

This function creates a synthetic dataset with a subset of lab tests
that are contained in the GEMINI "lab" table, as seen in [GEMINI Data
Repository Dictionary](https://geminimedicine.ca/the-gemini-database/).
The function currently focuses on simulating two lab tests: hemoglobin
and sodium, as they are often used to identify routine blood work tests
of complete blood count and electrolytes. This function will return:
collection date time, information about the test type, test code, and
test result value. It is a long format data table.

## Usage

``` r
dummy_lab_cbc_electrolyte(
  nid = 1000,
  n_hospitals = 10,
  time_period = c(2015, 2023),
  cohort = NULL,
  seed = NULL
)
```

## Arguments

- nid:

  (`integer`) Number of unique encounter IDs to simulate. In this data
  table, each ID occurs once. It is ignored if `cohort` is provided.

- n_hospitals:

  (`integer`) Number of hospitals in simulated dataset. It is ignored if
  `cohort` is provided

- time_period:

  (`numeric`): Date range of data, by years or specific dates in either
  format: ("yyyy-mm-dd", "yyyy-mm-dd") or (yyyy, yyyy). It is ignored if
  `cohort` is provided.

- cohort:

  (`data.frame or data.table`)  
  Optional, a data frame or data table with columns:

  - `genc_id` (`integer`): Mock encounter ID numbers

  - `hospital_num` (`integer`): Mock hospital ID numbers

  - `admission_date_time` (`character`): Date and time of IP admission
    in YYYY-MM-DD HH:MM format

  - `discharge_date_time` (`character`): Date and time of IP discharge
    in YYYY-MM-DD HH:MM format. When `cohort` is not NULL, `nid`,
    `n_hospitals`, and `time_period` are ignored.

- seed:

  (`integer`) Optional, a number for setting the seed to get
  reproducible results.

## Value

(`data.table`)  
A data.table object similar to the "lab" table that contains the
following fields:

- `genc_id` (`integer`): Mock encounter ID; integers starting from 1 or
  as seen in `cohort`

- `hospital_num` (`integer`): Mock hospital ID; integers starting from 1
  or as seen in `cohort`

- `test_type_mapped_omop` (`character`): Test name and code mapped by
  GEMINI; currently two tests are available: 3000963 (hemoglobin) and
  3019550 (sodium)

- `test_name_raw` (`character`): Test name as reported by hospital

- `test_code_raw` (`character`): Test code as reported by hospital

- `result_value` (`character`): Test results

- `collection_date_time` (`character`): Date and time when the sample
  was collected

## Examples

``` r
dummy_lab_cbc_electrolyte(nid = 10, n_hospitals = 1, seed = 1)
#>      genc_id hospital_num collection_date_time test_type_mapped_omop
#>        <int>        <int>               <char>                 <num>
#>   1:       1            1     2016-11-07 09:22               3000963
#>   2:       1            1     2016-11-08 08:07               3019550
#>   3:       1            1     2016-11-08 10:25               3000963
#>   4:       1            1     2016-11-07 06:28               3000963
#>   5:       1            1     2016-11-08 09:05               3019550
#>  ---                                                                
#> 149:      10            1     2021-12-29 14:49               3019550
#> 150:      10            1     2021-12-29 11:06               3000963
#> 151:      10            1     2021-12-29 09:58               3019550
#> 152:      10            1     2021-12-29 06:19               3000963
#> 153:      10            1     2021-12-29 08:33               3000963
#>      test_name_raw test_code_raw result_value
#>             <char>        <char>       <char>
#>   1:    HEMOGLOBIN           HGB           76
#>   2:        SODIUM          <NA>          139
#>   3:    HEMOGLOBIN          <NA>          101
#>   4:    Hemoglobin          <NA>          130
#>   5:        Sodium          <NA>          138
#>  ---                                         
#> 149:        Sodium          <NA>          138
#> 150:   Haemoglobin           HGB           89
#> 151:        SODIUM          <NA>          131
#> 152:    HEMOGLOBIN          <NA>           82
#> 153:           CBC                         85
dummy_lab_cbc_electrolyte(cohort = dummy_admdad())
#>        genc_id hospital_num collection_date_time test_type_mapped_omop
#>          <int>        <int>               <char>                 <num>
#>     1:       1            6     2019-03-08 03:56               3019550
#>     2:       1            6     2019-03-09 07:19               3000963
#>     3:       1            6     2019-03-08 06:43               3000963
#>     4:       1            6     2019-03-08 11:00               3019550
#>     5:       1            6     2019-03-08 03:40               3019550
#>    ---                                                                
#> 15747:    1000            7     2022-12-24 14:56               3019550
#> 15748:    1000            7     2022-12-24 20:28               3019550
#> 15749:    1000            7     2022-12-24 03:39               3019550
#> 15750:    1000            7     2022-12-24 19:35               3000963
#> 15751:    1000            7     2022-12-24 06:11               3019550
#>        test_name_raw test_code_raw result_value
#>               <char>        <char>       <char>
#>     1:        Sodium          <NA>          131
#>     2:    Hemoglobin          <NA>          126
#>     3:    Hemoglobin         HBTOT           78
#>     4:        Sodium          <NA>          136
#>     5:        SODIUM          <NA>          138
#>    ---                                         
#> 15747:        Sodium          <NA>          144
#> 15748:        Sodium                        132
#> 15749:        Sodium                        137
#> 15750:    Hemoglobin          <NA>          119
#> 15751:        Sodium          <NA>          137
```
