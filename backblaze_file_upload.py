#!/usr/bin/env python
# coding: utf-8

# __READ ME__

# - functions for automatic upload of both raw data ('backblaze_file_upload_raw_data') and lookup tables ('backblaze_file_upload_lookup_tables') into thei respective buckets on Backblaze B2 cloud storage
# - defined paths to files/folders and appropriate keys (see sections below)
# - either individual files or all files within a defined folder, defined by the 'source' argument of each function (folders wihin defined folder skipped)
# - only files in .csv format accepted
# - keys with 'read and write' permission for each bucket needed (not published) 

# __libraries__

# In[340]:


import numpy as np
import pandas as pd 
import os
from b2sdk.v2 import InMemoryAccountInfo, B2Api
from io import BytesIO
from pathlib import Path


# __backblaze B2 authentication__

# In[156]:


#Backblaze B2 authentication- LOOKUP TABLES
lookup_tables_bucket_name= 'hc-microscopy-lookup-tables'
lookup_tables_bucket_key_id= '003b5f880f95dd40000000007';
lookup_tables_bucket_key= 'K003IbJdbOrI7FFKICEO48JEWoJkW7Q'

#Backblaze B2 authentication- RAW-DATA TABLES
raw_data_bucket_name= 'hc-microscopy-raw-data'
raw_data_bucket_key_id= '003b5f880f95dd40000000005'
raw_data_bucket_key= 'K003Xj/crKQ+W76CAGRiXp+MeiMdWJM'


# __path to data source__

# In[451]:


path_to_raw_data= r"C:\Users\Jakub\Desktop\upload_test_raw_data"


# In[386]:


path_to_lookup_tables= r"C:\Users\Jakub\Desktop\upload_test_lookup_tables"


# __upload functions__

# * __raw data__

# In[478]:


###uploads raw-data table/s from the defined folder/file into the corresponding bucket ('hc-microscopy-raw-data')
###inputs: 'path'- path to folder/file, 'source'- 'folder'/'file', based on the source of data specified in 'path'
def backblaze_file_upload_raw_data(path, source, bucket_name= raw_data_bucket_name, key_id= raw_data_bucket_key_id, key= raw_data_bucket_key):
    
    ####init. B2 SDK
    info = InMemoryAccountInfo()
    b2_api = B2Api(info)
    
    ####raw data bucket load
    # authentication
    application_key_id = key_id
    application_key = key
    try: #authorize and get the bucket
        b2_api.authorize_account("production", application_key_id, application_key)
        bucket = b2_api.get_bucket_by_name(bucket_name)
    except Exception as e:
        raise RuntimeError(f"WARNING: Failed to authorize or get bucket: {e}")
    #list of all file names from the raw-data bucket
    file_names = [file_info.file_name for file_info, _ in bucket.ls(recursive=True)] 
    
    #####check the combination of path-source inputs
    if os.path.isdir(path) and source=='file':
        raise ValueError(f"Invalid combination of 'path' and 'source' arguments: path to FOLDER given with {source.upper()} as a source.")
    if os.path.isfile(path) and source=='folder':
        raise ValueError(f"Invalid combination of 'path' and 'source' arguments: path to FILE given with {source.upper()} as a source.")
        
    ####data upload
    #for folder as a data source
    if source== 'folder':
        for file_name in os.listdir(path): #iterate over the files in defined folder
            full_path = os.path.join(path, file_name)
            if os.path.isfile(full_path): #for files within defined folder
                if file_name.lower().endswith('.csv'): #skip any non-csv files                   
                    if file_name in file_names: #check if file already is in the bucket
                        print(f'WARNING: file "{file_name}" already exists in bucket "{bucket_name}", SKIPPED')
                    else: #upload files not in the bucket
                        try:
                            bucket.upload_local_file(local_file=full_path, file_name=file_name)
                            print(f'file "{file_name}" UPLOADED into bucket "{bucket_name}"')
                        except Exception as ex:
                            print(f'WARNING: file "{file_name}" NOT UPLOADED into bucket "{bucket_name}"')
                            print(f'error: {ex}')               
                else: #non-csv files
                    print(f'WARNING: file "{file_name}" has an invalid file format: "{Path(full_path).suffix}". Expected: ".csv", SKIPPED.')          
            else: #for folders within defined folder
                print(f'WARNING: path "{full_path}" corresponds to a folder, SKIPPED.')
                                         
    #for file as a data source
    elif source== 'file':
        file_name = os.path.basename(path) #get the file name       
        if file_name.lower().endswith('.csv'): #skip non-csv files
            if file_name in file_names: #check if file already is in the bucket
                print(f'WARNING: file "{file_name}" already exists in bucket "{bucket_name}", SKIPPED')
            else: #upload files not in the bucket
                try:
                    bucket.upload_local_file(local_file=path, file_name=file_name)
                    print(f'file "{file_name}" UPLOADED into bucket "{bucket_name}"')
                except Exception as ex:
                    print(f'WARNING: file "{file_name}" NOT UPLOADED into bucket "{bucket_name}"')
                    print(f'error: {ex}')        
        else: #non-csv files
            print(f'WARNING: file "{file_name}" has an invalid file format: "{Path(path).suffix}". Expected: ".csv", SKIPPED.')
                                     
    #invalid source format
    else: 
        raise ValueError(f"Invalid source argument: '{source}'. Expected: 'folder' or 'file'.")


# In[455]:


# backblaze_file_upload_raw_data(path= path_to_raw_data, source= 'folder')


# * __lookup tables__

# In[480]:


