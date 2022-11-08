# Remember to update codelists.txt with new codelists prior to import
from cohortextractor import codelist_from_csv, codelist

ra_codes = codelist_from_csv(
    "codelists/user-ruthcostello-rheumatoid-arthritis.csv",
    system="snomed",
    column="code",)

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
    system="snomed",
    column="dmd_id",)

# Ethnicity
ethnicity_codes = codelist_from_csv(
    "codelists/opensafely-ethnicity-snomed-0removed.csv",
    system="snomed",
    column="snomedcode",
    category_column="Grouping_6",)

# High risk and not high risk codes, to define clinical vulnerability to complications from COVID-19 infection/shielding
high_risk_covid_codes = codelist(
    ['1300561000000107'],
    system="snomed",
    )

not_high_risk_covid_codes = codelist(
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
    "codelists/user-bangzheng-creatinine-value.csv",
    system="snomed",
    column="code",
)
ckd_codes=codelist_from_csv(
    "codelists/primis-covid19-vacc-uptake-ckd35.csv",
    system="snomed",
    column="code",
)
cld_codes=codelist_from_csv(
    "codelists/primis-covid19-vacc-uptake-cld.csv",
    system="snomed",
    column="code",
)
psoriasis_codes=codelist_from_csv(
    "codelists/user-ruthcostello-psoriasis.csv",
    system="snomed",
    column="code",
)
psoriatic_arthritis_codes=codelist_from_csv(
    "codelists/opensafely-psoriatic-arthritis.csv",
    system="snomed",
    column="id",
)
sle_codes=codelist_from_csv(
    "codelists/user-ruthcostello-systemic-lupus-erythematosus.csv",
    system="snomed",
    column="code",
)
ibd_codes=codelist_from_csv(
    "codelists/opensafely-inflammatory-bowel-disease.csv",
    system="ctv3",
    column="CTV3ID",
)
haem_cancer_codes=codelist_from_csv(
    "codelists/opensafely-haematological-cancer.csv",
    system="ctv3",
    column="CTV3ID",
)
spondy_codes=codelist_from_csv(
    "codelists/user-ruthcostello-spondyloarthropathy.csv",
    system="snomed",
    column="code",
)
t1dm_codes=codelist_from_csv(
    "codelists/opensafely-type-1-diabetes.csv",
    system="ctv3",
    column="CTV3ID",
)
t2dm_codes= codelist_from_csv(
    "codelists/opensafely-type-2-diabetes.csv",
    system="ctv3",
    column="CTV3ID",
)
cardiac_codes=codelist_from_csv(
    "codelists/opensafely-chronic-cardiac-disease.csv",
    system="ctv3",
    column="CTV3ID",
)
ra_hospitalisation=codelist_from_csv(
    "codelists/user-ruthcostello-ra_hospitalisation.csv",
    system="icd10",
    column="code",
)
gc_codes=codelist_from_csv(
    "codelists/opensafely-asthma-oral-prednisolone-medication.csv",
    system="snomed",
    column="snomed_id",
)
clear_smoking_codes = codelist_from_csv(
    "codelists/opensafely-smoking-clear.csv",
    system="ctv3",
    column="CTV3Code",
    category_column="Category",
)
unclear_smoking_codes = codelist_from_csv(
    "codelists/opensafely-smoking-unclear.csv",
    system="ctv3",
    column="CTV3Code",
    category_column="Category",
)
opioid_strong_codes = codelist_from_csv(
    "codelists/opensafely-opioids-strong-for-msk-conditions.csv",
    system="snomed",
    column="code",
)
opioid_weak_codes = codelist_from_csv(
    "codelists/opensafely-opioids-weak-for-msk-conditions.csv",
    system="snomed",
    column="code",
)
msk_pain_codes = codelist_from_csv(
    "codelists/user-ruthcostello-msk_pain_medicines.csv",
    system="snomed",
    column="code",
)
ssri_codes = codelist_from_csv(
    "codelists/opensafely-selective-serotonin-reuptake-inhibitors-dmd.csv",
    system="snomed",
    column="dmd_id",
)