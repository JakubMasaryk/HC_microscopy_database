NODE A)
- data source: raw, unstructured data from the high-content imaging system combined with automated image analysis software (INCARTA)
- data stored at: see node C
- raw data format: '.csv' 
- raw data labels: 6-digit code (corresponds to date of data aquisition, format: YYMMDD; arbitrary for sample data) + suffix based on type of data '_sbw'/'_scd'
                   e.g., '20240502_sbw.csv'/'20240502_scd.csv' or '10000001_sbw.csv' for sample data
- types of raw data: each unique 6-digit code corresponds to two types of data, single-cell data (suffix '_scd') or summary-by-well data (sufix '_sbw')
- next step: raw data loaded to the Backblaze B2 cloud storage manually (no APIs available for INCARTA)


NODE B)
- data source: manually curated lookup tables for mysql relational database
- descriptions: TBA...
- next step(s): data loaded into a python script and uploaded into mysql relational database (see nodes D and E)


Node C)
- data source: nodes A and B
               raw data and lookup tables loaded to the Backblaze B2 cloud storage manually (no APIs available for INCARTA (node A), data from node C curated manually)
- data stored at: complete- Backblaze B2 cloud storage, bucket 'hc-microscopy-raw-data' (from node A)
                  sample- Backblaze B2 cloud storage, bucket 'hc-microscopy-raw-data-test' (from node A)
                  lookup tables- Backblaze B2 cloud storage, bucket 'hc-microscopy-lookup-tables' (from node B)
- data access: see node D
               authentication data available at https://github.com/JakubMasaryk/HC_microscopy_database/blob/raw_data_transformation/data_bucket_keys_read_only.txt
- next step(s): data loaded into a python script, transformed and uploaded into mysql relational database (see nodes D and E)


NODE D)
- data source: Backblaze B2 cloud storage (see node C)
- 2 types of data to process: raw data- see node A
                                      - loaded from cloud, processed and uploaded to mysql relational database using the script https://github.com/JakubMasaryk/HC_microscopy_database/blob/raw_data_transformation/backblaze_to_mysql_raw_data.py
                              lookup tables- see node B
                                      - loaded from cloud and uploaded to mysql relational database using the script TBA...
- data access: authentication data available at https://github.com/JakubMasaryk/HC_microscopy_database/blob/raw_data_transformation/data_bucket_keys_read_only.txt
               authentication data needs to be filled in the above-mentioned python scripts (before running)
- next step: data uploaded into the mysql relational database (see node E)


NODE E)
-data source: D
-data format: mysql storage format
-purpose: fully designed relational schema to store the data pipelines complete data 
          includes data generated form the data source (node A) and lookup tables (node B)
-link: https://github.com/JakubMasaryk/HC_microscopy_database/blob/schema/HC_microscopy_schema_design_v2.sql
-next step: data retrieval and analysis (nodes F and G)


NODE F)
-data source: relational database (node E)
-purpose: retrieval of specific data for particular analyses and visualisations, done through schema-associated views and/or stored procedures (ususally called directly in python scripts (from node G) through sqlalchemy)
-links: views- https://github.com/JakubMasaryk/HC_microscopy_database/tree/views
        stored procedures (published figures)- https://github.com/JakubMasaryk/HC_microscopy_database/tree/stored_procedures_published_figures
        stored procedures (mix)- https://github.com/JakubMasaryk/HC_microscopy_database/blob/stored_procedures/hc_microscopy_stored_procedures_mix.sql


NODE G)
-data source: views and stored procedures (node F)
              often allow also direct load of partiular csv file(s)- script specific
-purpose: statistical analysis, modelling and visualisation of the experimental data
          certain outputs, often further analysed elsewhere (list of hits from the screening and hits-associated data (e.g., hit label, description, enrichments...) fed back to the database (node E)
-link: https://github.com/JakubMasaryk/HC_microscopy_data_analysis
-next step: outputs
