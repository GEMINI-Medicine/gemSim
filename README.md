# gemSim
`gemSim` is a custom R package providing functions that generate synthetic data based on the [GEMINI database](https://geminimedicine.ca/the-gemini-database/).

It currently creates the following tables:
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

It also contains a wrapper function, `simulate_data_tables`, which calls on the other simulation functions to create a database, keeping inter-table relationships.
