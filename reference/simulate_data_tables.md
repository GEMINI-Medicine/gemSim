# Data simulation wrapper function

A wrapper that coordinates table-specific simulation functions to
generate relational synthetic tables that reflect the inter-table
structure of the GEMINI data. Users specify which tables to generate and
provide shared inputs such as the number of encounters, hospitals, and
the time period. The function returns a list of simulated `data.table`s
with inter-table relationships handled automatically. Specifically, the
`admdad` table is generated first and provides the encounter IDs used as
the primary key for subsequent table. All tables are simulated to mirror
their real-world linkage patterns to the `admdad` table in GEMINI data.
Available tables include:

- `admdad`

- `ipscu`

- `er`

- `erdiagnosis`

- `ipdiagnosis`

- `locality_variables`

- `lab` \*: currently simulates CBC or electrolyte tests only

- `radiology` \*: currently simulates MRI, CT, and ultrasound imaging
  data only

- `erintervention` \*: currently simulates intervention MRI

- `ipintervention` \*: currently simulates interventions MRI and MAID
  only

- `transfusion`: transfusion information about blood product and issue
  date times

- `physicians`

See [GEMINI Data Repository
Dictionary](https://geminimedicine.ca/the-gemini-database/) for table
definitions and individual simulation function documentation for
details.

## Usage

``` r
simulate_data_tables(
  tables,
  nid = 1000,
  n_hospitals = 10,
  time_period = c(2015, 2023),
  ...
)
```

## Arguments

- tables:

  (`vector`)  
  A `character` vector listing the names of required data tables

- nid:

  (`integer`)  
  The number of mock encounter IDs to simulate.

- n_hospitals:

  (`integer`)  
  The number of mock hospital ID numbers to simulate.

- time_period:

  (`vector`)  
  A numeric or character vector containing the data range of the data by
  years or specific dates in either format: ("yyyy-mm-dd", "yyyy-mm-dd")
  or (yyyy, yyyy). The start date and end date will be (yyyy-01-01 and
  yyyy-12-31) if (yyyy, yyyy) is the date range format provided.

- ...:

  Additional arguments that may be passed into data simulation
  functions. These arguments are normally used to customize table
  outputs.

## Value

(`list`)  
A list containing `data.table` objects, one per entry in the `tables`
parameter where entries are valid GEMINI data tables. May include:
`admdad`, `ipscu`, `er`, `erdiagnosis`, `ipdiagnosis`,
`locality_variables`, `lab`, `radiology`, `erintervention`,
`ipintervention`, `transfusion`, `physicians`

## Details

Wrapper function that calls data simulation functions to create a
synthetic, customizable database that reflects the inter-table relations
of the GEMINI database.

## Examples

``` r
simulate_data_tables(c("admdad", "ipscu", "er"))
#> $admdad
#>       genc_id hospital_num admission_date_time discharge_date_time   age gender
#>         <int>        <int>              <char>              <char> <int> <char>
#>    1:       1            2    2017-10-21 00:00    2017-11-09 13:15    80      F
#>    2:       2            1    2023-04-18 00:00    2023-04-18 15:41    75      M
#>    3:       3            5    2018-11-22 00:00    2019-01-20 23:21    59      M
#>    4:       4            1    2016-02-17 00:00    2016-02-19 00:04    56      M
#>    5:       5            3    2016-04-18 00:00    2016-04-18 17:51    52      M
#>   ---                                                                          
#>  996:     996            3    2023-03-28 00:00    2023-04-14 00:09    40      F
#>  997:     997            7    2017-04-15 00:00    2017-04-16 09:45    78      F
#>  998:     998           10    2019-09-06 00:00    2019-09-10 15:44    77      F
#>  999:     999            2    2022-05-28 00:00    2022-05-29 11:00    80      M
#> 1000:    1000            7    2023-07-04 00:00    2023-07-06 21:46    60      O
#>       discharge_disposition alc_service_transfer_flag number_of_alc_days
#>                       <int>                    <char>              <num>
#>    1:                     5                         y                  4
#>    2:                     5                     false                  0
#>    3:                     5                         0                  0
#>    4:                     5                     false                  0
#>    5:                    10                         0                  0
#>   ---                                                                   
#>  996:                    72                         0                  0
#>  997:                     5                     FALSE                  0
#>  998:                     5                   non-ALC                  0
#>  999:                     5                         n                  0
#> 1000:                     5                     FALSE                  0
#> 
#> $ipscu
#>      hospital_num genc_id scu_admit_date_time scu_discharge_date_time icu_flag
#>             <int>   <int>              <char>                  <char>   <lgcl>
#>   1:            2       1          2017-10-21        2017-10-22 17:48    FALSE
#>   2:            2       1    2017-11-06 15:48        2017-11-08 20:46    FALSE
#>   3:            2       1    2017-11-09 01:40        2017-11-09 12:34     TRUE
#>   4:            1       2          2023-04-18        2023-04-18 11:18     TRUE
#>   5:            4       7    2023-10-07 13:40        2023-10-08 17:28     TRUE
#>  ---                                                                          
#> 264:           10     968    2021-11-20 22:40        2021-11-24 11:09     TRUE
#> 265:           10     968    2021-11-25 07:08        2021-11-25 13:03     TRUE
#> 266:            4     985          2016-12-01        2016-12-01 21:03     TRUE
#> 267:            1     986    2023-12-01 16:32        2023-12-02 23:53     TRUE
#> 268:            1     986    2023-12-07 10:17        2023-12-08 18:59     TRUE
#>      scu_unit_number
#>                <num>
#>   1:              90
#>   2:              90
#>   3:              35
#>   4:              10
#>   5:              35
#>  ---                
#> 264:              20
#> 265:              45
#> 266:              45
#> 267:              60
#> 268:              10
#> 
#> $er
#>      genc_id hospital_num triage_date_time
#>        <int>        <int>           <char>
#>   1:       1            2 2017-10-20 10:26
#>   2:       2            1 2023-04-17 18:01
#>   3:       4            1 2016-02-16 15:44
#>   4:       5            3 2016-04-17 19:09
#>   5:       6            6 2017-09-29 17:29
#>  ---                                      
#> 696:     995           10 2015-06-07 17:34
#> 697:     996            3 2023-03-27 08:53
#> 698:     998           10 2019-09-05 10:38
#> 699:     999            2 2022-05-27 17:23
#> 700:    1000            7 2023-07-03 10:32
#> 

simulate_data_tables(c("admdad", "transfusion"), blood_product_list = c("4023915", "4137859"))
#> $admdad
#>       genc_id hospital_num admission_date_time discharge_date_time   age gender
#>         <int>        <int>              <char>              <char> <int> <char>
#>    1:       1            6    2019-04-25 00:00    2019-05-04 09:10    70      F
#>    2:       2            8    2016-12-09 00:00    2016-12-09 17:17    65      M
#>    3:       3            8    2023-06-19 00:00    2023-06-19 22:26    79      M
#>    4:       4           10    2020-09-25 00:00    2020-09-29 20:51    94      F
#>    5:       5            3    2017-06-23 00:00    2017-06-23 12:03    78      F
#>   ---                                                                          
#>  996:     996            1    2017-02-16 00:00    2017-02-24 11:15    76      F
#>  997:     997            1    2021-04-25 00:00    2021-05-03 12:32    46      F
#>  998:     998           10    2019-12-13 00:00    2019-12-16 12:57    82      M
#>  999:     999           10    2021-07-23 00:00    2021-08-01 11:35    84      M
#> 1000:    1000           10    2019-10-25 00:00    2019-11-02 15:10    73      F
#>       discharge_disposition alc_service_transfer_flag number_of_alc_days
#>                       <int>                    <char>              <num>
#>    1:                    30                                           NA
#>    2:                     4                       ALC                  1
#>    3:                    72                   non-ALC                  0
#>    4:                     5                   non-ALC                  0
#>    5:                     4                         n                  0
#>   ---                                                                   
#>  996:                     5                     false                  0
#>  997:                     4                     false                  0
#>  998:                     5                   non-ALC                  0
#>  999:                    62                   non-ALC                  0
#> 1000:                     5                   non-ALC                  0
#> 
#> $transfusion
#>      genc_id hospital_num  issue_date_time blood_product_mapped_omop
#>        <int>        <int>           <char>                    <char>
#>   1:       9            3 2017-01-13 12:12                   4023915
#>   2:      27            8 2019-09-01 12:42                   4137859
#>   3:      27            8 2019-09-01 12:56                   4137859
#>   4:      27            8 2019-09-01 09:48                   4023915
#>   5:      30           10 2015-01-05 13:26                   4023915
#>  ---                                                                
#> 467:     992            1 2014-12-31 13:10                   4137859
#> 468:     992            1 2014-12-29 17:26                   4137859
#> 469:     996            1 2017-02-20 12:21                   4023915
#> 470:     996            1 2017-02-19 13:16                   4023915
#> 471:     996            1 2017-02-16 09:18                   4137859
#>             blood_product_raw
#>                        <char>
#>   1:                  Albumin
#>   2: SAGM Red blood cells, LR
#>   3: SAGM Red blood cells, LR
#>   4:                  Albumin
#>   5:                  Albumin
#>  ---                         
#> 467: SAGM Red blood cells, LR
#> 468: SAGM Red blood cells, LR
#> 469:                  Albumin
#> 470:                  Albumin
#> 471: SAGM Red blood cells, LR
#> 

simulate_data_tables(c("er", "erintervention", "erdiagnosis"), int_code = c("3AN40VA", "3SC40WC"))
#> $admdad
#>       genc_id hospital_num admission_date_time discharge_date_time   age gender
#>         <int>        <int>              <char>              <char> <int> <char>
#>    1:       1            5    2020-01-02 00:00    2020-01-29 17:48    76      M
#>    2:       2            1    2021-10-25 00:00    2021-11-27 12:14    57      F
#>    3:       3            4    2019-05-18 00:00    2019-05-21 19:05    63      M
#>    4:       4            5    2018-01-21 00:00    2018-01-25 12:14    71      M
#>    5:       5            6    2017-09-18 00:00    2017-10-04 21:51    98      M
#>   ---                                                                          
#>  996:     996            9    2015-08-18 00:00    2015-08-29 12:42    51      F
#>  997:     997            9    2015-12-14 00:00    2015-12-18 12:47    80      M
#>  998:     998            9    2022-05-08 00:00    2022-05-12 16:15    84      F
#>  999:     999            3    2016-11-29 00:00    2016-11-30 14:42    71      F
#> 1000:    1000            4    2022-11-16 00:00    2022-11-17 11:27    88      M
#>       discharge_disposition alc_service_transfer_flag number_of_alc_days
#>                       <int>                    <char>              <num>
#>    1:                     5                         0                  0
#>    2:                     5                      <NA>                 NA
#>    3:                     4                         n                  0
#>    4:                    30                         0                  0
#>    5:                     5                     false                 NA
#>   ---                                                                   
#>  996:                     5                         0                  0
#>  997:                     4                         0                  0
#>  998:                     4                         0                  0
#>  999:                    10                      <NA>                 NA
#> 1000:                     5                         n                  0
#> 
#> $er
#>      genc_id hospital_num triage_date_time
#>        <int>        <int>           <char>
#>   1:       1            5 2020-01-01 15:35
#>   2:       2            1 2021-10-24 17:41
#>   3:       3            4 2019-05-17 18:19
#>   4:       5            6 2017-09-17 09:46
#>   5:       6           10 2018-01-23 15:01
#>  ---                                      
#> 696:     995            9 2023-05-26 00:38
#> 697:     996            9 2015-08-17 17:09
#> 698:     997            9 2015-12-13 13:23
#> 699:     998            9 2022-05-07 22:16
#> 700:    1000            4 2022-11-15 21:49
#> 
#> $erintervention
#>     genc_id hospital_num intervention_code
#>       <int>        <int>            <char>
#>  1:     282            5           3SC40WC
#>  2:     405            3           3AN40VA
#>  3:     471            8           3AN40VA
#>  4:     471            8           3AN40VA
#>  5:     808            2           3SC40WC
#>  6:     808            2           3SC40WC
#>  7:     808            2           3SC40WC
#>  8:     869            5           3AN40VA
#>  9:     869            5           3SC40WC
#> 10:     869            5           3SC40WC
#> 11:     918            6           3SC40WC
#> 
#> $erdiagnosis
#>       genc_id hospital_num er_diagnosis_code er_diagnosis_type
#>         <int>        <int>            <char>            <char>
#>    1:       1            5               R60                  
#>    2:       1            5              M248                 M
#>    3:       2            1              D105                 M
#>    4:       2            1              D151                 M
#>    5:       3            4              F380                  
#>   ---                                                         
#> 2774:     998            9              Q057                  
#> 2775:     998            9              A185                  
#> 2776:     998            9               W32                 M
#> 2777:    1000            4              B388                 M
#> 2778:    1000            4              Q931                 M
#> 
```
