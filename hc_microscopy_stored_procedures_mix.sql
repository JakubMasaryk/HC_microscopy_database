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

call p_ts_screen_first_round_specific_plate_data('1A');



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

call p_ts_screen_first_round_specific_genes('["ACT1", "LCB1", "LCB2", "LCB3"]', 0, 400, 100);



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

call p_ts_screen_first_round_keyword('(^|\\s)sphingolipid(\\s|$)', 0, 400, 100);


    
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

call hc_microscopy_data_v2.p_ts_screen_first_round_gene_ontology_based('["S000003538", "S000004557"]', 0, 400, 0);




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

call p_parameter_per_mutant_and_stage(3, 45, 120, 300);




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

call p_percentage_per_mutant_and_stage_ranked(3, 45, 120, 290, 'clearance', 'PRE2', 7);



-- STORED PROCEDURE 8:
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

call p_number_of_foci_single_cell_data_wt_vs_group_two_timepoints('["S000001855", "S000005853"]', 65, 195);





use hc_microscopy_data_v2;

drop procedure if exists p_avg_difference_wt_mutant;
delimiter //
create procedure p_avg_difference_wt_mutant(in p_sgd_id_list json, p_min_cell_count int, in p_f_end int, p_rf_end int)
begin

	with 
	cte_sgd_id_list as -- transforms the list of sgd IDs into a json table
	(
	select
		*
	from
		json_table(p_sgd_id_list, '$[*]' columns(standard_name varchar(12) path '$')) as sgd_id_list
	),
	cte_selected_genes_systematic_names as -- sgd IDs (from GO) to systematic names
	(
	select distinct	
		systematic_name
	from
		sgd_descriptions
	where
		sgd_id in (select * from cte_sgd_id_list)
	),
    cte_selected_experimetal_wells as -- only wells (date_label-mutation combinations) with cell count above the defined minimum
    (
	select
		sacm.date_label,
		sacm.experimental_well_label
		-- sacm.mutation,
		-- cac.timepoint,
		-- cac.number_of_cells
	from
		strains_and_conditions_main as sacm
	inner join
		experimental_data_sbw_cell_area_and_counts as cac
	on
		cac.date_label=sacm.date_label and
		cac.experimental_well_label=sacm.experimental_well_label
	inner join 
		experiments as e
	on
		sacm.date_label= e.date_label
	inner join
		experiment_types as et
	on
		e.experiment_type_id=et.experiment_type_id
	where
		sacm.mutated_gene_systematic_name in (select * from cte_selected_genes_systematic_names) and
		cac.timepoint= 1 and
		cac.number_of_cells >=p_min_cell_count and
		et.experiment_type= 'TS collection screening' and
		et.experiment_subtype= 'first round' and
		e.data_quality=  'Good'
	),
	cte_selected_experiments as -- experiments (date_labels) to draw the controls from
	(
	select distinct
		date_label
	from
		cte_selected_experimetal_wells
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
	select -- outer query, pivot table
		-- pivot_table.date_label,
		pivot_table.mutation,
		round(avg(case when pivot_table.stage= 'formation' then pivot_table.percentage_ctrl_minus_mut else null end),2) as formation,
		round(avg(case when pivot_table.stage= 'relocation & fusion' then pivot_table.percentage_ctrl_minus_mut else null end),2) as relocation_and_fusion,
		round(avg(case when pivot_table.stage= 'clearance' then pivot_table.percentage_ctrl_minus_mut else null end),2) as clearance
	from
	(
	select -- selected fields and calculations
		mutant_data.date_label,
		mutant_data.mutation,
		mutant_data.timepoint_minutes,
		case
			when mutant_data.timepoint_minutes <= p_f_end then 'formation'
			when mutant_data.timepoint_minutes > p_f_end and mutant_data.timepoint_minutes <= p_rf_end then 'relocation & fusion'
			else 'clearance'
		end as stage,
		control_data.percentage_control_data,
		mutant_data.percentage_mutant_data,
		control_data.percentage_control_data - mutant_data.percentage_mutant_data as percentage_ctrl_minus_mut
	from
	( -- mutant data subquery
	select
		cac.date_label,
		sacm.mutation,
		cac.timepoint * (select * from cte_microscopy_interval) - ((select * from cte_microscopy_interval) - (select * from cte_microscopy_initial_delay)) as timepoint_minutes,
		avg(cac.number_of_cells_with_foci/cac.number_of_cells*100) as percentage_mutant_data
	from
		experimental_data_sbw_cell_area_and_counts as cac
	inner join
		strains_and_conditions_main as sacm
	on
		sacm.date_label= cac.date_label and
		sacm.experimental_well_label= cac.experimental_well_label
	inner join
		cte_selected_experimetal_wells as sew
	on
		sacm.date_label= sew.date_label and
        sacm.experimental_well_label= sew.experimental_well_label
	where
		sacm.mutated_gene_systematic_name in (select * from cte_selected_genes_systematic_names)
	group by
		cac.date_label,
		sacm.mutation,
		timepoint_minutes
	) as mutant_data
	inner join
	( -- control data subquery
	select
		cac.date_label,
		cac.timepoint * (select * from cte_microscopy_interval) - ((select * from cte_microscopy_interval) - (select * from cte_microscopy_initial_delay)) as timepoint_minutes,
		avg(cac.number_of_cells_with_foci/cac.number_of_cells*100) as percentage_control_data
	from
		experimental_data_sbw_cell_area_and_counts as cac
	inner join
		strains_and_conditions_main as sacm
	on
		sacm.date_label= cac.date_label and
		sacm.experimental_well_label= cac.experimental_well_label
	where
		sacm.date_label in (select * from cte_selected_experiments) and
		sacm.mutation = 'wt control'
	group by
		cac.date_label,
		timepoint_minutes
	) as control_data
	on
		mutant_data.date_label= control_data.date_label and
		mutant_data.timepoint_minutes= control_data.timepoint_minutes
	order by
		mutant_data.date_label,
		mutant_data.mutation,
		mutant_data.timepoint_minutes
	) as pivot_table
	group by
		-- pivot_table.date_label,
		pivot_table.mutation
	order by 
		pivot_table.mutation asc;
        
end//
delimiter ;

call p_avg_difference_wt_mutant(
	'[
    "S000002720", "S000003157", "S000029717", "S000029707", "S000005126",
    "S000005107", "S000004538", "S000003999", "S000003931", "S000004486",
    "S000005005", "S000004440", "S000003884", "S000003874", "S000000033",
    "S000003067", "S000006132", "S000006114", "S000005589", "S000006067",
    "S000006064", "S000006052", "S000006014", "S000005487", "S000005481",
    "S000005440", "S000005437", "S000005400", "S000004842", "S000005337",
    "S000005320", "S000005246", "S000004670", "S000006306", "S000006245",
    "S000006220", "S000005693", "S000005671", "S000001240", "S000000668",
    "S000000653", "S000000627", "S000001127", "S000001108", "S000007288",
    "S000000536", "S000005896", "S000000252", "S000006316", "S000001639",
    "S000002189", "S000000993", "S000001504", "S000000933", "S000003032",
    "S000002467", "S000002432", "S000001894", "S000001802", "S000001789",
    "S000001492", "S000001489", "S000001465", "S000001451", "S000001410",
    "S000001372", "S000001332", "S000000781", "S000000780", "S000001063",
    "S000004012", "S000003446", "S000002855", "S000002826", "S000003391",
    "S000003317", "S000004332", "S000003727", "S000218208", "S000218207",
    "S000004254", "S000004211", "S000004194", "S000004157", "S000004096",
    "S000004065", "S000004038"
	]'
, 100, 90, 240);



