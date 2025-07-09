#mysql server connection parameters
#fill in!
username= ''
password= ''
hostname= ''
port= ''
schema= ''

#mysql server connection
connection_string = f"mysql+pymysql://{username}:{password}@{hostname}:{port}/{schema}"
engine = create_engine(connection_string) 

# ---------------------------------------------------
# ### __SBW ans SCD Data: direct load into relational schema__

# __raw data loaded, transformed and loaded directly into relational schema__

# __SBW data needs to be loaded before the corresponding SCD data__

#sbw data load, transformatiuon and direct load into the relational schema ('hc_microscopy_data_v2')
#input: path-path to file/folder (containing the file/s)
#       source: 'file'/'folder' in accordance with the 'path'
def sbw_data_transformation_load_into_db(path, source):
    
    #check the combination of path-source inputs
    if os.path.isdir(path) and source=='file':
        raise ValueError(f"Invalid combination of 'path' and 'source' arguments: path to FOLDER given with {source.upper()} as a source.")
        
    if os.path.isfile(path) and source=='folder':
        raise ValueError(f"Invalid combination of 'path' and 'source' arguments: path to FILE given with {source.upper()} as a source.")
    
    #if data source is multiple files in a folder: files loaded individually (6-digit part from file name (6-digit date number + sbw) used as a label- date_label)
    #dataset concatenated into a single df ('complete_dataset')
    if source=='folder':
        complete_dataset= pd.DataFrame()
        for dataset_label in os.listdir(path):
            if not dataset_label.lower().endswith('.csv'): #skip non-csv files
                continue
            date_label= dataset_label.split('_')[0]
            dataset_path= os.path.join(path, dataset_label) # path to a single plate
            dataset= pd.read_csv(dataset_path,
                                 converters= {'WELL LABEL':lambda x: x.replace(' - ', '0') if len(x) == 5 else x.replace(' - ', '')}) #plate data load
            dataset= dataset.assign(date_label= date_label)
            complete_dataset= pd.concat([complete_dataset, dataset], ignore_index= True) #appending to a common dataframe
            
    #single file load (file name (6-digit date number) used as a label- date_label)
    elif source=='file':
        complete_dataset= pd.read_csv(path,
                                      converters= {'WELL LABEL':lambda x: x.replace(' - ', '0') if len(x) == 5 else x.replace(' - ', '')}) #plate data load
        date_label=  os.path.basename(path).split('_')[0] 
        complete_dataset= complete_dataset.assign(date_label= date_label)
    
    #wrong input
    else:
        raise ValueError(f"Invalid source argument: '{source}'. Expected: 'folder' or 'file'.")
    
    #drop non-essential columns
    complete_dataset= complete_dataset.drop(['Row', 'Column', 'Z', 'Plate ID'], axis= 1, errors='ignore') 
    
    #rename columns
    complete_dataset.columns= ['experimental_well_label', 'timepoint', 'number_of_cells', 'cells_total_area', 'cells_avg_intensity_wv1', 'cells_max_intensity_wv1', 'cells_avg_intensity_wv2', 'cells_max_intensity_wv2',
                               'number_of_cells_with_foci', 'avg_number_of_foci_per_cell', 'avg_size_single_focus', 'foci_total_area', 'foci_intensity_wv2', 'cells_with_0_foci_percentage', 'cells_with_0_foci',
                               'cells_with_1_focus_percentage', 'cells_with_1_focus', 'cells_with_multiple_foci_percentage', 'cells_with_multiple_foci', 'date_label']
    
    #reorder columns
    complete_dataset= complete_dataset.reindex(['date_label', 'experimental_well_label', 'timepoint', 'number_of_cells', 'cells_total_area', 'cells_avg_intensity_wv1', 'cells_max_intensity_wv1', 'cells_avg_intensity_wv2', 'cells_max_intensity_wv2',
                                                'number_of_cells_with_foci', 'avg_number_of_foci_per_cell', 'avg_size_single_focus', 'foci_total_area', 'foci_intensity_wv2', 'cells_with_0_foci_percentage', 'cells_with_0_foci',
                                                'cells_with_1_focus_percentage', 'cells_with_1_focus', 'cells_with_multiple_foci_percentage', 'cells_with_multiple_foci'], axis= 1)
    
    #split dataset into three to be loaded into their respective tables in relational database
    #cell area and counts (load into 'experimetal_data_sbw_cell_area_and_counts')
    cac= complete_dataset.loc[:, ['date_label', 'experimental_well_label', 'timepoint', 'cells_total_area', 'number_of_cells', 'number_of_cells_with_foci', 'cells_with_0_foci_percentage', 'cells_with_0_foci',
                                  'cells_with_1_focus_percentage', 'cells_with_1_focus', 'cells_with_multiple_foci_percentage', 'cells_with_multiple_foci']]
    #cell foci intensity (load into 'experimental_data_sbw_cell_foci_intensity')
    cfi= complete_dataset.loc[:, ['date_label', 'experimental_well_label', 'timepoint', 'cells_avg_intensity_wv1', 'cells_max_intensity_wv1', 'cells_avg_intensity_wv2', 'cells_max_intensity_wv2', 'foci_intensity_wv2']]

    #foci number and size (load into 'experimental_data_sbw_foci_number_and_size')
    nas= complete_dataset.loc[:, ['date_label', 'experimental_well_label', 'timepoint', 'avg_number_of_foci_per_cell', 'avg_size_single_focus', 'foci_total_area']]
    
    #data load directly into relational db
    #three dataset (cac, cfi and nas) individually into their respective tables
    cac.to_sql(name='experimental_data_sbw_cell_area_and_counts', con=engine, if_exists='append', index=False)
    cfi.to_sql(name='experimental_data_sbw_cell_foci_intensity', con=engine, if_exists='append', index=False)
    nas.to_sql(name='experimental_data_sbw_foci_number_and_size', con=engine, if_exists='append', index=False)
    
    print(f"Data Transformation complete. Data loaded into relational db: {schema}")

