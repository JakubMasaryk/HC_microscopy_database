####database design
drop database if exists hc_microscopy_data_v2;
create database if not exists hc_microscopy_data_v2; 
use hc_microscopy_data_v2;


####file priviliges
-- make sure to edit the connection, on the Connection tab, go to the 'Advanced' sub-tab, and in the 'Others:' box add the line 'OPT_LOCAL_INFILE=1'.
SET GLOBAL local_infile = 1;
-- connection restart
SHOW VARIABLES LIKE 'local_infile'; -- should be 'ON'

####tables creation 
-- wild types
drop table if exists hc_microscopy_data_v2.wild_types;
create table hc_microscopy_data_v2.wild_types
(
wild_type_control_id tinyint primary key,
genotype varchar(250),
arbitrary_label varchar(50)
);


-- experiment types
drop table if exists hc_microscopy_data_v2.experiment_types;
create table hc_microscopy_data_v2.experiment_types
(
experiment_type varchar(40),
experiment_subtype varchar(40),
experiment_type_id tinyint primary key -- place at the end of the row to avoid end of the line '\n' issue with line ending with string 
);


-- experiments
drop table if exists hc_microscopy_data_v2.experiments;
create table hc_microscopy_data_v2.experiments
(
date_label int primary key,
collection varchar(5),
tested_metal enum('As', 'Cd') not null,
data_quality enum('Good', 'Bad'),
microscopy_interval_min decimal(4, 1),
microscopy_initial_delay_min decimal(4,1),
microscopy_duration_hours decimal(3,1),
number_of_fov tinyint,
wild_type_control_id tinyint,
experiment_type_id tinyint,
note varchar(100),
foreign key(wild_type_control_id) references hc_microscopy_data_v2.wild_types(wild_type_control_id)
on delete cascade,
foreign key(experiment_type_id) references hc_microscopy_data_v2.experiment_types(experiment_type_id)
on delete cascade
);


-- inhibitors
drop table if exists hc_microscopy_data_v2.inhibitors;
create table hc_microscopy_data_v2.inhibitors
(
inhibitor_id int primary key,
inhibitor_name varchar(50),
inhibitor_abbreviation varchar(5),
effect_description varchar(500),
index(inhibitor_abbreviation)
);


-- experiment-inhibitor
-- junction table between experiments and inhibitors; one experiment can be associated with multiple inhibitrs
drop table if exists hc_microscopy_data_v2.experiment_inhibitor;
create table hc_microscopy_data_v2.experiment_inhibitor
(
date_label int,
inhibitor_id int,
primary key(date_label, inhibitor_id),
foreign key (date_label) references hc_microscopy_data_v2.experiments(date_label)
on delete cascade,
foreign key (inhibitor_id) references hc_microscopy_data_v2.inhibitors(inhibitor_id)
on delete cascade
);


-- SGD descriptions
drop table if exists hc_microscopy_data_v2.sgd_descriptions;
create table hc_microscopy_data_v2.sgd_descriptions
(
sgd_id char(10) unique key,
systematic_name varchar(12) primary key,
standard_name varchar(12),
description varchar(700)
);


-- strains and conditions
-- 3 separate tables (main, inhibitor, pretreatment)
drop table if exists hc_microscopy_data_v2.strains_and_conditions_main;
create table hc_microscopy_data_v2.strains_and_conditions_main
(
date_label int,
collection_plate_label varchar(5),
experimental_well_label char(3),
corresponding_collection_well_label varchar(3),
mutated_gene_systematic_name varchar(12),
mutated_gene_standard_name varchar(12),
mutation varchar(20),
biological_repeat varchar(10), 
medium varchar(40),
metal_concentration decimal(5,2),
metal_concentration_unit varchar(5),
primary key (date_label, collection_plate_label, experimental_well_label),
foreign key (date_label) references hc_microscopy_data_v2.experiments(date_label)
on delete cascade,
foreign key (mutated_gene_systematic_name) references hc_microscopy_data_v2.sgd_descriptions(systematic_name)
on delete cascade,
index(date_label, experimental_well_label) -- to be referenced by other tables (is not the same as primary key)
);


