####Table: 'wild_types'

TRUNCATE TABLE hc_microscopy_data_v2.wild_types;
LOAD DATA LOCAL INFILE "C:\\Users\\Jakub\\Documents\\database_material_v2\\tab_wild_types.csv"
INTO TABLE hc_microscopy_data_v2.wild_types
FIELDS TERMINATED BY ',' 
-- ENCLOSED BY '"' 
LINES TERMINATED BY '\n'
IGNORE 1 ROWS; -- ignore header

-- update 1: 'Inhibitors' experiments
LOAD DATA LOCAL INFILE "C:\\Users\\Jakub\\Documents\\database_material_v2\\tab_wild_types_inhibitors_update.csv"
INTO TABLE hc_microscopy_data_v2.wild_types
FIELDS TERMINATED BY ',' 
-- ENCLOSED BY '"' 
LINES TERMINATED BY '\n'
IGNORE 1 ROWS; 


####Table: 'experiment_types'

TRUNCATE TABLE hc_microscopy_data_v2.experiment_types;
LOAD DATA LOCAL INFILE "C:\\Users\\Jakub\\Documents\\database_material_v2\\tab_experiment_type.csv"
INTO TABLE hc_microscopy_data_v2.experiment_types
FIELDS TERMINATED BY ',' 
--  ENCLOSED BY '"' 
LINES TERMINATED BY '\n'
IGNORE 1 ROWS; -- ignore header


####Table: 'experiments'

TRUNCATE TABLE hc_microscopy_data_v2.experiments;
LOAD DATA LOCAL INFILE "C:\\Users\\Jakub\\Documents\\database_material_v2\\tab_experiments.csv"
INTO TABLE hc_microscopy_data_v2.experiments
FIELDS TERMINATED BY ',' 
-- ENCLOSED BY '"' 
LINES TERMINATED BY '\n'
IGNORE 1 ROWS; -- ignore header

-- update 1: 'Inhibitors' experiments
LOAD DATA LOCAL INFILE "C:\\Users\\Jakub\\Documents\\database_material_v2\\tab_experiments_inhibitors_update.csv"
INTO TABLE hc_microscopy_data_v2.experiments
FIELDS TERMINATED BY ',' 
-- ENCLOSED BY '"' 
LINES TERMINATED BY '\n'
IGNORE 1 ROWS; 


####Table: 'inhibitors'

TRUNCATE TABLE hc_microscopy_data_v2.inhibitors;
LOAD DATA LOCAL INFILE "C:\\Users\\Jakub\\Documents\\database_material_v2\\tab_inhibitors.csv"
INTO TABLE hc_microscopy_data_v2.inhibitors
FIELDS TERMINATED BY ',' 
-- ENCLOSED BY '"' 
LINES TERMINATED BY '\n'
IGNORE 1 ROWS; -- ignore header

-- update 1: 'Inhibitors' experiments
LOAD DATA LOCAL INFILE "C:\\Users\\Jakub\\Documents\\database_material_v2\\tab_inhibitors_inhibitors_update.csv"
INTO TABLE hc_microscopy_data_v2.inhibitors
FIELDS TERMINATED BY ',' 
-- ENCLOSED BY '"' 
LINES TERMINATED BY '\n'
IGNORE 1 ROWS; -- ignore header

-- control inhibitor (to pair with non-treated wells from "strains_and_conditions_inhibitor" table)
INSERT INTO hc_microscopy_data_v2.inhibitors (inhibitor_id, inhibitor_name, inhibitor_abbreviation, effect_description)
VALUES (12, "-", "-", "-");


####Table: 'experiment_inhibitor'

TRUNCATE TABLE hc_microscopy_data_v2.experiment_inhibitor;
LOAD DATA LOCAL INFILE "C:\\Users\\Jakub\\Documents\\database_material_v2\\tab_experiment_inhibitor.csv"
INTO TABLE hc_microscopy_data_v2.experiment_inhibitor
FIELDS TERMINATED BY ',' 
-- ENCLOSED BY '"' 
LINES TERMINATED BY '\n'
IGNORE 1 ROWS; -- ignore header


####Table: 'sgd_descriptions'

