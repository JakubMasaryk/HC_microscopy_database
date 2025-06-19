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