drop table if exists hc_microscopy_data_v2.strains_and_conditions_inhibitor;
create table hc_microscopy_data_v2.strains_and_conditions_inhibitor
(
date_label int,
experimental_well_label char(3),
inhibitor_abbreviation varchar(5),
inhibitor_concentration decimal(5,2),
inhibitor_concentration_unit varchar(5),
inhibitor_solvent varchar(30),
inhibitor_solvent_concentration decimal(5,2),
inhibitor_solvent_concentration_unit varchar(5),
primary key (date_label, experimental_well_label),
foreign key (date_label, experimental_well_label) references hc_microscopy_data_v2.strains_and_conditions_main(date_label, experimental_well_label)
on delete cascade,
foreign key (inhibitor_abbreviation) references hc_microscopy_data_v2.inhibitors(inhibitor_abbreviation)
on delete cascade
);


drop table if exists hc_microscopy_data_v2.strains_and_conditions_pretreatment;
create table hc_microscopy_data_v2.strains_and_conditions_pretreatment
(
date_label int,
experimental_well_label char(3),
pretreatment varchar(30),
pretreatment_metal_concentration decimal(5,2),
pretreatment_metal_concentration_unit varchar(5),
pretreatment_duration_min decimal(4, 1),
primary key (date_label, experimental_well_label),
foreign key (date_label, experimental_well_label) references hc_microscopy_data_v2.strains_and_conditions_main(date_label, experimental_well_label)
on delete cascade
);


-- summary by well data (sbw) + corresponding single cell data (scd)
-- summary by well data contains averaged data from the single cells (averaged by well)
-- split into three pairs of tables tables (for cell area and counts, for intensities and for foci number and size/area)
-- decimal points cut at 6 digits, might raise 'truncate' warnings when loading the data
-- certain columns transformed from float to integer, might raise 'truncate' warnings
drop table if exists hc_microscopy_data_v2.experimental_data_sbw_cell_area_and_counts;
create table hc_microscopy_data_v2.experimental_data_sbw_cell_area_and_counts
(
date_label int,
experimental_well_label char(3),
timepoint smallint,
cells_total_area decimal(9,6),
number_of_cells smallint,
number_of_cells_with_foci smallint,
cells_with_0_foci_percentage decimal(9,6),
cells_with_0_foci smallint,
cells_with_1_focus_percentage decimal(9,6),
cells_with_1_focus smallint,
cells_with_multiple_foci_percentage decimal(9,6),
cells_with_multiple_foci smallint,
primary key (date_label, experimental_well_label, timepoint),
foreign key (date_label, experimental_well_label) references hc_microscopy_data_v2.strains_and_conditions_main(date_label, experimental_well_label)
on delete cascade
);


drop table if exists hc_microscopy_data_v2.experimental_data_scd_cell_area;
create table hc_microscopy_data_v2.experimental_data_scd_cell_area
(
date_label int,
experimental_well_label char(3),
timepoint smallint,
fov_cell_id varchar(7),
cell_area decimal(9,6),
primary key (date_label, experimental_well_label, timepoint, fov_cell_id),
foreign key (date_label, experimental_well_label, timepoint) references hc_microscopy_data_v2.experimental_data_sbw_cell_area_and_counts(date_label, experimental_well_label, timepoint)
on delete cascade
);


drop table if exists hc_microscopy_data_v2.experimental_data_sbw_cell_foci_intensity;
create table hc_microscopy_data_v2.experimental_data_sbw_cell_foci_intensity
(
date_label int,
experimental_well_label char(3),
timepoint smallint,
cells_avg_intensity_wv1 decimal(12,6),
cells_max_intensity_wv1 decimal(12,6),
cells_avg_intensity_wv2 decimal(12,6),
cells_max_intensity_wv2 decimal(12,6),
foci_intensity_wv2 decimal(12,6),
primary key (date_label, experimental_well_label, timepoint),
foreign key (date_label, experimental_well_label) references hc_microscopy_data_v2.strains_and_conditions_main(date_label, experimental_well_label)
on delete cascade
);


