% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/collectors.R
\name{vld_spec}
\alias{vld_spec}
\title{Specify validation checks}
\usage{
vld_spec(...)
}
\arguments{
\item{...}{Validation checks (with support for quasiquotation).}
}
\description{
Specify validation checks
}
\examples{
f <- function(x, y) "Pass"

## Make a positivity checker
chk_pos <- vld_spec("{{.}} is not positive" := {isTRUE(. > 0)}(x, x - y))
foo <- firmly(f, !!! chk_pos)

foo(2, 1)
\dontrun{
foo(1, 2)}

}
\seealso{
\code{\link[=vld_exprs]{vld_exprs()}}
}