TRUNCATE TABLE hc_microscopy_data_v2.sgd_descriptions;
LOAD DATA LOCAL INFILE "C:\\Users\\Jakub\\Documents\\database_material_v2\\tab_sgd_descriptions.csv"
INTO TABLE hc_microscopy_data_v2.sgd_descriptions
FIELDS TERMINATED BY ',' 
-- ENCLOSED BY '"' 
LINES TERMINATED BY '\n'
IGNORE 1 ROWS; -- ignore header


####Table: 'strains_and_conditions_main'

TRUNCATE TABLE hc_microscopy_data_v2.strains_and_conditions_main;
LOAD DATA LOCAL INFILE "C:\\Users\\Jakub\\Documents\\database_material_v2\\tab_strains_and_conditions_main.csv"
INTO TABLE hc_microscopy_data_v2.strains_and_conditions_main
FIELDS TERMINATED BY ',' 
-- ENCLOSED BY '"' 
LINES TERMINATED BY '\n'
IGNORE 1 ROWS; -- ignore header

-- update 1: 'Inhibitors' experiments
LOAD DATA LOCAL INFILE "C:\\Users\\Jakub\\Documents\\database_material_v2\\tab_strains_and_conditions_main_inhibitors_update.csv"
INTO TABLE hc_microscopy_data_v2.strains_and_conditions_main
FIELDS TERMINATED BY ',' 
-- ENCLOSED BY '"' 
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;


###Table: 'strains_and_conditions_pretreatment'

TRUNCATE TABLE hc_microscopy_data_v2.strains_and_conditions_pretreatment;
LOAD DATA LOCAL INFILE "C:\\Users\\Jakub\\Documents\\database_material_v2\\tab_strains_and_conditions_pretreatment.csv"
INTO TABLE hc_microscopy_data_v2.strains_and_conditions_pretreatment
FIELDS TERMINATED BY ',' 
-- ENCLOSED BY '"' 
LINES TERMINATED BY '\n'
IGNORE 1 ROWS; -- ignore header


####Table: 'strains_and_conditions_inhibitor'

TRUNCATE TABLE hc_microscopy_data_v2.strains_and_conditions_inhibitor;
-- empty table
LOAD DATA LOCAL INFILE "C:\\Users\\Jakub\\Documents\\database_material_v2\\tab_strains_and_conditions_inhibitor.csv"
INTO TABLE hc_microscopy_data_v2.strains_and_conditions_inhibitor
FIELDS TERMINATED BY ',' 
-- ENCLOSED BY '"' 
LINES TERMINATED BY '\n'
IGNORE 1 ROWS; -- ignore header

-- update 1: 'Inhibitors' experiments
LOAD DATA LOCAL INFILE "C:\\Users\\Jakub\\Documents\\database_material_v2\\tab_strains_and_conditions_inhibitor_inhibitor_update.csv"
INTO TABLE hc_microscopy_data_v2.strains_and_conditions_inhibitor
FIELDS TERMINATED BY ',' 
-- ENCLOSED BY '"' 
LINES TERMINATED BY '\n'
IGNORE 1 ROWS; 


####Table: 'experimental_data_sbw_cell_area_and_counts'

TRUNCATE TABLE hc_microscopy_data_v2.experimental_data_sbw_cell_area_and_counts;
LOAD DATA LOCAL INFILE "C:\\Users\\Jakub\\Documents\\database_material_v2\\tab_summary_by_well_data_cell_area_and_counts.csv"
INTO TABLE hc_microscopy_data_v2.experimental_data_sbw_cell_area_and_counts
FIELDS TERMINATED BY ',' 
-- ENCLOSED BY '"' 
LINES TERMINATED BY '\n'
IGNORE 1 ROWS; -- ignore header

-- update 1: 'Inhibitors' experiments
LOAD DATA LOCAL INFILE "C:\\Users\\Jakub\\Documents\\database_material_v2\\tab_summary_by_well_data_cell_area_and_counts_inhibitors_update.csv"
INTO TABLE hc_microscopy_data_v2.experimental_data_sbw_cell_area_and_counts
FIELDS TERMINATED BY ',' 
-- ENCLOSED BY '"' 
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;


####Table: 'experimental_data_scd_cell_area'

TRUNCATE TABLE hc_microscopy_data_v2.experimental_data_scd_cell_area;
LOAD DATA LOCAL INFILE "C:\\Users\\Jakub\\Documents\\database_material_v2\\tab_experimental_data_scd_cell_area.csv"
INTO TABLE hc_microscopy_data_v2.experimental_data_scd_cell_area
FIELDS TERMINATED BY ',' 
-- ENCLOSED BY '"' 
LINES TERMINATED BY '\n'
IGNORE 1 ROWS; -- ignore header

