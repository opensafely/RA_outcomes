# Creating script for common variables: age, gender, ethnicity & IMD
from cohortextractor import patients
from codelists import *

common_variables = dict(
        # Age
        age=patients.age_as_of(
            "2019-04-01",
            return_expectations={
                "rate": "universal",
                "int": {"distribution": "population_ages"},
            },
        ),
        # Sex
        sex=patients.sex(
            return_expectations={
                "rate": "universal",
                "category": {"ratios": {"M": 0.49, "F": 0.5, "U": 0.01}},
            },
        ),
        ethnicity=patients.categorised_as(
            {"0": "DEFAULT",
                "1": "eth='1' OR (NOT eth AND ethnicity_sus='1')",
                "2": "eth='2' OR (NOT eth AND ethnicity_sus='2')",
                "3": "eth='3' OR (NOT eth AND ethnicity_sus='3')",
                "4": "eth='4' OR (NOT eth AND ethnicity_sus='4')",
                "5": "eth='5' OR (NOT eth AND ethnicity_sus='5')",
            },
            return_expectations={
                "category": {"ratios": {"1": 0.2, "2": 0.2, "3": 0.2, "4": 0.2, "5": 0.2}},
                "incidence": 1.0,
                    },
            eth=patients.with_these_clinical_events(
                    ethnicity_codes,
                    returning="category",
                    find_last_match_in_period=True,
                    include_date_of_match=False,
                    return_expectations={
                        "category": {"ratios": {"1": 0.2, "2": 0.2, "3": 0.2, "4": 0.2, "5": 0.2}},
                        "incidence": 1.00,
                        },
                    ),
                    # fill missing ethnicity from SUS
                    ethnicity_sus=patients.with_ethnicity_from_sus(
                            returning="group_6",
                            use_most_frequent_code=True,
                            return_expectations={
                                "category": {"ratios": {"1": 0.2, "2": 0.2, "3": 0.2, "4": 0.2, "5": 0.2}},
                                "incidence": 1.00,
                            },
                    ),
            ),
        has_msoa=patients.satisfying(
        "NOT (msoa = '')",
            msoa=patients.address_as_of(
            "2019-04-01",
            returning="msoa",
            ),
        return_expectations={"incidence": 0.95}
        ),
        imd=patients.categorised_as(
            {
            "0": "DEFAULT",
            "1": """index_of_multiple_deprivation >=0 AND index_of_multiple_deprivation < 32844*1/5 AND has_msoa""",
            "2": """index_of_multiple_deprivation >= 32844*1/5 AND index_of_multiple_deprivation < 32844*2/5""",
            "3": """index_of_multiple_deprivation >= 32844*2/5 AND index_of_multiple_deprivation < 32844*3/5""",
            "4": """index_of_multiple_deprivation >= 32844*3/5 AND index_of_multiple_deprivation < 32844*4/5""",
            "5": """index_of_multiple_deprivation >= 32844*4/5 AND index_of_multiple_deprivation <= 32844""",
            },
        index_of_multiple_deprivation=patients.address_as_of(
            "2019-04-01",
            returning="index_of_multiple_deprivation",
            round_to_nearest=100,
            ),
        return_expectations={
            "rate": "universal",
            "category": {
                "ratios": {
                    "0": 0.05,
                    "1": 0.19,
                    "2": 0.19,
                    "3": 0.19,
                    "4": 0.19,
                    "5": 0.19,
                    }
                },
            },
        ),
        
        urban_rural=patients.address_as_of(
            "2019-04-01",
            returning="rural_urban_classification",
            return_expectations={
                "rate": "universal",
                "category": {"ratios": {1: 0.125, 2: 0.125, 3: 0.125, 4: 0.125, 5: 0.125, 6: 0.125, 7: 0.125, 8: 0.125}},
            },
        ),
        smoking_status=patients.categorised_as(
        {
            "S": "most_recent_smoking_code = 'S'",
            "E": """
                     most_recent_smoking_code = 'E' OR (    
                       most_recent_smoking_code = 'N' AND ever_smoked   
                     )  
                """,
            "N": "most_recent_smoking_code = 'N' AND NOT ever_smoked",
            "M": "DEFAULT",
        },
        return_expectations={
            "category": {"ratios": {"S": 0.4, "E": 0.3, "N": 0.2, "M": 0.1}}
            },
        most_recent_smoking_code=patients.with_these_clinical_events(
            clear_smoking_codes,
            find_last_match_in_period=True,
            on_or_before="2019-04-01",
            returning="category",
            ),
        ever_smoked=patients.with_these_clinical_events(
            filter_codes_by_category(clear_smoking_codes, include=["S", "E"]),
            on_or_before="2019-04-01",
            ),
        ),
        bmi=patients.most_recent_bmi(
            between=["2019-04-01 - 5 years", "2019-04-01"],
            minimum_age_at_measurement=18,
            return_expectations={
                "date": {"earliest": "2010-02-01", "latest": "2020-01-31"},
                "float": {"distribution": "normal", "mean": 28, "stddev": 8},
                "incidence": 0.80,
            }
        ),
    )