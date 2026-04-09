# Generate simulated radiology data

This function creates a dummy dataset with a subset of variables that
are contained in the GEMINI "radiology" table, as seen in [GEMINI Data
Repository Dictionary](https://geminimedicine.ca/the-gemini-database/).

This function only simulates modalities used in the MyPractice and
OurPractice Reports: CT, MRI, Ultrasound. It does not cover all
modalities seen in the actual "radiology" data table.

## Usage

``` r
dummy_radiology(
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
  to simulate multiple radiology tests, resulting in a data table with
  more rows than `nid`. Alternatively, if users provide a `cohort`
  input, the function will instead simulate radiology data for all
  `genc_ids` in the user-defined cohort table.

- n_hospitals:

  (`integer`)  
  The number of hospitals to simulate. Alternatively, if users provide a
  `cohort` input, the function will instead simulate radiology data for
  all `hospital_nums` in the user-defined cohort table

- time_period:

  (`vector`)  
  A numeric or character vector containing the data range of the data by
  years or specific dates in either format: ("yyyy-mm-dd", "yyyy-mm-dd")
  or (yyyy, yyyy) The start date and end date will be (yyyy-01-01 and
  yyyy-12-31) if (yyyy, yyyy) is the date range format provided.
  Optional when `cohort` is provided.

- cohort:

  (`data.frame or data.table`)  
  Optional, data frame or data table with the following columns:

  - `genc_id` (`integer`): Mock encounter ID number

  - `hospital_num` (`integer`): Mock hospital ID number

  - `admission_date_time` (`character`): Date and time of IP admission
    in YYYY-MM-DD HH:MM format

  - `discharge_date_time` (`character`): Date and time of IP discharge
    in YYYY-MM-DD HH:MM format. When a `cohort` input is provided,
    `nid`, `n_hospitals`, and `time_period` are ignored.

- seed:

  (`integer`)  
  Optional, a number to be used to set the seed for reproducible
  results.

## Value

(`data.table`)  
A `data.table` object similar that contains the following fields:

- `genc_id` (`integer`): Mock encounter ID number; integers starting
  from 1 or from `cohort` if provided

- `hospital_num` (`integer`): Mock hospital ID number; integers starting
  from 1 or from `cohort` if provided

- `modality_mapped` (`character`): Imaging modality: either MRI, CT, or
  Ultrasound.

- `ordered_date_time` (`character`): The date and time the radiology
  test was ordered

- `performed_date_time` (`character`): The date and time the radiology
  test was performed

## Examples

``` r
cohort <- dummy_admdad()
dummy_radiology(cohort = cohort)
#>       genc_id hospital_num ordered_date_time performed_date_time
#>         <int>        <int>            <char>              <char>
#>    1:       1            8  2015-03-03 09:08    2015-03-03 12:33
#>    2:       1            8  2015-03-06 01:33    2015-03-06 02:39
#>    3:       1            8  2015-03-06 15:15    2015-03-06 21:37
#>    4:       1            8  2015-03-05 07:37    2015-03-05 09:54
#>    5:       1            8  2015-03-04 23:59    2015-03-05 02:59
#>   ---                                                           
#> 4591:     999            4  2019-05-25 08:24    2019-05-25 14:20
#> 4592:     999            4  2019-05-27 09:38    2019-05-27 09:38
#> 4593:    1000            4  2021-06-14 13:12    2021-06-14 17:53
#> 4594:    1000            4  2021-06-13 19:57    2021-06-13 20:11
#> 4595:    1000            4  2021-06-13 12:13    2021-06-13 14:47
#>       modality_mapped
#>                <char>
#>    1:      Ultrasound
#>    2:              CT
#>    3:              CT
#>    4:             MRI
#>    5:              CT
#>   ---                
#> 4591:      Ultrasound
#> 4592:              CT
#> 4593:             MRI
#> 4594:              CT
#> 4595:      Ultrasound
dummy_radiology(nid = 1000, n_hospitals = 10, time_period = c(2020, 2023))
#>       genc_id hospital_num ordered_date_time performed_date_time
#>         <int>        <int>            <char>              <char>
#>    1:       1            6  2023-06-11 17:20    2023-06-11 17:20
#>    2:       1            6  2023-06-08 15:30    2023-06-09 05:00
#>    3:       2            6  2020-08-07 11:50    2020-08-07 11:50
#>    4:       2            6  2020-08-11 12:45    2020-08-11 16:38
#>    5:       2            6  2020-08-10 15:17    2020-08-10 15:34
#>   ---                                                           
#> 4437:    1000            6  2023-02-02 13:15    2023-02-02 14:55
#> 4438:    1000            6  2023-02-03 10:57    2023-02-03 12:00
#> 4439:    1000            6  2023-02-08 15:13    2023-02-08 23:33
#> 4440:    1000            6  2023-02-02 16:03    2023-02-02 16:03
#> 4441:    1000            6  2023-02-01 20:21    2023-02-02 23:18
#>       modality_mapped
#>                <char>
#>    1:              CT
#>    2:              CT
#>    3:      Ultrasound
#>    4:              CT
#>    5:      Ultrasound
#>   ---                
#> 4437:              CT
#> 4438:              CT
#> 4439:              CT
#> 4440:              CT
#> 4441:              CT
```
