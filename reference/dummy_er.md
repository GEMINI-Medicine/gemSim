# Generate simulated ER data.

This function creates a dummy dataset with a subset of variables that
are contained in the GEMINI "er" table, as seen in [GEMINI Data
Repository Dictionary](https://geminimedicine.ca/the-gemini-database/).

This function will return one triage date time for each encounter ID.

## Usage

``` r
dummy_er(
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
  table, each ID occurs once. Optional when `cohort` is provided.

- n_hospitals:

  (`integer`) Number of hospitals in the simulated dataset. Optional
  when `cohort` is provided.

- time_period:

  (`vector`)  
  A numeric or character vector containing the data range of the data by
  years or specific dates in either format: ("yyyy-mm-dd", "yyyy-mm-dd")
  or (yyyy, yyyy). The start date and end date will be (yyyy-01-01 and
  yyyy-12-31) if (yyyy, yyyy) is the date range format provided.
  Optional when `cohort` is provided.

- cohort:

  (`data.frame or data.table`): Optional, a data frame with the
  following columns:

  - `genc_id` (`integer`): Mock encounter ID

  - `hospital_num` (`integer`): Mock hospital ID number

  - `admission_date_time` (`character`): The date and time of admission
    to the hospital with format "%Y-%m-%d %H:%M"

  - `discharge_date_time` (`character`): The date and time of discharge
    from the hospital with format "%Y-%m-%d %H:%M" When `cohort` is not
    NULL, `nid`, `n_hospitals`, and `time_period` are ignored.

- seed:

  (`integer`) Optional, a number for setting the seed to get
  reproducible results.

## Value

(`data.table`) A data.table object similar to the "er" table that
contains the following fields:

- `genc_id` (`integer`): Mock encounter ID; integers starting from 1 or
  from `cohort` if provided

- `hospital_num` (`integer`): Mock hospital ID; integers starting from 1
  or from `cohort` if provided

- `triage_date_time` (`character`): The date and time of triage with
  format "%Y-%m-%d %H:%M"

## Examples

``` r
cohort <- dummy_admdad()
dummy_er(cohort = cohort, seed = 1)
#>       genc_id hospital_num triage_date_time
#>         <int>        <int>           <char>
#>    1:       1            9 2019-05-06 00:03
#>    2:       2           10 2015-07-23 00:06
#>    3:       3            2 2020-02-06 07:06
#>    4:       4            3 2016-01-23 05:38
#>    5:       5            1 2016-01-13 08:22
#>   ---                                      
#>  996:     996            2 2017-09-19 15:37
#>  997:     997            9 2018-12-16 07:30
#>  998:     998            5 2023-07-11 15:02
#>  999:     999            4 2015-05-18 07:15
#> 1000:    1000           10 2021-12-17 10:02
dummy_er(nid = 10, n_hospitals = 1, seed = 2)
#>     genc_id hospital_num triage_date_time
#>       <int>        <int>           <char>
#>  1:       1            1 2019-12-10 17:39
#>  2:       2            1 2017-02-21 16:37
#>  3:       3            1 2021-11-01 19:30
#>  4:       4            1 2016-08-03 07:38
#>  5:       5            1 2018-08-22 10:28
#>  6:       6            1 2022-09-01 05:48
#>  7:       7            1 2023-10-12 11:44
#>  8:       8            1 2017-01-11 10:27
#>  9:       9            1 2018-12-19 02:56
#> 10:      10            1 2015-08-27 14:17
```