-- update 1: experimental_data_scd_cell_area by previously missing data (date labels: 20240523 and 20240626)
LOAD DATA LOCAL INFILE "C:\\Users\\Jakub\\Documents\\database_material_v2\\tab_experimental_data_scd_cell_area_update.csv"
INTO TABLE hc_microscopy_data_v2.experimental_data_scd_cell_area
FIELDS TERMINATED BY ',' 
-- ENCLOSED BY '"' 
LINES TERMINATED BY '\n'
IGNORE 1 ROWS; 

-- update 2: 'Inhibitors' experiments
LOAD DATA LOCAL INFILE "C:\\Users\\Jakub\\Documents\\database_material_v2\\tab_experimental_data_scd_cell_area_inhibitors_update.csv"
INTO TABLE hc_microscopy_data_v2.experimental_data_scd_cell_area
FIELDS TERMINATED BY ',' 
-- ENCLOSED BY '"' 
LINES TERMINATED BY '\n'
IGNORE 1 ROWS; 


####Table: 'experimental_data_sbw_cell_foci_intensity'

TRUNCATE TABLE hc_microscopy_data_v2.experimental_data_sbw_cell_foci_intensity;
LOAD DATA LOCAL INFILE "C:\\Users\\Jakub\\Documents\\database_material_v2\\tab_summary_by_well_data_cell_foci_intensity.csv"
INTO TABLE hc_microscopy_data_v2.experimental_data_sbw_cell_foci_intensity
FIELDS TERMINATED BY ',' 
-- ENCLOSED BY '"' 
LINES TERMINATED BY '\n'
IGNORE 1 ROWS; -- ignore header

-- update 1: 'Inhibitors' experiments
LOAD DATA LOCAL INFILE "C:\\Users\\Jakub\\Documents\\database_material_v2\\tab_summary_by_well_data_cell_foci_intensity_inhibitors_update.csv"
INTO TABLE hc_microscopy_data_v2.experimental_data_sbw_cell_foci_intensity
FIELDS TERMINATED BY ',' 
-- ENCLOSED BY '"' 
LINES TERMINATED BY '\n'
IGNORE 1 ROWS; 


####Table: 'experimental_data_scd_cell_foci_intensity'

TRUNCATE TABLE hc_microscopy_data_v2.experimental_data_scd_cell_foci_intensity;
LOAD DATA LOCAL INFILE "C:\\Users\\Jakub\\Documents\\database_material_v2\\tab_experimental_data_scd_cell_foci_intensity.csv"
INTO TABLE hc_microscopy_data_v2.experimental_data_scd_cell_foci_intensity
FIELDS TERMINATED BY ',' 
-- ENCLOSED BY '"' 
LINES TERMINATED BY '\n'
IGNORE 1 ROWS; -- ignore header

-- update 1: experimental_data_scd_cell_foci_intensity by previously missing data (date labels: 20240523 and 20240626)
LOAD DATA LOCAL INFILE "C:\\Users\\Jakub\\Documents\\database_material_v2\\tab_experimental_data_scd_cell_foci_intensity_update.csv"
INTO TABLE hc_microscopy_data_v2.experimental_data_scd_cell_foci_intensity
FIELDS TERMINATED BY ',' 
-- ENCLOSED BY '"' 
LINES TERMINATED BY '\n'
IGNORE 1 ROWS; 

-- update 2: 'Inhibitors' experiments
LOAD DATA LOCAL INFILE "C:\\Users\\Jakub\\Documents\\database_material_v2\\tab_experimental_data_scd_cell_foci_intensity_inhibitors_update.csv"
INTO TABLE hc_microscopy_data_v2.experimental_data_scd_cell_foci_intensity
FIELDS TERMINATED BY ',' 
-- ENCLOSED BY '"' 
LINES TERMINATED BY '\n'
IGNORE 1 ROWS; 


####Table: 'experimental_data_sbw_foci_number_and_size'

