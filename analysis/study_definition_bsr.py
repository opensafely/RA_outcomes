from cohortextractor import (
StudyDefinition, 
patients, 
codelist, 
codelist_from_csv,
filter_codes_by_category,
combine_codelists,
)  

from common_variables import common_variables 
from codelists import *

all_ra_codes = combine_codelists(
    ra_codes,
    ra_codes_3_4
)

# Function to identify consecutive events
def op_appt_dates_and_mode_X(name, index_date, n):

    def var_signature(name, on_or_after, return_expectations, returning):
        return {
            name: patients.outpatient_appointment_date(
                    with_these_treatment_function_codes="410",
                    returning=returning,
                    on_or_after=on_or_after,
                    attended=True,
                    date_format="YYYY-MM-DD",
                    find_first_match_in_period=True,
                    return_expectations=return_expectations
        ),
        }
    variables = var_signature(f"{name}_date_1", index_date, return_expectations=None, returning="date")
    variables.update(var_signature(f"{name}_medium_1", index_date, return_expectations={"category": { "ratios":{ 
                "1": 0.6,
                "2": 0.2,
                "3": 0.1,
                "4": 0.1, 
                }}}, returning="consultation_medium_used"))
    for i in range(2, n+1):
        variables.update(var_signature(f"{name}_date_{i}", f"{name}_date_{i-1} + 1 day", return_expectations=None, returning="date"))
        variables.update(var_signature(f"{name}_medium_{i}", f"{name}_date_{i-1} + 1 day", return_expectations={"category": { "ratios":{ 
                "1": 0.6,
                "2": 0.2,
                "3": 0.1,
                "4": 0.1,
                }}}, returning="consultation_medium_used"))
    return variables


