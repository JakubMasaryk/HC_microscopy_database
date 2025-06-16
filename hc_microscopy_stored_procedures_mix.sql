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



-- STORED PROCEDURE 8:
-- returns single-cell data on agg. no. from selected mutants (SGD ID-based, exported from Gene Ontology) and corresponding wt controls (pooled together)
-- inputs: 'p_sgd_id_list'- list of mutated genes, 'p_reference_timepoint'- first selected timepoint, 'p_selected_timepoint'- second selected timepoint
drop procedure if exists hc_microscopy_data_v2.p_number_of_foci_single_cell_data_wt_vs_group_two_timepoints;
delimiter //
create procedure hc_microscopy_data_v2.p_number_of_foci_single_cell_data_wt_vs_group_two_timepoints(in p_sgd_id_list json, in p_reference_timepoint decimal(4,1), in p_selected_timepoint decimal(4,1))
begin
	with 
	cte_sgd_id_list as -- transforms the list of sgd IDs into a json table
	(
	select
		*
	from
		json_table(p_sgd_id_list, '$[*]' columns(standard_name varchar(12) path '$')) as sgd_id_list
	),
	cte_GO_selected_strains as -- sgd IDs (from GO) to systematic names
	(
	select distinct	
		systematic_name
	from
		sgd_descriptions
	where
		sgd_id in (select * from cte_sgd_id_list)
	),
	cte_selected_experiments as -- selected experiments (datel_labels) to draw controls from
	(
	select distinct	
		e.date_label
	from
		experiments as e
	inner join 
		experiment_types as et
	on
		e.experiment_type_id=et.experiment_type_id
	inner join
		strains_and_conditions_main as sac
	on
		sac.date_label=e.date_label
	where
		et.experiment_type= 'TS collection screening' and
		et.experiment_subtype= 'first round' and
		e.data_quality = 'Good' and
		sac.mutated_gene_systematic_name in (select * from cte_GO_selected_strains)
	),
	cte_microscopy_interval as -- microscopy interval for TS screen (1st round)
	(
	select distinct
		microscopy_interval_min
	from
		experiments
	where
		date_label in (select * from cte_selected_experiments)
	),
	cte_microscopy_initial_delay as -- microscopy initial delay for TS screen (1st round)
	(
	select distinct
		microscopy_initial_delay_min
	from
		experiments
	where
		date_label in (select * from cte_selected_experiments)
	)
	select -- control data
		*
	from
	(
	select
		sac.mutated_gene_systematic_name,
		sac.mutated_gene_standard_name,
		naa.timepoint * (select * from cte_microscopy_interval) - ((select * from cte_microscopy_interval) - (select * from cte_microscopy_initial_delay)) as timepoint_minutes,
		naa.number_of_foci
	from
		experimental_data_scd_foci_number_and_area as naa
	inner join
		strains_and_conditions_main as sac
	on
		sac.date_label = naa.date_label and
		sac.experimental_well_label= naa.experimental_well_label
	where
		naa.date_label in (select * from cte_selected_experiments) and 
		sac.mutated_gene_systematic_name= '-'
	) as a
	where
		a.timepoint_minutes in (p_reference_timepoint, p_selected_timepoint)
	#######
	union all
	#######
	select -- mutant data
		*
	from
	(
	select
		sac.mutated_gene_systematic_name,
		sac.mutated_gene_standard_name,
		naa.timepoint * (select * from cte_microscopy_interval) - ((select * from cte_microscopy_interval) - (select * from cte_microscopy_initial_delay)) as timepoint_minutes,
		naa.number_of_foci
	from
		experimental_data_scd_foci_number_and_area as naa
	inner join
		strains_and_conditions_main as sac
	on
		sac.date_label = naa.date_label and
		sac.experimental_well_label= naa.experimental_well_label
	where
		sac.mutated_gene_systematic_name in (select * from cte_GO_selected_strains)
	) as b
	where
		b.timepoint_minutes in (p_reference_timepoint, p_selected_timepoint);
end //
delimiter ;
-- call p_number_of_foci_single_cell_data_wt_vs_group_two_timepoints('["S000001855", "S000005853"]', 65, 195);



-- STORED PROCEDURE 9:
-- list of unique hits (standard gene name)
-- columns: effect-stage
-- 1: identified as a hit for particular effect-stage
-- 0: not considered a hit  for particular effect-stage
drop procedure if exists hc_microscopy_data_v2.p_hits_stages;
delimiter //
create procedure p_hits_stages()
begin
	select
		uh.hit_standard_name,
		-- esl.effect_stage_label,
		max(case when esl.effect_stage_label= 'decreased formation\r' then 1 else 0 end) as decreased_formation,
		max(case when esl.effect_stage_label= 'disrupted relocation & fusion\r' then 1 else 0 end) as disrupted_relocation_and_fusion,
		max(case when esl.effect_stage_label= 'slower clearance\r' then 1 else 0 end) as slower_clearance
	from
		hits_clusters as hc
	inner join 
		unique_hits as uh
	on
		hc.hit_systematic_name=uh.hit_systematic_name
	inner join
		effect_stage_labels as esl
	on
		hc.effect_stage_label_id=esl.effect_stage_label_id
	group by
		uh.hit_standard_name
	order by
		uh.hit_standard_name asc;
end //
delimiter ;
-- call p_hits_stages;



