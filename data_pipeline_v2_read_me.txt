NODE A)
- data source: high-content imaging system combined with automated image analysis using the INCARTA software
- data stored at: complete- TBA
                  sample- https://github.com/JakubMasaryk/HC_microscopy_database/tree/sample_data
- raw data format: .csv files, loaded manually (no APIs available for INCARTA), generally two types: single-cell data (scd) and summary-by-well data (sbw), labels 6-digit no. (corresponds to date of data aquisition, except for sample data- arbitrary 10000001 etc...) + 'sbw'/'scd' (e. g., '20240502_sbw' or '20240606_scd')
- next step: raw data loaded into python script for transformation and direct load into schema (see node B)
             or
             raw data loaded into python script for transformation and export in .xlsx fromat (stored for publishing purposes), the resulting files loaded into schema (in .csv format) (see node C)


NODE B)
- data source: raw data, (see node A)
- data format: .csv files (either sbw or scd data)
- purpose: data transformation (text formatting, column filtering, column names, dtypes etc...) and direct load into schema through sqlalchemy
- script link: https://github.com/JakubMasaryk/HC_microscopy_database/blob/raw_data_transformation/raw_data_load_transformation_and_load_into_db.py
- test: use the sample data from node A
- next step: data stored in a relational database to create the data tables (tables containing prefix 'experimental_data_') (see node E)


NODE C)
- data source: raw data, (see node A)
- data format: .csv files (either sbw or scd data)
- purpose: data transformation (text formatting, column filtering, column names, dtypes etc...) and file export (both .xlsx and .csv) primarily for publication purposes
- script link: https://github.com/JakubMasaryk/HC_microscopy_database/blob/raw_data_transformation/raw_data_load_transformation_and_export.py
- next step: potentially load into the relational database to create the data tables (tables containing prefix 'experimental_data_') (see node E)


NODE D)
-data source: transformed data (see node C)
              and/or
              external lookup tables (see node E)
-data format: .csv files
-purpose: loading of lookup-tables data into the relational database
          loading of the transformed data into the relational database (circumstantial, normally done through node B)
-script link: https://github.com/JakubMasaryk/HC_microscopy_database/blob/data_load/HC_microscopy_database_data_load_v2.sql


NODE E)
-data source: external lookup tables, various sources, detailed descriptions at: TBA
-lookup tables stored at: TBA
-data format: .csv files
-next step: load into the relational schema


NODE F)
-data source: nodes B and D
-data format: mysql storage format
-purpose: fully designed relational schema to store the data pipelines complete data 
          includes data generated form the data source (node A) and lookup tables (node E)
-link: https://github.com/JakubMasaryk/HC_microscopy_database/blob/schema/HC_microscopy_schema_design_v2.sql
-next step: data retrieval and analysis (nodes G and H)


NODE G)
-data source: relational database (node F)
-purpose: retrieval of specific data for particular analyses and visualisations, done through schema-associated views and/or stored procedures (ususally called directly in python scripts (from node H) through sqlalchemy)
-links: views- https://github.com/JakubMasaryk/HC_microscopy_database/tree/views
        stored procedures (published figures)- https://github.com/JakubMasaryk/HC_microscopy_database/tree/stored_procedures_published_figures
        stored procedures (mix)- https://github.com/JakubMasaryk/HC_microscopy_database/blob/stored_procedures/hc_microscopy_stored_procedures_mix.sql


NODE H)
-data source: primarily views and stored procedures (node G)
              or
              .csv data files (exported from node C or directly from node A and stored separatelly for publication purposes), often subjected to further data transformations within the particular script)
-purpose: statistical analysis, modelling and visualisation of the experimental data
          certain outputs, often further analysed elsewhere (list of hits from the screening and hits-associated data (e.g., hit label, description, enrichments...) fed back to the database (line I)
-link: https://github.com/JakubMasaryk/HC_microscopy_data_analysis
-next step: outputs


