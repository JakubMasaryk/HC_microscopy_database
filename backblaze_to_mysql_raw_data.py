import numpy as np
import pandas as pd 
import os
from b2sdk.v2 import InMemoryAccountInfo, B2Api
from io import BytesIO
from sqlalchemy import create_engine


# __read me__
# - load the lookup tables first at: https://github.com/JakubMasaryk/HC_microscopy_database/blob/raw_data_transformation/backblaze_to_mysql_lookup_tables.py
# - fill in the parameters of your mysql server (username, password, hostname, port, schema)
# - fill in the backblaze b2 data bucket authentication (data_bucket_name, bucket_key_id, bucket_key)
# - use either the 'hc-microscopy-raw-data' or 'hc-microscopy-raw-data-test' buckets
# - bucket keys (for reading only) at: https://github.com/JakubMasaryk/HC_microscopy_database/blob/raw_data_transformation/data_bucket_keys_read_only.txt
# - 'sbw' data needs to be uploaded first before uploading corresponding 'scd' data (foreign key constraint failure) 


# __mysql server connection parameters__
#fill in!
#mysql server connection parameters
username= ''
password= ''
hostname= ''
port= ''
schema= ''
#mysql server connection
connection_string = f"mysql+pymysql://{username}:{password}@{hostname}:{port}/{schema}"
engine = create_engine(connection_string) 


# __backblaze b2 authentication__
#Backblaze B2 authentication
data_bucket_name= ''
bucket_key_id= ''
bucket_key= ''


# __list of all .csv files in the bucket (of selected type of data)__
###function lists all files (of particular 'type_of_data' 'sbw'/'scd') from selected bucket
###inputs:
          #type_of_data: defines selected type of data, 'scd': single-cell data or 'sbw': summary-by-well data, only files containing selected suffix ('type_of_data') pulled
def all_files_list(type_of_data, bucket= data_bucket_name, key_id= bucket_key_id, key= bucket_key):
    
    #init. B2 SDK
    info = InMemoryAccountInfo()
    b2_api = B2Api(info)
    
    # authentication
    application_key_id = key_id
    application_key = key
    b2_api.authorize_account("production", application_key_id, application_key)

    # get the bucket
    bucket = b2_api.get_bucket_by_name(bucket)
    #load file names
    #only file nams containing 'type_of_data' label ('sbw' or 'scd')
    file_names = [file_info.file_name for file_info, _ in bucket.ls(recursive=True) if type_of_data.lower() in file_info.file_name.lower() and file_info.file_name.endswith('.csv')] #case-insensitive (.lower()), only .csv files
    
    for name in file_names:
        print(name)
#all_files_list('scd')


# __processing of selected sbw/scd files from the bucket__
###function pulls selected csv files from cloud (Backblaze B2 data bucket), applies transformations and uploads transformed data into mysql relational database
###inputs:
          #date_labels: defines selected files, 6-digit number defining each file on the cloud (precceding the '_sbw' or '_scd' suffix)
          #type_of_data: defines selected type of data, 'scd': single-cell data or 'sbw': summary-by-well data, only files containing selected suffix ('type_of_data') pulled