-- STORED PROCEDURE 10:
-- returns a single-cell data on number of aggregates per cell and average size of a single aggregate for all alleles of selected mutated gene from a selected time range
-- also returns corresponding control data: above mentioned data for 'wt control' from a particular experiment (defind by the 'date_label' field)
-- data filtered by a minimal-threshold cell count in the initial timepoint
-- inputs: p_selected_gene- selected gene, p_min_cell_count- minimal no. of cells in the well in the first timepoint, p_start_min- starting timepoint of a selected time range, p_end_min ending timepoint of a selected time range
drop procedure if exists hc_microscopy_data_v2.p_selected_gene_alleles_foci_count_size;
delimiter //
create procedure hc_microscopy_data_v2.p_selected_gene_alleles_foci_count_size(in p_selected_gene varchar(6), in p_min_cell_count int, in p_start_min int, in p_end_min int)
begin
	with
	cte_selected_experiments as -- selected expoeriments (date_labels) to pull control data from
	(
	select distinct
		e.date_label
	from
		experiments as e
	inner join
		experiment_types as et
	on
		e.experiment_type_id= et.experiment_type_id
	inner join
		strains_and_conditions_main as sacm
	on
		sacm.date_label=e.date_label
	where
		et.experiment_type = 'TS collection screening' and
		et.experiment_subtype= 'first round' and
		e.data_quality= 'Good' and
		sacm.mutated_gene_standard_name = p_selected_gene
	),
	cte_relevant_wells_with_above_thr_cc as -- filter down to wells with the initial cell count above threshold (p_min_cell_count)
	(
	select -- wells that have above the threshold cell counts in the initial timepoint
		sacm.date_label,
		sacm.experimental_well_label
	from
		strains_and_conditions_main as sacm
	inner join
		experimental_data_sbw_cell_area_and_counts as cac
	on
		sacm.date_label= cac.date_label and
		sacm.experimental_well_label= cac.experimental_well_label
	where
		sacm.date_label in (select * from cte_selected_experiments) and
		cac.timepoint= 1 and
		cac.number_of_cells >= p_min_cell_count
	),
	cte_microscopy_interval as -- microscopy interval for TS screen (1st round)
	(
	select distinct
		microscopy_interval_min
	from
		experiments
	where
		date_label in (select * from cte_selected_experiments)
	),
	cte_microscopy_initial_delay as -- microscopy initial delay for TS screen (1st round)
	(
	select distinct
		microscopy_initial_delay_min
	from
		experiments
	where
		date_label in (select * from cte_selected_experiments)
	),
	cte_control_data as -- control data
	(
	select
		sacm.date_label,
		sacm.mutated_gene_standard_name,
		sacm.mutation,
		fnaa.timepoint * (select * from cte_microscopy_interval) - ((select * from cte_microscopy_interval) - (select * from cte_microscopy_initial_delay)) as timepoint_minutes,
		fnaa.fov_cell_id,
		fnaa.number_of_foci,
		fnaa.total_foci_area/fnaa.number_of_foci as avg_size_single_focus
	from
		strains_and_conditions_main as sacm
	inner join
		cte_relevant_wells_with_above_thr_cc as cc_filter
	on
		sacm.date_label=cc_filter.date_label and
		sacm.experimental_well_label=cc_filter.experimental_well_label
	inner join
		experimental_data_scd_foci_number_and_area as fnaa
	on
		sacm.date_label=fnaa.date_label and
		sacm.experimental_well_label= fnaa.experimental_well_label
	where
		sacm.date_label in (select * from cte_selected_experiments) and
		sacm.mutation= 'wt control' and
		fnaa.timepoint * (select * from cte_microscopy_interval) - ((select * from cte_microscopy_interval) - (select * from cte_microscopy_initial_delay)) >= p_start_min and
		fnaa.timepoint * (select * from cte_microscopy_interval) - ((select * from cte_microscopy_interval) - (select * from cte_microscopy_initial_delay)) <= p_end_min
	)
	select -- selected mutant data
		sacm.date_label,
		sacm.mutated_gene_standard_name,
		sacm.mutation,
		fnaa.timepoint * (select * from cte_microscopy_interval) - ((select * from cte_microscopy_interval) - (select * from cte_microscopy_initial_delay)) as timepoint_minutes,
		fnaa.fov_cell_id,
		fnaa.number_of_foci,
		fnaa.total_foci_area/fnaa.number_of_foci as avg_size_single_focus
	from
		strains_and_conditions_main as sacm
	inner join
		cte_relevant_wells_with_above_thr_cc as cc_filter
	on
		sacm.date_label=cc_filter.date_label and
		sacm.experimental_well_label=cc_filter.experimental_well_label
	inner join
		experimental_data_scd_foci_number_and_area as fnaa
	on
		sacm.date_label=fnaa.date_label and
		sacm.experimental_well_label= fnaa.experimental_well_label
	where
		sacm.date_label in (select * from cte_selected_experiments) and
		sacm.mutated_gene_standard_name= p_selected_gene and
		fnaa.timepoint * (select * from cte_microscopy_interval) - ((select * from cte_microscopy_interval) - (select * from cte_microscopy_initial_delay)) >= p_start_min and
		fnaa.timepoint * (select * from cte_microscopy_interval) - ((select * from cte_microscopy_interval) - (select * from cte_microscopy_initial_delay)) <= p_end_min
	union all
	select -- corresponding control data
		*
	from
		cte_control_data
	order by 
		date_label asc,
        mutated_gene_standard_name asc,
        timepoint_minutes asc;
end//
delimiter ;
-- call p_selected_gene_alleles_foci_count_size('ACT1', 50, 280, 330);

