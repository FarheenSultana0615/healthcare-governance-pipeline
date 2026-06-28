with disease as (
  select * from {{ ref('mart_disease_by_state_year') }}
),

phc as (
  select * from {{ ref('mart_phc_by_state_year') }}
),

joined as (
  select
    -- dimensions
    coalesce(d.state, p.state)  as state,
    coalesce(d.year,  p.year)   as year,

    -- disease burden
    d.district_count,
    d.districts_with_malaria,
    d.avg_annual_parasite_incidence,
    d.avg_blood_exam_rate,
    d.avg_slide_positivity_rate,
    d.avg_falciparum_incidence,
    d.avg_pf_cases_pct,

    -- facility availability
    p.total_subcenters,
    p.total_phc,
    p.total_chc,
    p.subcenters_rural,
    p.subcenters_urban,
    p.phc_rural,
    p.phc_urban,

    -- derived governance metrics (the interesting stuff)
    case
      when p.total_phc > 0
      then round(d.avg_annual_parasite_incidence / p.total_phc, 6)
      else null
    end as api_per_phc,   -- malaria burden per health centre

    case
      when p.total_phc > 0 and p.total_subcenters > 0
      then round(
        (d.districts_with_malaria * 1.0 / nullif(d.district_count,0)) * 100,
        2)
      else null
    end as malaria_district_pct,  -- % of districts with active malaria

    case
      when p.total_phc is null then 'no_phc_data'
      when d.avg_annual_parasite_incidence is null then 'no_disease_data'
      else 'complete'
    end as join_quality

  from disease d
  full outer join phc p
    on d.state_year_key = p.state_year_key
)

select * from joined
where state is not null
order by state, year