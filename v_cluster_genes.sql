-- view of a complete experimental dataset of sbw data from TS screen first round 
-- (only experiments with 'Good' data quality included) 
create or replace view v_TS_screening_experimental_data_sbw as
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
    sacm.experimental_well_label,
	sacm.mutated_gene_systematic_name,
	sacm.mutated_gene_standard_name,
	sacm.mutation,
	case
		when sacm.mutation= 'wt control' then cte1.wt_label
		else '-'
	end as wt_label,
	caac.timepoint,
	fnaa.timepoint * cte2.interval_min - (cte2.interval_min - cte3.delay_min) as timepoint_minutes,
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

select * from v_TS_screening_experimental_data_sbw;



-- view of a complete experimental dataset of scd data from TS screen first round 
-- (only experiments with 'Good' data quality included) 
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
        sacm.experimental_well_label,
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

select -- always filter only to needed data (e.g., by 'date_label' or 'mutataed_gene_standard_name')
	* 
from 
	v_TS_screening_experimental_data_scd
where
	mutated_gene_standard_name= 'ACT1';
    

-- view of all the hit clusters with corresponding effect-stage labels and enrichments
create or replace view v_clusters_enrichments as
select distinct
    esl.effect_stage_label,
    c.cluster_label,
    e.go_enrichment_category,
    e.enrichment_description,
    ce.strength,
    ce.fdr
from
	hits_clusters as hc
inner join
	effect_stage_labels as esl
on
	hc.effect_stage_label_id=esl.effect_stage_label_id
inner join
	clusters as c
on
	hc.cluster_id=c.cluster_id
inner join
	cluster_enrichment as ce
on
	hc.cluster_id= ce.cluster_id
inner join
	enrichments as e
on
	e.enrichment_id=ce.enrichment_id;

select * from v_clusters_enrichments;

-- returns list of all hits (standard name, systematic name and sgdID), their effect-stage label and respective cluster (if applicable)
create or replace view v_cluster_genes as
select
	esl.effect_stage_label,
	c.cluster_label,
    hc.hit_systematic_name,
    uh.hit_standard_name,
    sgd.sgd_id
from
	hits_clusters as hc
inner join
	clusters as c
on
	hc.cluster_id=c.cluster_id
inner join
	unique_hits as uh
on
	hc.hit_systematic_name=uh.hit_systematic_name
inner join
	sgd_descriptions as sgd
on
	sgd.systematic_name=hc.hit_systematic_name
inner join
	effect_stage_labels as esl
on
	esl.effect_stage_label_id=hc.effect_stage_label_id
order by
	esl.effect_stage_label_id asc;

select * from v_cluster_genes;













