use hc_microscopy_data_v2;

-- Figure 3 (C): data on all unique combinations of hits-effect stage labels-cluster labels (together with systematic name and SGD id)
-- used in Supplemetary Table 'Fig.3_supp_table_enrichments' sheet 'clusters_proteins'
drop procedure if exists hc_microscopy_data_v2.p_hits_labels;
delimiter //
create procedure hc_microscopy_data_v2.p_hits_labels()
begin
	with
	cte_hit_all_labels as
	(
	select
		uh.hit_standard_name,
		uh.hit_systematic_name,
		sd.sgd_id
	from
		unique_hits as uh
	inner join
		sgd_descriptions as sd
	on
		uh.hit_systematic_name= sd.systematic_name
	)
	select
		esl.effect_stage_label,
		c.cluster_label,
		clus_lab.hit_standard_name,
		clus_lab.hit_systematic_name,
		clus_lab.sgd_id
	from
		hits_clusters as hc
	inner join
		effect_stage_labels as esl
	on
		hc.effect_stage_label_id= esl.effect_stage_label_id
	inner join
		clusters as c
	on
		hc.cluster_id=c.cluster_id
	inner join
		cte_hit_all_labels as clus_lab
	on
		hc.hit_systematic_name=clus_lab.hit_systematic_name
	where
		c.cluster_id != 0
	order by
		hc.effect_stage_label_id asc,
		c.cluster_id asc;
end //
delimiter ;