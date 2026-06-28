with phc as (
  select * from {{ ref('stg_ndap_phc') }}
)

select
  state_clean                                  as state,
  year,
  country,
  coalesce(subcenters_rural, 0)                as subcenters_rural,
  coalesce(subcenters_urban, 0)                as subcenters_urban,
  coalesce(phc_rural,        0)                as phc_rural,
  coalesce(phc_urban,        0)                as phc_urban,
  coalesce(chc_rural,        0)                as chc_rural,
  coalesce(chc_urban,        0)                as chc_urban,
  (coalesce(subcenters_rural,0) + coalesce(subcenters_urban,0)) as total_subcenters,
  (coalesce(phc_rural,0)        + coalesce(phc_urban,0))        as total_phc,
  (coalesce(chc_rural,0)        + coalesce(chc_urban,0))        as total_chc,
  lower(trim(concat(state_clean, '|', year)))  as state_year_key
from phc
where state_clean is not null
  and year        is not null