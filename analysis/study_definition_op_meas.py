from cohortextractor import StudyDefinition, patients, codelist, codelist_from_csv, Measure  

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
    # Flags to identify people with RA 
    # Including date range as seemed to be some implausible dates
    # 1909 is 110 years prior to 2018 - so a person who was that old at 
    # baseline and was diagnosed at birth would be the maximum date
    has_ra_code=patients.with_these_clinical_events(
        codelist=ra_codes,
        between=["1909-03-01", "index_date"],
        returning="binary_flag",
    ),
    # Identifying date of first code with plausable date
    first_ra_code=patients.with_these_clinical_events(
        codelist=ra_codes,
        between=["1909-03-01", "index_date"],
        returning="date",
        date_format="YYYY-MM-DD",
        return_first_date_in_period="True",
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
     # Alternative diagnoses after RA
    alt_diag=patients.satisfying(
        """
        psoriatic_arthritis_after OR
        spondy_after""",
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
    
    # Do not want to include people with an alternative diagnosis for DMARD prescriptions
    has_alt_dmard_diag=patients.satisfying(
        """
        has_ibd OR
        has_psoriasis OR
        has_psoriatic_arthritis OR
        has_sle OR
        has_cancer
        """,
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
        (has_ra_code AND has_dmards) OR
        (number_ra_codes>=2 AND NOT alt_diag)
        """,
    ),
   
     prescribed_biologics=patients.with_high_cost_drugs(
        drug_name_matches=["abatacept", "adalimumab", "baracitinib", "certolizumab", 
        "etanercept", "golimumab", "guselkumab", "infliximab", "ixekizumab", "methotrexate_hcd",
        "rituximab", "sarilumab", "secukinumab", "tocilizumab", "tofacitinib", "upadacitinib",
        "ustekinumab"],
        on_or_before="2020-03-01",
        returning="binary_flag",
    ),
    # Determine number of appointments during years 2019-2021
    op_appt=patients.outpatient_appointment_date(
        returning="binary_flag",
        with_these_treatment_function_codes="410",
        attended="True",
        between=["index_date", "last_day_of_month(index_date)"],
        return_expectations = {"incidence": 0.7},
    ),
    op_appt_medium=patients.outpatient_appointment_date(
        returning="consultation_medium_used",
        with_these_treatment_function_codes="410",
        attended="True",
        between=["index_date", "last_day_of_month(index_date)"],
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
    op_appt_first=patients.outpatient_appointment_date(
        returning="binary_flag",
        with_these_treatment_function_codes="410",
        attended="True",
        is_first_attendance="True",
        between=["index_date", "last_day_of_month(index_date)"],
        return_expectations={
                "int": {"distribution": "normal", "mean": 3, "stddev": 1},
                "incidence": 0.6,
            },
    ),

    **common_variables
)

measures = [
    Measure(
        id="op_appt_rate",
        numerator="op_appt",
        denominator="population",
        group_by="population",
    ),
    Measure(
        id="op_appt_medium_rate",
        numerator="op_appt",
        denominator="population",
        group_by="op_appt_medium",
    ),
    Measure(
        id="op_appt_first_rate",
        numerator="op_appt_first",
        denominator="population",
        group_by="population",
    ),
]
