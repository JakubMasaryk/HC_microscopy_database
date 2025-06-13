use hc_microscopy_data_v2;

-- FIGURE 2: number of foci per cell (single cell data)
# stored procedure p_number_of_foci_single_cell_data_two_timepoints called in python script 'Figure2_single_cell_agg_counts' 
# returns data from WT characterisation experiment; data on number of foci per single cell (not averaged per well), 2 timepoints: well labels, timepoint fields, cell id (based on FOV-object_id), number of foci, conditions fields
# data on both As-exposed and control cells
# arguments: 'p_reference_timepoint': decimal, reference timepoint (late formation stage)
#			 'p_selected_timepoint1-3': decimal, selected timepoints (early formation, early and late relocation & fusion stage)
drop procedure if exists hc_microscopy_data_v2.p_number_of_foci_single_cell_data_two_timepoints;
delimiter //
create procedure hc_microscopy_data_v2.p_number_of_foci_single_cell_data_two_timepoints(in p_reference_timepoint decimal(4,1), in p_selected_timepoint_1 decimal(4,1), in p_selected_timepoint_2 decimal(4,1), in p_selected_timepoint_3 decimal(4,1))
begin
	select
		*
    from
    (
	with 
	cte_experiment_id as # relevant experiments
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
		et.experiment_type= 'WT characterisation' and
		et.experiment_subtype= 'basic'
	),
	cte_microscopy_interval as # microscopy interval for WT characterisation experiments
	(
	select distinct
		microscopy_interval_min
	from
		experiments
	where
		date_label in (select * from cte_experiment_id)
	),
	cte_microscopy_initial_delay as # microscopy initial delay for for WT characterisation experiments
	(
	select distinct
		microscopy_initial_delay_min
	from
		experiments
	where
		date_label in (select * from cte_experiment_id)
	)
	select # selected fields
		scd_fna.experimental_well_label,
		scd_fna.timepoint,
		scd_fna.timepoint * (select * from cte_microscopy_interval) - ((select * from cte_microscopy_interval) - (select * from cte_microscopy_initial_delay)) as timepoint_minutes,
		scd_fna.fov_cell_id,
		scd_fna.number_of_foci,
		e.tested_metal,
		sacm.metal_concentration,
		sacm.metal_concentration_unit
	from
		experimental_data_scd_foci_number_and_area as scd_fna
	inner join
		experiments as e
	on 
		e.date_label= scd_fna.date_label
	inner join 
		strains_and_conditions_main as sacm
	on
		scd_fna.date_label= sacm.date_label and
		scd_fna.experimental_well_label= sacm.experimental_well_label
	where
		scd_fna.date_label in (select * from cte_experiment_id)
	) as a
    where # filter down to 2 timepoints (reference and selected)
		a.timepoint_minutes = p_reference_timepoint or
        a.timepoint_minutes = p_selected_timepoint_1 or
        a.timepoint_minutes = p_selected_timepoint_2 or
        a.timepoint_minutes = p_selected_timepoint_3;
end //
delimiter ;