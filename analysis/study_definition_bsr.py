from cohortextractor import (
StudyDefinition, 
patients, 
codelist, 
codelist_from_csv,
filter_codes_by_category,
)  

from common_variables import common_variables 
from codelists import *
# Function to identify consecutive events
#def with_these_op_dates_x(name, on_or_after, n, return_expectations):

 #   def var_signature(name, on_or_after, return_expectations):
  #      return {
   #         name: patients.outpatient_appointment_date(
    #            returning="date",
     #           with_these_treatment_function_codes="410",
      #          on_or_after=on_or_after,
       #         date_format="YYYY-MM-DD",
       #         return_expectations=return_expectations
       #     ),
        #}
   # variables = var_signature(f"{name}_1", on_or_after, return_expectations)
   # for i in range(2, n+1):
   #     variables.update(var_signature(f"{name}_{i}", f"{name}_{i-1} + 1 day", return_expectations))
   # return variables

#Medium
#def with_these_op_mediums_x(name, on_or_after, n, return_expectations):

  #  def var_signature(name, on_or_after, return_expectations):
  #      return {
   #         name: patients.outpatient_appointment_date(
    #            returning="consultation_medium_used",
   #             with_these_treatment_function_codes="410",
   #             on_or_after=on_or_after,
   #             return_expectations=return_expectations
    #    ),
    #    }
  #  variables = var_signature(f"{name}_1", on_or_after, return_expectations)
  #  for i in range(2, n+1):
   #     variables.update(var_signature(f"{name}_{i}", f"{name}_{i-1} + 1 day", return_expectations))
   # return variables

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
    
    # Flags to identify people with RA 
    # Including date range as seemed to be some implausible dates
    # 1909 is 110 years prior to 2018 - so a person who was that old at 
    # baseline and was diagnosed at birth would be the maximum date
    has_ra_code=patients.with_these_clinical_events(
        codelist=ra_codes,
        between=["1909-03-01", "index_date"],
        returning="binary_flag",
    ),
    number_ra_codes=patients.with_these_clinical_events(
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
        codelist=ra_codes,
        between=["1909-03-01", "index_date"],
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
    has_ra=patients.satisfying(
        """
        has_dmards OR
        (number_ra_codes>=2 AND NOT alt_diag)
        """,
    ),
    # Determine number of appointments during years 2019-2022
    outpatient_appt_2019=patients.outpatient_appointment_date(
        returning="number_of_matches_in_period",
        with_these_treatment_function_codes="410",
        attended="True",
        between=["2019-04-01", "2020-03-31"],
        return_expectations={
                "int": {"distribution": "normal", "mean": 8, "stddev": 2},
                "incidence": 0.9,
            },
    ),
    outpatient_appt_2020=patients.outpatient_appointment_date(
        returning="number_of_matches_in_period",
        with_these_treatment_function_codes="410",
        attended="True",
        between=["2020-04-01", "2021-03-31"],
        return_expectations={
                "int": {"distribution": "normal", "mean": 8, "stddev": 2},
                "incidence": 0.9,
            },
    ),
    outpatient_appt_2021=patients.outpatient_appointment_date(
        returning="number_of_matches_in_period",
        with_these_treatment_function_codes="410",
        attended="True",
        between=["2021-04-01", "2021-12-31"],
        return_expectations={
                "int": {"distribution": "normal", "mean": 8, "stddev": 2,},
                "incidence": 0.9,
            },
    ),
    # Medium of last consultation for each year
    outpatient_medium_2019=patients.outpatient_appointment_date(
        returning="consultation_medium_used",
        with_these_treatment_function_codes="410",
        attended="True",
        between=["2019-04-01", "2020-03-31"],
        return_expectations={
           "category": { "ratios":{ 
                "1": 0.2,
                "2": 0.1,
                "3": 0.1,
                "4": 0.1,
                "5": 0.1,
                "6": 0.1,
                "7": 0.1,
                "8": 0.1,
                "98": 0.1, 
                },
            },
        },
    ),
    outpatient_medium_2020=patients.outpatient_appointment_date(
        returning="consultation_medium_used",
        with_these_treatment_function_codes="410",
        attended="True",
        between=["2020-04-01", "2021-03-31"],
        return_expectations={
           "category": { "ratios":{ 
                "1": 0.2,
                "2": 0.1,
                "3": 0.1,
                "4": 0.1,
                "5": 0.1,
                "6": 0.1,
                "7": 0.1,
                "8": 0.1,
                "98": 0.1, 
                },
            },
        },
    ),
    outpatient_medium_2021=patients.outpatient_appointment_date(
        returning="consultation_medium_used",
        with_these_treatment_function_codes="410",
        attended="True",
        between=["2021-04-01", "2021-12-31"],
        return_expectations={
            "category": { "ratios":{ 
                "1": 0.2,
                "2": 0.1,
                "3": 0.1,
                "4": 0.1,
                "5": 0.1,
                "6": 0.1,
                "7": 0.1,
                "8": 0.1,
                "98": 0.1, 
                },
            },
        },
    ),
    **common_variables
)