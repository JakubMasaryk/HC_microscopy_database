-- integration of other, relevant quantitative studies
-- based on tables 'aggregated_proteins', 'as_interacting_proteins', 'as_sensitive_mutants', 'increased_aggregation_mutants' and 'reduced_aggregation_mutants' 
-- see the respective table descriptions at: https://github.com/JakubMasaryk/HC_microscopy_database/blob/schema/tables_READ_ME
-- all s. cerevisiae annotated ORFs listed (based on SGD), if the particular ORF was idetified as a hit in a given quntitative study- 1 (if not- 0)
-- description of putative protein-products function for particular ORF listed at the end
create or replace view hc_microscopy_data_v2.v_quantitative_studies_overview as
select
	sd.systematic_name,
  sd.standard_name,
  case
	  when ap.systematic_name is null then 0
    else 1
	end as aggregating_protein,
	case
		when aip.systematic_name is null then 0
    else 1
	end as as_binding_protein,
	case
		when asm.systematic_name is null then 0
    else 1
	end as as_sensitive_mutation,
	case
	  when ram.systematic_name is null then 0
    else 1
	end as reduced_aggregation_mutation,
	case
		when iam.systematic_name is null then 0
    else 1
	end as increased_aggregation_mutation,
    sd.description
from
	sgd_descriptions as sd
left join
	aggregated_proteins as ap
on
	sd.systematic_name=ap.systematic_name
left join
	as_interacting_proteins as aip
on
	sd.systematic_name=aip.systematic_name
left join
	as_sensitive_mutants as asm
on
	sd.systematic_name=asm.systematic_name
left join
	reduced_aggregation_mutants as ram
on
	sd.systematic_name=ram.systematic_name
left join
	increased_aggregation_mutants as iam
on
	sd.systematic_name=iam.systematic_name
where
	sd.sgd_id != '-';