def backblaze_to_mysql_raw_data_selected_files(date_labels, type_of_data, engine= engine, schema= schema, bucket= data_bucket_name, key_id= bucket_key_id, key= bucket_key):
    
    #define file names based on selected 'date_labels' and 'type_of_data'
    file_names= [str(x) + '_' + type_of_data + '.csv' for x in date_labels] #adds the '_sbw'/'_scd' and '.csv'
    
    #init. B2 SDK
    info = InMemoryAccountInfo()
    b2_api = B2Api(info)
    
    # authentication
    application_key_id = key_id
    application_key = key
    b2_api.authorize_account("production", application_key_id, application_key)

    # get the bucket
    bucket = b2_api.get_bucket_by_name(bucket)
    
    #data load, transformation and upload to mysql database (specific for each type of data):
    ###sbw data####
    if type_of_data== 'sbw':
        #iterate over files, transform, split the data and upload to db
        for file_name in file_names:

            try:
                ###data load from Backblaze B2###
                #store data into in-memory object ('in_memory_data')
                in_memory_data = BytesIO() #inmemory storage object
                bucket.download_file_by_name(file_name).save(in_memory_data) #download data from specified bucket-file into 'in_memory_storage'
                in_memory_data.seek(0) #rewind to the beginning
                # Load into pandas df
                single_file_data = pd.read_csv(in_memory_data,
                                               converters= {'WELL LABEL':lambda x: x.replace(' - ', '0') if len(x) == 5 else x.replace(' - ', '')})
                single_file_data= single_file_data.assign(date_label= file_name.split('_')[0]) #assign the 'date_label' (based on the 6-digit file label preceeding the '_sbw'/'_scd' suffix)
                print('---------------------------------------------------')
                print(f'File loaded: {file_name}')
                ###processing###
                #drop non-essential columns
                single_file_data= single_file_data.drop(['Row', 'Column', 'Z', 'Plate ID'], axis= 1, errors='ignore') 
                #rename columns
                single_file_data.columns= ['experimental_well_label', 'timepoint', 'number_of_cells', 'cells_total_area', 'cells_avg_intensity_wv1', 'cells_max_intensity_wv1', 'cells_avg_intensity_wv2', 'cells_max_intensity_wv2',
                                           'number_of_cells_with_foci', 'avg_number_of_foci_per_cell', 'avg_size_single_focus', 'foci_total_area', 'foci_intensity_wv2', 'cells_with_0_foci_percentage', 'cells_with_0_foci',
                                           'cells_with_1_focus_percentage', 'cells_with_1_focus', 'cells_with_multiple_foci_percentage', 'cells_with_multiple_foci', 'date_label']
                #reorder columns
                single_file_data= single_file_data.reindex(['date_label', 'experimental_well_label', 'timepoint', 'number_of_cells', 'cells_total_area', 'cells_avg_intensity_wv1', 'cells_max_intensity_wv1', 'cells_avg_intensity_wv2', 'cells_max_intensity_wv2',
                                                            'number_of_cells_with_foci', 'avg_number_of_foci_per_cell', 'avg_size_single_focus', 'foci_total_area', 'foci_intensity_wv2', 'cells_with_0_foci_percentage', 'cells_with_0_foci',
                                                            'cells_with_1_focus_percentage', 'cells_with_1_focus', 'cells_with_multiple_foci_percentage', 'cells_with_multiple_foci'], axis= 1)
                #split dataset into three to be loaded into their respective tables in relational database
                #cell area and counts (load into 'experimetal_data_sbw_cell_area_and_counts')
                cac= single_file_data.loc[:, ['date_label', 'experimental_well_label', 'timepoint', 'cells_total_area', 'number_of_cells', 'number_of_cells_with_foci', 'cells_with_0_foci_percentage', 'cells_with_0_foci',
                                              'cells_with_1_focus_percentage', 'cells_with_1_focus', 'cells_with_multiple_foci_percentage', 'cells_with_multiple_foci']]
                #cell foci intensity (load into 'experimental_data_sbw_cell_foci_intensity')
                cfi= single_file_data.loc[:, ['date_label', 'experimental_well_label', 'timepoint', 'cells_avg_intensity_wv1', 'cells_max_intensity_wv1', 'cells_avg_intensity_wv2', 'cells_max_intensity_wv2', 'foci_intensity_wv2']]
                #foci number and size (load into 'experimental_data_sbw_foci_number_and_size')
                nas= single_file_data.loc[:, ['date_label', 'experimental_well_label', 'timepoint', 'avg_number_of_foci_per_cell', 'avg_size_single_focus', 'foci_total_area']]

                #data load directly into relational db
                #three dataset (cac, cfi and nas) individually into their respective tables
                try:
                    cac.to_sql(name='experimental_data_sbw_cell_area_and_counts', con=engine, if_exists='append', index=False)
                    print(f'File uploaded into the {schema}: {file_name}, cac data')
                except Exception as ex:
                    print(f'File not uploaded into the {schema}: {file_name}, cac data')
                    print(f'Error: {ex}')
                try:    
                    cfi.to_sql(name='experimental_data_sbw_cell_foci_intensity', con=engine, if_exists='append', index=False)
                    print(f'File uploaded into the {schema}: {file_name}, cfi data')
                except Exception as ex:
                    print(f'File not uploaded into the {schema}: {file_name}, cfi data')
                    print(f'Error: {ex}')
                try:                   
                    nas.to_sql(name='experimental_data_sbw_foci_number_and_size', con=engine, if_exists='append', index=False)
                    print(f'File uploaded into the {schema}: {file_name}, nas data')
                except Exception as ex:
                    print(f'File not uploaded into the {schema}: {file_name}, nas data')
                    print(f'Error: {ex}')       

            except Exception as exep: #mostly for missing or mislabeled files
                print('---------------------------------------------------')
                print(f'File not loaded: {file_name}: ({exep})')
    
    ###scd data###
    elif type_of_data== 'scd':
        #iterate over files, transform, split the data and upload to db
        for file_name in file_names:

            try:
                ###data load from Backblaze B2###
                #store data into in-memory object ('in_memory_data')
                in_memory_data = BytesIO() #inmemory storage object
                bucket.download_file_by_name(file_name).save(in_memory_data) #download data from specified bucket-file into 'in_memory_storage'
                in_memory_data.seek(0) #rewind to the beginning
                # Load into pandas df
                single_file_data = pd.read_csv(in_memory_data,
                                               converters= {'WELL LABEL':lambda x: x.replace(' - ', '0') if len(x) == 5 else x.replace(' - ', '')})
                single_file_data= single_file_data.assign(date_label= file_name.split('_')[0], #assign the 'date_label' (based on the 6-digit file label preceeding the '_sbw'/'_scd' suffix)
                                                          fov_cell_id= (single_file_data['FOV']).astype('str') + '-' +  (single_file_data['OBJECT ID']).astype('str')) #assigning unique cell id (FOV + object id)
                print('---------------------------------------------------')
                print(f'File loaded: {file_name}')
                ###processing###
                #filter down to only essential columns
                single_file_data= single_file_data.loc[:, ['WELL LABEL', 'T', 'Cells Area wv1', 'Cells Intensity wv1', 'Cells Max Intensity wv1', 'Cells Intensity wv2', 'Cells Max Intensity wv2', 'Granules Org per Cell wv2', 'Granules Total Area wv2', 'Granules Intensity wv2', 'date_label', 'fov_cell_id']]
                #rename the columns
                single_file_data.columns= ['experimental_well_label', 'timepoint', 'cell_area', 'cells_intensity_wv1', 'cells_max_intensity_wv1', 'cells_intensity_wv2', 'cells_max_intensity_wv2', 'number_of_foci', 'total_foci_area', 'foci_intensity_wv2', 'date_label', 'fov_cell_id']
                #fillna with 0
                single_file_data= single_file_data.fillna(0)
                #reorder columns
                single_file_data= single_file_data.reindex(columns= ['date_label', 'experimental_well_label', 'fov_cell_id', 'timepoint', 'cell_area', 'cells_intensity_wv1', 'cells_max_intensity_wv1', 'cells_intensity_wv2', 'cells_max_intensity_wv2', 'number_of_foci', 'total_foci_area', 'foci_intensity_wv2' ])
                #split dataset into three to be loaded into their respective tables in relational database
                #cell area (load into 'experimetal_data_scd_cell_area')
                ca= single_file_data.loc[:, ['date_label', 'experimental_well_label', 'timepoint', 'fov_cell_id', 'cell_area']]
                #cell foci intensity (load into 'experimental_data_scd_cell_foci_intensity')
                cfi= single_file_data.loc[:, ['date_label', 'experimental_well_label', 'timepoint', 'fov_cell_id', 'cells_intensity_wv1', 'cells_max_intensity_wv1', 'cells_intensity_wv2', 'cells_max_intensity_wv2', 'foci_intensity_wv2']]
                #foci number and area (load into 'experimetal_data_scd_foci_number_and_area')
                naa= single_file_data.loc[:, ['date_label', 'experimental_well_label', 'timepoint', 'fov_cell_id', 'number_of_foci', 'total_foci_area']]              
                #data load directly into relational db
                #three dataset (ca, cfi and naa) individually into their respective tables
                try:
                    ca.to_sql(name='experimental_data_scd_cell_area', con=engine, if_exists='append', index=False)
                    print(f'File uploaded into the {schema}: {file_name}, ca data')
                except Exception as ex: 
                    print(f'File not uploaded into the {schema}: {file_name}, ca data')
                    print(f'Error: {ex}')
                try:
                    cfi.to_sql(name='experimental_data_scd_cell_foci_intensity', con=engine, if_exists='append', index=False)
                    print(f'File uploaded into the {schema}: {file_name}, cfi data')
                except Exception as ex: 
                    print(f'File not uploaded into the {schema}: {file_name}, cfi data')
                    print(f'Error: {ex}')
                try:
                    naa.to_sql(name='experimental_data_scd_foci_number_and_area', con=engine, if_exists='append', index=False)
                    print(f'File uploaded into the {schema}: {file_name}, naa data')
                except Exception as ex:
                    print(f'File not uploaded into the {schema}: {file_name}, naa data')
                    print(f'Error: {ex}')
                
            except Exception as exep: #mostly for missing or mislabeled files
                print('---------------------------------------------------')
                print(f'File not loaded: {file_name}: ({exep})')
    
    ###wrong 'type_of_data' input###
    else: 
        raise ValueError(f"Invalid 'type_of_data' argument: '{type_of_data}'. Expected: 'sbw' or 'scd'.")
