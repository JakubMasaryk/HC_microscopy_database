A)
- data source: high-content imaging system combined with automated image analysis using the INCARTA software
- raw data format: .csv files, loaded manually (no APIs available for INCARTA), generally two types: single-cell data (scd) and summary-by-well data (sbw)
- next step: raw data loaded into python script for transformation and direct load into schema (see node B)
             raw data loaded into python script for transformation and export in .xlsx fromat (stored for publishing purposes), the resulting files loaded into schema (in .csv format) (see node C)

B)
- data source: raw data, (see node A)
- data format: .csv files (either sbw or scd data)
- purpose: data transformation (text formatting, column filtering, column names, dtypes etc...) and direct load into schema through sqlalchemy
- script link: TBA
- next step: data stored in a relational database to create the data tables (tables containing prefix 'experimental_data_') (see node E)

C)
- data source: raw data, (see node A)
- data format: .csv files (either sbw or scd data)
- purpose: data transformation (text formatting, column filtering, column names, dtypes etc...) and file export (both .xlsx and .csv) primarly for publication purposes
- script link: TBA
- next step: potentially load into the relational database to create the data tables (tables containing prefix 'experimental_data_') (see node E)
