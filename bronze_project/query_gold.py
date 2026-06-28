import duckdb

con = duckdb.connect('C:/Users/noorr/OneDrive/Documents/WHO/bronze_project/bronze.duckdb')

print('=== TOP AT-RISK STATES ===')
print(con.execute("""
    SELECT state, year, risk_tier, burden_rank_in_year,
           round(api_per_phc, 4)                    as api_per_phc,
           round(avg_annual_parasite_incidence, 4)   as api,
           total_phc
    FROM gold_state_health_rankings
    WHERE risk_tier IN ('CRITICAL','HIGH')
    ORDER BY year DESC, burden_rank_in_year ASC
    LIMIT 10
""").df().to_string())

print()
print('=== WORSENING STATES ===')
print(con.execute("""
    SELECT state, year, api_yoy_pct_change, trend_direction, resource_adequacy
    FROM gold_yoy_trends
    WHERE trend_direction = 'WORSENING'
    ORDER BY api_yoy_pct_change DESC
    LIMIT 10
""").df().to_string())

print()
print('=== IMPROVING STATES ===')
print(con.execute("""
    SELECT state, year, api_yoy_pct_change, trend_direction, resource_adequacy
    FROM gold_yoy_trends
    WHERE trend_direction = 'IMPROVING'
    ORDER BY api_yoy_pct_change ASC
    LIMIT 10
""").df().to_string())

print()
print('=== PIPELINE STATS ===')
print(con.execute("""
    SELECT
        count(distinct state)                                               as total_states,
        count(distinct year)                                                as total_years,
        count(*)                                                            as total_rows,
        sum(CASE WHEN join_quality='complete'      THEN 1 ELSE 0 END)      as complete_rows,
        sum(CASE WHEN join_quality!='complete'     THEN 1 ELSE 0 END)      as incomplete_rows
    FROM mart_india_health
""").df().to_string())

print()
print('=== RISK TIER DISTRIBUTION ===')
print(con.execute("""
    SELECT risk_tier, count(*) as state_year_count
    FROM gold_state_health_rankings
    GROUP BY risk_tier
    ORDER BY state_year_count DESC
""").df().to_string())

con.close()