###uploads lookup table/s from the defined folder/file into the corresponding bucket ('hc-microscopy-lookup-tables')
###appropriate folder is selected according to the core of the name of the file (e.g., file named 'inhibitors_update_test.csv' will be uploaded into the folder 'd_inhibitors' (resulting full file name: 'd_inhibitors/inhibitors_update_test.csv'))
###inputs: 'path'- path to folder/file, 'source'- 'folder'/'file', based on the source of data specified in 'path'
def backblaze_file_upload_lookup_tables(path, source, bucket_name= lookup_tables_bucket_name, key_id= lookup_tables_bucket_key_id, key= lookup_tables_bucket_key):
    
    ####init. B2 SDK
    info = InMemoryAccountInfo()
    b2_api = B2Api(info)
    
    ####raw data bucket load
    # authentication
    application_key_id = key_id
    application_key = key
    try: #authorize and get the bucket
        b2_api.authorize_account("production", application_key_id, application_key)
        bucket = b2_api.get_bucket_by_name(bucket_name)
    except Exception as e:
        raise RuntimeError(f"WARNING: Failed to authorize or get bucket: {e}")
    #list of all file names from the raw-data bucket
    file_names = [file_info.file_name for file_info, _ in bucket.ls(recursive=True)] 
    #list of backblaze-bucket folders (name prefixes)
    folder_prefix= set([file_name.split('/')[0] for file_name in file_names]) #set to obtain only unique prefixes
    
    #####check the combination of path-source inputs
    if os.path.isdir(path) and source=='file':
        raise ValueError(f"Invalid combination of 'path' and 'source' arguments: path to FOLDER given with {source.upper()} as a source.")
    if os.path.isfile(path) and source=='folder':
        raise ValueError(f"Invalid combination of 'path' and 'source' arguments: path to FILE given with {source.upper()} as a source.")
        
    ####data upload
    #for folder as a data source
    if source== 'folder':
        for file_name in os.listdir(path): #iterate over the files in defined folder
            full_path = os.path.join(path, file_name) #full path to a specific file
            file_name_stripped= file_name.split('update')[0].rstrip('_') if 'update' in file_name else file_name[:-4] #stripped to the core of the name (to match bucket folder prefix from 'folder_prefix' list)
            if os.path.isfile(full_path): #for files within defined folder
                if file_name.lower().endswith('.csv'): #skip any non-csv files
                    try: #look for the corresponding folder prefix
                        corresponding_prefix= [prefix for prefix in folder_prefix if file_name_stripped in prefix][0] #look for the corresponding folder name (contains the full core name 'file_name_stripped')
                        full_name= os.path.join(corresponding_prefix, file_name).replace("\\", "/") #name used for upload: bucket-folder prefix + file_name, replace '\' with a forward slah (backblaze requirement)
                        if full_name in file_names: #check if file already is in the bucket
                            print(f'WARNING: file "{file_name}" already exists in bucket "{bucket_name}", SKIPPED')
                        else: #upload files not in the bucket
                            try:
                                bucket.upload_local_file(local_file=full_path, file_name=full_name)
                                print(f'file "{file_name}" UPLOADED into bucket "{bucket_name}, folder "{corresponding_prefix}"')
                            except Exception as ex:
                                print(f'WARNING: file "{full_name}" NOT UPLOADED into bucket "{bucket_name}"')
                                print(f'error: {ex}')  
                    except Exception as e: # corresponding folder does not exist
                        print(f'WARNING: corresponding folder does not exists in the selected bucket, file "{file_name}" SKIPPED')
                else: #non-csv files
                        print(f'WARNING: file "{file_name}" has an invalid file format: "{Path(full_path).suffix}". Expected: ".csv", SKIPPED.')
            else: #for folders within defined folder
                print(f'WARNING: path "{full_path}" corresponds to a folder, SKIPPED.') 
                       
    #for file as a data source
    elif source== 'file':
        file_name = os.path.basename(path) #get the file name
        file_name_stripped= file_name.split('update')[0].rstrip('_') if 'update' in file_name else file_name[:-4] #stripped to the core of the name (to match bucket folder prefix from 'folder_prefix' list)
        if file_name.lower().endswith('.csv'): #skip non-csv files
            try:
                corresponding_prefix= [prefix for prefix in folder_prefix if file_name_stripped in prefix][0] #look for the corresponding folder name (contains the full core name 'file_name_stripped')
                full_name= os.path.join(corresponding_prefix, file_name).replace("\\", "/") #name used for upload: bucket-folder prefix + file_name, replace '\' with a forward slah (backblaze requirement)
                if full_name in file_names: #check if file already is in the bucket
                    print(f'WARNING: file "{file_name}" already exists in bucket "{bucket_name}", SKIPPED')
                else: #upload files not in the bucket
                    try:
                        bucket.upload_local_file(local_file=path, file_name=full_name)
                        print(f'file "{file_name}" UPLOADED into bucket "{bucket_name}, folder "{corresponding_prefix}"')
                    except Exception as ex:
                        print(f'WARNING: file "{full_name}" NOT UPLOADED into bucket "{bucket_name}"')
                        print(f'error: {ex}')
            except Exception as e: # corresponding folder does not exist
                print(f'WARNING: corresponding folder does not exists in the selected bucket, file "{file_name}" SKIPPED')
        else: #non-csv files
            print(f'WARNING: file "{file_name}" has an invalid file format: "{Path(path).suffix}". Expected: ".csv", SKIPPED.') 
                    
    #invalid source format
    else: 
        raise ValueError(f"Invalid source argument: '{source}'. Expected: 'folder' or 'file'.")


# In[482]:


# backblaze_file_upload_lookup_tables(path= path_to_lookup_tables, source= 'folder')

