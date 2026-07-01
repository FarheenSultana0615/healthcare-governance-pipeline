with raw as (
  select *
  from read_parquet('{{ var("bronze_path") }}/PHC_Facilities_dataset.parquet')
),

clean as (
  select
    *,
    lower(regexp_replace(regexp_replace(trim(State), '\\s+', ' '), '[^a-z0-9\\s]', '')) as state_norm,
    regexp_extract(Year, '[0-9]{4}') as year_num
  from raw
),

mapped as (
  select
    *,
    case
      -- original 10 mappings (first char stripped)
      when state_norm like '%hhattisgarh%'      then 'chhattisgarh'
      when state_norm like '%runachal pradesh%'  then 'arunachal pradesh'
      when state_norm like '%harkhand%'          then 'jharkhand'
      when state_norm like '%ndhra pradesh%'     then 'andhra pradesh'
      when state_norm like '%aryana%'            then 'haryana'
      when state_norm like '%disha%'             then 'odisha'
      when state_norm like '%imachal pradesh%'   then 'himachal pradesh'
      when state_norm like '%ujarat%'            then 'gujarat'
      when state_norm like '%handigarh%'         then 'chandigarh'
      when state_norm like '%aharashtra%'        then 'maharashtra'
      when state_norm like '%ammu and kashmir%'  then 'jammu and kashmir'
      when state_norm like '%ssam%'              then 'assam'
      when state_norm like '%ajasthan%'          then 'rajasthan'
      when state_norm like '%arnataka%'          then 'karnataka'
      when state_norm like '%erala%'             then 'kerala'
      when state_norm like '%anipur%'            then 'manipur'
      when state_norm like '%izoram%'            then 'mizoram'
      when state_norm like '%agaland%'           then 'nagaland'
      -- extended mappings found in gold layer output
      when state_norm like '%ikkim%'             then 'sikkim'
      when state_norm like '%ripura%'            then 'tripura'
      when state_norm like '%est bengal%'        then 'west bengal'
      when state_norm like '%elhi%'              then 'delhi'
      when state_norm like '%ttarakhand%'        then 'uttarakhand'
      when state_norm like '%uducherry%'         then 'puducherry'
      when state_norm like '%unjab%'             then 'punjab'
      when state_norm like '%akshadweep%'        then 'lakshadweep'
      when state_norm like '%ndaman%'            then 'andaman and nicobar islands'
      when state_norm like '%he dadra%'          then 'dadra and nagar haveli and daman and diu'
      when state_norm like '%eghalaya%'          then 'meghalaya'
      when state_norm like '%adhya pradesh%'     then 'madhya pradesh'
      when state_norm like '%ttar pradesh%'      then 'uttar pradesh'
      when state_norm like '%ihar%'              then 'bihar'
      else state_norm
    end as state_clean
  from clean
)

select
  state_clean,
  Country                                               as country,
  year_num                                              as year,
  lower(trim(concat(state_clean, '|', year_num)))       as facility_id,
  try_cast("Number Of Sub Centers In Rural Areas (UOM:Number), Scaling Factor:1"          as int) as subcenters_rural,
  try_cast("Number Of Sub Centers In Urban Areas (UOM:Number), Scaling Factor:1"          as int) as subcenters_urban,
  try_cast("Primary Helath Centres (Phc) In Rural Areas (UOM:Number), Scaling Factor:1"   as int) as phc_rural,
  try_cast("Primary Helath Centres (Phc) In Urban Areas (UOM:Number), Scaling Factor:1"   as int) as phc_urban,
  try_cast("Community Health Centres (Chc) In Rural Areas (UOM:Number), Scaling Factor:1" as int) as chc_rural,
  try_cast("Community Health Centres (Chc) In Urban Areas (UOM:Number), Scaling Factor:1" as int) as chc_urban,
  'NDAP PHC' as raw_source
from mapped