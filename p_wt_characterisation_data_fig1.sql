use hc_microscopy_data_v2;

-- FIGURE 1, S1 and S2: WT characterisation --
# stored procedure p_wt_characterisation_data called in python scripts 'Figure1_S1_wt_characterisation' and 'FigureS2_As_pre-treatment'
# returns data from WT characterisation experiment: well labels, timepoint fields, number of cells, number of cells with foci, percentage of cells with foci, average number of foci per cell and average size of a single focus
# data on both As-exposed and control cells
# arguments: 'p_initial_timepoints_skipped': int, number of initial timepoints skipped (generally low quality data from initital timepoint, use at least 1)
#			 'p_experiment_subtype': varchar, 'basic' for Figure 1/S1 and 'pretreatment' for Figure 2
drop procedure if exists p_wt_characterisation_data;
delimiter //
create procedure p_wt_characterisation_data(in p_initial_timepoints_skipped int, in p_experiment_subtype varchar(15))
begin
	with 
	cte_wt_characterisation_date_label as # relevant experiments
	(
	select distinct
		date_label
	from
		experiments as e
	inner join
		experiment_types as et
	on
		e.experiment_type_id=et.experiment_type_id
	where
		et.experiment_type= 'WT characterisation' and
		et.experiment_subtype= p_experiment_subtype
	),
	cte_microscopy_interval as # microscopy interval for WT characterisation experiments
	(
	select distinct
		microscopy_interval_min
	from
		experiments
	where
		date_label = (select * from cte_wt_characterisation_date_label)
	),
	cte_microscopy_initial_delay as # microscopy initial delay for for WT characterisation experiments
	(
	select distinct
		microscopy_initial_delay_min
	from
		experiments
	where
		date_label = (select * from cte_wt_characterisation_date_label)
	)
	select # fields
		cac.experimental_well_label,
		cac.timepoint,
        (cac.timepoint * (select * from cte_microscopy_interval) - ((select * from cte_microscopy_interval) - (select * from cte_microscopy_initial_delay)))/60 as timepoint_hours,
		cac.timepoint * (select * from cte_microscopy_interval) - ((select * from cte_microscopy_interval) - (select * from cte_microscopy_initial_delay)) as timepoint_minutes,
		cac.number_of_cells,
		cac.number_of_cells_with_foci,
		cac.number_of_cells_with_foci/cac.number_of_cells*100 as percentage_of_cells_with_foci,
		nas.avg_number_of_foci_per_cell,
		nas.avg_size_single_focus
	from
		experimental_data_sbw_cell_area_and_counts as cac
	inner join #join
		experimental_data_sbw_foci_number_and_size as nas
	on
		cac.date_label= nas.date_label and
		cac.experimental_well_label= nas.experimental_well_label and
		cac.timepoint= nas.timepoint
	where #filtering
		cac.date_label= (select * from cte_wt_characterisation_date_label) and
		cac.timepoint > p_initial_timepoints_skipped;
end//
delimiter ;