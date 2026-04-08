# Generate simulated transfusion data

This function creates a dummy dataset with a subset of variables that
are contained in the GEMINI "transfusion" table, as seen in [GEMINI Data
Repository Dictionary](https://geminimedicine.ca/the-gemini-database/).

## Usage

``` r
dummy_transfusion(
  nid = 1000,
  n_hospitals = 10,
  time_period = c(2015, 2023),
  cohort = NULL,
  blood_product_list = NULL,
  seed = NULL
)
```

## Arguments

- nid:

  (`integer`)  
  The number of unique mock encounter IDs to simulate. Encounter IDs may
  repeat, resulting in a data table with more rows than `nid`. Optional
  if `cohort` is provided.

- n_hospitals:

  (`integer`)  
  The number of hospitals to simulate, optional if `cohort` is provided.

- time_period:

  (`vector`)  
  A numeric or character vector containing the data range of the data by
  years or specific dates in either format: ("yyyy-mm-dd", "yyyy-mm-dd")
  or (yyyy, yyyy). The start date and end date will be (yyyy-01-01 and
  yyyy-12-31) if (yyyy, yyyy) is the date range format provided. Not
  used when `cohort` is provided.

- cohort:

  (`data.frame or data.table`)  
  Optional, a data frame or data table with columns:

  - `genc_id` (`integer`): Mock encounter ID number

  - `hospital_num` (`integer`): Mock hospital ID number

  - `admission_date_time` (`character`): Date and time of IP admission
    in YYYY-MM-DD HH:MM format.

  - `discharge_date_time` (`character`): Date and time of IP discharge
    in YYYY-MM-DD HH:MM format. When `cohort` is not NULL, `nid`,
    `n_hospitals`, and `time_period` are ignored.

- blood_product_list:

  (`character`)  
  Either a string or a character vector to sample for the variable
  `blood_product_mapped_omop`. Items must be real blood product OMOP
  codes or it will not be used and a warning will be raised.

- seed:

  (`integer`)  
  Optional, a number to be used to set the seed for reproducible
  results.

## Value

(`data.table`)  
A data.table object similar to the "transfusion" table with the
following fields:

- `genc_id` (`integer`): Mock encounter ID number; integers starting
  from 1 or from `cohort`

- `hospital_num` (`integer`): Mock hospital ID number; integers starting
  from 1 or from `cohort`

- `issue_date_time` (`character`): The date and time the transfusion was
  issued, in the format ("yy-mm-dd hh:mm")

- `blood_product_mapped_omop` (`character`): Blood product name mapped
  by GEMINI following international standard.

- `blood_product_raw` (`character`): Type of blood product or component
  transfused as reported by hospital.

## Examples

``` r
dummy_transfusion(nid = 1000, n_hospitals = 30, seed = 1)
#>       genc_id hospital_num  issue_date_time blood_product_mapped_omop
#>         <int>        <int>           <char>                    <char>
#>    1:       1           25 2020-01-03 18:12                   4022173
#>    2:       1           25 2020-01-04 21:10                   4022173
#>    3:       1           25 2020-01-03 13:45                   4022173
#>    4:       1           25 2020-01-04 08:44                   4022173
#>    5:       1           25 2020-01-05 09:57                   4022173
#>   ---                                                                
#> 4854:     999           16 2015-11-10 06:27                   4022173
#> 4855:     999           16 2015-11-10 14:13                   4022173
#> 4856:     999           16 2015-11-10 13:46                   4022173
#> 4857:    1000           11 2016-06-02 12:48                   4022173
#> 4858:    1000           11 2016-05-30 14:05                   4022173
#>       blood_product_raw
#>                  <char>
#>    1:   Red Blood Cells
#>    2:   Red Blood Cells
#>    3:   Red Blood Cells
#>    4:   Red Blood Cells
#>    5:   Red Blood Cells
#>   ---                  
#> 4854:   Red Blood Cells
#> 4855:   Red Blood Cells
#> 4856:   Red Blood Cells
#> 4857:   Red Blood Cells
#> 4858:   Red Blood Cells
dummy_transfusion(cohort = dummy_admdad())
#>       genc_id hospital_num  issue_date_time blood_product_mapped_omop
#>         <int>        <int>           <char>                    <char>
#>    1:       1           10 2021-05-11 02:47                   4022173
#>    2:       1           10 2021-05-09 21:32                   4022173
#>    3:       2            9 2016-07-29 04:38                   4022173
#>    4:       2            9 2016-07-29 04:38                   4022173
#>    5:       2            9 2016-07-29 04:38                   4022173
#>   ---                                                                
#> 4803:    1000            5 2021-06-02 10:46                   4137859
#> 4804:    1000            5 2021-06-04 12:54                   4137859
#> 4805:    1000            5 2021-06-02 10:14                   4137859
#> 4806:    1000            5 2021-06-03 16:01                   4137859
#> 4807:    1000            5 2021-06-04 16:39                   4137859
#>              blood_product_raw
#>                         <char>
#>    1:          Red Blood Cells
#>    2:          Red Blood Cells
#>    3:          Red Blood Cells
#>    4:          Red Blood Cells
#>    5:          Red Blood Cells
#>   ---                         
#> 4803: SAGM Red blood cells, LR
#> 4804: SAGM Red blood cells, LR
#> 4805: SAGM Red blood cells, LR
#> 4806: SAGM Red blood cells, LR
#> 4807: SAGM Red blood cells, LR
dummy_transfusion(nid = 100, n_hospitals = 1, blood_product_list = c("0", "35605159", "35615187"))
#> Warning: User input contains at least one invalid blood product OMOP code: 0
#>      genc_id hospital_num  issue_date_time blood_product_mapped_omop
#>        <int>        <int>           <char>                    <char>
#>   1:       1            1 2017-04-26 23:34                  35605159
#>   2:       1            1 2017-04-26 21:00                  35615187
#>   3:       2            1 2019-06-08 15:01                  35615187
#>   4:       2            1 2019-06-08 16:10                  35615187
#>   5:       2            1 2019-06-10 23:56                  35605159
#>  ---                                                                
#> 530:     100            1 2021-08-26 01:45                  35615187
#> 531:     100            1 2021-08-26 18:12                  35615187
#> 532:     100            1 2021-08-27 13:33                  35605159
#> 533:     100            1 2021-08-27 15:49                  35605159
#> 534:     100            1 2021-08-27 16:26                  35605159
#>                blood_product_raw
#>                           <char>
#>   1:                 C1-ESTERASE
#>   2: Intravenous Immune Globulin
#>   3: Intravenous Immune Globulin
#>   4: Intravenous Immune Globulin
#>   5:                 C1-ESTERASE
#>  ---                            
#> 530: Intravenous Immune Globulin
#> 531: Intravenous Immune Globulin
#> 532:                 C1-ESTERASE
#> 533:                 C1-ESTERASE
#> 534:                 C1-ESTERASE
```
