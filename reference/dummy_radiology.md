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
#>    1:       1            8  2015-03-08 23:27    2015-03-09 00:25
#>    2:       1            8  2015-03-27 12:43    2015-03-27 14:38
#>    3:       1            8  2015-03-07 09:51    2015-03-07 12:15
#>    4:       2            8  2016-09-09 15:47    2016-09-09 20:20
#>    5:       2            8  2016-08-19 14:35    2016-08-20 14:32
#>   ---                                                           
#> 4460:    1000            4  2021-06-08 09:43    2021-06-09 05:14
#> 4461:    1000            4  2021-06-11 16:49    2021-06-11 20:57
#> 4462:    1000            4  2021-06-08 05:40    2021-06-08 05:58
#> 4463:    1000            4  2021-06-07 13:41    2021-06-07 16:54
#> 4464:    1000            4  2021-06-11 11:02    2021-06-12 02:07
#>       modality_mapped
#>                <char>
#>    1:      Ultrasound
#>    2:              CT
#>    3:              CT
#>    4:      Ultrasound
#>    5:      Ultrasound
#>   ---                
#> 4460:              CT
#> 4461:              CT
#> 4462:      Ultrasound
#> 4463:              CT
#> 4464:      Ultrasound
dummy_radiology(nid = 1000, n_hospitals = 10, time_period = c(2020, 2023))
#>       genc_id hospital_num ordered_date_time performed_date_time
#>         <int>        <int>            <char>              <char>
#>    1:       1            8  2020-12-08 10:38    2020-12-08 13:29
#>    2:       1            8  2020-12-04 16:02    2020-12-04 18:15
#>    3:       1            8  2020-12-07 10:08    2020-12-07 12:35
#>    4:       1            8  2020-12-05 11:06    2020-12-05 13:18
#>    5:       2            3  2022-03-22 11:27    2022-03-22 22:51
#>   ---                                                           
#> 4475:     999            3  2022-01-30 00:33    2022-01-30 00:47
#> 4476:     999            3  2022-01-30 13:02    2022-01-30 20:05
#> 4477:    1000            2  2021-05-16 22:45    2021-05-16 23:12
#> 4478:    1000            2  2021-05-16 17:55    2021-05-16 21:32
#> 4479:    1000            2  2021-05-16 12:08    2021-05-16 15:18
#>       modality_mapped
#>                <char>
#>    1:              CT
#>    2:      Ultrasound
#>    3:              CT
#>    4:              CT
#>    5:              CT
#>   ---                
#> 4475:              CT
#> 4476:              CT
#> 4477:      Ultrasound
#> 4478:              CT
#> 4479:              CT
```
