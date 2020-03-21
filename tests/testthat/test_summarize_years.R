library("fars")

test_that(
    "fars_summarize_years argument and value are consistent", {
        years <- c(2015, 2013, 2015)
        result <- fars_summarize_years(years)
        expect_that(result, is_a('tbl_df'))
        expect_that(
            length(unique(years)),
            equals(dim(result)[2] - 1)
        )
    }
)
        
