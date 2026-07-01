with raw as (
  select *
  from read_parquet('{{ var("bronze_path") }}/who_ghe_full.parquet')
)

select
  DIM_COUNTRY_CODE                                            as country_iso,
  cast(DIM_YEAR_CODE as int)                                  as year,
  DIM_GHECAUSE_TITLE                                          as indicator_name,
  DIM_SEX_CODE                                                as sex,
  try_cast(VAL_DTHS_RATE100K_NUMERIC as double)               as value,
  'WHO GHE'                                                   as source,
  concat(DIM_GHECAUSE_TITLE,'|',DIM_COUNTRY_CODE,'|',DIM_YEAR_CODE) as raw_id
from raw
where VAL_DTHS_RATE100K_NUMERIC is not null