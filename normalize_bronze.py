import pandas as pd, pathlib
p = pathlib.Path("bronze")

# NDAP Disease
disease = pd.read_csv(p/"Disease_incidence_dataset.csv")
disease.to_parquet(p/"Disease_incidence_dataset.parquet", index=False)

# NDAP PHC
phc = pd.read_csv(p/"PHC_Facilities_dataset.csv")
phc.to_parquet(p/"PHC_Facilities_dataset.parquet", index=False)

# WHO GHE
who = pd.read_csv(p/"who_ghe_full.csv")
who.to_parquet(p/"who_ghe_full.parquet", index=False)
