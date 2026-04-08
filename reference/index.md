# Package index

## Simulation functions

Functions for generating synthetic GEMINI data

- [`dummy_diag()`](https://gemini-medicine.github.io/GEMINI-data-simulation/reference/dummy_diag.md)
  : Generate Simulated Diagnosis Data Table

- [`dummy_er()`](https://gemini-medicine.github.io/GEMINI-data-simulation/reference/dummy_er.md)
  : Generate simulated ER data.

- [`dummy_erintervention_mri()`](https://gemini-medicine.github.io/GEMINI-data-simulation/reference/dummy_erintervention_mri.md)
  : Generate simulated erintervention data

- [`dummy_admdad()`](https://gemini-medicine.github.io/GEMINI-data-simulation/reference/dummy_admdad.md)
  : Simulate admdad data

- [`dummy_ipintervention_mri_maid()`](https://gemini-medicine.github.io/GEMINI-data-simulation/reference/dummy_ipintervention_mri_maid.md)
  : Generate simulated ipintervention data

- [`dummy_ipscu()`](https://gemini-medicine.github.io/GEMINI-data-simulation/reference/dummy_ipscu.md)
  : Generate simulated ipscu data.

- [`dummy_lab_cbc_electrolyte()`](https://gemini-medicine.github.io/GEMINI-data-simulation/reference/dummy_lab_cbc_electrolyte.md)
  : Generate simulated lab data

- [`dummy_locality()`](https://gemini-medicine.github.io/GEMINI-data-simulation/reference/dummy_locality.md)
  : Generate simulated locality variables data

- [`dummy_physicians()`](https://gemini-medicine.github.io/GEMINI-data-simulation/reference/dummy_physicians.md)
  : Generate simulated physicians data

- [`dummy_radiology()`](https://gemini-medicine.github.io/GEMINI-data-simulation/reference/dummy_radiology.md)
  : Generate simulated radiology data

- [`dummy_transfusion()`](https://gemini-medicine.github.io/GEMINI-data-simulation/reference/dummy_transfusion.md)
  : Generate simulated transfusion data

- [`generate_id_hospital()`](https://gemini-medicine.github.io/GEMINI-data-simulation/reference/generate_id_hospital.md)
  :

  Generate a data table with basic inpatient stay information. At the
  minimum, it will include an encounter and hospital ID, along with
  other information if `cohort` is included in the input.

- [`sample_icd()`](https://gemini-medicine.github.io/GEMINI-data-simulation/reference/sample_icd.md)
  : Simulate ICD-10 Diagnosis Codes

- [`sample_scu_date_time()`](https://gemini-medicine.github.io/GEMINI-data-simulation/reference/sample_scu_date_time.md)
  : Sample SCU admission and discharge date times by genc_id.

- [`simulate_data_tables()`](https://gemini-medicine.github.io/GEMINI-data-simulation/reference/simulate_data_tables.md)
  : Data simulation wrapper function

## Datasets

Data files used for sampling in data simulation

- [`blood_product_lookup`](https://gemini-medicine.github.io/GEMINI-data-simulation/reference/blood_product_lookup.md)
  :

  Blood product lookup table for `dummy_transfusion` function.

- [`da21uid_statcan_v2021`](https://gemini-medicine.github.io/GEMINI-data-simulation/reference/da21uid_statcan_v2021.md)
  : StatCan dissemination area ID lookup

- [`lookup_cci`](https://gemini-medicine.github.io/GEMINI-data-simulation/reference/lookup_cci.md)
  : CCI lookup table for MAID and MRI codes