# Definition for objective 2 - outpatient appointments
# Include people age 18+, registered with a GP at index, with at least 3 months registration
# and a diagnosis of RA
# Exclude people with missing age, sex or STP as likely low data quality
study = StudyDefinition(
    default_expectations={
        "date": {"earliest": "1900-01-01", "latest": "today"},
        "rate": "uniform",
        "incidence": 0.5,
    },
    index_date="2019-04-01",
    population=patients.satisfying(
        """
        has_follow_up AND
        (age >=18 AND age <=110) AND
        (NOT died) AND
        (sex = 'M' OR sex = 'F') AND
        (stp != 'missing') AND
        (imd != 0) AND
        has_ra
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
    has_ra=patients.satisfying(
            """
            has_dmards OR
            (number_ra_codes>=2 AND number_strong_ra_codes>=1 AND NOT alt_diag)
            """,
             # Flags to identify people with RA 
        # Including date range as seemed to be some implausible dates
        # 1909 is 110 years prior to 2018 - so a person who was that old at 
        # baseline and was diagnosed at birth would be the maximum date
        has_ra_code=patients.with_these_clinical_events(
            codelist=all_ra_codes,
            between=["1909-03-01", "2019-04-01"],
            returning="binary_flag",
        ),
        number_ra_codes=patients.with_these_clinical_events(
            codelist=all_ra_codes,
            between=["1909-03-01", "2019-04-01"],
            return_number_of_matches_in_period="True",
            return_expectations={
                    "int": {"distribution": "normal", "mean": 3, "stddev": 1},
                    "incidence": 1,
                },
        ),
        number_strong_ra_codes=patients.with_these_clinical_events(
        codelist=ra_codes,
        between=["1909-03-01", "index_date"],
        return_number_of_matches_in_period="True",
        return_expectations={
                "int": {"distribution": "normal", "mean": 3, "stddev": 1},
                "incidence": 1,
            },
        ),
        # Identifying date of first code with plausable date
        first_ra_code=patients.with_these_clinical_events(
            codelist=all_ra_codes,
            between=["1909-03-01", "2019-04-01"],
            returning="date",
            date_format="YYYY-MM-DD",
            return_first_date_in_period="True",
        ),
        # Alternative diagnoses after RA
        psoriatic_arthritis_after=patients.with_these_clinical_events(
            codelist=psoriatic_arthritis_codes,
            on_or_after="first_ra_code",
            returning="binary_flag",
        ),
        spondy_after=patients.with_these_clinical_events(
            codelist=spondy_codes,
            on_or_after="first_ra_code",
            returning="binary_flag",
        ),
        alt_diag=patients.satisfying(
            """
            psoriatic_arthritis_after OR
            spondy_after""",
        ),

        metho_count=patients.with_these_medications(
            codelist=metho_codes,
            on_or_after="first_ra_code",
            return_number_of_matches_in_period="True",
            return_expectations={
                    "int": {"distribution": "normal", "mean": 3, "stddev": 1},
                    "incidence": 1,
                },
        ),
        sulfa_count=patients.with_these_medications(
            codelist=sulfasalazine_codes,
            on_or_after="first_ra_code",
            return_number_of_matches_in_period="True",
            return_expectations={
                    "int": {"distribution": "normal", "mean": 3, "stddev": 1},
                    "incidence": 1,
                },
        ),
        hydrox_count=patients.with_these_medications(
            codelist=hydroxychloroquine_codes,
            on_or_after="first_ra_code",
            return_number_of_matches_in_period="True",
            return_expectations={
                    "int": {"distribution": "normal", "mean": 3, "stddev": 1},
                    "incidence": 1,
                },
        ),
        leflu_count=patients.with_these_medications(
            codelist=leflunomide_codes,
            on_or_after="first_ra_code",
            return_number_of_matches_in_period="True",
            return_expectations={
                    "int": {"distribution": "normal", "mean": 3, "stddev": 1},
                    "incidence": 1,
                },
        ),
        azathioprine_count=patients.with_these_medications(
            codelist=azathioprine_codes,
            on_or_after="first_ra_code",
            return_number_of_matches_in_period="True",
            return_expectations={
                    "int": {"distribution": "normal", "mean": 3, "stddev": 1},
                    "incidence": 1,
                },
        ),
        has_ibd=patients.with_these_clinical_events(
            codelist=ibd_codes,
            between=["first_ra_code - 5 years", "first_ra_code"],
            returning="binary_flag",
            ),
        has_psoriasis=patients.with_these_clinical_events(
            codelist=psoriasis_codes,
            between=["first_ra_code - 5 years", "first_ra_code"],
            returning="binary_flag",
            ),
        has_psoriatic_arthritis=patients.with_these_clinical_events(
            codelist=psoriatic_arthritis_codes,
            between=["first_ra_code - 5 years", "first_ra_code"],
            returning="binary_flag",
            ),
        has_sle=patients.with_these_clinical_events(
            codelist=sle_codes,
            between=["first_ra_code - 5 years", "first_ra_code"],
            returning="binary_flag",
            ),
        has_cancer=patients.with_these_clinical_events(
            codelist=haem_cancer_codes,
            between=["first_ra_code - 5 years", "first_ra_code"],
            returning="binary_flag",
            ),
        # Do not want to include people with an alternative diagnosis for DMARD prescriptions
        has_alt_dmard_diag=patients.satisfying(
            """
            has_ibd OR
            has_psoriasis OR
            has_psoriatic_arthritis OR
            has_sle OR
            has_cancer
            """,
        ),
        has_dmards=patients.satisfying(
            """
            (metho_count>=2 OR
            sulfa_count>=2 OR
            hydrox_count>=2 OR
            leflu_count>=2) AND NOT
            has_alt_dmard_diag
            """,
        ),
    ),
    dereg_date=patients.date_deregistered_from_all_supported_practices(
        on_or_after="index_date",
        date_format="YYYY-MM-DD",
        return_expectations={"date": {"earliest": "2020-03-01"}}
    ),
    died_fu=patients.died_from_any_cause(
            on_or_after="index_date",
            returning="date_of_death",
            date_format="YYYY-MM-DD",
            return_expectations={"date": {"earliest": "2020-03-01"}}
    ),
    age_2019=patients.age_as_of(
            "2019-04-01",
            return_expectations={
                "rate": "universal",
                "int": {"distribution": "population_ages"},
            },
        ),
    
   **op_appt_dates_and_mode_X(
        name="op_appt",
        index_date="index_date",
        n=10
    ),

    **common_variables
)