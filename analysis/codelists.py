# Remember to update codelists.txt with new codelists prior to import
from cohortextractor import codelist_from_csv, codelist

ra_codes = codelist_from_csv(
    "codelists/opensafely-rheumatoid-arthritis.csv",
    system="ctv3",
    column="CTV3ID",)

metho_codes = codelist_from_csv(
    "codelists/opensafely-methotrexate-oral.csv",
    system="snomed",
    column="dmd_id",)

leflunomide_codes = codelist_from_csv(
    "codelists/opensafely-leflunomide-dmd.csv",
    system="snomed",
    column="dmd_id",)

sulfasalazine_codes = codelist_from_csv(
    "codelists/opensafely-sulfasalazine-oral-dmd.csv",
    system="snomed",
    column="dmd_id",)

hydroxychloroquine_codes = codelist_from_csv(
    "codelists/opensafely-hydroxychloroquine.csv",
    system="snomed",
    column="snomed_id",)

azathioprine_codes = codelist_from_csv(
    "codelists/opensafely-azathioprine-dmd.csv",
    system="dmd_id",
    column="dmd_id",)

# Ethnicity
ethnicity_codes = codelist_from_csv(
    "codelists/opensafely-ethnicity-with-categories-snomed.csv",
    system="snomed",
    column="Code",
    category_column="6_group",
)

# High risk and not high risk codes, to define clinical vulnerability to complications from COVID-19 infection/shielding
high_risk_codes = codelist(
    ['1300561000000107'],
    system="snomed",
    )

not_high_risk_codes = codelist(
    ['1300591000000101', '1300571000000100'],
    system="snomed",
    )

# Blood monitoring
ast_codes = codelist_from_csv(
    "codelists/opensafely-alanine-aminotransferase-alt-tests.csv",
    system="snomed",
    column="code",
)
rbc_codes = codelist_from_csv(
    "codelists/opensafely-red-blood-cell-rbc-tests.csv",
    system="snomed",
    column="code",
)
creatinine_codes = codelist_from_csv(
    "codelists/user-Andrew-ue-check-represented-by-serum-creatinine-level.csv",
    system="snomed",
    column="code",
)
ckd_codes=codelist_from_csv(
    "codelists/primis-covid19-vacc-uptake-ckd35.csv",
    system="snomed",
    column="code",
)
cld_codes=codelist_from_csv(
    "codelists/primis-covid19-vacc-uptake-cld_cod.csv",
    system="snomed",
    column="code",
)