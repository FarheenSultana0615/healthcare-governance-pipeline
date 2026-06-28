with raw as (
  select *
  from read_parquet('C:/Users/noorr/OneDrive/Documents/WHO/bronze/Disease_incidence_dataset.parquet')
),

clean as (
  select
    *,
    lower(regexp_replace(regexp_replace(trim(State), '\\s+', ' '), '[^a-z0-9\\s]', '')) as state_norm,
    lower(regexp_replace(regexp_replace(trim(District), '\\s+', ' '), '[^a-z0-9\\s]', '')) as district_norm,
    regexp_extract(Year, '[0-9]{4}') as year_num
  from raw
),

mapped as (
  select
    *,
    case
      when state_norm like '%hhattisgarh%'    then 'chhattisgarh'
      when state_norm like '%runachal pradesh%' then 'arunachal pradesh'
      when state_norm like '%harkhand%'        then 'jharkhand'
      when state_norm like '%ndhra pradesh%'   then 'andhra pradesh'
      when state_norm like '%aryana%'          then 'haryana'
      when state_norm like '%disha%'           then 'odisha'
      when state_norm like '%imachal pradesh%' then 'himachal pradesh'
      when state_norm like '%ujarat%'          then 'gujarat'
      when state_norm like '%handigarh%'       then 'chandigarh'
      when state_norm like '%aharashtra%'      then 'maharashtra'
      when state_norm like '%ammu and kashmir%' then 'jammu and kashmir'
      when state_norm like '%ssam%'            then 'assam'
      when state_norm like '%ajasthan%'        then 'rajasthan'
      when state_norm like '%arnataka%'        then 'karnataka'
      when state_norm like '%erala%'           then 'kerala'
      when state_norm like '%anipur%'          then 'manipur'
      when state_norm like '%izoram%'          then 'mizoram'
      when state_norm like '%agaland%'         then 'nagaland'
      else state_norm
    end as state_clean
  from clean
)

select
  state_clean,
  district_norm                                    as district_clean,
  lower(trim(concat(state_clean, '|', district_norm))) as facility_id,
  year_num                                         as year,
  try_cast("Cases Due To Plasmodium Falciparum (UOM:%(Percentage)), Scaling Factor:1"  as double) as pf_cases_pct,
  try_cast("Annual Parasite Incidence (UOM:Number), Scaling Factor:1"                  as double) as api,
  try_cast("Annual Blood Examination Rate (UOM:Number), Scaling Factor:1"              as double) as aber,
  try_cast("Slide Positivity Rate  (UOM:Number), Scaling Factor:1"                     as double) as spr,
  try_cast("Annual Falciparum Incidence   (UOM:Number), Scaling Factor:1"              as double) as afi,
  'NDAP Disease' as raw_source
from mapped