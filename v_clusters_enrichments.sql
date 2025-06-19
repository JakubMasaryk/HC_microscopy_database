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
