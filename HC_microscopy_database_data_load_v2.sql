-- Table: 'wild_types'

-- original
TRUNCATE TABLE hc_microscopy_data_v2.wild_types;
LOAD DATA LOCAL INFILE "...\wild_types.csv"
INTO TABLE hc_microscopy_data_v2.wild_types
FIELDS TERMINATED BY ',' 
-- ENCLOSED BY '"' 
LINES TERMINATED BY '\n'
IGNORE 1 ROWS; -- ignore header

-- update 1
LOAD DATA LOCAL INFILE "...\wild_types_update_1.csv.csv"
INTO TABLE hc_microscopy_data_v2.wild_types
FIELDS TERMINATED BY ',' 
-- ENCLOSED BY '"' 
LINES TERMINATED BY '\n'
IGNORE 1 ROWS; 


-- Table: 'experiment_types'

-- original
TRUNCATE TABLE hc_microscopy_data_v2.experiment_types;
LOAD DATA LOCAL INFILE "...\experiment_types.csv"
INTO TABLE hc_microscopy_data_v2.experiment_types
FIELDS TERMINATED BY ',' 
--  ENCLOSED BY '"' 
LINES TERMINATED BY '\n'
IGNORE 1 ROWS; -- ignore header

-- update 1
LOAD DATA LOCAL INFILE "...\experiment_types_update_1.csv"
INTO TABLE hc_microscopy_data_v2.experiment_types
FIELDS TERMINATED BY ',' 
--  ENCLOSED BY '"' 
LINES TERMINATED BY '\n'
IGNORE 1 ROWS; -- ignore header

-- Table: 'experiments'

-- original
TRUNCATE TABLE hc_microscopy_data_v2.experiments;
LOAD DATA LOCAL INFILE "...\experiments.csv"
INTO TABLE hc_microscopy_data_v2.experiments
FIELDS TERMINATED BY ',' 
-- ENCLOSED BY '"' 
LINES TERMINATED BY '\n'
IGNORE 1 ROWS; -- ignore header

-- update 1
LOAD DATA LOCAL INFILE "...\experiments_update_1.csv"
INTO TABLE hc_microscopy_data_v2.experiments
FIELDS TERMINATED BY ',' 
-- ENCLOSED BY '"' 
LINES TERMINATED BY '\n'
IGNORE 1 ROWS; 

-- update 2
LOAD DATA LOCAL INFILE "...\experiments_update_2.csv"
INTO TABLE hc_microscopy_data_v2.experiments
FIELDS TERMINATED BY ',' 
-- ENCLOSED BY '"' 
LINES TERMINATED BY '\n'
IGNORE 1 ROWS; 

-- update 3
LOAD DATA LOCAL INFILE "...\experiments_update_3.csv"
INTO TABLE hc_microscopy_data_v2.experiments
FIELDS TERMINATED BY ',' 
-- ENCLOSED BY '"' 
LINES TERMINATED BY '\n'
IGNORE 1 ROWS; 

-- Table: 'inhibitors'

-- original
TRUNCATE TABLE hc_microscopy_data_v2.inhibitors;
LOAD DATA LOCAL INFILE "...\inhibitors.csv"
INTO TABLE hc_microscopy_data_v2.inhibitors
FIELDS TERMINATED BY ',' 
-- ENCLOSED BY '"' 
LINES TERMINATED BY '\n'
IGNORE 1 ROWS; -- ignore header

-- update 1
LOAD DATA LOCAL INFILE "...\inhibitors_update_1.csv"
INTO TABLE hc_microscopy_data_v2.inhibitors
FIELDS TERMINATED BY ',' 
-- ENCLOSED BY '"' 
LINES TERMINATED BY '\n'
IGNORE 1 ROWS; -- ignore header

-- update 2
LOAD DATA LOCAL INFILE "...\inhibitors_update_2.csv"
INTO TABLE hc_microscopy_data_v2.inhibitors
FIELDS TERMINATED BY ',' 
-- ENCLOSED BY '"' 
LINES TERMINATED BY '\n'
IGNORE 1 ROWS; -- ignore header


-- Table: 'experiment_inhibitor'