#scd data load, transformatiuon and direct load into the relational schema ('hc_microscopy_data_v2')
#input: path-path to file/folder (containing the file/s)
#       source: 'file'/'folder' in accordance with the 'path'
def scd_data_transformation_load_into_db(path, source):
    
    #check the combination of path-source inputs
    if os.path.isdir(path) and source=='file':
        raise ValueError(f"Invalid combination of 'path' and 'source' arguments: path to FOLDER given with {source.upper()} as a source.")
        
    if os.path.isfile(path) and source=='folder':
        raise ValueError(f"Invalid combination of 'path' and 'source' arguments: path to FILE given with {source.upper()} as a source.")
    
    #if data source is multiple files in a folder: files loaded individually (6-digit part from file name (6-digit date number + scd) used as a label- date_label)
    #dataset concatenated into a single df ('complete_dataset')
    if source=='folder':
        complete_dataset= pd.DataFrame()
        for dataset_label in os.listdir(path):
            if not dataset_label.lower().endswith('.csv'): #skip non-csv files
                continue
            date_label= (dataset_label.split('_')[0])
            dataset_path= os.path.join(path, dataset_label) # path to a single plate
            dataset= pd.read_csv(dataset_path,
                                 converters= {'WELL LABEL':lambda x: x.replace(' - ', '0') if len(x) == 5 else x.replace(' - ', '')}) #plate data load
            dataset= dataset.assign(date_label= date_label,
                                    fov_cell_id= (dataset['FOV']).astype('str') + '-' +  (dataset['OBJECT ID']).astype('str'))
            complete_dataset= pd.concat([complete_dataset, dataset], ignore_index= True) #appending to a common dataframe
            
    #single file load (file name (6-digit date number) used as a label- date_label)
    elif source=='file':
        complete_dataset= pd.read_csv(path,
                                      converters= {'WELL LABEL':lambda x: x.replace(' - ', '0') if len(x) == 5 else x.replace(' - ', '')}) #plate data load
        date_label= os.path.basename(path).split('_')[0]
        complete_dataset= complete_dataset.assign(date_label= date_label,
                                                  fov_cell_id= (complete_dataset['FOV']).astype('str') + '-' +  (complete_dataset['OBJECT ID']).astype('str'))
    
    #wrong input
    else:
        raise ValueError(f"Invalid source argument: '{source}'. Expected: 'folder' or 'file'.")
        
    #filter down to only essential columns
    complete_dataset= complete_dataset.loc[:, ['WELL LABEL', 'T', 'Cells Area wv1', 'Cells Intensity wv1', 'Cells Max Intensity wv1', 'Cells Intensity wv2', 'Cells Max Intensity wv2', 'Granules Org per Cell wv2', 'Granules Total Area wv2', 'Granules Intensity wv2', 'date_label', 'fov_cell_id']]
    
    #rename the columns
    complete_dataset.columns= ['experimental_well_label', 'timepoint', 'cell_area', 'cells_intensity_wv1', 'cells_max_intensity_wv1', 'cells_intensity_wv2', 'cells_max_intensity_wv2', 'number_of_foci', 'total_foci_area', 'foci_intensity_wv2', 'date_label', 'fov_cell_id']
    
    #fillna with 0
    complete_dataset= complete_dataset.fillna(0)
    
    #reorder columns
    complete_dataset= complete_dataset.reindex(columns= ['date_label', 'experimental_well_label', 'fov_cell_id', 'timepoint', 'cell_area', 'cells_intensity_wv1', 'cells_max_intensity_wv1', 'cells_intensity_wv2', 'cells_max_intensity_wv2', 'number_of_foci', 'total_foci_area', 'foci_intensity_wv2'])
    
    #split dataset into three to be loaded into their respective tables in relational database
    #cell area (load into 'experimetal_data_scd_cell_area')
    ca= complete_dataset.loc[:, ['date_label', 'experimental_well_label', 'timepoint', 'fov_cell_id', 'cell_area']]
    #cell foci intensity (load into 'experimental_data_scd_cell_foci_intensity')
    cfi= complete_dataset.loc[:, ['date_label', 'experimental_well_label', 'timepoint', 'fov_cell_id', 'cells_intensity_wv1', 'cells_max_intensity_wv1', 'cells_intensity_wv2', 'cells_max_intensity_wv2', 'foci_intensity_wv2']]
    #foci number and area (load into 'experimetal_data_scd_foci_number_and_area')
    naa= complete_dataset.loc[:, ['date_label', 'experimental_well_label', 'timepoint', 'fov_cell_id', 'number_of_foci', 'total_foci_area']]
    
    #data load directly into relational db
    #three dataset (ca, cfi and naa) individually into their respective tables
    ca.to_sql(name='experimental_data_scd_cell_area', con=engine, if_exists='append', index=False)
    cfi.to_sql(name='experimental_data_scd_cell_foci_intensity', con=engine, if_exists='append', index=False)
    naa.to_sql(name='experimental_data_scd_foci_number_and_area', con=engine, if_exists='append', index=False)
    
    print(f"Data Transformation complete. Data loaded into relational db: {schema}")


#to transform and load the sample data into db (specify the exact folder)
sbw_data_transformation_load_into_db(path= r".../sample_data_sbw", source= 'folder')
scd_data_transformation_load_into_db(path= r".../sample_data_scd", source= 'folder')

