use hc_microscopy_data_v2;
SET GLOBAL net_read_timeout = 600;
SET GLOBAL net_write_timeout = 600;



-- STORED PROCEDURE 1:  p_ts_screen_first_round_specific_plate_data:
		-- procedure returns all (unfiltered) data from the TS screening- 1st round for a specific collection plate
		-- data on percentage of cells containing aggregates, average size of a single aggregate and average number of aggregates per cell
drop procedure if exists hc_microscopy_data_v2.p_ts_screen_first_round_specific_plate_data;
delimiter //
create procedure hc_microscopy_data_v2.p_ts_screen_first_round_specific_plate_data(p_plate_label varchar(3))
begin

	with
	cte_TS_screen_first_round_dates as -- date labels for selected experiments (based on experiment type/subtype: 'TS collection screening'/'first round' and data quality: 'Good')
	(
	select distinct
		e.date_label
	from 
		experiments as e
	inner join 
		experiment_types as et
	on
		e.experiment_type_id= et.experiment_type_id
	where
		e.data_quality = 'Good' and
		et.experiment_type= 'TS collection screening' and
		et.experiment_subtype= 'first round'
	),
	cte_microscopy_interval_min as -- microscopy interval (in minutes) based on data quality and experiment type/subtype
	(
	select distinct
		microscopy_interval_min
	from 
		experiments
	where
		date_label in (select * from cte_TS_screen_first_round_dates)
	),
	cte_initital_delay_min as -- microscopy initial delay (in minutes) based on data quality and experiment type/subtype
	(
	select distinct
		microscopy_initial_delay_min
	from 
		experiments
	where
		date_label in (select * from cte_TS_screen_first_round_dates)
	)
	select -- selected columns and calculations
		scm.date_label,
		scm.collection_plate_label,
		scm.experimental_well_label,
		scm.mutated_gene_systematic_name,
		scm.mutated_gene_standard_name,
		scm.mutation,
		cac.timepoint * (select * from cte_microscopy_interval_min) - ((select * from cte_microscopy_interval_min) - (select * from cte_initital_delay_min)) as timepoint_minutes,
		cac.number_of_cells,
		round(cac.number_of_cells_with_foci/cac.number_of_cells*100,2) as percentage_of_cells_with_foci,
		nas.avg_number_of_foci_per_cell,
		nas.avg_size_single_focus
	from
		strains_and_conditions_main as scm
	inner join
		experimental_data_sbw_cell_area_and_counts as cac
	on
		scm.date_label= cac.date_label and 
		scm.experimental_well_label= cac.experimental_well_label
	inner join 
		experimental_data_sbw_foci_number_and_size as nas
	on
		cac.date_label= nas.date_label and 
		cac.experimental_well_label= nas.experimental_well_label and
		cac.timepoint=nas.timepoint
	where -- filtering to data from TS screening 1st round and specific plate label
		scm.date_label in (select * from cte_TS_screen_first_round_dates) and
        scm.collection_plate_label= p_plate_label;

end//
delimiter ;
-- call p_ts_screen_first_round_specific_plate_data('1A');



-- STORED PROCEDURE 2:  p_ts_screen_first_round_specific_genes:
		-- procedure returns all (unfiltered) data from the TS screening- 1st round for a specific set of genes (all alleles/mutations) with minimal cell coounts and within range of defined timepoints (in minutes)
		-- data on percentage of cells containing aggregates, average size of a single aggregate and average number of aggregates per cell
