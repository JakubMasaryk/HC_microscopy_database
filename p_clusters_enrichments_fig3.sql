use hc_microscopy_data_v2;

-- Figure 3 (B): data on clusters and enrichments
# stored procedure p_ts_screen_first_round_all_data called in python script 'Figure3_enrichments'
# returns data on all clusters and corresponding enrichments based on hits from TS screening 1st round
# arguments: 'p_strength_threshold': minimal enrichment strength, 'p_fdr_threshold': maximal false discovery rate (fdr)
drop procedure if exists hc_microscopy_data_v2.p_clusters_enrichments;
delimiter //
create procedure hc_microscopy_data_v2.p_clusters_enrichments(in p_strength_threshold decimal(3,2), in p_fdr_threshold decimal(7,6))
begin

	with
	cte_unique_effect_stage_cluster as -- unique list of effect-stage-cluster combinations 
	(
	select distinct
		sl.effect_stage_label_id,
		sl.effect_stage_label,
		c.cluster_id,
		c.cluster_label
	from
		hits_clusters as hc
	inner join
		clusters as c
	on
		c.cluster_id= hc.cluster_id
	inner join
		effect_stage_labels as sl
	on
		hc.effect_stage_label_id= sl.effect_stage_label_id
	where
		cluster_label != 'no cluster\r'
	),
	cte_enrichments_per_cluster as -- list of clusters with corresponding number of enrichments
	(
	select
		cluster_id,
		count(distinct enrichment_id) as enrichments_per_cluster
	from
		cluster_enrichment
	group by
		cluster_id
	),
	cte_nodes_per_cluster as -- list of clusters with corresponding number of nodes/genes
	(
	select
		cluster_id,
		count(distinct hit_systematic_name) as nodes_per_cluster
	from
		hits_clusters
	group by
		cluster_id
	)
	select -- selected fields
		cte1.effect_stage_label,
		replace(replace(replace(replace(replace(cte1.cluster_label, '_', ' '), 'dna', 'DNA'), 'mrna', 'mRNA'), 'rna', 'RNA'), 'sec62 63', 'Sec62/Sec63') as cluster_label,
		case
			when e.go_enrichment_category= 'GO Process' then 'GO Biological Process'
			else 'GO Cellular Compartment'
		end as go_enrichment_category,
		e.go_id as go_enrichment_id,
		e.enrichment_description,
		ce.strength,
		round(ce.fdr, 4) as fdr,
		cte3.nodes_per_cluster,
		cte2.enrichments_per_cluster
	from
		cluster_enrichment as ce
	inner join
		enrichments as e
	on 
		ce.enrichment_id=e.enrichment_id
	inner join 
		cte_unique_effect_stage_cluster as cte1
	on
		cte1.cluster_id=ce.cluster_id
	inner join
		cte_enrichments_per_cluster as cte2
	on
		cte2.cluster_id= ce.cluster_id
	inner join
		cte_nodes_per_cluster as cte3
	on
		cte3.cluster_id= ce.cluster_id
	where
		ce.strength >=  p_strength_threshold and
        	ce.fdr < p_fdr_threshold
	order by
		cte1.effect_stage_label asc,
		cte3.nodes_per_cluster desc,
        	cluster_label asc,
        	go_enrichment_category asc,
        	ce.strength desc;
        
end //
delimiter ;