use hc_microscopy_data_v2;

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

call p_hits_stages;



-- all alleles/mutation for each unique hit + average difference from their corresponding WT control 
-- wt controls averaged per plate 
-- mutations occuring multiple times averaged
drop procedure if exists hc_microscopy_data_v2.p_hit_alleles_percentage;
delimiter //
create procedure p_hit_alleles_percentage() 
begin
	with
	cte_unique_hits_systematic_name as
	(
	select
		hit_systematic_name
	from
		unique_hits
	),
	cte_all_hit_mutations as
	(
	select distinct
		mutation
	from
		strains_and_conditions_main
	where
		mutated_gene_systematic_name in (select * from cte_unique_hits_systematic_name)
	order by
		mutation asc
	),
	cte_selected_experiments as
	(
	select distinct
		e.date_label
	from
		strains_and_conditions_main as sacm
	inner join 
		experiments as e
	on
		sacm.date_label=e.date_label
	inner join
		experiment_types as et
	on
		e.experiment_type_id=et.experiment_type_id
	where
		mutated_gene_systematic_name in (select * from cte_unique_hits_systematic_name) and
		e.data_quality= 'Good' and
		et.experiment_type= 'TS collection screening' and
		et.experiment_subtype= 'first round'
	),
	cte_control_data as
	(
	select
		cac.date_label,
		cac.timepoint,
		avg(round(cac.number_of_cells_with_foci/cac.number_of_cells*100,2)) as percentage_control_data
	from
		experimental_data_sbw_cell_area_and_counts as cac
	inner join 
		strains_and_conditions_main as sacm
	on
		cac.date_label=sacm.date_label and
		cac.experimental_well_label= sacm.experimental_well_label
	where
		cac.date_label in (select * from cte_selected_experiments) and
		cac.number_of_cells >= 50 and
		sacm.mutation= 'wt control'
	group by
		cac.date_label,
		cac.timepoint
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
	select
		*
	from
	(
	select
		a.mutated_gene_standard_name,
		a.mutation,
		avg(case when a.stage= 'formation' then a.percentage_control_minus_mutant else null end) as formation,
		avg(case when a.stage= 'relocation & fusion' then a.percentage_control_minus_mutant else null end) as relocation_and_fusion,
		avg(case when a.stage= 'clearance' then a.percentage_control_minus_mutant else null end) as clearance
	from
	(
	select
		sacm.mutated_gene_standard_name,
		sacm.mutation,
		round(ctrl.percentage_control_data, 2) - round(cac.number_of_cells_with_foci/cac.number_of_cells*100, 2) as percentage_control_minus_mutant,
		case
			when 
				cac.timepoint * (select * from cte_microscopy_interval) - ((select * from cte_microscopy_interval) - (select * from cte_microscopy_initial_delay)) <= 62 then 'formation'
			when 
				cac.timepoint * (select * from cte_microscopy_interval) - ((select * from cte_microscopy_interval) - (select * from cte_microscopy_initial_delay)) > 62 and 
				cac.timepoint * (select * from cte_microscopy_interval) - ((select * from cte_microscopy_interval) - (select * from cte_microscopy_initial_delay)) <= 300 then 'relocation & fusion'
			else 
				'clearance'
		end as stage
	from
		experimental_data_sbw_cell_area_and_counts as cac
	inner join 
		strains_and_conditions_main as sacm
	on
		cac.date_label=sacm.date_label and
		cac.experimental_well_label= sacm.experimental_well_label
	inner join
		cte_control_data as ctrl
	on
		cac.date_label= ctrl.date_label and
		cac.timepoint= ctrl.timepoint
	where
		sacm.mutation in (select * from cte_all_hit_mutations) and
		cac.number_of_cells >= 50
	order by 
		sacm.mutated_gene_standard_name asc,
		sacm.mutation asc
	) as a
	group by
		a.mutated_gene_standard_name,
		a.mutation
	) as b
	where -- remove null cells, mutants cell count of which goes below the threshold at one or more stages
		b.formation is not null and
		b.relocation_and_fusion is not null and
		b.clearance is not null;
end //
delimiter ;

call p_hit_alleles_percentage;



use hc_microscopy_data_v2;

drop procedure if exists hc_microscopy_data_v2.p_aggregate_processing_proteins;
delimiter //
create procedure hc_microscopy_data_v2.p_aggregate_processing_proteins()
begin
	with 
	cte_agg_processing_proteins as -- proteins present in aggregates but not interacting with As
	(
	select
		systematic_name
	from
		aggregated_proteins
	where
		systematic_name not in (select systematic_name from as_interacting_proteins)
	),
	cte_agg_processing_hits as -- agg_processing_proteins identified as hits with decreased formation
	(
	select
		hc.hit_systematic_name
	from
		hits_clusters as hc
	inner join
		effect_stage_labels as esl
	on
		hc.effect_stage_label_id=esl.effect_stage_label_id
	where
		esl.effect_stage_label= 'decreased formation\r' and
		hc.hit_systematic_name in (select * from cte_agg_processing_proteins)
	),
	cte_selected_experiments as
	(
	select distinct
		e.date_label
	from
		strains_and_conditions_main as sacm
	inner join 
		experiments as e
	on
		sacm.date_label=e.date_label
	inner join
		experiment_types as et
	on
		e.experiment_type_id=et.experiment_type_id
	where
		mutated_gene_systematic_name in (select * from cte_agg_processing_hits) and
		e.data_quality= 'Good' and
		et.experiment_type= 'TS collection screening' and
		et.experiment_subtype= 'first round'
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
	cte_control_data as
	(
	select
		sacm.date_label,
		-- sacm.mutation,
		cac.timepoint,
		cac.timepoint * (select * from cte_microscopy_interval) - ((select * from cte_microscopy_interval) - (select * from cte_microscopy_initial_delay)) as timepoint_minutes,
		round(avg(cac.number_of_cells_with_foci/cac.number_of_cells*100),2) as control_percentage,
		round(avg(nas.avg_number_of_foci_per_cell), 4) as control_agg_number,
		round(avg(nas.avg_size_single_focus), 6) as control_agg_size
	from
		strains_and_conditions_main as sacm
	inner join
		experimental_data_sbw_cell_area_and_counts as cac
	on
		sacm.date_label= cac.date_label and
		sacm.experimental_well_label= cac.experimental_well_label
	inner join
		experimental_data_sbw_foci_number_and_size as nas
	on
		sacm.date_label= nas.date_label and
		sacm.experimental_well_label= nas.experimental_well_label and
		cac.timepoint= nas.timepoint
	where
		sacm.date_label in (select * from cte_selected_experiments) and
		sacm.mutation = 'wt control'
	group by
		sacm.date_label,
		cac.timepoint,
		timepoint_minutes
	)
	select
		a.mutation,
		a.stage,
		avg(a.ctrl_minus_mut_percentage) as ctrl_minus_mut_percentage,
		avg(a.ctrl_minus_mut_agg_no) as ctrl_minus_mut_agg_no,
		avg(a.ctrl_minus_mut_agg_size) as ctrl_minus_mut_agg_size
	from
	(
	select
		sacm.mutation,
		case
		when 
			cac.timepoint * (select * from cte_microscopy_interval) - ((select * from cte_microscopy_interval) - (select * from cte_microscopy_initial_delay)) <= 62 
		then 
			1
        when 
			cac.timepoint * (select * from cte_microscopy_interval) - ((select * from cte_microscopy_interval) - (select * from cte_microscopy_initial_delay)) > 62 and
            cac.timepoint * (select * from cte_microscopy_interval) - ((select * from cte_microscopy_interval) - (select * from cte_microscopy_initial_delay)) <= 300
		then 
			2
		else
			3
	end as stage_index,
    case
		when 
			cac.timepoint * (select * from cte_microscopy_interval) - ((select * from cte_microscopy_interval) - (select * from cte_microscopy_initial_delay)) <= 62 
		then 
			'formation'
        when 
			cac.timepoint * (select * from cte_microscopy_interval) - ((select * from cte_microscopy_interval) - (select * from cte_microscopy_initial_delay)) > 62 and
            cac.timepoint * (select * from cte_microscopy_interval) - ((select * from cte_microscopy_interval) - (select * from cte_microscopy_initial_delay)) <= 300
		then 
			'relocation & fusion'
		else
			'clearance'
	end as stage,
    ctrl.control_percentage - round(avg(cac.number_of_cells_with_foci/cac.number_of_cells*100),2) as ctrl_minus_mut_percentage,
    ctrl.control_agg_number - round(avg(nas.avg_number_of_foci_per_cell), 4) as ctrl_minus_mut_agg_no,
    ctrl.control_agg_size - round(avg(nas.avg_size_single_focus), 6) as ctrl_minus_mut_agg_size
from
	strains_and_conditions_main as sacm
inner join
	experimental_data_sbw_cell_area_and_counts as cac
on
	sacm.date_label= cac.date_label and
    sacm.experimental_well_label= cac.experimental_well_label
inner join
	experimental_data_sbw_foci_number_and_size as nas
on
	sacm.date_label= nas.date_label and
    sacm.experimental_well_label= nas.experimental_well_label and
    cac.timepoint= nas.timepoint
left join 
	cte_control_data as ctrl
on
	ctrl.date_label= sacm.date_label and
    ctrl.timepoint= cac.timepoint
where
    sacm.mutated_gene_systematic_name in (select * from cte_agg_processing_hits) and
    sacm.date_label in (select * from cte_selected_experiments)
group by
	sacm.date_label,
	sacm.mutation,
    cac.timepoint,
    timepoint_minutes
) as a
group by
	a.mutation,
    a.stage,
    a.stage_index
order by
	a.mutation asc,
    a.stage_index asc;
end //
delimiter ;
call p_aggregate_processing_proteins;



drop procedure if exists hc_microscopy_data_v2.p_most_affected_alleles_slower_clearance_hits;
delimiter //
# for each hit from the 'slower clearance' group returns 3 of the most affected alleles (mutations)
# calculated as an average difference (between a particular mutant and a corresponding control) of a percentage of cells containing aggregates in the clearance stage (time > 300 minutes)
# control data averaged per each plate and assigned to each mutant based on date label
create procedure hc_microscopy_data_v2.p_most_affected_alleles_slower_clearance_hits()
#most affected alleles (top3) of the decreased-clearance hits, for follow-up
begin
	with
	cte_slower_clearance_hits as -- systematic names for all slower-clearance hits
	(
	select
		hc.hit_systematic_name
	from
		hits_clusters as hc
	inner join
		effect_stage_labels as esl
	on
		hc.effect_stage_label_id=esl.effect_stage_label_id
	where
		esl.effect_stage_label= 'slower clearance\r'
	),
	cte_selected_experiments as -- selected experiments (date_labels) that contain at least one of the slower-clearance hits (only TS screening 1st round, 'Good' data quality)
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
		strains_and_conditions_main as sacm
	on
		sacm.date_label=e.date_label
	where
		et.experiment_type = 'TS collection screening' and
		et.experiment_subtype= 'first round' and
		e.data_quality= 'Good' and
		sacm.mutated_gene_systematic_name in (select * from cte_slower_clearance_hits)
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
	cte_control_data as -- date label plus data on percentage of cells containing aggregates, only WT controls, averaged per plate (only clearance timepoints included)
	(
	select
		cac.date_label,
		cac.timepoint,
		cac.timepoint * (select * from cte_microscopy_interval) - ((select * from cte_microscopy_interval) - (select * from cte_microscopy_initial_delay)) as timepoint_minutes,
		round(avg(cac.number_of_cells_with_foci/cac.number_of_cells*100), 4) as percentage_control
	from
		experimental_data_sbw_cell_area_and_counts as cac
	inner join
		strains_and_conditions_main as sacm
	on
		sacm.date_label= cac.date_label and
		sacm.experimental_well_label= cac.experimental_well_label
	where
		sacm.mutation= 'wt control' and
		cac.date_label in (select * from cte_selected_experiments) and
		cac.timepoint * (select * from cte_microscopy_interval) - ((select * from cte_microscopy_interval) - (select * from cte_microscopy_initial_delay)) > 300
	group by
		cac.date_label,
		cac.timepoint
	order by 
		cac.date_label asc
	)
	select -- pivot table
		a.mutated_gene_standard_name,
		ifnull(max(case when a.allele_index = 1 then a.mutation else null end), "-") as most_affected_allele,
		ifnull(max(case when a.allele_index = 2 then a.mutation else null end), "-") as second_most_affected_allele,
		ifnull(max(case when a.allele_index = 3 then a.mutation else null end), "-") as third_most_affected_allele
	from
	(
	select -- control minus mutant data
		sacm.mutated_gene_standard_name,
		sacm.mutation,
		row_number() over (partition by sacm.mutated_gene_standard_name order by round(avg(ctrl.percentage_control - cac.number_of_cells_with_foci/cac.number_of_cells*100),2) asc) as allele_index,
		round(avg(ctrl.percentage_control - cac.number_of_cells_with_foci/cac.number_of_cells*100),2) as control_minus_hit_percentage
	from
		experimental_data_sbw_cell_area_and_counts as cac
	inner join
		strains_and_conditions_main as sacm
	on
		sacm.date_label= cac.date_label and
		sacm.experimental_well_label= cac.experimental_well_label
	inner join
		cte_control_data as ctrl
	on
		cac.date_label = ctrl.date_label and 
		cac.timepoint=ctrl.timepoint
	where
		sacm.mutated_gene_systematic_name in (select * from cte_slower_clearance_hits) and
		cac.date_label in (select * from cte_selected_experiments) and
		cac.timepoint * (select * from cte_microscopy_interval) - ((select * from cte_microscopy_interval) - (select * from cte_microscopy_initial_delay)) > 300 -- only clearance-stage timepoints
	group by
		sacm.mutated_gene_standard_name,
		sacm.mutation -- averaged per allele (mutation), in case multiple similar alleles present (duplicate entries present in the TS collection in high frequency)
	order by
		sacm.mutated_gene_standard_name asc
	) as a
	where
		a.control_minus_hit_percentage < 0 -- only negative values (mutants where the clearance is negatively affected, percentage of cells with aggregates higher in the clearance stage, compared to control)
	group by
		a.mutated_gene_standard_name;
end //
delimiter ;

call p_most_affected_alleles_slower_clearance_hits();


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

call p_selected_gene_alleles_foci_count_size('ACT1', 50, 280, 330);


drop procedure if exists hc_microscopy_data_v2.p_selected_gene_alleles_formation_diff_from_wt;
delimiter //
create procedure hc_microscopy_data_v2.p_selected_gene_alleles_formation_diff_from_wt(in p_selected_gene varchar(6), in p_min_cell_count int, in p_formation_end_min int)
begin
	with
	cte_selected_experiments as
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
		strains_and_conditions_main as sacm
	on
		e.date_label= sacm.date_label
	where
		e.data_quality= 'Good' and
		et.experiment_type = 'TS collection screening' and
		et.experiment_subtype= 'first round' and
		sacm.mutated_gene_standard_name= p_selected_gene
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
	cte_control_data as
	(
	select -- control data, averaged per experiment (date_label
		sacm.date_label,
		caac.timepoint,
		round(avg(caac.number_of_cells_with_foci/caac.number_of_cells*100), 2) as control_percentage,
		round(avg(fnas.avg_number_of_foci_per_cell), 4) as control_foci_number,
		round(avg(fnas.avg_size_single_focus), 4) as control_single_focus_size
	from
		strains_and_conditions_main as sacm
	inner join
		cte_relevant_wells_with_above_thr_cc as cc_filter
	on
		sacm.date_label= cc_filter.date_label and -- filter by cell count
		sacm.experimental_well_label= cc_filter.experimental_well_label -- filter by cell count
	inner join
		experimental_data_sbw_cell_area_and_counts as caac
	on
		sacm.date_label= caac.date_label and
		sacm.experimental_well_label= caac.experimental_well_label
	inner join
		experimental_data_sbw_foci_number_and_size as fnas
	on
		sacm.date_label= fnas.date_label and
		sacm.experimental_well_label= fnas.experimental_well_label and
		caac.timepoint= fnas.timepoint
	where
		sacm.mutation= 'wt control' and
		sacm.date_label in (select * from cte_selected_experiments) and
		caac.timepoint * (select * from cte_microscopy_interval) - ((select * from cte_microscopy_interval) - (select * from cte_microscopy_initial_delay)) <= p_formation_end_min
	group by
		sacm.date_label,
		sacm.mutation,
		caac.timepoint
	)
	select
		ctrl_minus_mutant_data.mutation,
		avg(ctrl_minus_mutant_data.percentage_control_minus_mutant) as percentage_avg_difference,
		avg(ctrl_minus_mutant_data.foci_number_control_minus_mutant) as foci_number_avg_difference,
		avg(ctrl_minus_mutant_data.focus_size_control_minus_mutant) as single_focus_size_avg_difference
	from
	(
	select -- control data, averaged per experiment (date_label
		sacm.date_label,
		caac.timepoint,
		sacm.mutation,
		round(caac.number_of_cells_with_foci/caac.number_of_cells*100, 2) as mutant_percentage,
		ctrl.control_percentage,
		ctrl.control_percentage - round(caac.number_of_cells_with_foci/caac.number_of_cells*100, 2) as percentage_control_minus_mutant,
		round(fnas.avg_number_of_foci_per_cell, 4) as mutant_foci_number,
		ctrl.control_foci_number,
		ctrl.control_foci_number - round(fnas.avg_number_of_foci_per_cell, 4) as foci_number_control_minus_mutant,
		round(fnas.avg_size_single_focus, 4) as mutant_single_focus_size,
		ctrl.control_single_focus_size,
		ctrl.control_single_focus_size - round(fnas.avg_size_single_focus, 4) as focus_size_control_minus_mutant
	from
		strains_and_conditions_main as sacm
	inner join
		cte_relevant_wells_with_above_thr_cc as cc_filter
	on
		sacm.date_label= cc_filter.date_label and -- filter by cell count
		sacm.experimental_well_label= cc_filter.experimental_well_label -- filter by cell count
	inner join
		experimental_data_sbw_cell_area_and_counts as caac
	on
		sacm.date_label= caac.date_label and
		sacm.experimental_well_label= caac.experimental_well_label
	inner join
		experimental_data_sbw_foci_number_and_size as fnas
	on
		sacm.date_label= fnas.date_label and
		sacm.experimental_well_label= fnas.experimental_well_label and
		caac.timepoint= fnas.timepoint
	inner join
		cte_control_data as ctrl
	on
		sacm.date_label= ctrl.date_label and
		caac.timepoint= ctrl.timepoint
	where
		sacm.mutated_gene_standard_name= p_selected_gene and
		sacm.date_label in (select * from cte_selected_experiments) and
		caac.timepoint * (select * from cte_microscopy_interval) - ((select * from cte_microscopy_interval) - (select * from cte_microscopy_initial_delay)) <= p_formation_end_min
	)
	as 
		ctrl_minus_mutant_data
	group by
		ctrl_minus_mutant_data.mutation
	order by
		avg(ctrl_minus_mutant_data.percentage_control_minus_mutant) desc;
end //
delimiter ;

call p_selected_gene_alleles_formation_diff_from_wt('ACT1', 50, 70);


-- function returns unique-allele/mutation counts for every gene in the TS collection
-- input: selected gene- standard name (e.g., ACT1)
drop function if exists hc_microscopy_data_v2.f_no_of_alleles;
delimiter //
create function hc_microscopy_data_v2.f_no_of_alleles(p_gene_systematic_name varchar(12))
returns int
deterministic
begin
	declare v_no_of_alleles int;
    
    select 
		count(distinct mutation)
	into 
		v_no_of_alleles
	from 
		hc_microscopy_data_v2.strains_and_conditions_main
	where
		mutated_gene_standard_name = p_gene_systematic_name;
	
    return v_no_of_alleles;
    
end //
delimiter ;

-- for each unique hit returns:
-- stage in which the particular protein was idetified as hit (1- YES, 0- NO)
-- number of alleles in collection ('allele_count')
-- whether particular hit is potential aggregate-processing protein (present in aggregates but not interacting with As)
drop procedure if exists hc_microscopy_data_v2.p_unique_hit_stage_effect_allele_count;
delimiter //
create procedure hc_microscopy_data_v2.p_unique_hit_stage_effect_allele_count()
begin
	with
	cte_allele_counts as
	(
	select distinct
		sacm.mutated_gene_systematic_name,
		sacm.mutated_gene_standard_name,
		f_no_of_alleles(sacm.mutated_gene_standard_name) as allele_count
	from
		strains_and_conditions_main as sacm
	inner join
		unique_hits as uh
	on
		sacm.mutated_gene_systematic_name= uh.hit_systematic_name
	),
	cte_potential_agg_processor as
	(
	select
		systematic_name,
		1 as potential_agg_processor
	from
		aggregated_proteins
	where
		systematic_name not in (select systematic_name from as_interacting_proteins)
	)
	select
		uh.hit_systematic_name,
		uh.hit_standard_name,
		-- esl.effect_stage_label,
		max(case when esl.effect_stage_label = 'decreased formation\r' then 1 else 0 end) as decreased_formation,
		max(case when esl.effect_stage_label = 'disrupted relocation & fusion\r' then 1 else 0 end) as disrupted_relocation_and_fusion,
		max(case when esl.effect_stage_label = 'slower clearance\r' then 1 else 0 end) as slower_clearance,
		round(avg(ac.allele_count)) as allele_count,
		ifnull(round(avg(pap.potential_agg_processor)), 0) as potential_agg_processor
	from
		unique_hits as uh
	inner join
		hits_clusters as hc
	on 
		uh.hit_systematic_name= hc.hit_systematic_name
	inner join
		effect_stage_labels as esl
	on
		esl.effect_stage_label_id= hc.effect_stage_label_id
	inner join
		cte_allele_counts as ac
	on
		uh.hit_systematic_name= ac.mutated_gene_systematic_name
	left join
		cte_potential_agg_processor as pap
	on
		uh.hit_systematic_name=pap.systematic_name
	group by
		uh.hit_systematic_name,
		uh.hit_standard_name
	order by
		uh.hit_standard_name;
end //
delimiter ;

call p_unique_hit_stage_effect_allele_count;
    
    
    
-- returns single-cell data on number of foci per cell for all of the alleles of a selected gene (and corresponding controls)
-- inputs: 'p_selected_gene'- selected gene, 'p_min_cc'- mnimum cell count for a particular well, 'p_start_min'- starting timepoint in minutes, 'p_end_min'- starting timepoint in minutes
drop procedure if exists hc_microscopy_data_v2.p_single_cell_data_agg_no_all_alleles_selected_gene;
delimiter //
create procedure hc_microscopy_data_v2.p_single_cell_data_agg_no_all_alleles_selected_gene(in p_selected_gene varchar(8), in p_min_cc int, p_start_min int, in p_end_min int)
begin
	with
	cte_selected_experiments as -- selected experiments, only experiments ('date_label') where at least one allele of the selected gene was analysed
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
		strains_and_conditions_main as sacm
	on
		e.date_label= sacm.date_label
	where
		e.data_quality= 'Good' and
		et.experiment_type = 'TS collection screening' and
		et.experiment_subtype= 'first round' and
		sacm.mutated_gene_standard_name= p_selected_gene
	),
	cte_cell_count_filter as -- date label + wells above cell-count threshold
	(
	select
		sacm.date_label,
		sacm.experimental_well_label
	from
		strains_and_conditions_main as sacm
	inner join
		experimental_data_sbw_cell_area_and_counts as caac
	on
		sacm.date_label=caac.date_label and
		sacm.experimental_well_label= caac.experimental_well_label
	where
		caac.timepoint= 1 and
		caac.number_of_cells >= p_min_cc
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
		sacm.date_label,
		sacm.experimental_well_label,
		sacm.mutation,
		fnaa.timepoint * (select * from cte_microscopy_interval) - ((select * from cte_microscopy_interval) - (select * from cte_microscopy_initial_delay)) as timepoint_minutes,
		fnaa.fov_cell_id,
		fnaa.number_of_foci
	from
		strains_and_conditions_main as sacm
	inner join
		cte_cell_count_filter as cc -- cell-cont filter
	on
		sacm.date_label= cc.date_label and
		sacm.experimental_well_label= cc.experimental_well_label
	inner join
		experimental_data_scd_foci_number_and_area as fnaa
	on
		sacm.date_label= fnaa.date_label and
		sacm.experimental_well_label= fnaa.experimental_well_label
	where
		sacm.date_label in (select * from cte_selected_experiments) and
		sacm.mutation= 'wt control' and
		fnaa.timepoint * (select * from cte_microscopy_interval) - ((select * from cte_microscopy_interval) - (select * from cte_microscopy_initial_delay)) > p_start_min and
		fnaa.timepoint * (select * from cte_microscopy_interval) - ((select * from cte_microscopy_interval) - (select * from cte_microscopy_initial_delay)) <= p_end_min
	--
	union -- concat control and mutant data
	--
	select -- mutant data
		sacm.date_label,
		sacm.experimental_well_label,
		sacm.mutation,
		fnaa.timepoint * (select * from cte_microscopy_interval) - ((select * from cte_microscopy_interval) - (select * from cte_microscopy_initial_delay)) as timepoint_minutes,
		fnaa.fov_cell_id,
		fnaa.number_of_foci
	from
		strains_and_conditions_main as sacm
	inner join
		cte_cell_count_filter as cc -- cell-cont filter
	on
		sacm.date_label= cc.date_label and
		sacm.experimental_well_label= cc.experimental_well_label
	inner join
		experimental_data_scd_foci_number_and_area as fnaa
	on
		sacm.date_label= fnaa.date_label and
		sacm.experimental_well_label= fnaa.experimental_well_label
	where
		sacm.date_label in (select * from cte_selected_experiments) and
		sacm.mutated_gene_standard_name= p_selected_gene and
		fnaa.timepoint * (select * from cte_microscopy_interval) - ((select * from cte_microscopy_interval) - (select * from cte_microscopy_initial_delay)) > p_start_min and
		fnaa.timepoint * (select * from cte_microscopy_interval) - ((select * from cte_microscopy_interval) - (select * from cte_microscopy_initial_delay)) <= p_end_min;
end //
delimiter ;
call p_single_cell_data_agg_no_all_alleles_selected_gene('CDC48', 33, 300, 320);


-- returns single-cell data on foci size for all of the alleles of a selected gene (and corresponding controls)
-- inputs: 'p_selected_gene'- selected gene, 'p_min_cc'- mnimum cell count for a particular well, 'p_start_min'- starting timepoint in minutes, 'p_end_min'- starting timepoint in minutes
drop procedure if exists hc_microscopy_data_v2.p_single_cell_data_agg_size_all_alleles_selected_gene;
delimiter //
create procedure hc_microscopy_data_v2.p_single_cell_data_agg_size_all_alleles_selected_gene(in p_selected_gene varchar(6), in p_min_cell_count int, in p_start_min int, in p_end_min int)
begin
	with
	cte_selected_experiments as
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
		strains_and_conditions_main as sacm
	on
		e.date_label= sacm.date_label
	where
		sacm.mutated_gene_standard_name= p_selected_gene and
		e.data_quality= 'Good' and
		et.experiment_type = 'TS collection screening' and
		et.experiment_subtype= 'first round'
	),
	cte_cell_count_filter as -- wells with a certain cell count
	(
	select 
		sacm.date_label,
		sacm.experimental_well_label
	from
		strains_and_conditions_main as sacm
	inner join
		experimental_data_sbw_cell_area_and_counts as caac
	on
		sacm.date_label=caac.date_label and
		sacm.experimental_well_label=caac.experimental_well_label
	where
		caac.timepoint= 1 and
		caac.number_of_cells >= p_min_cell_count
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
		sacm.date_label,
		sacm.experimental_well_label,
		sacm.mutation,
		fnaa.timepoint * (select * from cte_microscopy_interval) - ((select * from cte_microscopy_interval) - (select * from cte_microscopy_initial_delay)) as timepoint_minutes,
		fnaa.fov_cell_id,
		round(fnaa.total_foci_area/fnaa.number_of_foci, 6) as avg_focus_size
	from
		strains_and_conditions_main as sacm
	inner join
		cte_cell_count_filter as cc -- cell-cont filter
	on
		sacm.date_label= cc.date_label and
		sacm.experimental_well_label= cc.experimental_well_label
	inner join
		experimental_data_scd_foci_number_and_area as fnaa
	on
		sacm.date_label= fnaa.date_label and
		sacm.experimental_well_label= fnaa.experimental_well_label
	where
		sacm.date_label in (select * from cte_selected_experiments) and
		sacm.mutation= 'wt control' and
		fnaa.timepoint * (select * from cte_microscopy_interval) - ((select * from cte_microscopy_interval) - (select * from cte_microscopy_initial_delay)) > p_start_min and
		fnaa.timepoint * (select * from cte_microscopy_interval) - ((select * from cte_microscopy_interval) - (select * from cte_microscopy_initial_delay)) <= p_end_min and
		fnaa.number_of_foci > 0
	-- ----
	union
	-- ----
	select -- control data
		sacm.date_label,
		sacm.experimental_well_label,
		sacm.mutation,
		fnaa.timepoint * (select * from cte_microscopy_interval) - ((select * from cte_microscopy_interval) - (select * from cte_microscopy_initial_delay)) as timepoint_minutes,
		fnaa.fov_cell_id,
		round(fnaa.total_foci_area/fnaa.number_of_foci, 6) as avg_focus_size
	from
		strains_and_conditions_main as sacm
	inner join
		cte_cell_count_filter as cc -- cell-cont filter
	on
		sacm.date_label= cc.date_label and
		sacm.experimental_well_label= cc.experimental_well_label
	inner join
		experimental_data_scd_foci_number_and_area as fnaa
	on
		sacm.date_label= fnaa.date_label and
		sacm.experimental_well_label= fnaa.experimental_well_label
	where
		sacm.mutated_gene_standard_name= p_selected_gene and
		fnaa.timepoint * (select * from cte_microscopy_interval) - ((select * from cte_microscopy_interval) - (select * from cte_microscopy_initial_delay)) > p_start_min and
		fnaa.timepoint * (select * from cte_microscopy_interval) - ((select * from cte_microscopy_interval) - (select * from cte_microscopy_initial_delay)) <= p_end_min and
		fnaa.number_of_foci > 0;
end //
delimiter ;
call p_single_cell_data_agg_size_all_alleles_selected_gene('CDC48', 33, 0, 70);


#allele plus cc in first and the last timepoint (plus ratio l/f)
drop procedure if exists hc_microscopy_data_v2.ideal_starting_cc;
delimiter //
create procedure hc_microscopy_data_v2.ideal_starting_cc(in p_low_end decimal(3,2), in p_high_end decimal(3,2))
begin
	with
	cte_selected_experiments as
	(
	select
		date_label
	from
		experiments as e
	inner join
		experiment_types as et
	on
		e.experiment_type_id=et.experiment_type_id
	where
		e.data_quality= 'Good' and
		et.experiment_type = 'TS collection screening' and
		et.experiment_subtype= 'first round'
	),
	cte_min_timepoint as
	(
	select
		min(caac.timepoint) as min_timepoint
	from
		experimental_data_sbw_cell_area_and_counts as caac
	inner join
		strains_and_conditions_main as sacm
	on
		sacm.date_label= caac.date_label and
		sacm.experimental_well_label= caac.experimental_well_label
	where
		sacm.date_label in (select * from cte_selected_experiments)
		
	),
	cte_max_timepoint as
	(
	select
		max(caac.timepoint) as max_timepoint
	from
		experimental_data_sbw_cell_area_and_counts as caac
	inner join
		strains_and_conditions_main as sacm
	on
		sacm.date_label= caac.date_label and
		sacm.experimental_well_label= caac.experimental_well_label
	where
		sacm.date_label in (select * from cte_selected_experiments)
		
	)
	select
		ifnull(b.ratio_category, "no category") as category,
		avg(b.starting_cell_count) as initial_cel_count
	from
	(
	select
		a.mutated_gene_standard_name as gene,
		a.mutation as allele,
		a.cc_min_timepoint as starting_cell_count,
		a.cc_max_timepoint as ending_cell_count,
		round(a.cc_max_timepoint/a.cc_min_timepoint, 2) as ratio_ending_to_starting_cc,
		case
			when 
				round(a.cc_max_timepoint/a.cc_min_timepoint, 2) > p_high_end + 0.5 
			then "high ratio"
			when 
				round(a.cc_max_timepoint/a.cc_min_timepoint, 2) <= p_high_end + 0.5 and
				round(a.cc_max_timepoint/a.cc_min_timepoint, 2) > p_high_end
			then "semi-high ratio"
			when
				round(a.cc_max_timepoint/a.cc_min_timepoint, 2) <= p_high_end and
				round(a.cc_max_timepoint/a.cc_min_timepoint, 2) > p_low_end
			then "ideal ratio"
			when
				round(a.cc_max_timepoint/a.cc_min_timepoint, 2) <= p_low_end and
				round(a.cc_max_timepoint/a.cc_min_timepoint, 2) > p_low_end - 0.5
			then "semi-low ratio"
			when
				round(a.cc_max_timepoint/a.cc_min_timepoint, 2) < p_low_end - 0.5
			then "low ratio"
		end as ratio_category
	from
	(
	select
		sacm.mutated_gene_standard_name,
		sacm.mutation,
		-- caac.timepoint,
		max(case when caac.timepoint = (select * from cte_min_timepoint) then caac.number_of_cells else null end) as cc_min_timepoint,
		max(case when caac.timepoint = (select * from cte_max_timepoint) then caac.number_of_cells else null end) as cc_max_timepoint
		-- caac.number_of_cells
	from
		strains_and_conditions_main as sacm
	inner join
		experimental_data_sbw_cell_area_and_counts as caac
	on
		sacm.date_label=caac.date_label and
		sacm.experimental_well_label=caac.experimental_well_label
	where
		sacm.date_label in (select * from cte_selected_experiments) and
		sacm.mutation != "wt control" and
		(caac.timepoint = (select * from cte_min_timepoint) or caac.timepoint = (select * from cte_max_timepoint))
	group by
		sacm.mutated_gene_standard_name,
		sacm.mutation
	) as a
	order by
		ratio_ending_to_starting_cc desc
	) as b
	group by
		b.ratio_category;
end //
delimiter ;

call ideal_starting_cc(0.75, 1.25);


-- pulls all relevant summary-by-well data for a specific inhibitor (and other inhibitors done within the same experiment)
-- input: 'p_inh_abb' abbrevation for a selected inhibitor, e.g., 'CHX' for cycloheximide
-- 		  'p_init_tmpts_skip' number of initital timepoints skipped (generally low-quality data)
drop procedure if exists hc_microscopy_data_v2.p_inhibitor_sbw_data;
delimiter //
create procedure hc_microscopy_data_v2.p_inhibitor_sbw_data(in p_inh_abb varchar(10), in p_init_tmpts_skip int)
begin
	with
	cte_inhib_experiments as -- date_labels for all experiments including selected inhibitor
	(
	select distinct	
		ei.date_label
	from
		experiment_inhibitor as ei
	inner join
		inhibitors as i
	on
		ei.inhibitor_id=i.inhibitor_id
	where
		i.inhibitor_abbreviation= p_inh_abb
	),	
	cte_microscopy_intervals as -- date_label and microscopy interval (in mins), if multiple are relevant- multiple pairs
	(
	select distinct
		date_label,
		microscopy_interval_min
	from
		experiments
	where
		date_label in (select * from cte_inhib_experiments)
	),
	cte_microscopy_initial_delays as -- date_label and microscopy initial delay (in mins), if multiple are relevant- multiple pairs
	(
	select distinct
		date_label,
		microscopy_initial_delay_min
	from
		experiments
	where
		date_label in (select * from cte_inhib_experiments)
	)
	select -- relevant data
		sacm.date_label,
		sacm.experimental_well_label,
		sacm.biological_repeat,
		sacm.metal_concentration,
		sacm.metal_concentration_unit,
		saci.inhibitor_abbreviation,
		saci.inhibitor_concentration,
		saci.inhibitor_concentration_unit,
		saci.inhibitor_solvent,
		saci.inhibitor_solvent_concentration,
		saci.inhibitor_solvent_concentration_unit,
		-- cac.timepoint,
		-- cte1.microscopy_interval_min,
		-- cte2.microscopy_initial_delay_min,
		cac.timepoint * cte1.microscopy_interval_min - (cte1.microscopy_interval_min - cte2.microscopy_initial_delay_min) as timepoint_minutes,
		cac.number_of_cells,
		cac.number_of_cells_with_foci,
        round(cac.number_of_cells_with_foci/cac.number_of_cells*100, 2) as percentage_of_cells_with_foci,
		fnas.avg_number_of_foci_per_cell,
		fnas.avg_size_single_focus
	from
		strains_and_conditions_main as sacm
	inner join
		strains_and_conditions_inhibitor as saci
	on
		sacm.date_label= saci.date_label and
		sacm.experimental_well_label= saci.experimental_well_label
	inner join
		experimental_data_sbw_cell_area_and_counts as cac
	on
		sacm.date_label= cac.date_label and
		sacm.experimental_well_label= cac.experimental_well_label
	inner join
		experimental_data_sbw_foci_number_and_size as fnas
	on
		cac.date_label=fnas.date_label and
		cac.experimental_well_label= fnas.experimental_well_label and
		cac.timepoint= fnas.timepoint
	inner join
		cte_microscopy_intervals as cte1
	on
		sacm.date_label= cte1.date_label
	inner join
		cte_microscopy_initial_delays as cte2
	on
		sacm.date_label= cte2.date_label
	where
		sacm.date_label in (select * from cte_inhib_experiments) and
        cac.timepoint > p_init_tmpts_skip;
end //
delimiter ;
call p_inhibitor_sbw_data('CHX', 3);


-- pulls all relevant single-cell data for a specific inhibitor (and other inhibitors done within the same experiment)
-- input: 'p_inh_abb' abbrevation for a selected inhibitor, e.g., 'CHX' for cycloheximide
-- 		  'p_init_tmpts_skip' number of initital timepoints skipped (generally low-quality data)
drop procedure if exists hc_microscopy_data_v2.p_inhibitor_scd_data;
delimiter //
create procedure hc_microscopy_data_v2.p_inhibitor_scd_data(in p_inh_abb varchar(10), in p_init_tmpts_skip int)
begin
with
	cte_inhib_experiments as -- date_labels for all experiments including selected inhibitor
	(
	select distinct	
		ei.date_label
	from
		experiment_inhibitor as ei
	inner join
		inhibitors as i
	on
		ei.inhibitor_id=i.inhibitor_id
	where
		i.inhibitor_abbreviation= p_inh_abb
	),	
	cte_microscopy_intervals as -- date_label and microscopy interval (in mins), if multiple are relevant- multiple pairs
	(
	select distinct
		date_label,
		microscopy_interval_min
	from
		experiments
	where
		date_label in (select * from cte_inhib_experiments)
	),
	cte_microscopy_initial_delays as -- date_label and microscopy initial delay (in mins), if multiple are relevant- multiple pairs
	(
	select distinct
		date_label,
		microscopy_initial_delay_min
	from
		experiments
	where
		date_label in (select * from cte_inhib_experiments)
	)
	select -- relevant data
		sacm.date_label,
		sacm.experimental_well_label,
		sacm.biological_repeat,
		sacm.metal_concentration,
		sacm.metal_concentration_unit,
		saci.inhibitor_abbreviation,
		saci.inhibitor_concentration,
		saci.inhibitor_concentration_unit,
		saci.inhibitor_solvent,
		saci.inhibitor_solvent_concentration,
		saci.inhibitor_solvent_concentration_unit,
		-- fnaa.timepoint,
		-- cte1.microscopy_interval_min,
		-- cte2.microscopy_initial_delay_min,
		fnaa.timepoint * cte1.microscopy_interval_min - (cte1.microscopy_interval_min - cte2.microscopy_initial_delay_min) as timepoint_minutes,
		fnaa.fov_cell_id,
		fnaa.number_of_foci,
		fnaa.total_foci_area
	from
		strains_and_conditions_main as sacm
	inner join
		strains_and_conditions_inhibitor as saci
	on
		sacm.date_label= saci.date_label and
		sacm.experimental_well_label= saci.experimental_well_label
	inner join
		experimental_data_scd_foci_number_and_area as fnaa
	on
		sacm.date_label= fnaa.date_label and
		sacm.experimental_well_label= fnaa.experimental_well_label
	inner join
		cte_microscopy_intervals as cte1
	on
		sacm.date_label= cte1.date_label
	inner join
		cte_microscopy_initial_delays as cte2
	on
		sacm.date_label= cte2.date_label
	where
		sacm.date_label in (select * from cte_inhib_experiments) and
        fnaa.timepoint > p_init_tmpts_skip;
end //
delimiter ;
call p_inhibitor_scd_data('NOC', 3);


drop procedure if exists hc_microscopy_data_v2.p_inhibitors_control_data;
delimiter //
create procedure hc_microscopy_data_v2.p_inhibitors_control_data()
begin
	with 
	cte_inhib_experiments as
	(
	select distinct
		e.date_label
	from
		experiments as e
	inner join 
		experiment_types as et
	on
		e.experiment_type_id=et.experiment_type_id
	where
		et.experiment_type= 'Inhibitor'
	),	
	cte_microscopy_intervals as -- date_label and microscopy interval (in mins), if multiple are relevant- multiple pairs
	(
	select distinct
		date_label,
		microscopy_interval_min
	from
		experiments
	where
		date_label in (select * from cte_inhib_experiments)
	),
	cte_microscopy_initial_delays as -- date_label and microscopy initial delay (in mins), if multiple are relevant- multiple pairs
	(
	select distinct
		date_label,
		microscopy_initial_delay_min
	from
		experiments
	where
		date_label in (select * from cte_inhib_experiments)
	)
	select
		sacm.date_label,
		-- fnas.timepoint,
		fnas.timepoint * cte1.microscopy_interval_min - (cte1.microscopy_interval_min - cte2.microscopy_initial_delay_min) as timepoint_minutes,
		fnas.avg_number_of_foci_per_cell,
		fnas.avg_size_single_focus
	from
		strains_and_conditions_main as sacm
	inner join
		strains_and_conditions_inhibitor saci
	on
		sacm.date_label= saci.date_label and
		sacm.experimental_well_label= saci.experimental_well_label
	inner join
		experimental_data_sbw_foci_number_and_size as fnas
	on
		sacm.date_label= fnas.date_label and
		sacm.experimental_well_label= fnas.experimental_well_label 
	inner join
		cte_microscopy_intervals as cte1
	on
		sacm.date_label= cte1.date_label
	inner join
		cte_microscopy_initial_delays as cte2
	on
		sacm.date_label= cte2.date_label
	where
		sacm.date_label in (select * from cte_inhib_experiments) and
		sacm.metal_concentration= 0.5 and
		saci.inhibitor_concentration= 0 and
		saci.inhibitor_solvent_concentration= 0;
end //
delimiter ;

call p_inhibitors_control_data();



-- inhibitor sbw data pull : selected date_label (single input) and selected experimental_well_label (list)
-- pull for each inhibitor used in figures (chx, lata, noc, brfa, mg132...)
-- inputs: 'p_date_label'- date_label of a selected experiment, 'p_well_list'- list of relevant wells
drop procedure if exists hc_microscopy_data_v2.inhibitors_data_sbw;
delimiter //
create procedure hc_microscopy_data_v2.inhibitors_data_sbw(in p_date_label int, in p_well_list json)
begin
	with
	cte_date_label_initital_delay_control_strain as
	(
	select
		e.date_label,
		e.microscopy_interval_min,
		e.microscopy_initial_delay_min,
		wt.arbitrary_label
	from
		experiments as e
	inner join
		wild_types as wt
	on
		e.wild_type_control_id= wt.wild_type_control_id
	),
	cte_well_list as -- transforms the list of selected mutants (p_gene_list) into a json table
	(
	select
		*
	from
		json_table(p_well_list, '$[*]' columns(standard_name varchar(12) path '$')) as gene_list
	)
	select
		sacm.date_label,
        sacm.biological_repeat,
		fnas.timepoint,
        fnas.timepoint * cte1.microscopy_interval_min - (cte1.microscopy_interval_min - cte1.microscopy_initial_delay_min) as timepoint_minutes,
		case
			when cte1.arbitrary_label= 'erg6' then '#erg6'
			else cte1.arbitrary_label
		end as strain_arbitrary_label,
		sacm.metal_concentration as as_concentration,
		sacm.metal_concentration_unit as as_concentration_unit,
		saci.inhibitor_abbreviation,
		saci.inhibitor_concentration,
		saci.inhibitor_concentration_unit,
		saci.inhibitor_solvent,
		saci.inhibitor_solvent_concentration,
		saci.inhibitor_solvent_concentration_unit,
		round(caac.number_of_cells_with_foci/caac.number_of_cells*100, 2) as percentage_of_cells_with_agg,
		fnas.avg_number_of_foci_per_cell,
		fnas.avg_size_single_focus
	from
		strains_and_conditions_main as sacm
	inner join
		strains_and_conditions_inhibitor as saci
	on
		sacm.date_label=saci.date_label and
		sacm.experimental_well_label= saci.experimental_well_label
	inner join
		experimental_data_sbw_cell_area_and_counts as caac
	on
		sacm.date_label= caac.date_label and
		sacm.experimental_well_label= caac.experimental_well_label
	inner join
		experimental_data_sbw_foci_number_and_size as fnas
	on
		caac.date_label= fnas.date_label and
		caac.experimental_well_label= fnas.experimental_well_label and
		caac.timepoint= fnas.timepoint
	inner join
		cte_date_label_initital_delay_control_strain as cte1
	on
		sacm.date_label= cte1.date_label
	where
		sacm.date_label= p_date_label and
        sacm.experimental_well_label in (select * from cte_well_list);
end //
delimiter ;

call hc_microscopy_data_v2.inhibitors_data_sbw(20240524, '["A22", "B22", "C22", "D22", "E22", "F22", "A23", "B23", "C23", "D23", "E23", "F23", "A24", "B24", "C24", "D24", "E24", "F24"]'); -- MG132
call hc_microscopy_data_v2.inhibitors_data_sbw(20240916, '["I13", "J13", "K13", "L13", "M13", "N13", "I14", "J14", "K14", "L14", "M14", "N14", "I16", "J16", "K16", "L16", "M16", "N16"]'); -- Brefeldin A
call hc_microscopy_data_v2.inhibitors_data_sbw(20240816, '["I01", "J01", "K01", "L01", "M01", "N01", "I02", "J02", "K02", "L02", "M02", "N02", "I04", "J04", "K04", "L04", "M04", "N04"]'); -- Nocodazole
call hc_microscopy_data_v2.inhibitors_data_sbw(20240502, '["A13", "B13", "C13", "A14", "B14", "C14", "A16", "B16", "C16", "A18", "B18", "C18", "D14", "E14", "F14", "D17", "E17", "F17"]'); -- Latrunculin A
call hc_microscopy_data_v2.inhibitors_data_sbw(20240502, '["A13", "B13", "C13", "A14", "B14", "C14", "A16", "B16", "C16", "A17", "B17", "C17", "D14", "E14", "F14", "D15", "E15", "F15"]'); -- Cycloheximide



-- inhibitor scd data pull : selected date_label (single input) and selected experimental_well_label (list)
-- pull for each inhibitor used in figures (chx, lata, noc, brfa, mg132...)
-- inputs: 'p_date_label'- date_label of a selected experiment, 'p_well_list'- list of relevant wells 
drop procedure if exists hc_microscopy_data_v2.inhibitors_data_scd;
delimiter //
create procedure hc_microscopy_data_v2.inhibitors_data_scd(in p_date_label int, in p_well_list json)
begin
	with
	cte_date_label_initital_delay_control_strain as
	(
	select
		e.date_label,
		e.microscopy_interval_min,
		e.microscopy_initial_delay_min,
		wt.arbitrary_label
	from
		experiments as e
	inner join
		wild_types as wt
	on
		e.wild_type_control_id= wt.wild_type_control_id
	),
	cte_well_list as -- transforms the list of selected mutants (p_gene_list) into a json table
	(
	select
		*
	from
		json_table(p_well_list, '$[*]' columns(standard_name varchar(12) path '$')) as gene_list
	)
	select
		sacm.date_label,
        sacm.biological_repeat,
        fnaa.timepoint,
        fnaa.timepoint * cte1.microscopy_interval_min - (cte1.microscopy_interval_min - cte1.microscopy_initial_delay_min) as timepoint_minutes,
		case
			when cte1.arbitrary_label= 'erg6' then '#erg6'
			else cte1.arbitrary_label
		end as strain_arbitrary_label,
		sacm.metal_concentration as as_concentration,
		sacm.metal_concentration_unit as as_concentration_unit,
		saci.inhibitor_abbreviation,
		saci.inhibitor_concentration,
		saci.inhibitor_concentration_unit,
		saci.inhibitor_solvent,
		saci.inhibitor_solvent_concentration,
		saci.inhibitor_solvent_concentration_unit,
		concat("_", fnaa.fov_cell_id) as fov_cell_id, -- '_' prevents automatic reformatting into date dtype by excel
		fnaa.number_of_foci,
        fnaa.total_foci_area
	from
		strains_and_conditions_main as sacm
	inner join
		strains_and_conditions_inhibitor as saci
	on
		sacm.date_label=saci.date_label and
		sacm.experimental_well_label= saci.experimental_well_label
	inner join
		experimental_data_scd_foci_number_and_area as fnaa
	on
		sacm.date_label= fnaa.date_label and
		sacm.experimental_well_label= fnaa.experimental_well_label
	inner join
		cte_date_label_initital_delay_control_strain as cte1
	on
		sacm.date_label= cte1.date_label
	where
		sacm.date_label= p_date_label and
        sacm.experimental_well_label in (select * from cte_well_list);
end //
delimiter ;


call hc_microscopy_data_v2.inhibitors_data_scd(20240502, '["D14", "E14", "F14", "D17", "E17", "F17"]'); -- Latrunculin A
call hc_microscopy_data_v2.inhibitors_data_scd(20240816, '["L02", "M02", "N02", "L04", "M04", "N04"]'); -- Nocodazole
call hc_microscopy_data_v2.inhibitors_data_scd(20240916, '["L14", "M14", "N14", "L16", "M16", "N16"]'); -- Brefeldin A


