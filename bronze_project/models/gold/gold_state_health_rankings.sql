with base as (
  select * from {{ ref('mart_india_health') }}
  where join_quality = 'complete'
    and avg_annual_parasite_incidence is not null
    and total_phc is not null
    and total_phc > 0
),

ranked as (
  select
    state,
    year,
    avg_annual_parasite_incidence,
    avg_slide_positivity_rate,
    avg_falciparum_incidence,
    total_phc,
    total_chc,
    total_subcenters,
    api_per_phc,
    malaria_district_pct,
    district_count,
    districts_with_malaria,

    -- burden score: higher = worse health situation
    round(
      (coalesce(avg_annual_parasite_incidence, 0) * 0.4)
      + (coalesce(avg_slide_positivity_rate,  0) * 0.3)
      + (coalesce(avg_falciparum_incidence,   0) * 0.3)
    , 4) as burden_score,

    -- infrastructure score: higher = better covered
    round(
      log(total_phc + total_chc + total_subcenters + 1)
    , 4) as infrastructure_score,

    -- risk tier based on burden vs infrastructure
    case
      when avg_annual_parasite_incidence > 1
       and total_phc < 50  then 'CRITICAL'
      when avg_annual_parasite_incidence > 0.5
       and total_phc < 100 then 'HIGH'
      when avg_annual_parasite_incidence > 0.1 then 'MODERATE'
      else 'LOW'
    end as risk_tier,

    -- rank within each year
    rank() over (
      partition by year
      order by avg_annual_parasite_incidence desc nulls last
    ) as burden_rank_in_year

  from base
)

select * from ranked
order by year desc, burden_rank_in_year asc