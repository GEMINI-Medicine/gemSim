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
#>    1:       1           25 2020-01-05 18:12                   4022173
#>    2:       1           25 2020-01-04 21:10                   4022173
#>    3:       1           25 2020-01-04 13:45                   4022173
#>    4:       1           25 2020-01-04 17:59                   4022173
#>    5:       1           25 2020-01-05 09:57                   4022173
#>   ---                                                                
#> 4854:     999           16 2015-10-31 06:27                   4137859
#> 4855:     999           16 2015-11-02 22:41                   4137859
#> 4856:     999           16 2015-10-28 13:46                   4137859
#> 4857:    1000           11 2016-06-04 12:48                   4022173
#> 4858:    1000           11 2016-06-02 14:05                   4022173
#>              blood_product_raw
#>                         <char>
#>    1:          Red Blood Cells
#>    2:          Red Blood Cells
#>    3:          Red Blood Cells
#>    4:          Red Blood Cells
#>    5:          Red Blood Cells
#>   ---                         
#> 4854: SAGM Red blood cells, LR
#> 4855: SAGM Red blood cells, LR
#> 4856: SAGM Red blood cells, LR
#> 4857:          Red Blood Cells
#> 4858:          Red Blood Cells
dummy_transfusion(cohort = dummy_admdad())
#>       genc_id hospital_num  issue_date_time blood_product_mapped_omop
#>         <int>        <int>           <char>                    <char>
#>    1:       1            8 2023-05-26 14:03                   4137859
#>    2:       1            8 2023-05-26 19:37                   4137859
#>    3:       1            8 2023-05-23 17:01                   4137859
#>    4:       1            8 2023-05-24 17:36                   4137859
#>    5:       1            8 2023-05-26 19:54                   4137859
#>   ---                                                                
#> 4888:     999            9 2023-08-04 15:22                   4137859
#> 4889:    1000            9 2015-11-29 14:03                   4137859
#> 4890:    1000            9 2015-11-29 18:14                   4137859
#> 4891:    1000            9 2015-11-28 15:15                   4137859
#> 4892:    1000            9 2015-11-29 00:55                   4137859
#>              blood_product_raw
#>                         <char>
#>    1: SAGM Red blood cells, LR
#>    2: SAGM Red blood cells, LR
#>    3: SAGM Red blood cells, LR
#>    4: SAGM Red blood cells, LR
#>    5: SAGM Red blood cells, LR
#>   ---                         
#> 4888: SAGM Red blood cells, LR
#> 4889: SAGM Red blood cells, LR
#> 4890: SAGM Red blood cells, LR
#> 4891: SAGM Red blood cells, LR
#> 4892: SAGM Red blood cells, LR
dummy_transfusion(nid = 100, n_hospitals = 1, blood_product_list = c("0", "35605159", "35615187"))
#> Warning: User input contains at least one invalid blood product OMOP code: 0
#>      genc_id hospital_num  issue_date_time blood_product_mapped_omop
#>        <int>        <int>           <char>                    <char>
#>   1:       1            1 2021-04-08 17:08                  35605159
#>   2:       1            1 2021-04-07 11:03                  35605159
#>   3:       2            1 2016-04-28 14:36                         0
#>   4:       2            1 2016-04-28 15:13                  35615187
#>   5:       2            1 2016-04-28 10:11                         0
#>  ---                                                                
#> 473:     100            1 2017-11-29 10:55                  35605159
#> 474:     100            1 2017-11-29 19:03                  35615187
#> 475:     100            1 2017-11-30 02:48                         0
#> 476:     100            1 2017-11-30 04:03                         0
#> 477:     100            1 2017-11-29 20:40                  35615187
#>                blood_product_raw
#>                           <char>
#>   1:                 C1-ESTERASE
#>   2:                 C1-ESTERASE
#>   3:                         FAR
#>   4: Intravenous Immune Globulin
#>   5:                         FAR
#>  ---                            
#> 473:                 C1-ESTERASE
#> 474: Intravenous Immune Globulin
#> 475:                         FAR
#> 476:                         FAR
#> 477: Intravenous Immune Globulin
```