-- original
TRUNCATE TABLE hc_microscopy_data_v2.experiment_inhibitor;
LOAD DATA LOCAL INFILE "...\experiment_inhibitor.csv"
INTO TABLE hc_microscopy_data_v2.experiment_inhibitor
FIELDS TERMINATED BY ',' 
-- ENCLOSED BY '"' 
LINES TERMINATED BY '\n'
IGNORE 1 ROWS; -- ignore header


-- Table: 'sgd_descriptions'

-- original
TRUNCATE TABLE hc_microscopy_data_v2.sgd_descriptions;
LOAD DATA LOCAL INFILE "...\sgd_descriptions.csv"
INTO TABLE hc_microscopy_data_v2.sgd_descriptions
FIELDS TERMINATED BY ',' 
-- ENCLOSED BY '"' 
LINES TERMINATED BY '\n'
IGNORE 1 ROWS; -- ignore header


-- Table: 'strains_and_conditions_main'

-- original
TRUNCATE TABLE hc_microscopy_data_v2.strains_and_conditions_main;
LOAD DATA LOCAL INFILE "...\strains_and_conditions_main.csv"
INTO TABLE hc_microscopy_data_v2.strains_and_conditions_main
FIELDS TERMINATED BY ',' 
-- ENCLOSED BY '"' 
LINES TERMINATED BY '\n'
IGNORE 1 ROWS; -- ignore header

-- update 1
LOAD DATA LOCAL INFILE "...\strains_and_conditions_main_update_1.csv"
INTO TABLE hc_microscopy_data_v2.strains_and_conditions_main
FIELDS TERMINATED BY ',' 
-- ENCLOSED BY '"' 
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

-- update 2
LOAD DATA LOCAL INFILE "...\strains_and_conditions_main_update_2.csv"
INTO TABLE hc_microscopy_data_v2.strains_and_conditions_main
FIELDS TERMINATED BY ',' 
-- ENCLOSED BY '"' 
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

-- update 3
LOAD DATA LOCAL INFILE "...\strains_and_conditions_main_update_3.csv"
INTO TABLE hc_microscopy_data_v2.strains_and_conditions_main
FIELDS TERMINATED BY ',' 
-- ENCLOSED BY '"' 
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;


-- Table: 'strains_and_conditions_pretreatment'

-- original
TRUNCATE TABLE hc_microscopy_data_v2.strains_and_conditions_pretreatment;
LOAD DATA LOCAL INFILE "...\strains_and_conditions_pretreatment.csv"
INTO TABLE hc_microscopy_data_v2.strains_and_conditions_pretreatment
FIELDS TERMINATED BY ',' 
-- ENCLOSED BY '"' 
LINES TERMINATED BY '\n'
IGNORE 1 ROWS; -- ignore header


-- Table: 'strains_and_conditions_inhibitor'

-- original
TRUNCATE TABLE hc_microscopy_data_v2.strains_and_conditions_inhibitor;
-- empty table
LOAD DATA LOCAL INFILE "...\strains_and_conditions_inhibitor.csv"
INTO TABLE hc_microscopy_data_v2.strains_and_conditions_inhibitor
FIELDS TERMINATED BY ',' 
-- ENCLOSED BY '"' 
LINES TERMINATED BY '\n'
IGNORE 1 ROWS; -- ignore header


-- Table: 'as_interacting_proteins'

-- original
TRUNCATE TABLE hc_microscopy_data_v2.as_interacting_proteins;
LOAD DATA LOCAL INFILE "...\as_interacting_proteins.csv"
INTO TABLE hc_microscopy_data_v2.as_interacting_proteins
FIELDS TERMINATED BY ',' 
-- ENCLOSED BY '"' 
LINES TERMINATED BY '\n'
IGNORE 1 ROWS; -- ignore header


-- Table: 'aggregated_proteins'

-- original
TRUNCATE TABLE hc_microscopy_data_v2.aggregated_proteins;
LOAD DATA LOCAL INFILE "...\aggregated_proteins.csv"
INTO TABLE hc_microscopy_data_v2.aggregated_proteins
FIELDS TERMINATED BY ',' 
-- ENCLOSED BY '"' 
LINES TERMINATED BY '\n'
IGNORE 1 ROWS; -- ignore header


-- Table: 'as_sensitive_mutants'

-- original
TRUNCATE TABLE hc_microscopy_data_v2.as_sensitive_mutants;
LOAD DATA LOCAL INFILE "...\as_sensitive_mutants.csv"
INTO TABLE hc_microscopy_data_v2.as_sensitive_mutants
FIELDS TERMINATED BY ',' 
-- ENCLOSED BY '"' 
LINES TERMINATED BY '\n'
IGNORE 1 ROWS; -- ignore header


