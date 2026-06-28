with disease as (
  select * from {{ ref('stg_ndap_disease') }}
)

select
  state_clean                        as state,
  year,
  count(distinct district_clean)     as district_count,
  round(avg(api),  4)                as avg_annual_parasite_incidence,
  round(avg(aber), 4)                as avg_blood_exam_rate,
  round(avg(spr),  4)                as avg_slide_positivity_rate,
  round(avg(afi),  4)                as avg_falciparum_incidence,
  round(avg(pf_cases_pct), 4)        as avg_pf_cases_pct,
  sum(case when api  > 0 then 1 else 0 end) as districts_with_malaria,
  lower(trim(concat(state_clean, '|', year))) as state_year_key
from disease
where state_clean is not null
  and year       is not null
group by state_clean, year