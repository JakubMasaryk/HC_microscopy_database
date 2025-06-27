#!/usr/bin/env python
# coding: utf-8

# In[144]:


import numpy as np
import pandas as pd 
import os
from b2sdk.v2 import InMemoryAccountInfo, B2Api
from io import BytesIO
from sqlalchemy import create_engine


# __read me__

# - create the mysql relational database first, script at: https://github.com/JakubMasaryk/HC_microscopy_database/blob/schema/HC_microscopy_schema_design_v2.sql
# - fill in the parameters of your mysql server (username, password, hostname, port, schema)
# - fill in the backblaze b2 data bucket authentication (data_bucket_name, bucket_key_id, bucket_key)
# - use the 'hc-microscopy-lookup-tables' bucket
# - bucket keys (for reading only) at: https://github.com/JakubMasaryk/HC_microscopy_database/blob/raw_data_transformation/data_bucket_keys_read_only.txt 

# __mysql server connection parameters__

# In[148]:


#fill in!
#mysql server connection parameters
username= 'root'
password= 'poef.qve5353'
hostname= '127.0.0.1'
port= '3306'
schema= 'hc_microscopy_data_test'

#mysql server connection
connection_string = f"mysql+pymysql://{username}:{password}@{hostname}:{port}/{schema}"
engine = create_engine(connection_string) 


# __backblaze b2 authentication__

# In[150]:


#Backblaze B2 authentication
data_bucket_name= 'hc-microscopy-lookup-tables'
bucket_key_id= '003b5f880f95dd40000000004';
bucket_key= 'K003saZ/8kHqxs+TqqMbIh3Z7JcnrLQ'


# __lookup tables from backblaze b2 to mysql upload__

# In[178]:


def backlblaze_to_mysql_lookup_tables(engine= engine, schema= schema, bucket= data_bucket_name, key_id= bucket_key_id, key= bucket_key):
   
    #init. B2 SDK
    info = InMemoryAccountInfo()
    b2_api = B2Api(info)

    # authentication
    application_key_id = key_id
    application_key = key
    b2_api.authorize_account("production", application_key_id, application_key)

    # get the bucket
    bucket = b2_api.get_bucket_by_name(bucket)

    #list of al file names in the bucket
    all_file_names= [file_info.file_name for file_info, _ in bucket.ls(recursive= True)]
    
    ###for each lookup-table folder (defined by the prefix, e.g., 'd_inhibitors') load all files (original + all of the updates, e.g., 'd_inhibitors/inhibitors.csv' + 'd_inhibitors/inhibitors_update_1.csv' + 'd_inhibitors/inhibitors_update_2.csv') and upload them into corressponding tables in mysql relational db (e.g., 'inhibitors')
    
    #split the file-names list by folder
    for file_name in all_file_names:
        if not file_name.endswith('.csv'): # only .csv files
            continue
        try:
            ###data load from Backblaze B2###
            #store data into in-memory object ('in_memory_data')
            in_memory_data = BytesIO() #inmemory storage object
            bucket.download_file_by_name(file_name).save(in_memory_data) #download data from specified bucket-file into 'in_memory_storage'
            in_memory_data.seek(0) #rewind to the beginning
            # Load into pandas df
            single_file_data = pd.read_csv(in_memory_data)
            #extract the destination mysql table name from the full file name
            my_sql_table= file_name.split('/')[0].split('_', 1)[1] 
            print('---------------------------------------------------')
            print(f'File loaded: {file_name}')
            #load into relational db (corresponding table, defined by 'my_sql_table')
            try:
                single_file_data.to_sql(name=my_sql_table, con=engine, if_exists='append', index=False)
                print(f'File "{file_name}" uploaded into schema: "{schema}", table: "{my_sql_table}"')
            except Exception as ex:
                print(f'File "{file_name}" NOT uploaded into schema')
                print(f'Error: {ex}')
                
        except Exception as exep: #for failed file loading
            print('---------------------------------------------------')
            print(f'File NOT loaded: "{file_name}"')
            print(f'Error: {exep}')


# In[180]:


backlblaze_to_mysql_lookup_tables()


# In[ ]:




