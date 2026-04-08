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
#>    1:       1            4 2022-02-23 23:02
#>    2:       2            6 2020-09-15 14:07
#>    3:       3            6 2020-03-14 07:06
#>    4:       4            6 2020-11-05 05:38
#>    5:       5           10 2018-03-15 14:22
#>   ---                                      
#>  996:     996            6 2022-09-02 12:23
#>  997:     997            2 2018-04-10 15:16
#>  998:     998            4 2017-05-06 12:09
#>  999:     999            7 2023-06-24 10:12
#> 1000:    1000            1 2016-03-26 10:02
dummy_er(nid = 10, n_hospitals = 1, seed = 2)
#>     genc_id hospital_num triage_date_time
#>       <int>        <int>           <char>
#>  1:       1            1 2019-12-11 09:35
#>  2:       2            1 2017-02-22 13:58
#>  3:       3            1 2021-11-02 17:15
#>  4:       4            1 2016-08-03 19:16
#>  5:       5            1 2018-08-23 10:28
#>  6:       6            1 2022-09-01 15:48
#>  7:       7            1 2023-10-13 15:29
#>  8:       8            1 2017-01-11 13:26
#>  9:       9            1 2018-12-19 02:56
#> 10:      10            1 2015-08-28 14:17
```
