from cohortextractor import StudyDefinition, patients, codelist, codelist_from_csv  

from common_variables import common_variables
from codelists import *
# Trying code to get medication info more efficiently based on code in 
# immunosuppressant-meds-research repo
def get_medication_for_dates(med_codelist, with_med_func, dates, return_count):
    if (return_count):
        returning="number_of_matches_in_period"
        return_expectations={
            "int": {"distribution": "normal", "mean": 3, "stddev": 2},
            "incidence": 0.1,
        }
    else:
        returning="binary_flag"
        return_expectations={
            "incidence": 0.1
        }
    return with_med_func(
        med_codelist,
        between=dates,
        returning=returning,
        return_expectations=return_expectations
    )

def get_medication_early_late(med_codelist, with_med_func, type):
    if (type == "latest"):
        med_params={"find_last_match_in_period": True}
    else:
        med_params={"find_first_match_in_period": True}        
    return with_med_func(
        med_codelist,
        between=["2008-03-01", "2018-02-28"],
        returning="date",
        **med_params,
        date_format="YYYY-MM",
        return_expectations={
            "incidence": 0.2,
            "date": {"earliest": "2010-01-01", "latest": "2020-02-29"},
        },
    )

def medication_counts_and_dates(var_name, med_codelist_file, needs_6m_12m=False):
    """
    Generates dictionary of covariats for a medication including counts (or binary flags for high cost drugs) and dates
    
    Takes a variable prefix and medication codelist filename (minus .csv)
    Returns a dictionary suitable for unpacking into the main study definition
    This will include all five of the items defined in the functions above
    """
    
    definitions={}
    if ("medication" in med_codelist_file):
            column_name="snomed_id"
        else:
            column_name="dmd_id"
        med_codelist=codelist_from_csv(med_codelist_file + ".csv", system="snomed", column=column_name)
        with_med_func=patients.with_these_medications
    
    med_functions=[
        ("3m_0m", get_medication_for_dates, {"dates": ["2018-01-01", "2018-03-01"], "return_count"}),
        ("6m_3m", get_medication_for_dates, {"dates": ["2017-09-01", "2017-12-31"], "return_count"}),
        ("6m_3m", get_medication_for_dates, {"dates": ["2017-08-31", "2017-06-01"], "return_count"})
    ]
    if (needs_6m_12m):
      med_functions += [("12m_6m", get_medication_for_dates, {"dates": ["2017-05-31", "2017-03-01"], "return_count": not high_cost})]
    for (suffix, fun, params) in med_functions:
        definitions[var_name + "_" + suffix] = fun(med_codelist, with_med_func, **params)
    return definitions

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
**medication_counts_and_dates("azathioprine", "opensafely-azathioprine-dmd", False),

**common_variables
)

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