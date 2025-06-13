use hc_microscopy_data_v2;

-- Figure 3 (A): TS mutant library screening 1st round
# stored procedure p_ts_screen_first_round_all_data called in python script 'Figure3_TS_screening_first_round'
# returns all data from the 1st round of TS mutant library screeniing (only 'Good' quality data): date label, plate label, well label, mutant label fields, timepoint fields, number of cells, number of cells with foci, percentage of cells with foci, size and number of foci 
# data on As-exposed cells
# arguments: 'p_initial_timepoints_skipped': int, number of initial timepoints skipped (generally low quality data from initital timepoint, use at least 1)
drop procedure if exists hc_microscopy_data_v2.p_ts_screen_first_round_all_data;
delimiter //
create procedure hc_microscopy_data_v2.p_ts_screen_first_round_all_data(in p_initital_skipped_timepoints int)
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
		scm.corresponding_collection_well_label,
		scm.mutated_gene_systematic_name,
		scm.mutated_gene_standard_name,
		scm.mutation,
        cac.timepoint,
		cac.timepoint * (select * from cte_microscopy_interval_min) - ((select * from cte_microscopy_interval_min) - (select * from cte_initital_delay_min)) as timepoint_minutes,
        (cac.timepoint * (select * from cte_microscopy_interval_min) - ((select * from cte_microscopy_interval_min) - (select * from cte_initital_delay_min)))/60 as timepoint_hours,
		cac.number_of_cells,
        cac.number_of_cells_with_foci,
		cac.number_of_cells_with_foci/cac.number_of_cells*100 as percentage_of_cells_with_foci,
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
	where -- filtering to data from TS screening 1st round
		scm.date_label in (select * from cte_TS_screen_first_round_dates) and
        cac.timepoint > p_initital_skipped_timepoints;
end//
delimiter ;