drop table if exists hc_microscopy_data_v2.experimental_data_scd_cell_foci_intensity;
create table hc_microscopy_data_v2.experimental_data_scd_cell_foci_intensity
(
date_label int,
experimental_well_label char(3),
timepoint smallint,
fov_cell_id varchar(7),
cells_intensity_wv1 decimal(12,6),
cells_max_intensity_wv1 decimal(12,6),
cells_intensity_wv2 decimal(12,6),
cells_max_intensity_wv2 decimal(12,6),
foci_intensity_wv2 decimal(12,6),
primary key (date_label, experimental_well_label, timepoint, fov_cell_id),
foreign key (date_label, experimental_well_label, timepoint) references hc_microscopy_data_v2.experimental_data_sbw_cell_foci_intensity(date_label, experimental_well_label, timepoint)
on delete cascade
);


drop table if exists hc_microscopy_data_v2.experimental_data_sbw_foci_number_and_size;
create table hc_microscopy_data_v2.experimental_data_sbw_foci_number_and_size
(
date_label int,
experimental_well_label char(3),
timepoint smallint,
avg_number_of_foci_per_cell decimal(8,6),
avg_size_single_focus decimal(8,6),
foci_total_area decimal(8,6),
primary key (date_label, experimental_well_label, timepoint),
foreign key (date_label, experimental_well_label) references hc_microscopy_data_v2.strains_and_conditions_main(date_label, experimental_well_label)
on delete cascade
);


drop table if exists hc_microscopy_data_v2.experimental_data_scd_foci_number_and_area;
create table hc_microscopy_data_v2.experimental_data_scd_foci_number_and_area
(
date_label int,
experimental_well_label char(3),
timepoint smallint,
fov_cell_id varchar(7),
number_of_foci tinyint,
total_foci_area decimal(8,6),
primary key (date_label, experimental_well_label, timepoint, fov_cell_id),
foreign key (date_label, experimental_well_label, timepoint) references hc_microscopy_data_v2.experimental_data_sbw_foci_number_and_size(date_label, experimental_well_label, timepoint)
on delete cascade
);


-- As-binding proteins
-- based on Lorentzon (2025), 'Table S4 Datasets', columns 'As-Biotin final 174' (in first submission, December 2024, j cell biol)
-- SGD descriptions
drop table if exists hc_microscopy_data_v2.as_interacting_proteins;
create table hc_microscopy_data_v2.as_interacting_proteins
(
systematic_name varchar(12) primary key,
standard_name varchar(12),
foreign key (systematic_name) references hc_microscopy_data_v2.sgd_descriptions(systematic_name)
on delete cascade
);


-- aggregated proteins (in presence of As)
-- based on Ibstedt 2014 (doi: 10.1242/bio.20148938)
-- copied from Lorentzon 2025, 'Table S4 Datasets', column 'Aggregated proteins in the presence of arsenite As(III) (WT cells) - (As-set in Ibstedt et al 2014)'  (in first submission, December 2024, j cell biol)
drop table if exists hc_microscopy_data_v2.aggregated_proteins;
create table hc_microscopy_data_v2.aggregated_proteins
(
systematic_name varchar(12) primary key,
standard_name varchar(12),
foreign key (systematic_name) references hc_microscopy_data_v2.sgd_descriptions(systematic_name)
on delete cascade
);


-- As-sensitive mutants (haploid)
-- based on 4 studies: , listed mutants indentified in at least one of the studies
-- copied from Lorentzon 2025, 'Table S4 Datasets', column 'Compendium As(III) sensitive (haploid) mutants Thorsen, Haugen, Zhou, Pan  (712 genes)'  (in first submission, December 2024, j cell biol)
-- 9 records not included:
			-- YAL043C-A: dubious ORF, YAR002aW: no SGD record, YCL012W: merged ORF, YCL060C: merged ORF, YFL056C: pseudogene, 
			-- YML033W: merged ORF, YML058C-A: dubious ORF, YML095C-A: dubious ORF, YOR031W: blocked reading frame
drop table if exists hc_microscopy_data_v2.as_sensitive_mutants;
create table hc_microscopy_data_v2.as_sensitive_mutants
(
systematic_name varchar(12) primary key,
standard_name varchar(12),
foreign key (systematic_name) references hc_microscopy_data_v2.sgd_descriptions(systematic_name)
on delete cascade
);
 

