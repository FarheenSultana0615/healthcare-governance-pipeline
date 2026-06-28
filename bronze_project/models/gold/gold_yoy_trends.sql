with base as (
  select * from {{ ref('mart_india_health') }}
  where join_quality = 'complete'
    and avg_annual_parasite_incidence is not null
),

with_lag as (
  select
    state,
    year,
    avg_annual_parasite_incidence   as api,
    avg_slide_positivity_rate       as spr,
    avg_falciparum_incidence        as afi,
    total_phc,
    total_subcenters,
    api_per_phc,

    -- previous year values using LAG
    lag(avg_annual_parasite_incidence) over (
      partition by state order by year
    ) as api_prev_year,

    lag(total_phc) over (
      partition by state order by year
    ) as phc_prev_year,

    lag(avg_slide_positivity_rate) over (
      partition by state order by year
    ) as spr_prev_year

  from base
),

final as (
  select
    state,
    year,
    api,
    spr,
    afi,
    total_phc,
    api_per_phc,
    api_prev_year,

    -- year-over-year change
    round(api - api_prev_year, 4)                        as api_yoy_change,

    -- % change
    case
      when api_prev_year > 0
      then round(((api - api_prev_year) / api_prev_year) * 100, 2)
      else null
    end as api_yoy_pct_change,

    -- phc growth
    total_phc - coalesce(phc_prev_year, total_phc)       as phc_yoy_change,

    -- trend label
    case
      when api_prev_year is null then 'baseline_year'
      when api < api_prev_year   then 'IMPROVING'
      when api > api_prev_year   then 'WORSENING'
      else 'STABLE'
    end as trend_direction,

    -- is infrastructure keeping up with burden?
    case
      when (api - coalesce(api_prev_year, api)) > 0
       and (total_phc - coalesce(phc_prev_year, total_phc)) <= 0
      then 'UNDER_RESOURCED'
      when (api - coalesce(api_prev_year, api)) < 0
      then 'RECOVERING'
      else 'ADEQUATE'
    end as resource_adequacy

  from with_lag
)

select * from final
order by state, year