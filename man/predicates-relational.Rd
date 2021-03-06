% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/predicates.R
\name{predicates-relational}
\alias{predicates-relational}
\title{Relational predicates}
\arguments{
\item{x}{Object to test.}

\item{to}{Reference object.}

\item{lwr, upr}{Lower/upper bound.}

\item{na.rm}{Should \code{NA} values be disregarded?}
}
\description{
Relational predicates
}
\examples{
f <- function(x, y) log(y - x) / log(x)
foo <- firmly(f, chk_gt(0, x - 1, "y not greater than x" := y - x))
foo(2, 4)
\dontrun{
foo(1, 2)
foo(2, 2)}

}
\seealso{
\code{\link[=all.equal]{all.equal()}}, \code{\link[=identical]{identical()}}
}
\alias{chk_identical}
\alias{chk_not_identical}
\alias{chk_equal}
\alias{chk_not_equal}
\alias{chk_equivalent}
\alias{chk_not_equivalent}
\alias{chk_gt}
\alias{chk_lt}
\alias{chk_gte}
\alias{chk_lte}
\usage{
chk_identical(x, to)

chk_not_identical(x, to)

chk_equal(x, to)

chk_not_equal(x, to)

chk_equivalent(x, to)

chk_not_equivalent(x, to)

chk_gt(x, lwr, na.rm = FALSE)

chk_lt(x, upr, na.rm = FALSE)

chk_gte(x, lwr, na.rm = FALSE)

chk_lte(x, upr, na.rm = FALSE)
}