drop procedure if exists hc_microscopy_data_v2.p_ts_screen_first_round_specific_genes;
delimiter //
create procedure hc_microscopy_data_v2.p_ts_screen_first_round_specific_genes(in p_gene_list json, in p_starting_timepoint_min smallint, in p_ending_timepoint_min smallint, in p_min_cell_count int)
-- define list of selected mutants (p_gene_list) in format '["GENE1", "GENE2", etc...]', not necessary to include 'wt control'
-- define starting (p_starting_timepoint_min)  and ending (p_ending_timepoint_min) timepoints as integers
-- define minimal cell count (p_min_cell_count) as integer 
begin
	with 
	cte1_gene_list as -- transforms the list of selected mutants (p_gene_list) into a json table
	(
	select
		*
	from
		json_table(p_gene_list, '$[*]' columns(standard_name varchar(12) path '$')) as gene_list
	),
	cte2_selected_experiments as -- list of experiments (date_label) where the selected mutants were analysed, only 'Good' quality data
	(
	select distinct
		scm.date_label
	from 
		hc_microscopy_data_v2.strains_and_conditions_main as scm
	inner join 
		hc_microscopy_data_v2.experiments as e 
	on 
		scm.date_label=e.date_label
	inner join
		hc_microscopy_data_v2.experiment_types as et
	on
		e.experiment_type_id=et.experiment_type_id
	where 
		scm.mutated_gene_standard_name in (select distinct * from cte1_gene_list) and 
		scm.mutated_gene_standard_name != 'wt control' and
		e.data_quality='Good' and
		et.experiment_type= 'TS collection screening' and
        et.experiment_subtype= 'first round'
	),
	cte3_microscopy_interval_min as -- microscopy interval for TS collection screening, 1st round
	(
	select distinct
		e.microscopy_interval_min 
	from 
		hc_microscopy_data_v2.experiments as e
	inner join
		hc_microscopy_data_v2.experiment_types as et
	on
		e.experiment_type_id=et.experiment_type_id
	where
		et.experiment_type= 'TS collection screening' and
        et.experiment_subtype= 'first round'
	),
	cte4_microscopy_initial_delay_min as -- initial delay for TS collection screening, 1st round
	(
	select distinct
		e.microscopy_initial_delay_min 
	from 
		hc_microscopy_data_v2.experiments as e
	inner join
		hc_microscopy_data_v2.experiment_types as et
	on
		e.experiment_type_id=et.experiment_type_id
	where
		et.experiment_type= 'TS collection screening' and
        et.experiment_subtype= 'first round'
	)
    select -- data for 'wt control' from selected experiment (date_label), averaged per each experiment (date_label, one control dataset per each experiment)
		control_data.mutated_gene_standard_name,
        control_data.mutation,
        control_data.timepoint_minutes,
        avg(control_data.percentage_of_cells_with_foci) as percentage_of_cells_with_foci,
        avg(control_data.avg_number_of_foci_per_cell) as avg_number_of_foci_per_cell,
        avg(control_data.avg_size_single_focus) as avg_size_single_focus
	from
    (
	select 
		scm.date_label,
        scm.experimental_well_label,
        scm.mutated_gene_standard_name,
        scm.mutation,
		cac.timepoint * (select * from cte3_microscopy_interval_min) - ((select * from cte3_microscopy_interval_min) - (select * from cte4_microscopy_initial_delay_min)) as timepoint_minutes,
        round(cac.number_of_cells_with_foci/cac.number_of_cells*100,2) as percentage_of_cells_with_foci,
        nas.avg_number_of_foci_per_cell,
        nas.avg_size_single_focus
	from 
		hc_microscopy_data_v2.strains_and_conditions_main as scm
	inner join
		hc_microscopy_data_v2.experimental_data_sbw_cell_area_and_counts as cac
	on
		scm.date_label= cac.date_label and
        scm.experimental_well_label= cac.experimental_well_label
	inner join
		hc_microscopy_data_v2.experimental_data_sbw_foci_number_and_size as nas
	on
		cac.date_label=nas.date_label and
        cac.experimental_well_label=nas.experimental_well_label and
        cac.timepoint=nas.timepoint
	where
		scm.date_label in (select * from cte2_selected_experiments) and
        scm.mutation = 'wt control' and
        cac.number_of_cells > p_min_cell_count
	) as control_data
    where
		control_data.timepoint_minutes >= p_starting_timepoint_min and
        control_data.timepoint_minutes <= p_ending_timepoint_min
	group by
		control_data.date_label,
        control_data.mutated_gene_standard_name,
        control_data.mutation,
        control_data.timepoint_minutes
	-- ----------------
    union
    -- ----------------
    select -- data for selected genes (cte1_gene_list), averaged per each allele (mutation, one dataset per each mutation)
		mutant_data.mutated_gene_standard_name,
        mutant_data.mutation,
        mutant_data.timepoint_minutes,
        avg(mutant_data.percentage_of_cells_with_foci) as percentage_of_cells_with_foci,
        avg(mutant_data.avg_number_of_foci_per_cell) as avg_number_of_foci_per_cell,
        avg(mutant_data.avg_size_single_focus) as avg_size_single_focus
	from
    (
	select 
		scm.date_label,
        scm.experimental_well_label,
        scm.mutated_gene_standard_name,
        scm.mutation,
		cac.timepoint * (select * from cte3_microscopy_interval_min) - ((select * from cte3_microscopy_interval_min) - (select * from cte4_microscopy_initial_delay_min)) as timepoint_minutes,
        round(cac.number_of_cells_with_foci/cac.number_of_cells*100,2) as percentage_of_cells_with_foci,
        nas.avg_number_of_foci_per_cell,
        nas.avg_size_single_focus
	from 
		hc_microscopy_data_v2.strains_and_conditions_main as scm
	inner join
		hc_microscopy_data_v2.experimental_data_sbw_cell_area_and_counts as cac
	on
		scm.date_label= cac.date_label and
        scm.experimental_well_label= cac.experimental_well_label
	inner join
		hc_microscopy_data_v2.experimental_data_sbw_foci_number_and_size as nas
	on
		cac.date_label=nas.date_label and
        cac.experimental_well_label=nas.experimental_well_label and
        cac.timepoint=nas.timepoint
	where
        scm.mutated_gene_standard_name in (select * from cte1_gene_list) and
        cac.number_of_cells > p_min_cell_count
	) as mutant_data
    where
		mutant_data.timepoint_minutes >= p_starting_timepoint_min and
        mutant_data.timepoint_minutes <= p_ending_timepoint_min
	group by
        mutant_data.mutated_gene_standard_name,
        mutant_data.mutation,
        mutant_data.timepoint_minutes
    ;