-- mutants with increased aggregation (upon As-exposure)
-- based on Andersson 2021 (doi: 10.1242/jcs.258338)
drop table if exists hc_microscopy_data_v2.increased_aggregation_mutants;
create table hc_microscopy_data_v2.increased_aggregation_mutants
(
systematic_name varchar(12) primary key,
standard_name varchar(12),
foreign key (systematic_name) references hc_microscopy_data_v2.sgd_descriptions(systematic_name)
on delete cascade
);


-- mutants with reduced aggregation (upon As-exposure)
-- based on Andersson 2021 (doi: 10.1242/jcs.258338)
-- 2 records dropped
		-- 'YDR134C': blocked reading frame, 'YMR158C-B': uncharacterized
drop table if exists hc_microscopy_data_v2.reduced_aggregation_mutants;
create table hc_microscopy_data_v2.reduced_aggregation_mutants
(
systematic_name varchar(12) primary key,
standard_name varchar(12),
foreign key (systematic_name) references hc_microscopy_data_v2.sgd_descriptions(systematic_name)
on delete cascade
);


-- TS reference group
-- TS collection, mutants with low cell counts (during TS screening 1st round) filtered out
-- serves as a reference group for clustering/functional enrichments of the identified hits
drop table if exists hc_microscopy_data_v2.ts_reference_group;
create table hc_microscopy_data_v2.ts_reference_group
(
systematic_name varchar(12) primary key,
standard_name varchar(12),
foreign key (systematic_name) references hc_microscopy_data_v2.sgd_descriptions(systematic_name)
on delete cascade
);


-- unique hits
-- mutants identified during the 1st round of TS screening as having an effect on any of the three stages
-- unique list of hits, no regards to a specific stage
drop table if exists hc_microscopy_data_v2.unique_hits;
create table hc_microscopy_data_v2.unique_hits
(
hit_systematic_name varchar(12) primary key,
hit_standard_name varchar(12),
foreign key (hit_systematic_name) references hc_microscopy_data_v2.sgd_descriptions(systematic_name)
on delete cascade
);


-- effect stage label
-- label for each hit, contains an effect and particular stage the effect applies on (e.g., decreased formation)
drop table if exists hc_microscopy_data_v2.effect_stage_labels;
create table hc_microscopy_data_v2.effect_stage_labels
(
effect_stage_label_id tinyint primary key,
effect_stage_label varchar(50)
);


-- clusters
-- unique cluster labels + id
drop table if exists hc_microscopy_data_v2.clusters;
create table hc_microscopy_data_v2.clusters
(
cluster_id smallint primary key,
cluster_label varchar(50)
);


-- enrichments
-- unique enrichments: id, category and gene ontology id and description
drop table if exists hc_microscopy_data_v2.enrichments;
create table hc_microscopy_data_v2.enrichments
(
enrichment_id smallint primary key,
go_enrichment_category varchar(30),
go_id varchar(30),
enrichment_description varchar(400)
);


-- cluster_enrichment
-- contains clusters and corresponding enrichments
-- junction table clusters-enrichments
drop table if exists hc_microscopy_data_v2.cluster_enrichment;
create table hc_microscopy_data_v2.cluster_enrichment
(
cluster_id smallint,
enrichment_id smallint,
strength decimal(3,2),
fdr decimal(7,6),
primary key(cluster_id, enrichment_id),
foreign key (cluster_id) references hc_microscopy_data_v2.clusters(cluster_id)
on delete cascade,
foreign key (enrichment_id) references hc_microscopy_data_v2.enrichments(enrichment_id)
on delete cascade
);


-- hits_clusters
-- hits with corresponding effect-stage and cluster (if applicable
-- junction table connecting unique_hits-clusters-effect_stage
drop table if exists hc_microscopy_data_v2.hits_clusters;
create table hc_microscopy_data_v2.hits_clusters
(
hit_systematic_name varchar(12),
effect_stage_label_id tinyint,
cluster_id smallint,
primary key(hit_systematic_name, effect_stage_label_id),
foreign key (hit_systematic_name) references hc_microscopy_data_v2.unique_hits(hit_systematic_name)
on delete cascade,
foreign key (effect_stage_label_id) references hc_microscopy_data_v2.effect_stage_labels(effect_stage_label_id)
on delete cascade,
foreign key (cluster_id) references hc_microscopy_data_v2.clusters(cluster_id)
on delete cascade
);