TRUNCATE TABLE hc_microscopy_data_v2.experimental_data_sbw_foci_number_and_size;
LOAD DATA LOCAL INFILE "C:\\Users\\Jakub\\Documents\\database_material_v2\\tab_summary_by_well_data_foci_number_and_size.csv"
INTO TABLE hc_microscopy_data_v2.experimental_data_sbw_foci_number_and_size
FIELDS TERMINATED BY ',' 
-- ENCLOSED BY '"' 
LINES TERMINATED BY '\n'
IGNORE 1 ROWS; -- ignore header

-- update 1: 'Inhibitors' experiments
LOAD DATA LOCAL INFILE "C:\\Users\\Jakub\\Documents\\database_material_v2\\tab_summary_by_well_data_foci_number_and_size_inhibitors_update.csv"
INTO TABLE hc_microscopy_data_v2.experimental_data_sbw_foci_number_and_size
FIELDS TERMINATED BY ',' 
-- ENCLOSED BY '"' 
LINES TERMINATED BY '\n'
IGNORE 1 ROWS; 


####Table: 'experimental_data_scd_foci_number_and_area'

TRUNCATE TABLE hc_microscopy_data_v2.experimental_data_scd_foci_number_and_area;
LOAD DATA LOCAL INFILE "C:\\Users\\Jakub\\Documents\\database_material_v2\\tab_experimental_data_scd_foci_number_and_area.csv"
INTO TABLE hc_microscopy_data_v2.experimental_data_scd_foci_number_and_area
FIELDS TERMINATED BY ',' 
-- ENCLOSED BY '"' 
LINES TERMINATED BY '\n'
IGNORE 1 ROWS; -- ignore header

-- update 1: experimental_data_scd_foci_number_and_area by previously missing data (date labels: 20240523 and 20240626)
LOAD DATA LOCAL INFILE "C:\\Users\\Jakub\\Documents\\database_material_v2\\tab_experimental_data_scd_foci_number_and_area_update.csv"
INTO TABLE hc_microscopy_data_v2.experimental_data_scd_foci_number_and_area
FIELDS TERMINATED BY ',' 
-- ENCLOSED BY '"' 
LINES TERMINATED BY '\n'
IGNORE 1 ROWS; 

-- update 2: 'Inhibitors' experiments
LOAD DATA LOCAL INFILE "C:\\Users\\Jakub\\Documents\\database_material_v2\\tab_experimental_data_scd_foci_number_and_area_inhibitors_update.csv"
INTO TABLE hc_microscopy_data_v2.experimental_data_scd_foci_number_and_area
FIELDS TERMINATED BY ',' 
-- ENCLOSED BY '"' 
LINES TERMINATED BY '\n'
IGNORE 1 ROWS; 


####Table: 'as_interacting_proteins'

TRUNCATE TABLE hc_microscopy_data_v2.as_interacting_proteins;
LOAD DATA LOCAL INFILE "C:\\Users\\Jakub\\Documents\\database_material_v2\\tab_as_interacting_proteins.csv"
INTO TABLE hc_microscopy_data_v2.as_interacting_proteins
FIELDS TERMINATED BY ',' 
-- ENCLOSED BY '"' 
LINES TERMINATED BY '\n'
IGNORE 1 ROWS; -- ignore header


####Table: 'aggregated_proteins'

TRUNCATE TABLE hc_microscopy_data_v2.aggregated_proteins;
LOAD DATA LOCAL INFILE "C:\\Users\\Jakub\\Documents\\database_material_v2\\tab_aggregated_proteins.csv"
INTO TABLE hc_microscopy_data_v2.aggregated_proteins
FIELDS TERMINATED BY ',' 
-- ENCLOSED BY '"' 
LINES TERMINATED BY '\n'
IGNORE 1 ROWS; -- ignore header


####Table: 'as_sensitive_mutants'

TRUNCATE TABLE hc_microscopy_data_v2.as_sensitive_mutants;
LOAD DATA LOCAL INFILE "C:\\Users\\Jakub\\Documents\\database_material_v2\\tab_as_sensitive_mutants.csv"
INTO TABLE hc_microscopy_data_v2.as_sensitive_mutants
FIELDS TERMINATED BY ',' 
-- ENCLOSED BY '"' 
LINES TERMINATED BY '\n'
IGNORE 1 ROWS; -- ignore header


####Table: 'increased_aggregation_mutants'