end //
delimiter ;
-- call p_ts_screen_first_round_specific_genes('["ACT1", "LCB1", "LCB2", "LCB3"]', 0, 400, 100);



-- STORED PROCEDURE 3:  p_ts_screen_first_round_keyword:
		-- procedure returns all (unfiltered) data from the TS screening- 1st round for a specific keyword to search in the 'sgd_description table' - 'description' column with minimal cell coounts and within range of defined timepoints (in minutes)
		-- data on percentage of cells containing aggregates, average size of a single aggregate and average number of aggregates per cell
drop procedure if exists hc_microscopy_data_v2.p_ts_screen_first_round_keyword;
delimiter //
create procedure hc_microscopy_data_v2.p_ts_screen_first_round_keyword(in p_keyword varchar(50), in p_starting_timepoint_min smallint, in p_ending_timepoint_min smallint, in p_min_cell_count int)
-- define keyword in format:  '(^|\\s)keyword(\\s|$)'
-- define starting (p_starting_timepoint_min)  and ending (p_ending_timepoint_min) timepoints as integers
-- define minimal cell count (p_min_cell_count) as integer 
begin
	with 
	cte1_gene_list as -- search the keyword (p_keyword) in sgd descriptions and return corresponding gene list
	(
	select distinct
		standard_name
	from
		sgd_descriptions
	where
		LOWER(description) REGEXP(p_keyword)
	),
	cte2_selected_experiments as -- list of experiments (date_label) where the selected mutants were analysed, only 'Good' quality data
	(
	select distinct
		scm.date_label
	from 
		hc_microscopy_data_v2.strains_and_conditions_main as scm
	inner join 
		hc_microscopy_data_v2.experiments as e 
	on 
		scm.date_label=e.date_label
	inner join
		hc_microscopy_data_v2.experiment_types as et
	on
		e.experiment_type_id=et.experiment_type_id
	where 
		scm.mutated_gene_standard_name in (select distinct * from cte1_gene_list) and 
		scm.mutated_gene_standard_name != 'wt control' and
		e.data_quality='Good' and
		et.experiment_type= 'TS collection screening' and
        et.experiment_subtype= 'first round'
	),
	cte3_microscopy_interval_min as -- microscopy interval for TS collection screening, 1st round
	(
	select distinct
		e.microscopy_interval_min 
	from 
		hc_microscopy_data_v2.experiments as e
	inner join
		hc_microscopy_data_v2.experiment_types as et
	on
		e.experiment_type_id=et.experiment_type_id
	where
		et.experiment_type= 'TS collection screening' and
        et.experiment_subtype= 'first round'
	),
	cte4_microscopy_initial_delay_min as -- initial delay for TS collection screening, 1st round
	(
	select distinct
		e.microscopy_initial_delay_min 
	from 
		hc_microscopy_data_v2.experiments as e
	inner join
		hc_microscopy_data_v2.experiment_types as et
	on
		e.experiment_type_id=et.experiment_type_id
	where
		et.experiment_type= 'TS collection screening' and
        et.experiment_subtype= 'first round'
	)
    select -- data for 'wt control' from selected experiment (date_label), averaged per each experiment (date_label, one control dataset per each experiment)
		control_data.mutated_gene_standard_name,
        control_data.mutation,
        control_data.timepoint_minutes,
        avg(control_data.percentage_of_cells_with_foci) as percentage_of_cells_with_foci,
        avg(control_data.avg_number_of_foci_per_cell) as avg_number_of_foci_per_cell,
        avg(control_data.avg_size_single_focus) as avg_size_single_focus
	from
    (
	select 
		scm.date_label,
        scm.experimental_well_label,
        scm.mutated_gene_standard_name,
        scm.mutation,
		cac.timepoint * (select * from cte3_microscopy_interval_min) - ((select * from cte3_microscopy_interval_min) - (select * from cte4_microscopy_initial_delay_min)) as timepoint_minutes,
        round(cac.number_of_cells_with_foci/cac.number_of_cells*100,2) as percentage_of_cells_with_foci,
        nas.avg_number_of_foci_per_cell,
        nas.avg_size_single_focus
	from 
		hc_microscopy_data_v2.strains_and_conditions_main as scm
	inner join
		hc_microscopy_data_v2.experimental_data_sbw_cell_area_and_counts as cac
	on
		scm.date_label= cac.date_label and
        scm.experimental_well_label= cac.experimental_well_label
	inner join
		hc_microscopy_data_v2.experimental_data_sbw_foci_number_and_size as nas
	on
		cac.date_label=nas.date_label and
        cac.experimental_well_label=nas.experimental_well_label and
        cac.timepoint=nas.timepoint
	where
		scm.date_label in (select * from cte2_selected_experiments) and
        scm.mutation = 'wt control' and
        cac.number_of_cells > p_min_cell_count
	) as control_data
    where
		control_data.timepoint_minutes >= p_starting_timepoint_min and
        control_data.timepoint_minutes <= p_ending_timepoint_min
	group by
		control_data.date_label,
        control_data.mutated_gene_standard_name,
        control_data.mutation,
        control_data.timepoint_minutes
	-- ----------------
    union
    -- ----------------
    select -- data for selected genes (cte1_gene_list), averaged per each allele (mutation, one dataset per each mutation)
		mutant_data.mutated_gene_standard_name,
        mutant_data.mutation,
        mutant_data.timepoint_minutes,
        avg(mutant_data.percentage_of_cells_with_foci) as percentage_of_cells_with_foci,
        avg(mutant_data.avg_number_of_foci_per_cell) as avg_number_of_foci_per_cell,
        avg(mutant_data.avg_size_single_focus) as avg_size_single_focus
	from
    (
	select 
		scm.date_label,
        scm.experimental_well_label,
        scm.mutated_gene_standard_name,
        scm.mutation,
		cac.timepoint * (select * from cte3_microscopy_interval_min) - ((select * from cte3_microscopy_interval_min) - (select * from cte4_microscopy_initial_delay_min)) as timepoint_minutes,
        round(cac.number_of_cells_with_foci/cac.number_of_cells*100,2) as percentage_of_cells_with_foci,
        nas.avg_number_of_foci_per_cell,
        nas.avg_size_single_focus
	from 
		hc_microscopy_data_v2.strains_and_conditions_main as scm
	inner join
		hc_microscopy_data_v2.experimental_data_sbw_cell_area_and_counts as cac
	on
		scm.date_label= cac.date_label and
        scm.experimental_well_label= cac.experimental_well_label
	inner join
		hc_microscopy_data_v2.experimental_data_sbw_foci_number_and_size as nas
	on
		cac.date_label=nas.date_label and
        cac.experimental_well_label=nas.experimental_well_label and
        cac.timepoint=nas.timepoint
	where
        scm.mutated_gene_standard_name in (select * from cte1_gene_list) and
        cac.number_of_cells > p_min_cell_count
	) as mutant_data
    where
		mutant_data.timepoint_minutes >= p_starting_timepoint_min and
        mutant_data.timepoint_minutes <= p_ending_timepoint_min
	group by
        mutant_data.mutated_gene_standard_name,
        mutant_data.mutation,
        mutant_data.timepoint_minutes
    ;
