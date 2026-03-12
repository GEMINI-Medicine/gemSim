<!-- badges: start -->
[![R-CMD-check](https://github.com/GEMINI-Medicine/gemSim/actions/workflows/check-standard.yaml/badge.svg)](https://github.com/GEMINI-Medicine/gemSim/actions/workflows/check-standard.yaml)

<!-- badges: end -->

# gemSim
`gemSim` is a custom R package for generating synthetic datasets that mimic the structure of the [GEMINI database](https://geminimedicine.ca/the-gemini-database/).

The package **does not** sample from or reproduce real GEMINI data. Instead, it generates fully synthetic, randomly simulated data designed to approximate the database schema (e.g., table names and key linkage variables) and high-level distributional characteristics of GEMINI's current data holdings (e.g., age & gender distributions, frequency of lab/radiology testing, hospital-level variability etc.).

Some data elements are simulated in ways that produce plausible individual records. For instance, clinical date-time variables are generated to fall within the admission–discharge window of a given hospital encounter. However, many aspects of the data are not intended to reflect real clinical relationships. In particular, clinical outcomes, predictors, and covariates commonly used in research are simulated independently of one another and therefore should not be interpreted as having any meaningful associations.

**As a result, the primary purpose of `gemSim` is to support software development and testing without requiring access to real GEMINI data. This includes, but is not limited to::**

* Unit testing within CI/CD pipelines (e.g., for Rgemini)
* Debugging of analytics or reporting workflows
* Demonstrations and example code (e.g., in package vignettes)
* Development of new utility functions

# Supported tables 

`gemSim` currently creates synthetic data for the following tables (see [GEMINI data dictionary](https://geminimedicine.ca/the-gemini-database/#data-dictionary) for more details):

* Admdad  
* Locality Variables  
* IPSCU  
* ER  
* IP Diagnosis  
* ER Diagnosis  
* IP Intervention (MRI and MAID)  
* ER Intervention (MRI)  
* Lab (CBC or electrolyte)  
* Radiology  
* Transfusion  
* Physicians

# Code examples

To simulate data for a single table, run: 

```
library(gemSim)
admdad <- dummy_ipadmdad(
  nid = 1000, # number of encounters to be simulated
  n_hospitals = 10, # number of hospitals to be simulated
  time_period = c(2015, 2023), # fiscal years to be simulated
  seed = 1 # seed for reproducilibity
)
```

To simulate multiple tables while maintaining key inter-table relationships (e.g., `genc_ids`, `hospital_nums`, plausible date-times), use the wrapper function `simulate_data_tables()`:

```
dummy_data <- simulate_data_tables(
  tables = c(
    "admdad", "ipscu", "er", "erdiagnosis", "ipdiagnosis", "locality_variables",
    "lab","radiology", "erintervention", "ipintervention", "transfusion",
    "physicians"
  ),
  nid = 5000,
  time_period = c(2021, 2024),
  seed = 1
)
```


# GEMINI dummy DB

Using the `gemSim` package, a dummy GEMINI database with 5,000 randomly simulated `genc_ids` has been created, which can be queried as follows:

```
library(DBI)
library(RPostgres)
library(data.table)

# connect to dummy DB
con <- dbConnect(
  RPostgres::Postgres(),
  host     = "gemini-db-dummy.j.aivencloud.com",
  port     = 10571,
  dbname   = "dummy_db_v1_0_0", # most recent version
  user     = "gemini_user",
  password = "gemini",
  sslmode  = "require"
)

# query dummy admdad table
adm <- dbGetQuery(con, "SELECT * FROM admdad;")
```

The following code was used to generate the dummy DB: 

```
library(gemSim)

test_data <- simulate_data_tables(
  c("admdad", "ipscu", "er", "erdiagnosis", "ipdiagnosis", "locality_variables",
    "lab","radiology", "erintervention", "ipintervention", "transfusion",
    "physicians"), nid = 5000, time_period = c(2021, 2024), seed = 1)
```