TRUNCATE TABLE hc_microscopy_data_v2.increased_aggregation_mutants;
LOAD DATA LOCAL INFILE "C:\\Users\\Jakub\\Documents\\database_material_v2\\tab_mutants_increased_aggregation.csv"
INTO TABLE hc_microscopy_data_v2.increased_aggregation_mutants
FIELDS TERMINATED BY ',' 
-- ENCLOSED BY '"' 
LINES TERMINATED BY '\n'
IGNORE 1 ROWS; -- ignore header


####Table: 'reduced_aggregation_mutants'

TRUNCATE TABLE hc_microscopy_data_v2.reduced_aggregation_mutants;
LOAD DATA LOCAL INFILE "C:\\Users\\Jakub\\Documents\\database_material_v2\\tab_mutants_reduced_aggregation.csv"
INTO TABLE hc_microscopy_data_v2.reduced_aggregation_mutants
FIELDS TERMINATED BY ',' 
-- ENCLOSED BY '"' 
LINES TERMINATED BY '\n'
IGNORE 1 ROWS; -- ignore header


####Table: 'ts_reference_group'

TRUNCATE TABLE hc_microscopy_data_v2.ts_reference_group;
LOAD DATA LOCAL INFILE "C:\\Users\\Jakub\\Documents\\database_material_v2\\tab_ts_reference_group.csv"
INTO TABLE hc_microscopy_data_v2.ts_reference_group
FIELDS TERMINATED BY ',' 
-- ENCLOSED BY '"' 
LINES TERMINATED BY '\n'
IGNORE 1 ROWS; -- ignore header


####Table: 'unique_hits'

TRUNCATE TABLE hc_microscopy_data_v2.unique_hits;
LOAD DATA LOCAL INFILE "C:\\Users\\Jakub\\Documents\\database_material_v2\\tab_unique_hits.csv"
INTO TABLE hc_microscopy_data_v2.unique_hits
FIELDS TERMINATED BY ',' 
-- ENCLOSED BY '"' 
LINES TERMINATED BY '\n'
IGNORE 1 ROWS; -- ignore header


####Table: 'effect_stage_labels'

TRUNCATE TABLE hc_microscopy_data_v2.effect_stage_labels;
LOAD DATA LOCAL INFILE "C:\\Users\\Jakub\\Documents\\database_material_v2\\tab_effect_stage_labels.csv"
INTO TABLE hc_microscopy_data_v2.effect_stage_labels
FIELDS TERMINATED BY ',' 
-- ENCLOSED BY '"' 
LINES TERMINATED BY '\n'
IGNORE 1 ROWS; -- ignore header


####Table: 'clusters'

TRUNCATE TABLE hc_microscopy_data_v2.clusters;
LOAD DATA LOCAL INFILE "C:\\Users\\Jakub\\Documents\\database_material_v2\\tab_clusters.csv"
INTO TABLE hc_microscopy_data_v2.clusters
FIELDS TERMINATED BY ',' 
-- ENCLOSED BY '"' 
LINES TERMINATED BY '\n'
IGNORE 1 ROWS; -- ignore header


####Table: 'enrichments'

TRUNCATE TABLE hc_microscopy_data_v2.enrichments;
LOAD DATA LOCAL INFILE "C:\\Users\\Jakub\\Documents\\database_material_v2\\tab_enrichments.csv"
INTO TABLE hc_microscopy_data_v2.enrichments
FIELDS TERMINATED BY ',' 
-- ENCLOSED BY '"' 
LINES TERMINATED BY '\n'
IGNORE 1 ROWS; -- ignore header


####Table: 'cluster_enrichment'

TRUNCATE TABLE hc_microscopy_data_v2.cluster_enrichment;
LOAD DATA LOCAL INFILE "C:\\Users\\Jakub\\Documents\\database_material_v2\\tab_cluster_enrichment.csv"
INTO TABLE hc_microscopy_data_v2.cluster_enrichment
FIELDS TERMINATED BY ',' 
-- ENCLOSED BY '"' 
LINES TERMINATED BY '\n'
IGNORE 1 ROWS; -- ignore header


####Table: 'hits_clusters'

TRUNCATE TABLE hc_microscopy_data_v2.hits_clusters;
LOAD DATA LOCAL INFILE "C:\\Users\\Jakub\\Documents\\database_material_v2\\tab_hits_clusters.csv"
INTO TABLE hc_microscopy_data_v2.hits_clusters
FIELDS TERMINATED BY ',' 
-- ENCLOSED BY '"' 
LINES TERMINATED BY '\n'
IGNORE 1 ROWS; -- ignore header
