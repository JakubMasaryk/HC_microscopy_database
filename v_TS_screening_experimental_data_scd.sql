create or replace view v_TS_screening_experimental_data_scd as
with cte_selected_experiments as -- selected experiments + wt label (arbitrary, genotype listed elsewhere)
(
select 
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
),
cte_microscopy_intervals as -- date_label and microscopy interval (in mins), if multiple are relevant- multiple pairs
(
select distinct
	date_label,
	microscopy_interval_min as interval_min
from
	experiments
where
	date_label in (select exp_label from cte_selected_experiments)
),
cte_microscopy_initial_delays as -- date_label and microscopy initial delay (in mins), if multiple are relevant- multiple pairs
(
select distinct
	date_label,
	microscopy_initial_delay_min as delay_min
from
	experiments
where
	date_label in (select exp_label from cte_selected_experiments)
)
select
	sacm.date_label,
    sacm.collection_plate_label,
    sacm.mutated_gene_systematic_name,
    sacm.mutated_gene_standard_name,
    sacm.mutation,
    case
		when sacm.mutation= 'wt control' then cte1.wt_label
        else '-'
	end as wt_label,
    fnaa.timepoint,
	fnaa.timepoint * cte2.interval_min - (cte2.interval_min - cte3.delay_min) as timepoint_minutes,
    fnaa.fov_cell_id,
    fnaa.number_of_foci,
    fnaa.total_foci_area
from
	strains_and_conditions_main as sacm
inner join
	cte_selected_experiments as cte1
on
	sacm.date_label=cte1.exp_label
inner join
	experimental_data_scd_foci_number_and_area as fnaa
on
	sacm.date_label=fnaa.date_label and
    sacm.experimental_well_label=fnaa.experimental_well_label 
inner join
	cte_microscopy_intervals as cte2
on
	sacm.date_label=cte2.date_label
inner join
	cte_microscopy_initial_delays as cte3
on
	sacm.date_label= cte3.date_label
order by
	sacm.collection_plate_label asc,
    sacm.experimental_well_label asc,
    fnaa.timepoint asc
;

select -- always filter only to needed data (e.g., by 'date_label' or 'mutataed_gene_standard_name'
	* 
from 
	v_TS_screening_experimental_data_scd
where
	mutated_gene_standard_name= 'ACT1';