end //
delimiter ;
-- call p_ts_screen_first_round_keyword('(^|\\s)sphingolipid(\\s|$)', 0, 400, 100);


    
-- STORED PROCEDURE 4:  p_ts_screen_first_round_gene_ontology_based:
		-- procedure returns all (unfiltered) data from the TS screening- 1st round for a specific set of gene-ontology based genes (all alleles/mutations) with minimal cell coounts and within range of defined timepoints (in minutes)
		-- data on percentage of cells containing aggregates, average size of a single aggregate and average number of aggregates per cell
drop procedure if exists hc_microscopy_data_v2.p_ts_screen_first_round_gene_ontology_based;
delimiter //
create procedure hc_microscopy_data_v2.p_ts_screen_first_round_gene_ontology_based(in p_sgd_id_list json, in p_starting_timepoint_min smallint, in p_ending_timepoint_min smallint, in p_min_cell_count int)
-- define list of selected genes by sgd_id (p_sgd_id_list) in format '["S000000001", "S000000002", etc...]', not necessary to include 'wt control'
-- define starting (p_starting_timepoint_min)  and ending (p_ending_timepoint_min) timepoints as integers
-- define minimal cell count (p_min_cell_count) as integer 
begin
	with 
	cte1_sgd_id as -- transforms the list of sgd IDs into a json table
	(
	select
		*
	from
		json_table(p_sgd_id_list, '$[*]' columns(standard_name varchar(12) path '$')) as sgd_id_list
	),
    cte2_selected_genes as
    (
    select distinct
		standard_name
	from 
		sgd_descriptions
	where
		sgd_id in (select * from cte1_sgd_id)
    ),
	cte3_selected_experiments as -- list of experiments (date_label) where the selected mutants were analysed, only 'Good' quality data
	(
	select distinct
		scm.date_label
	from 
		hc_microscopy_data_v2.strains_and_conditions_main as scm
	inner join 
		hc_microscopy_data_v2.experiments as e 
	on 
		scm.date_label=e.date_label
	inner join
		hc_microscopy_data_v2.experiment_types as et
	on
		e.experiment_type_id=et.experiment_type_id
	where 
		scm.mutated_gene_standard_name in (select distinct * from cte2_selected_genes) and 
		scm.mutated_gene_standard_name != 'wt control' and
		e.data_quality='Good' and
		et.experiment_type= 'TS collection screening' and
        et.experiment_subtype= 'first round'
	),
	cte4_microscopy_interval_min as -- microscopy interval for TS collection screening, 1st round
	(
	select distinct
		e.microscopy_interval_min 
	from 
		hc_microscopy_data_v2.experiments as e
	inner join
		hc_microscopy_data_v2.experiment_types as et
	on
		e.experiment_type_id=et.experiment_type_id
	where
		et.experiment_type= 'TS collection screening' and
        et.experiment_subtype= 'first round'
	),
	cte5_microscopy_initial_delay_min as -- initial delay for TS collection screening, 1st round
	(
	select distinct
		e.microscopy_initial_delay_min 
	from 
		hc_microscopy_data_v2.experiments as e
	inner join
		hc_microscopy_data_v2.experiment_types as et
	on
		e.experiment_type_id=et.experiment_type_id
	where
		et.experiment_type= 'TS collection screening' and
        et.experiment_subtype= 'first round'
	)
    select -- data for 'wt control' from selected experiment (date_label), averaged per each experiment (date_label, one control dataset per each experiment)
		concat(cast(control_data.date_label as CHAR), ' ', control_data.mutated_gene_standard_name, 'wt control') as mutated_gene_standard_name, -- added as a specific label for each full 'wt control' dataset (instead of the mutated_gene_standard_name)
        control_data.mutation,
        control_data.timepoint_minutes,
        avg(control_data.percentage_of_cells_with_foci) as percentage_of_cells_with_foci,
        avg(control_data.avg_number_of_foci_per_cell) as avg_number_of_foci_per_cell,
        avg(control_data.avg_size_single_focus) as avg_size_single_focus
	from
    (
	select 
		scm.date_label,
        scm.experimental_well_label,
        scm.mutated_gene_standard_name,
        scm.mutation,
		cac.timepoint * (select * from cte4_microscopy_interval_min) - ((select * from cte4_microscopy_interval_min) - (select * from cte5_microscopy_initial_delay_min)) as timepoint_minutes,
        round(cac.number_of_cells_with_foci/cac.number_of_cells*100,2) as percentage_of_cells_with_foci,
        nas.avg_number_of_foci_per_cell,
        nas.avg_size_single_focus
	from 
		hc_microscopy_data_v2.strains_and_conditions_main as scm
	inner join
		hc_microscopy_data_v2.experimental_data_sbw_cell_area_and_counts as cac
	on
		scm.date_label= cac.date_label and
        scm.experimental_well_label= cac.experimental_well_label
	inner join
		hc_microscopy_data_v2.experimental_data_sbw_foci_number_and_size as nas
	on
		cac.date_label=nas.date_label and
        cac.experimental_well_label=nas.experimental_well_label and
        cac.timepoint=nas.timepoint
	where
		scm.date_label in (select * from cte3_selected_experiments) and
        scm.mutation = 'wt control' and
        cac.number_of_cells > p_min_cell_count
	) as control_data
    where
		control_data.timepoint_minutes >= p_starting_timepoint_min and
        control_data.timepoint_minutes <= p_ending_timepoint_min
	group by
		control_data.date_label,
        -- control_data.mutated_gene_standard_name,
        concat(cast(control_data.date_label as CHAR), ' ', control_data.mutated_gene_standard_name, 'wt control'),
        control_data.mutation,
        control_data.timepoint_minutes
	-- ----------------
    union
    -- ----------------
    select -- data for selected genes (cte1_gene_list), averaged per each allele (mutation, one dataset per each mutation)
		mutant_data.mutated_gene_standard_name,
        mutant_data.mutation,
        mutant_data.timepoint_minutes,
        avg(mutant_data.percentage_of_cells_with_foci) as percentage_of_cells_with_foci,
        avg(mutant_data.avg_number_of_foci_per_cell) as avg_number_of_foci_per_cell,
        avg(mutant_data.avg_size_single_focus) as avg_size_single_focus
	from
    (
	select 
		scm.date_label,
        scm.experimental_well_label,
        scm.mutated_gene_standard_name,
        scm.mutation,
		cac.timepoint * (select * from cte4_microscopy_interval_min) - ((select * from cte4_microscopy_interval_min) - (select * from cte5_microscopy_initial_delay_min)) as timepoint_minutes,
        round(cac.number_of_cells_with_foci/cac.number_of_cells*100,2) as percentage_of_cells_with_foci,
        nas.avg_number_of_foci_per_cell,
        nas.avg_size_single_focus
	from 
		hc_microscopy_data_v2.strains_and_conditions_main as scm
	inner join
		hc_microscopy_data_v2.experimental_data_sbw_cell_area_and_counts as cac
	on
		scm.date_label= cac.date_label and
        scm.experimental_well_label= cac.experimental_well_label
	inner join
		hc_microscopy_data_v2.experimental_data_sbw_foci_number_and_size as nas
	on
		cac.date_label=nas.date_label and
        cac.experimental_well_label=nas.experimental_well_label and
        cac.timepoint=nas.timepoint
	where
        scm.mutated_gene_standard_name in (select * from cte2_selected_genes) and
        cac.number_of_cells > p_min_cell_count
	) as mutant_data
    where
		mutant_data.timepoint_minutes >= p_starting_timepoint_min and
        mutant_data.timepoint_minutes <= p_ending_timepoint_min
	group by
        mutant_data.mutated_gene_standard_name,
        mutant_data.mutation,
        mutant_data.timepoint_minutes
    ;