# backblaze_to_mysql_raw_data_selected_files(date_labels= [10000001, 10000002, 10000003], type_of_data= 'sbw') # sample run


# __processing of all sbw/scd files from the bucket__ 
###function pulls alle csv files (of selected 'type_of_data') from cloud (Backblaze B2 data bucket), applies transformations and uploads transformed data into mysql relational database
###inputs:
          #type_of_data: defines selected type of data, 'scd': single-cell data or 'sbw': summary-by-well data, only files containing selected suffix ('type_of_data') pulled
def backblaze_to_mysql_raw_data_all_files(type_of_data, engine= engine, schema= schema, bucket= data_bucket_name, key_id= bucket_key_id, key= bucket_key):
    
    #init. B2 SDK
    info = InMemoryAccountInfo()
    b2_api = B2Api(info)
    
    # authentication
    application_key_id = key_id
    application_key = key
    b2_api.authorize_account("production", application_key_id, application_key)

    # get the bucket
    bucket = b2_api.get_bucket_by_name(bucket)
    
    #load file names
    #only file nams containing 'type_of_data' label ('sbw' or 'scd')
    file_names = [file_info.file_name for file_info, _ in bucket.ls(recursive=True) if type_of_data.lower() in file_info.file_name.lower() and file_info.file_name.endswith('.csv')] #case-insensitive (.lower()), only .csv files
    
    #data load, transformation and upload to mysql database (specific for each type of data):
    ###sbw data####
    if type_of_data== 'sbw':
        for file_name in file_names:

            try:
                ###data load from Backblaze B2###
                #store data into in-memory object ('in_memory_data')
                in_memory_data = BytesIO() #inmemory storage object
                bucket.download_file_by_name(file_name).save(in_memory_data) #download data from specified bucket-file into 'in_memory_storage'
                in_memory_data.seek(0) #rewind to the beginning
                # Load into pandas df
                single_file_data = pd.read_csv(in_memory_data,
                                               converters= {'WELL LABEL':lambda x: x.replace(' - ', '0') if len(x) == 5 else x.replace(' - ', '')})
                single_file_data= single_file_data.assign(date_label= file_name.split('_')[0]) #assign the 'date_label' (based on the 6-digit file label preceeding the '_sbw'/'_scd' suffix)
                print('---------------------------------------------------')
                print(f'File loaded: {file_name}')
                ###processing###
                #drop non-essential columns
                single_file_data= single_file_data.drop(['Row', 'Column', 'Z', 'Plate ID'], axis= 1, errors='ignore') 
                #rename columns
                single_file_data.columns= ['experimental_well_label', 'timepoint', 'number_of_cells', 'cells_total_area', 'cells_avg_intensity_wv1', 'cells_max_intensity_wv1', 'cells_avg_intensity_wv2', 'cells_max_intensity_wv2',
                                           'number_of_cells_with_foci', 'avg_number_of_foci_per_cell', 'avg_size_single_focus', 'foci_total_area', 'foci_intensity_wv2', 'cells_with_0_foci_percentage', 'cells_with_0_foci',
                                           'cells_with_1_focus_percentage', 'cells_with_1_focus', 'cells_with_multiple_foci_percentage', 'cells_with_multiple_foci', 'date_label']
                #reorder columns
                single_file_data= single_file_data.reindex(['date_label', 'experimental_well_label', 'timepoint', 'number_of_cells', 'cells_total_area', 'cells_avg_intensity_wv1', 'cells_max_intensity_wv1', 'cells_avg_intensity_wv2', 'cells_max_intensity_wv2',
                                                            'number_of_cells_with_foci', 'avg_number_of_foci_per_cell', 'avg_size_single_focus', 'foci_total_area', 'foci_intensity_wv2', 'cells_with_0_foci_percentage', 'cells_with_0_foci',
                                                            'cells_with_1_focus_percentage', 'cells_with_1_focus', 'cells_with_multiple_foci_percentage', 'cells_with_multiple_foci'], axis= 1)
                #split dataset into three to be loaded into their respective tables in relational database
                #cell area and counts (load into 'experimetal_data_sbw_cell_area_and_counts')
                cac= single_file_data.loc[:, ['date_label', 'experimental_well_label', 'timepoint', 'cells_total_area', 'number_of_cells', 'number_of_cells_with_foci', 'cells_with_0_foci_percentage', 'cells_with_0_foci',
                                              'cells_with_1_focus_percentage', 'cells_with_1_focus', 'cells_with_multiple_foci_percentage', 'cells_with_multiple_foci']]
                #cell foci intensity (load into 'experimental_data_sbw_cell_foci_intensity')
                cfi= single_file_data.loc[:, ['date_label', 'experimental_well_label', 'timepoint', 'cells_avg_intensity_wv1', 'cells_max_intensity_wv1', 'cells_avg_intensity_wv2', 'cells_max_intensity_wv2', 'foci_intensity_wv2']]
                #foci number and size (load into 'experimental_data_sbw_foci_number_and_size')
                nas= single_file_data.loc[:, ['date_label', 'experimental_well_label', 'timepoint', 'avg_number_of_foci_per_cell', 'avg_size_single_focus', 'foci_total_area']]

                #data load directly into relational db
                #three dataset (cac, cfi and nas) individually into their respective tables
                try:
                    cac.to_sql(name='experimental_data_sbw_cell_area_and_counts', con=engine, if_exists='append', index=False)
                    print(f'File uploaded into the {schema}: {file_name}, cac data')
                except Exception as ex:
                    print(f'File not uploaded into the {schema}: {file_name}, cac data')
                    print(f'Error: {ex}')
                try:    
                    cfi.to_sql(name='experimental_data_sbw_cell_foci_intensity', con=engine, if_exists='append', index=False)
                    print(f'File uploaded into the {schema}: {file_name}, cfi data')
                except Exception as ex:
                    print(f'File not uploaded into the {schema}: {file_name}, cfi data')
                    print(f'Error: {ex}')
                try:                   
                    nas.to_sql(name='experimental_data_sbw_foci_number_and_size', con=engine, if_exists='append', index=False)
                    print(f'File uploaded into the {schema}: {file_name}, nas data')
                except Exception as ex:
                    print(f'File not uploaded into the {schema}: {file_name}, nas data')
                    print(f'Error: {ex}')       

            except Exception as exep: #mostly for missing or mislabeled files
                print('---------------------------------------------------')
                print(f'File not loaded: {file_name}: ({exep})')
    
    ###scd data###
    elif type_of_data== 'scd':
        for file_name in file_names:

            try:
                ###data load from Backblaze B2###
                #store data into in-memory object ('in_memory_data')
                in_memory_data = BytesIO() #inmemory storage object
                bucket.download_file_by_name(file_name).save(in_memory_data) #download data from specified bucket-file into 'in_memory_storage'
                in_memory_data.seek(0) #rewind to the beginning
                # Load into pandas df
                single_file_data = pd.read_csv(in_memory_data,
                                               converters= {'WELL LABEL':lambda x: x.replace(' - ', '0') if len(x) == 5 else x.replace(' - ', '')})
                single_file_data= single_file_data.assign(date_label= file_name.split('_')[0], #assign the 'date_label' (based on the 6-digit file label preceeding the '_sbw'/'_scd' suffix)
                                                          fov_cell_id= (single_file_data['FOV']).astype('str') + '-' +  (single_file_data['OBJECT ID']).astype('str')) #assigning unique cell id (FOV + object id)
                print('---------------------------------------------------')
                print(f'File loaded: {file_name}')
                ###processing###
                #filter down to only essential columns
                single_file_data= single_file_data.loc[:, ['WELL LABEL', 'T', 'Cells Area wv1', 'Cells Intensity wv1', 'Cells Max Intensity wv1', 'Cells Intensity wv2', 'Cells Max Intensity wv2', 'Granules Org per Cell wv2', 'Granules Total Area wv2', 'Granules Intensity wv2', 'date_label', 'fov_cell_id']]
                #rename the columns
                single_file_data.columns= ['experimental_well_label', 'timepoint', 'cell_area', 'cells_intensity_wv1', 'cells_max_intensity_wv1', 'cells_intensity_wv2', 'cells_max_intensity_wv2', 'number_of_foci', 'total_foci_area', 'foci_intensity_wv2', 'date_label', 'fov_cell_id']
                #fillna with 0
                single_file_data= single_file_data.fillna(0)
                #reorder columns
                single_file_data= single_file_data.reindex(columns= ['date_label', 'experimental_well_label', 'fov_cell_id', 'timepoint', 'cell_area', 'cells_intensity_wv1', 'cells_max_intensity_wv1', 'cells_intensity_wv2', 'cells_max_intensity_wv2', 'number_of_foci', 'total_foci_area', 'foci_intensity_wv2' ])
                #split dataset into three to be loaded into their respective tables in relational database
                #cell area (load into 'experimetal_data_scd_cell_area')
                ca= single_file_data.loc[:, ['date_label', 'experimental_well_label', 'timepoint', 'fov_cell_id', 'cell_area']]
                #cell foci intensity (load into 'experimental_data_scd_cell_foci_intensity')
                cfi= single_file_data.loc[:, ['date_label', 'experimental_well_label', 'timepoint', 'fov_cell_id', 'cells_intensity_wv1', 'cells_max_intensity_wv1', 'cells_intensity_wv2', 'cells_max_intensity_wv2', 'foci_intensity_wv2']]
                #foci number and area (load into 'experimetal_data_scd_foci_number_and_area')
                naa= single_file_data.loc[:, ['date_label', 'experimental_well_label', 'timepoint', 'fov_cell_id', 'number_of_foci', 'total_foci_area']]              
                #data load directly into relational db
                #three dataset (ca, cfi and naa) individually into their respective tables
                try:
                    ca.to_sql(name='experimental_data_scd_cell_area', con=engine, if_exists='append', index=False)
                    print(f'File uploaded into the {schema}: {file_name}, ca data')
                except Exception as ex: 
                    print(f'File not uploaded into the {schema}: {file_name}, ca data')
                    print(f'Error: {ex}')
                try:
                    cfi.to_sql(name='experimental_data_scd_cell_foci_intensity', con=engine, if_exists='append', index=False)
                    print(f'File uploaded into the {schema}: {file_name}, cfi data')
                except Exception as ex: 
                    print(f'File not uploaded into the {schema}: {file_name}, cfi data')
                    print(f'Error: {ex}')
                try:
                    naa.to_sql(name='experimental_data_scd_foci_number_and_area', con=engine, if_exists='append', index=False)
                    print(f'File uploaded into the {schema}: {file_name}, naa data')
                except Exception as ex:
                    print(f'File not uploaded into the {schema}: {file_name}, naa data')
                    print(f'Error: {ex}')
                
            except Exception as exep: #mostly for missing or mislabeled files
                print('---------------------------------------------------')
                print(f'File not loaded: {file_name}: ({exep})')
    
    ###wrong 'type_of_data' input###
    else: 
        raise ValueError(f"Invalid 'type_of_data' argument: '{type_of_data}'. Expected: 'sbw' or 'scd'.")
# backblaze_to_mysql_raw_data_all_files(type_of_data= 'scd') #sample run





