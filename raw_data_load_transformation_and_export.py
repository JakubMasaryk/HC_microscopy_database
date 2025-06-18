import numpy as np
import pandas as pd
import os
import string
from sqlalchemy import create_engine

#mysql server connection parameters
#fill in!
username= ''
password= ''
hostname= ''
port= ''
schema= 'hc_microscopy_data_v2'

#mysql server connection
connection_string = f"mysql+pymysql://{username}:{password}@{hostname}:{port}/{schema}"
engine = create_engine(connection_string) 


# ---------------------------------------------------

# ### __SBW ans SCD Data: file export__

# * __sbw data__

#sbw data load, transformatiuon and export as a file (.csv or .xlsx)
#input: path-path to file/folder (containing the file/s)
#       source: 'file'/'folder' in accordance with the 'path'
#       export format: '.csv', '.xlsx' 
def sbw_data_transformation_export(path, source, export_format):
    
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
    
    #data export (into csv or xlsx)
    #three dataset (cac, cfi and nas) individually
    #labels: 'cac'/'cfi'/'nas' + '_sbw_dataset' + '.csv'/'.xlsx'
    if source == 'folder':
        base_dir = path
    else:
        base_dir = os.path.dirname(path)

    if export_format == 'csv':
        # print("Exporting data to CSV format...")
        cac.to_csv(os.path.join(base_dir, 'cac_sbw_dataset.csv'), index=False, encoding='utf-8')
        cfi.to_csv(os.path.join(base_dir, 'cfi_sbw_dataset.csv'), index=False, encoding='utf-8')
        nas.to_csv(os.path.join(base_dir, 'nas_sbw_dataset.csv'), index=False, encoding='utf-8')

    elif export_format == 'xlsx':
        # print("Exporting data to XLSX format...")
        cac.to_excel(os.path.join(base_dir, 'cac_sbw_dataset.xlsx'), index=False)
        cfi.to_excel(os.path.join(base_dir, 'cfi_sbw_dataset.xlsx'), index=False)
        nas.to_excel(os.path.join(base_dir, 'nas_sbw_dataset.xlsx'), index=False)

    else:
        raise ValueError(f"Invalid export format: '{export_format}'. Expected: 'csv' or 'xlsx'.")
    
    print(f"Data Transformation and Export complete. Files saved in: {base_dir}")
    

# * __scd data__

#scd data load, transformatiuon and export as a file (.csv or .xlsx)
#input: path-path to file/folder (containing the file/s)
#       source: 'file'/'folder' in accordance with the 'path'
#       export format: 'csv', 'xlsx' (xlsx preferable due to certain 'fov_cell_id' entries being recognized as a date in csv)
def scd_data_transformation_export(path, source, export_format):
    
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
            date_label= dataset_label.split('_')[0]
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
    complete_dataset= complete_dataset.reindex(columns= ['date_label', 'experimental_well_label', 'fov_cell_id', 'timepoint', 'cell_area', 'cells_intensity_wv1', 'cells_max_intensity_wv1', 'cells_intensity_wv2', 'cells_max_intensity_wv2', 'number_of_foci', 'total_foci_area', 'foci_intensity_wv2' ])
    
    #split dataset into three to be loaded into their respective tables in relational database
    #cell area (load into 'experimetal_data_scd_cell_area')
    ca= complete_dataset.loc[:, ['date_label', 'experimental_well_label', 'timepoint', 'fov_cell_id', 'cell_area']]
    #cell foci intensity (load into 'experimental_data_scd_cell_foci_intensity')
    cfi= complete_dataset.loc[:, ['date_label', 'experimental_well_label', 'timepoint', 'fov_cell_id', 'cells_intensity_wv1', 'cells_max_intensity_wv1', 'cells_intensity_wv2', 'cells_max_intensity_wv2', 'foci_intensity_wv2']]
    #foci number and area (load into 'experimetal_data_scd_foci_number_and_area')
    naa= complete_dataset.loc[:, ['date_label', 'experimental_well_label', 'timepoint', 'fov_cell_id', 'number_of_foci', 'total_foci_area']]
    
    #data export (into csv or xlsx)
    #three dataset (ca, cfi and naa) individually
    #labels: 'ca'/'cfi'/'naa' + '_sbw_dataset' + '.csv'/'.xlsx'
    if source == 'folder':
        base_dir = path
    else:
        base_dir = os.path.dirname(path)

    if export_format == 'csv':
        # print("Exporting data to CSV format...")
        ca.to_csv(os.path.join(base_dir, 'ca_scd_dataset.csv'), index=False, encoding='utf-8')
        cfi.to_csv(os.path.join(base_dir, 'cfi_scd_dataset.csv'), index=False, encoding='utf-8')
        naa.to_csv(os.path.join(base_dir, 'naa_scd_dataset.csv'), index=False, encoding='utf-8')

    elif export_format == 'xlsx':
        # print("Exporting data to XLSX format...")
        ca.to_excel(os.path.join(base_dir, 'ca_scd_dataset.xlsx'), index=False)
        cfi.to_excel(os.path.join(base_dir, 'cfi_scd_dataset.xlsx'), index=False)
        naa.to_excel(os.path.join(base_dir, 'naa_scd_dataset.xlsx'), index=False)

    else:
        raise ValueError(f"Invalid export format: '{export_format}'. Expected: 'csv' or 'xlsx'.")
    
    print(f"Data Transformation and Export complete. Files saved in: {base_dir}")


# sbw_data_transformation_export(path= r"", source= 'folder', export_format= 'xlsx')
# scd_data_transformation_export(path= r"", source= 'folder', export_format= 'xlsx')

