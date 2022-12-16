# Create Sankey diagram of outpatient appointments
# Date: 13/12/2022

library(dplyr)
library(tidyr)
library(here)

make_long <- function(.df, ..., value = NULL) {
  if("..r" %in% names(.df)) stop("The column name '..r' is not allowed")
  .vars <- dplyr::quos(...)

  if(!missing(value)) {
    value_var <- dplyr::enquo(value)
    out <- .df %>%
      dplyr::select(!!!.vars, value = !!value_var) %>%
      dplyr::mutate(..r = dplyr::row_number()) %>%
      tidyr::gather(x, node, -..r, -value) %>%
      dplyr::arrange(.data$..r) %>%
      dplyr::group_by(.data$..r) %>%
      dplyr::mutate(next_x = dplyr::lead(.data$x),
                    next_node = dplyr::lead(.data$node)
      ) %>%
      dplyr::ungroup() %>%
      dplyr::select(-..r) %>%
      dplyr::relocate(value, .after = dplyr::last_col())
  } else {
    out <- .df %>%
      dplyr::select(!!!.vars) %>%
      dplyr::mutate(..r = dplyr::row_number()) %>%
      tidyr::gather(x, node, -..r) %>%
      dplyr::arrange(.data$..r) %>%
      dplyr::group_by(.data$..r) %>%
      dplyr::mutate(next_x = dplyr::lead(.data$x),
                    next_node = dplyr::lead(.data$node)
      ) %>%
      dplyr::ungroup() %>%
      dplyr::select(-..r)
  }

  levels <- unique(out$x)

  out %>%
    dplyr::mutate(dplyr::across(c(x, next_x), ~factor(., levels = levels)))
}


data <- read.csv("output/input.csv")
myvars <- c("outpatient_appt_2019", "outpatient_appt_2020", "outpatient_appt_2021", "patient_id")
cut_data <- data[myvars]
# Create stage variable for category of outpatient appointments for each year
cut_data$outpatient_cat_2019 <- cut(cut_data$outpatient_appt_2019,
                                breaks=c(0,1,3,Inf),
                                labels=c("None", "1-2", "3+"),
                                right = FALSE)
cut_data$outpatient_cat_2020 <- cut(cut_data$outpatient_appt_2020,
                                    breaks=c(0,1,3,Inf),
                                    labels=c("None", "1-2", "3+"),
                                    right = FALSE)
cut_data$outpatient_cat_2021 <- cut(cut_data$outpatient_appt_2021,
                                    breaks=c(0,1,3,Inf),
                                    labels=c("None", "1-2", "3+"),
                                    right = FALSE)
# Create numeric node variable for each year corresponding to category
cut_data$outpatient_node_2019 <- cut(cut_data$outpatient_appt_2019,
                                    breaks=c(0,1,3,Inf),
                                    labels=c("0", "1", "2"),
                                    right = FALSE)
cut_data$outpatient_node_2020 <- cut(cut_data$outpatient_appt_2020,
                                    breaks=c(0,1,3,Inf),
                                    labels=c("0", "1", "2"),
                                    right = FALSE)
cut_data$outpatient_node_2021 <- cut(cut_data$outpatient_appt_2021,
                                    breaks=c(0,1,3,Inf),
                                    labels=c("0", "1", "2"),
                                    right = FALSE)
sankey_compact_data <- cut_data %>%
  make_long(outpatient_cat_2019, outpatient_cat_2020, outpatient_cat_2021) %>%
  dplyr:: group_by(x, node, next_x, next_node) %>%
  dplyr:: summarise(n = n())

write.csv (sankey_compact_data, here::here ("output/", "sankey_compact.csv"))