-- Table: 'increased_aggregation_mutants'

-- original
TRUNCATE TABLE hc_microscopy_data_v2.increased_aggregation_mutants;
LOAD DATA LOCAL INFILE "...\increased_aggregation_mutants.csv"
INTO TABLE hc_microscopy_data_v2.increased_aggregation_mutants
FIELDS TERMINATED BY ',' 
-- ENCLOSED BY '"' 
LINES TERMINATED BY '\n'
IGNORE 1 ROWS; -- ignore header


-- Table: 'reduced_aggregation_mutants'

-- original
TRUNCATE TABLE hc_microscopy_data_v2.reduced_aggregation_mutants;
LOAD DATA LOCAL INFILE "...\reduced_aggregation_mutants.csv"
INTO TABLE hc_microscopy_data_v2.reduced_aggregation_mutants
FIELDS TERMINATED BY ',' 
-- ENCLOSED BY '"' 
LINES TERMINATED BY '\n'
IGNORE 1 ROWS; -- ignore header


-- Table: 'ts_reference_group'

-- original
TRUNCATE TABLE hc_microscopy_data_v2.ts_reference_group;
LOAD DATA LOCAL INFILE "...\ts_reference_group.csv"
INTO TABLE hc_microscopy_data_v2.ts_reference_group
FIELDS TERMINATED BY ',' 
-- ENCLOSED BY '"' 
LINES TERMINATED BY '\n'
IGNORE 1 ROWS; -- ignore header


-- Table: 'unique_hits'

-- original
TRUNCATE TABLE hc_microscopy_data_v2.unique_hits;
LOAD DATA LOCAL INFILE "...\unique_hits.csv"
INTO TABLE hc_microscopy_data_v2.unique_hits
FIELDS TERMINATED BY ',' 
-- ENCLOSED BY '"' 
LINES TERMINATED BY '\n'
IGNORE 1 ROWS; -- ignore header


-- Table: 'effect_stage_labels'

-- original
TRUNCATE TABLE hc_microscopy_data_v2.effect_stage_labels;
LOAD DATA LOCAL INFILE "...\effect_stage_labels.csv"
INTO TABLE hc_microscopy_data_v2.effect_stage_labels
FIELDS TERMINATED BY ',' 
-- ENCLOSED BY '"' 
LINES TERMINATED BY '\n'
IGNORE 1 ROWS; -- ignore header


-- Table: 'clusters'

-- original
TRUNCATE TABLE hc_microscopy_data_v2.clusters;
LOAD DATA LOCAL INFILE "...\clusters.csv"
INTO TABLE hc_microscopy_data_v2.clusters
FIELDS TERMINATED BY ',' 
-- ENCLOSED BY '"' 
LINES TERMINATED BY '\n'
IGNORE 1 ROWS; -- ignore header


-- Table: 'enrichments'

-- original
TRUNCATE TABLE hc_microscopy_data_v2.enrichments;
LOAD DATA LOCAL INFILE "...\enrichments.csv"
INTO TABLE hc_microscopy_data_v2.enrichments
FIELDS TERMINATED BY ',' 
-- ENCLOSED BY '"' 
LINES TERMINATED BY '\n'
IGNORE 1 ROWS; -- ignore header


-- Table: 'cluster_enrichment'

-- original
TRUNCATE TABLE hc_microscopy_data_v2.cluster_enrichment;
LOAD DATA LOCAL INFILE "...\cluster_enrichment.csv"
INTO TABLE hc_microscopy_data_v2.cluster_enrichment
FIELDS TERMINATED BY ',' 
-- ENCLOSED BY '"' 
LINES TERMINATED BY '\n'
IGNORE 1 ROWS; -- ignore header


-- Table: 'hits_clusters'

-- original
TRUNCATE TABLE hc_microscopy_data_v2.hits_clusters;
LOAD DATA LOCAL INFILE "...\hits_clusters.csv"
INTO TABLE hc_microscopy_data_v2.hits_clusters
FIELDS TERMINATED BY ',' 
-- ENCLOSED BY '"' 
LINES TERMINATED BY '\n'
IGNORE 1 ROWS; -- ignore header
