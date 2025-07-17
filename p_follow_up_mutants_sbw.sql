drop procedure if exists hc_microscopy_data_v2.p_follow_up_mutants_sbw;
delimiter //
create procedure hc_microscopy_data_v2.p_follow_up_mutants_sbw(in p_skip_initital_timepoints int, in p_mutant_list json)
begin
	with 
	cte_mutant_list as -- transforms the list of selected mutants (p_gene_list) into a json table
	(
	select
		*
	from
		json_table(p_mutant_list, '$[*]' columns(standard_name varchar(12) path '$')) as gene_list
	),
	cte_selected_experiments as -- date label of selected experiment
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
		e.date_label= sacm.date_label
	where
		et.experiment_subtype= 'follow-up' and
		sacm.mutated_gene_standard_name in (select * from cte_mutant_list)
	),
	cte_selected_experiments_mic_setup as -- microscopy setup of selected experiment
	(
	select 
		e.date_label,
		e.microscopy_interval_min,
		e.microscopy_initial_delay_min
	from
		experiments as e
	inner join
		cte_selected_experiments as cte1
	on
		e.date_label= cte1.date_label
	)
	select -- selected fields
		sacm.experimental_well_label as Well,
		cac.timepoint as Timepoint,
		(cac.timepoint * cte2.microscopy_interval_min - (cte2.microscopy_interval_min - cte2.microscopy_initial_delay_min))/60 as TimepointHours,
		cac.timepoint * cte2.microscopy_interval_min - (cte2.microscopy_interval_min - cte2.microscopy_initial_delay_min) as TimepointMinutes,
		cac.number_of_cells as NumberOfCells,
		cac.number_of_cells_with_foci as NumberOfCellsContainingAggregates,
		(cac.number_of_cells_with_foci/cac.number_of_cells) * 100 as PercentageOfCellsContainingAggregates,
		fnas.avg_number_of_foci_per_cell as AverageNumberOfAggregatesPerCell,
		fnas.avg_size_single_focus as AverageSizeOfSingleAggregates,
		case
			when sacm.mutation= 'wt control' then 'WT'
			else sacm.mutation
		end as Mutant,
		case
			when sacm.metal_concentration= 0 then 'control'
			else 'As-exposed'
		end as 'Condition',
		sacm.biological_repeat as 'Repeat'
	from
		strains_and_conditions_main as sacm
	inner join
		experimental_data_sbw_cell_area_and_counts as cac
	on
		sacm.date_label= cac.date_label and
		sacm.experimental_well_label= cac.experimental_well_label
	inner join
		cte_selected_experiments_mic_setup as cte2
	on
		sacm.date_label= cte2.date_label
	inner join
		experimental_data_sbw_foci_number_and_size as fnas
	on
		fnas.date_label= cac.date_label and
		fnas.experimental_well_label= cac.experimental_well_label and
		fnas.timepoint= cac.timepoint
	where
		cac.timepoint > p_skip_initital_timepoints and
		(sacm.mutated_gene_standard_name = '-' or -- WT control data from the particular experiment/s
		sacm.mutated_gene_standard_name in (select * from cte_mutant_list)) -- selected mutants data from the particular experiment/s
;
end //
delimiter ;

-- call hc_microscopy_data_v2.p_follow_up_mutants_sbw(0, '["HRD1", "UBR1", "SLX8", "RAD6"]');
