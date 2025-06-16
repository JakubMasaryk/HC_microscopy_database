create or replace view v_TS_screening_experimental_data_sbw as
with cte_selected_experiments as
(
select distinct
	e.date_label as exp_label,
    wt.arbitrary_label as wt_label
from
	experiments as e
inner join
	experiment_types as et
on 
	e.experiment_type_id=et.experiment_type_id
inner join
	wild_types as wt
on
	e.wild_type_control_id=wt.wild_type_control_id
where
	e.data_quality= 'Good' and
    et.experiment_type= 'TS collection screening' and
    et.experiment_subtype= 'first round'
)
select
	sacm.date_label,
    sacm.collection_plate_label,
    sacm.mutated_gene_systematic_name,
    sacm.mutated_gene_standard_name,
    sacm.mutation,
    caac.timepoint,
    caac.number_of_cells_with_foci/caac.number_of_cells*100 as percentage_of_cells_with_foci,
    fnaa.avg_number_of_foci_per_cell,
    fnaa.avg_size_single_focus
from
	strains_and_conditions_main as sacm
inner join
	cte_selected_experiments as cte1
on
	sacm.date_label=cte1.exp_label
inner join
	experimental_data_sbw_cell_area_and_counts as caac
on
	sacm.date_label= caac.date_label and
	sacm.experimental_well_label= caac.experimental_well_label
inner join
	experimental_data_sbw_foci_number_and_size as fnaa
on
	sacm.date_label=fnaa.date_label and
    sacm.experimental_well_label=fnaa.experimental_well_label and
    caac.timepoint=fnaa.timepoint
order by
	sacm.collection_plate_label asc,
    sacm.experimental_well_label asc,
    fnaa.timepoint asc
;
-- select * from v_TS_screening_experimental_data_sbw;