end //
delimiter ;
-- call hc_microscopy_data_v2.p_ts_screen_first_round_gene_ontology_based('["S000003538", "S000004557"]', 0, 400, 0);




-- STORED PROCEDURE 5: p_parameter_per_mutant_and_stage
		-- pivot table, index: Mutation, Columns: Stages, data: avg percentage/size/number per stage
        -- data grouped per experiment/plate, duplicated records will occur (especially for the 'wt control')
        -- parameters: p_rf_start= start of the relocation & fusion stage, p_cl_start= start of the clearance stage (both in minutes), p_initital_skipped_timepoints
drop procedure if exists hc_microscopy_data_v2.p_parameter_per_mutant_and_stage;
delimiter //
create procedure hc_microscopy_data_v2.p_parameter_per_mutant_and_stage(in p_initital_skipped_timepoints int, in p_form_start int, in p_rf_start int, in p_cl_start int)
begin

	with
	cte_TS_screen_first_round_dates as -- date labels for selected experiments (based on experiment type/subtype: 'TS collection screening'/'first round' and data quality: 'Good')
	(
	select distinct
		e.date_label
	from 
		experiments as e
	inner join 
		experiment_types as et
	on
		e.experiment_type_id= et.experiment_type_id
	where
		e.data_quality = 'Good' and
		et.experiment_type= 'TS collection screening' and
		et.experiment_subtype= 'first round'
	),
	cte_microscopy_interval_min as -- microscopy interval (in minutes) based on data quality and experiment type/subtype
	(
	select distinct
		microscopy_interval_min
	from 
		experiments
	where
		date_label in (select * from cte_TS_screen_first_round_dates)
	),
	cte_initital_delay_min as -- microscopy initial delay (in minutes) based on data quality and experiment type/subtype
	(
	select distinct
		microscopy_initial_delay_min
	from 
		experiments
	where
		date_label in (select * from cte_TS_screen_first_round_dates)
	)
    select -- outer query, pivot
		a.date_label as experiment_id,
        a.mutated_gene_standard_name,
        a.mutation,
        avg(case when a.stage= 'formation' then a.percentage_of_cells_with_foci else null end) as perc_formation,
        avg(case when a.stage= 'formation' then a.avg_number_of_foci_per_cell else null end) as no_formation,
        avg(case when a.stage= 'formation' then a.avg_size_single_focus else null end) as size_formation,
        avg(case when a.stage= 'relocation & fusion' then a.percentage_of_cells_with_foci else null end) as perc_relocation_and_fusion,
        avg(case when a.stage= 'relocation & fusion' then a.avg_number_of_foci_per_cell else null end) as no_relocation_and_fusion,
        avg(case when a.stage= 'relocation & fusion' then a.avg_size_single_focus else null end) as size_relocation_and_fusion,
        avg(case when a.stage= 'clearance' then a.percentage_of_cells_with_foci else null end) as perc_clearance,
        avg(case when a.stage= 'clearance' then a.avg_number_of_foci_per_cell else null end) as no_clearance,
        avg(case when a.stage= 'clearance' then a.avg_size_single_focus else null end) as size_clearance
	from
    (
	select -- selected columns and calculations, inner query, stage definitions
		scm.date_label,
        scm.mutated_gene_standard_name,
		scm.mutation,
		-- cac.timepoint * (select * from cte_microscopy_interval_min) - ((select * from cte_microscopy_interval_min) - (select * from cte_initital_delay_min)) as timepoint_minutes,
		cac.number_of_cells_with_foci/cac.number_of_cells*100 as percentage_of_cells_with_foci,
		nas.avg_number_of_foci_per_cell,
		nas.avg_size_single_focus,
        case
			when cac.timepoint * (select * from cte_microscopy_interval_min) - ((select * from cte_microscopy_interval_min) - (select * from cte_initital_delay_min)) > p_form_start and cac.timepoint * (select * from cte_microscopy_interval_min) - ((select * from cte_microscopy_interval_min) - (select * from cte_initital_delay_min)) <= p_rf_start then 'formation'
            when cac.timepoint * (select * from cte_microscopy_interval_min) - ((select * from cte_microscopy_interval_min) - (select * from cte_initital_delay_min)) > p_rf_start and cac.timepoint * (select * from cte_microscopy_interval_min) - ((select * from cte_microscopy_interval_min) - (select * from cte_initital_delay_min)) <= p_cl_start then 'relocation & fusion'
            when cac.timepoint * (select * from cte_microscopy_interval_min) - ((select * from cte_microscopy_interval_min) - (select * from cte_initital_delay_min)) > p_cl_start then 'clearance' 
		end as stage  
	from
		strains_and_conditions_main as scm
	inner join
		experimental_data_sbw_cell_area_and_counts as cac
	on
		scm.date_label= cac.date_label and 
		scm.experimental_well_label= cac.experimental_well_label
	inner join 
		experimental_data_sbw_foci_number_and_size as nas
	on
		cac.date_label= nas.date_label and 
		cac.experimental_well_label= nas.experimental_well_label and
		cac.timepoint=nas.timepoint
	where -- filtering to data from TS screening 1st round
		scm.date_label in (select * from cte_TS_screen_first_round_dates) and
        cac.timepoint > p_initital_skipped_timepoints
	) as a
    group by
		a.date_label,
        a.mutated_gene_standard_name,
        a.mutation;

