from cohortextractor import StudyDefinition, patients, codelist, codelist_from_csv  

from common_variables import common_variables
from codelists import *

# Definition for objective 1 - blood monitoring
# Include people age 18+, registered with a GP at index, with at least 3 months registration,
# a diagnosis of RA (an RA code and at least 2 DMARD prescriptions)
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
        has_ra_code
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
has_ra_code=patients.with_these_clinical_events(
    codelist=ra_codes,
    on_or_before="index_date",
    returning="binary_flag",
),
number_ra_codes=patients.with_these_clinical_events(
    codelist=ra_codes,
    on_or_before="index_date",
    return_number_of_matches_in_period="True",
    return_expectations={
            "int": {"distribution": "normal", "mean": 3, "stddev": 1},
            "incidence": 1,
        },
),
first_ra_code=patients.with_these_clinical_events(
    codelist=ra_codes,
    on_or_before="index_date",
    returning="date",
    return_first_date_in_period="True",
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
sulfa_count=patients.with_these_medications(
    codelist=sulfasalazine_codes,
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
# Determine if have prescriptions in 3 month windows
metho_12_9=patients.with_these_medications(
    metho_codes,
    between=["index_date-12 months", "index_date - 9 months"],
    returning="binary_flag",
),
metho_9_6=patients.with_these_medications(
    metho_codes,
    between=["index_date-9 months", "index_date - 6 months"],
    returning="binary_flag",
),
metho_6_3=patients.with_these_medications(
    metho_codes,
    between=["index_date-6 months", "index_date - 3 months"],
    returning="binary_flag",
),
metho_3_0=patients.with_these_medications(
    metho_codes,
    between=["index_date-3 months", "index_date"],
    returning="binary_flag",
),
# sulfasalazine
sulfa_12_9=patients.with_these_medications(
    sulfasalazine_codes,
    between=["index_date-12 months", "index_date - 9 months"],
    returning="binary_flag",
),
sulfa_9_6=patients.with_these_medications(
    sulfasalazine_codes,
    between=["index_date-9 months", "index_date - 6 months"],
    returning="binary_flag",
),
sulfa_6_3=patients.with_these_medications(
    sulfasalazine_codes,
    between=["index_date-6 months", "index_date - 3 months"],
    returning="binary_flag",
),
sulfa_3_0=patients.with_these_medications(
    sulfasalazine_codes,
    between=["index_date-3 months", "index_date"],
    returning="binary_flag",
),
# leflunomide
leflu_12_9=patients.with_these_medications(
    leflunomide_codes,
    between=["index_date-12 months", "index_date - 9 months"],
    returning="binary_flag",
),
leflu_9_6=patients.with_these_medications(
    leflunomide_codes,
    between=["index_date-9 months", "index_date - 6 months"],
    returning="binary_flag",
),
leflu_6_3=patients.with_these_medications(
    leflunomide_codes,
    between=["index_date-6 months", "index_date - 3 months"],
    returning="binary_flag",
),
leflu_3_0=patients.with_these_medications(
    leflunomide_codes,
    between=["index_date-3 months", "index_date"],
    returning="binary_flag",
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
# Consider people to have prescribing and monitoring if 4+ prescriptions 
# (allowing for prescribing for >1 month) and 3+ blood tests (again allowing
# some leeway)
dmard_monitored_prior = patients.satisfying(
    """
    (metho_count>=4 OR sulfa_count>=4 OR leflu_count>=4) AND
    (fbc_count>=3 OR lft_count>=3)
    """,
),
# Identify people with comorbidity for stratification
comorbidity = patients.satisfying(
    """
    ckd_prior OR
    cld_prior
    """,
    ckd_prior=patients.with_these_clinical_events(
        codelist=ckd_codes,
        on_or_before="2018-03-01",
        returning="binary_flag",
    ),
    cld_prior=patients.with_these_clinical_events(
        codelist=cld_codes,
        on_or_before="2018-03-01",
        returning="binary_flag",
    ),
),
**common_variables
)