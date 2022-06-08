from cohortextractor import StudyDefinition, patients, codelist, codelist_from_csv  

from common_variables import common_variables 
from codelists import *

# Definition for objective 2 - outpatient appointments
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
        (household>0 AND household <=15) AND
        (care_home_type="PR") AND
        has_ra
        """,
    ),
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
    metho_count=patients.with_these_medications(
        codelist=metho_codes,
        on_or_before="index_date",
        return_number_of_matches_in_period="True",
        return_expectations={
                "int": {"distribution": "normal", "mean": 3, "stddev": 1},
                "incidence": 1,
            },
    ),
    sulfa_count=patients.with_these_medications(
        codelist=sulfasalazine_codes,
        on_or_before="index_date",
        return_number_of_matches_in_period="True",
        return_expectations={
                "int": {"distribution": "normal", "mean": 3, "stddev": 1},
                "incidence": 1,
            },
    ),
    hydrox_count=patients.with_these_medications(
        codelist=hydroxychloroquine_codes,
        on_or_before="index_date",
        return_number_of_matches_in_period="True",
        return_expectations={
                "int": {"distribution": "normal", "mean": 3, "stddev": 1},
                "incidence": 1,
            },
    ),
    leflu_count=patients.with_these_medications(
        codelist=leflunomide_codes,
        on_or_before="index_date",
        return_number_of_matches_in_period="True",
        return_expectations={
                "int": {"distribution": "normal", "mean": 3, "stddev": 1},
                "incidence": 1,
            },
    ),
    has_dmards=patients.satisfying(
        """
        metho_count>2 OR
        sulfa_count>2 OR
        hydrox_count>2 OR
        leflu_count>2
        """,
    ),
    has_ra=patients.satisfying(
        """
        (has_ra_code AND has_dmards) OR
        number_ra_codes>2
        """,
    ),
    # Determine number of appointments during years 2018-2021
    outpatient_appt_2018=patients.outpatient_appointment_date(
        returning="number_of_matches_in_period",
        with_these_treatment_function_codes="410",
        between=["2018-03-01", "2019-02-28"],
        return_expectations={
                "int": {"distribution": "normal", "mean": 3, "stddev": 1},
                "incidence": 1,
            },
    ),
    outpatient_appt_2019=patients.outpatient_appointment_date(
        returning="number_of_matches_in_period",
        with_these_treatment_function_codes="410",
        between=["2019-03-01", "2020-02-29"],
        return_expectations={
                "int": {"distribution": "normal", "mean": 3, "stddev": 1},
                "incidence": 1,
            },
    ),
    outpatient_appt_2020=patients.outpatient_appointment_date(
        returning="number_of_matches_in_period",
        with_these_treatment_function_codes="410",
        between=["2020-03-01", "2021-02-28"],
        return_expectations={
                "int": {"distribution": "normal", "mean": 3, "stddev": 1},
                "incidence": 1,
            },
    ),
    outpatient_appt_2021=patients.outpatient_appointment_date(
        returning="number_of_matches_in_period",
        with_these_treatment_function_codes="410",
        between=["2021-03-01", "2022-02-28"],
        return_expectations={
                "int": {"distribution": "normal", "mean": 3, "stddev": 1},
                "incidence": 1,
            },
    ),
    # Medium of last consultation for each year
    outpatient_medium_2018=patients.outpatient_appointment_date(
        returning="consultation_medium_used",
        with_these_treatment_function_codes="410",
        between=["2018-03-01", "2019-02-28"],
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
    outpatient_medium_2019=patients.outpatient_appointment_date(
        returning="consultation_medium_used",
        with_these_treatment_function_codes="410",
        between=["2019-03-01", "2020-02-29"],
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
        between=["2020-03-01", "2021-02-28"],
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
        between=["2021-03-01", "2022-02-28"],
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
    prescribed_biologics=patients.with_high_cost_drugs(
        drug_name_matches=["abatacept", "adalimumab", "baracitinib", "certolizumab", 
        "etanercept", "golimumab", "guselkumab", "infliximab", "ixekizumab", "methotrexate_hcd",
        "rituximab", "sarilumab", "secukinumab", "tocilizumab", "tofacitinib", "upadacitinib",
        "ustekinumab"],
        on_or_before="2020-03-01",
        returning="binary_flag",
    ),
    **common_variables
)