end//
delimiter ;
-- call p_parameter_per_mutant_and_stage(3, 45, 120, 300);




-- STORED PROCEDURE 6: p_percentage_per_mutant_and_stage_ranked
		-- procedure serves to see the most affected alleles (mutations), might be of interest when selecting mutants for follow-up experiments
		-- returns data on percentage of cells containing aggregates, averaged per stage for selected number of alleles of a selected gene, also contains a corresponding control data
        -- if multiple copies of one allele present: averaged
        -- controls are averaged per plate
        -- data grouped per experiment/plate
        -- parameters: p_rf_start= start of the relocation & fusion stage, p_cl_start= start of the clearance stage (both in minutes),p_initital_skipped_timepoints
drop procedure if exists hc_microscopy_data_v2.p_percentage_per_mutant_and_stage_ranked;
delimiter //
create procedure hc_microscopy_data_v2.p_percentage_per_mutant_and_stage_ranked(in p_initital_skipped_timepoints int, in p_form_start int, in p_rf_start int, in p_cl_start int, in p_selected_stage varchar(30), in p_selected_gene varchar(6), in p_max_rank int)
begin

	with
	cte_TS_screen_first_round_dates as -- date labels for selected experiments (based on experiment type/subtype: 'TS collection screening'/'first round' and data quality: 'Good')
	(
	select distinct
		e.date_label
	from 
		experiments as e
	inner join 
		experiment_types as et
	on
		e.experiment_type_id= et.experiment_type_id
	where
		e.data_quality = 'Good' and
		et.experiment_type= 'TS collection screening' and
		et.experiment_subtype= 'first round'
	),
	cte_microscopy_interval_min as -- microscopy interval (in minutes) based on data quality and experiment type/subtype
	(
	select distinct
		microscopy_interval_min
	from 
		experiments
	where
		date_label in (select * from cte_TS_screen_first_round_dates)
	),
	cte_initital_delay_min as -- microscopy initial delay (in minutes) based on data quality and experiment type/subtype
	(
	select distinct
		microscopy_initial_delay_min
	from 
		experiments
	where
		date_label in (select * from cte_TS_screen_first_round_dates)
	)
    select -- outer query, filtering by rank and gene
		b.gene,
        b.experiment_id,
        b.mutation,
        b.ranking,
        b.stage,
        b.percentage_of_cells_with_foci,
        control.corresponding_control
	from
    (
    select -- outer query, averaging and ranking
        a.mutated_gene_standard_name as gene,
		a.date_label as experiment_id,
        a.mutation,
        a.stage,
        avg(a.percentage_of_cells_with_foci) as percentage_of_cells_with_foci,
        row_number() over (partition by a.mutated_gene_standard_name order by avg(a.percentage_of_cells_with_foci) desc) as ranking
	from
    (
	select -- selected columns and calculations, inner query, stage definitions
		scm.date_label,
        scm.mutated_gene_standard_name,
		scm.mutation,
		-- cac.timepoint * (select * from cte_microscopy_interval_min) - ((select * from cte_microscopy_interval_min) - (select * from cte_initital_delay_min)) as timepoint_minutes,
		cac.number_of_cells_with_foci/cac.number_of_cells*100 as percentage_of_cells_with_foci,
        case
			when cac.timepoint * (select * from cte_microscopy_interval_min) - ((select * from cte_microscopy_interval_min) - (select * from cte_initital_delay_min)) > p_form_start and cac.timepoint * (select * from cte_microscopy_interval_min) - ((select * from cte_microscopy_interval_min) - (select * from cte_initital_delay_min)) <= p_rf_start then 'formation'
            when cac.timepoint * (select * from cte_microscopy_interval_min) - ((select * from cte_microscopy_interval_min) - (select * from cte_initital_delay_min)) > p_rf_start and cac.timepoint * (select * from cte_microscopy_interval_min) - ((select * from cte_microscopy_interval_min) - (select * from cte_initital_delay_min)) <= p_cl_start then 'relocation & fusion'
            when cac.timepoint * (select * from cte_microscopy_interval_min) - ((select * from cte_microscopy_interval_min) - (select * from cte_initital_delay_min)) > p_cl_start then 'clearance' 
		end as stage  
	from
		strains_and_conditions_main as scm
	inner join
		experimental_data_sbw_cell_area_and_counts as cac
	on
		scm.date_label= cac.date_label and 
		scm.experimental_well_label= cac.experimental_well_label
	inner join 
		experimental_data_sbw_foci_number_and_size as nas
	on
		cac.date_label= nas.date_label and 
		cac.experimental_well_label= nas.experimental_well_label and
		cac.timepoint=nas.timepoint
	where -- filtering to data from TS screening 1st round
		scm.date_label in (select * from cte_TS_screen_first_round_dates) and
        cac.timepoint > p_initital_skipped_timepoints
	) as a
    where
		a.stage= p_selected_stage
    group by
		a.date_label,
        a.mutated_gene_standard_name,
        a.mutation,
        a.stage
	) as b
    inner join
    ( -- subquery: corresponding control data
    select
		c.date_label,
        avg(c.percentage_of_cells_with_foci) as corresponding_control
	from
    (
	select -- selected columns and calculations, inner query, stage definitions
		scm.date_label,
        scm.mutated_gene_standard_name,
		scm.mutation,
		-- cac.timepoint * (select * from cte_microscopy_interval_min) - ((select * from cte_microscopy_interval_min) - (select * from cte_initital_delay_min)) as timepoint_minutes,
		cac.number_of_cells_with_foci/cac.number_of_cells*100 as percentage_of_cells_with_foci,
        case
			when cac.timepoint * (select * from cte_microscopy_interval_min) - ((select * from cte_microscopy_interval_min) - (select * from cte_initital_delay_min)) > p_form_start and cac.timepoint * (select * from cte_microscopy_interval_min) - ((select * from cte_microscopy_interval_min) - (select * from cte_initital_delay_min)) <= p_rf_start then 'formation'
            when cac.timepoint * (select * from cte_microscopy_interval_min) - ((select * from cte_microscopy_interval_min) - (select * from cte_initital_delay_min)) > p_rf_start and cac.timepoint * (select * from cte_microscopy_interval_min) - ((select * from cte_microscopy_interval_min) - (select * from cte_initital_delay_min)) <= p_cl_start then 'relocation & fusion'
            when cac.timepoint * (select * from cte_microscopy_interval_min) - ((select * from cte_microscopy_interval_min) - (select * from cte_initital_delay_min)) > p_cl_start then 'clearance' 
		end as stage  
	from
		strains_and_conditions_main as scm
	inner join
		experimental_data_sbw_cell_area_and_counts as cac
	on
		scm.date_label= cac.date_label and 
		scm.experimental_well_label= cac.experimental_well_label
	inner join 
		experimental_data_sbw_foci_number_and_size as nas
	on
		cac.date_label= nas.date_label and 
		cac.experimental_well_label= nas.experimental_well_label and
		cac.timepoint=nas.timepoint
	where -- filtering to data from TS screening 1st round
		scm.date_label in (select * from cte_TS_screen_first_round_dates) and
        cac.timepoint > p_initital_skipped_timepoints and
        scm.mutation= 'wt control'
	) as c
    where
		c.stage= p_selected_stage
	group by
		c.date_label,
        c.mutated_gene_standard_name,
        c.mutation
    ) as control
    on
		control.date_label=b.experiment_id
    where
		b.gene= p_selected_gene and
        b.ranking <= p_max_rank;

end//
delimiter ;
-- call p_percentage_per_mutant_and_stage_ranked(3, 45, 120, 290, 'clearance', 'PRE2', 7);
