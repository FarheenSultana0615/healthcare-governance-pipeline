# diagnose_relationships.py
import duckdb
import textwrap

PARQUET_DISEASE = r"C:\Users\noorr\OneDrive\Documents\WHO\bronze\Disease_incidence_dataset.parquet"
PARQUET_PHC     = r"C:\Users\noorr\OneDrive\Documents\WHO\bronze\PHC_Facilities_dataset.parquet"

con = duckdb.connect(database=':memory:')

# Load both files into temporary views
con.execute(f"CREATE VIEW disease AS SELECT * FROM read_parquet('{PARQUET_DISEASE}')")
con.execute(f"CREATE VIEW phc     AS SELECT * FROM read_parquet('{PARQUET_PHC}')")

# Replace these expressions with the exact facility_id expressions you use in your models.
# Current assumption: disease uses lower(trim(concat(State,'|',District)))
# and phc uses lower(trim(concat(State,'|',regexp_extract(Year,'[0-9]{{4}}')))) or similar.
# Adjust the expressions below to match your staging SQL exactly.

child_key_expr = "lower(regexp_replace(regexp_replace(trim(concat(State,'|',District)), '\\\\s+', ' '), '[^a-z0-9\\| ]', ''))"
parent_key_expr = "lower(regexp_replace(regexp_replace(trim(concat(State,'|',regexp_extract(Year,'[0-9]{4}'))), '\\\\s+', ' '), '[^a-z0-9\\| ]', ''))"

# A. Count distinct missing child keys and missing rows
sql_count_missing = textwrap.dedent(f"""
select
  count(distinct child.facility_id) as missing_distinct_child_keys,
  count(*) as missing_rows
from (
  select {child_key_expr} as facility_id, *
  from disease
) as child
left join (
  select {parent_key_expr} as facility_id, *
  from phc
) as parent
  on child.facility_id = parent.facility_id
where parent.facility_id is null;
""")

# B. Top 50 distinct missing keys
sql_top_missing = textwrap.dedent(f"""
select child.facility_id, count(*) as occurrences
from (
  select {child_key_expr} as facility_id, *
  from disease
) as child
left join (
  select {parent_key_expr} as facility_id, *
  from phc
) as parent
  on child.facility_id = parent.facility_id
where parent.facility_id is null
group by child.facility_id
order by occurrences desc
limit 50;
""")

print("Running missing count...")
print(con.execute(sql_count_missing).fetchdf())

print("\\nTop 50 missing keys (facility_id, occurrences):")
print(con.execute(sql_top_missing).fetchdf())

con.close()
