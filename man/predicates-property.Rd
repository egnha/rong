% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/predicates.R
\name{predicates-property}
\alias{predicates-property}
\title{Property predicates}
\arguments{
\item{x}{Object to test.}

\item{nm, nms}{Name(s).}

\item{n}{Length.}

\item{which}{Object attribute(s).}

\item{what}{Class name.}
}
\description{
Property predicates
}
\examples{
f <- function(x, y) NULL
foo <- firmly(f, "x, y are not disjoint" := chk_empty(intersect(x, y)))
foo(letters[1:3], letters[4:5])
\dontrun{
foo(letters[1:3], letters[3:5])}

}
\seealso{
\link[=predicates-set]{Set predicates},
\code{\link[=chk_null]{chk_null()}}, \code{\link[=chk_not_null]{chk_not_null()}}
}
\alias{chk_empty}
\alias{chk_not_empty}
\alias{chk_singleton}
\alias{chk_not_na}
\alias{chk_without_na}
\alias{chk_named}
\alias{chk_has_name}
\alias{chk_has_names}
\alias{chk_has_length}
\alias{chk_has_attr}
\alias{chk_has_attrs}
\alias{chk_inherits}
\usage{
chk_empty(x)

chk_not_empty(x)

chk_singleton(x)

chk_not_na(x)

chk_without_na(x)

chk_named(x)

chk_has_name(x, nm)

chk_has_names(x, nms)

chk_has_length(x, n)

chk_has_attr(x, which)

chk_has_attrs(x, which)

chk_inherits(x, what)
}
