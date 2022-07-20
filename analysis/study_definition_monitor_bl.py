from cohortextractor import StudyDefinition, patients, combine_codelists  

from common_variables import common_variables
from codelists import *

diabetes_codes=combine_codelists(
    t1dm_codes, t2dm_codes
)
# Definition for objective 1 - blood monitoring
# Include people age 18+, registered with a GP at index, with at least 3 months registration,
# a diagnosis of RA, psoriatic arthritis or psoriasis 
# and at least one year of DMARD prescribing and monitoring in year prior to index
# Exclude people with missing age, sex or STP as likely low data quality

study = StudyDefinition(
    default_expectations={
        "date": {"earliest": "1900-01-01", "latest": "today"},
        "rate": "uniform",
        "incidence": 0.5,
    },
    index_date="2018-03-01",
    population=patients.satisfying(
        """
        has_follow_up AND
        (age >=18 AND age <=110) AND
        (NOT died) AND
        (sex = 'M' OR sex = 'F') AND
        (stp != 'missing') AND
        (imd != 0) AND
        dmard_rheum_prior
        """,
    
        has_follow_up=patients.registered_with_one_practice_between(
            "index_date - 3 months", "index_date"
        ),
        died=patients.died_from_any_cause(
                on_or_before="index_date"
        ),
        stp=patients.registered_practice_as_of(
                "index_date",
                returning="stp_code",
                return_expectations={
                "category": {"ratios": {"STP1": 0.3, "STP2": 0.2, "STP3": 0.5}},
                },
        ),
    ),
household=patients.household_as_of(
    "2020-02-01",
    returning="household_size",
    return_expectations={
            "int": {"distribution": "normal", "mean": 3, "stddev": 1},
            "incidence": 1,
        },
),
care_home_type=patients.care_home_status_as_of(
    "2020-02-01",
    categorised_as={
        "PC":
        """
        IsPotentialCareHome
        AND LocationDoesNotRequireNursing='Y'
        AND LocationRequiresNursing='N'
        """,
        "PN":
        """
        IsPotentialCareHome
        AND LocationDoesNotRequireNursing='N'
        AND LocationRequiresNursing='Y'
        """,
        "PS": "IsPotentialCareHome",
        "PR": "NOT IsPotentialCareHome",
        "": "DEFAULT",
    },
    return_expectations={
        "rate": "universal",
        "category": {"ratios": {"PC": 0.05, "PN": 0.05, "PS": 0.05, "PR": 0.84, "": 0.01},},
    },
),    

# Counting number of prescriptions in year prior to index
metho_count=patients.with_these_medications(
    codelist=metho_codes,
    between=["index_date - 12 months", "index_date"],
    return_number_of_matches_in_period="True",
    return_expectations={
            "int": {"distribution": "normal", "mean": 3, "stddev": 1},
            "incidence": 1,
        },
),
aza_count=patients.with_these_medications(
    codelist=azathioprine_codes,
    between=["index_date - 12 months", "index_date"],
    return_number_of_matches_in_period="True",
    return_expectations={
            "int": {"distribution": "normal", "mean": 3, "stddev": 1},
            "incidence": 1,
        },
),
leflu_count=patients.with_these_medications(
    codelist=leflunomide_codes,
    between=["index_date - 12 months", "index_date"],
    return_number_of_matches_in_period="True",
    return_expectations={
            "int": {"distribution": "normal", "mean": 3, "stddev": 1},
            "incidence": 1,
        },
),
has_ra_code=patients.with_these_clinical_events(
    codelist=ra_codes,
    between=["1909-03-01", "index_date - 12 months"],
    returning="binary_flag",
),
has_psoriasis_code=patients.with_these_clinical_events(
    codelist=psoriasis_codes,
    between=["1909-03-01", "index_date - 12 months"],
    returning="binary_flag",
),
has_psoriatic_arthritis_code=patients.with_these_clinical_events(
    codelist=psoriatic_arthritis_codes,
    between=["1909-03-01", "index_date - 12 months"],
    returning="binary_flag",
),
first_ra_code=patients.with_these_clinical_events(
    codelist=ra_codes,
    between=["1909-03-01", "index_date - 12 months"],
    returning="date",
    return_first_date_in_period="True",
),
first_psoriasis_code=patients.with_these_clinical_events(
    codelist=psoriasis_codes,
    between=["1909-03-01", "index_date - 12 months"],
    returning="date",
    return_first_date_in_period="True",
),
first_psoriatic_arthritis_code=patients.with_these_clinical_events(
    codelist=psoriatic_arthritis_codes,
    between=["1909-03-01", "index_date - 12 months"],
    returning="date",
    return_first_date_in_period="True",
),
has_rheum_code=patients.satisfying(
    """
    has_ra_code OR
    has_psoriasis_code OR
    has_psoriatic_arthritis_code
    """
),
### MONITORING PARAMETERS
# Using AST for liver function tests and red blood cells for full blood count 
fbc_count=patients.with_these_clinical_events(
    codelist=rbc_codes,
    between=["index_date - 12 months", "index_date"],
    return_number_of_matches_in_period="True",
    return_expectations={
            "int": {"distribution": "normal", "mean": 3, "stddev": 1},
            "incidence": 1,
        },
),
lft_count=patients.with_these_clinical_events(
    codelist=ast_codes,
    between=["index_date - 12 months", "index_date"],
    return_number_of_matches_in_period="True",
    return_expectations={
            "int": {"distribution": "normal", "mean": 3, "stddev": 1},
            "incidence": 1,
        },
),
creatinine_count=patients.with_these_clinical_events(
    codelist=creatinine_codes,
    between=["index_date - 12 months", "index_date"],
    return_number_of_matches_in_period="True",
    return_expectations={
            "int": {"distribution": "normal", "mean": 3, "stddev": 1},
            "incidence": 1,
        },
),
# Consider people to have prescribing and monitoring if 4+ prescriptions 
# (allowing for prescribing for >1 month) and a diagnosis of RA, psoriasis 
# or psoriatic arthritis
dmard_rheum_prior = patients.satisfying(
    """
    (metho_count>=4 OR aza_count>=4 OR leflu_count>=4) AND
    has_rheum_code
    """,
),
# Identify people with comorbidity for stratification - CVD, CKD, CLD & diabetes
ckd_prior=patients.with_these_clinical_events(
        codelist=ckd_codes,
        on_or_before="index_date",
        returning="binary_flag",
    ),
cld_prior=patients.with_these_clinical_events(
    codelist=cld_codes,
    on_or_before="index_date",
    returning="binary_flag",
),
diabetes_prior=patients.with_these_clinical_events(
    codelist=diabetes_codes,
    on_or_before="index_date",
    returning="binary_flag",
),
cvd_prior=patients.with_these_clinical_events(
    codelist=cardiac_codes,
    on_or_before="index_date",
    returning="binary_flag",
),
comorbidity = patients.satisfying(
    """
    ckd_prior OR
    cld_prior OR 
    diabetes_prior OR
    cvd_prior
    """,),

**common_variables
)