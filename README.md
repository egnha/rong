
<!-- README.md is generated from README.Rmd. Please edit that file -->
[![Build Status](https://travis-ci.org/egnha/rong.svg?branch=master)](https://travis-ci.org/egnha/rong) [![codecov](https://codecov.io/gh/egnha/rong/branch/master/graph/badge.svg)](https://codecov.io/gh/egnha/rong)

rong
====

*The rong approach to wrong inputs. Two (w)rongs make a right.*

> *rong* is a complete reimplementation of [valaddin](https://github.com/egnha/valaddin) that supports tidyverse semantics.
>
> Since this is a major break in the API of the current [CRAN version](https://cran.r-project.org/package=valaddin) of valaddin (which appears to have no reverse dependencies), it make sense to start from a clean slate and distinguish this reconception with a new name.

Overview
--------

Dealing with invalid function inputs is a chronic pain for R users, given R’s weakly typed nature. *rong* provides pain relief in the form of an adverb, `firmly()`, that enables you to *transform* an existing function into a function with input validation checks, in a manner suitable for both programmatic and interactive use.

Additionally, rong provides:

-   `fasten()`, to help you write cleaner and more explicit function declarations in your scripts, by providing a *functional operator* that “fastens” a given set of input validations to functions (i.e., it [curries](https://en.wikipedia.org/wiki/Currying) `firmly()`)

-   `validate()`, as syntactic sugar to validate *objects*, by applying input validation to the identity function

-   `loosely()`, to undo the application of input validation checks, at any time, by returning the original function

These functions support [tidyverse semantics](https://rpubs.com/hadley/dplyr-programming) such as [quasiquotation](http://rlang.tidyverse.org/reference/quasiquotation.html) and [splicing](http://rlang.tidyverse.org/reference/quasiquotation.html), to provide a flexible yet simple grammar for input validations.

Installation
------------

``` r
# install.packages("devtools")
devtools::install_github("egnha/rong")
```

Usage
-----

To illustrate rong’s functional approach to input validation, consider the function that computes the barycentric coordinates of a point in the plane:

``` r
bc <- function(x, y) {
  c(x, y, 1 - x - y)
}
```

### When validating inputs, think *function transformation*

Imagine applying `bc()` “firmly,” exactly as before, but with the assurance that the inputs are indeed numeric. To enable this, transform `bc()` using `firmly()`, relative to the validation specified by the predicate function `is.numeric()`:

``` r
library(rong)

bc2 <- firmly(bc, is.numeric)

bc2(.5, .2)
#> [1] 0.5 0.2 0.3

bc2(.5, ".2")
#> Error: bc2(x = 0.5, y = ".2")
#> FALSE: is.numeric(y)
```

### Specify error messages that are context-aware

Using the string-interpolation syntax provided by the [glue](https://github.com/tidyverse/glue) package, make error messages more informative, by taking into account the context of an error:

``` r
bc3 <- firmly(bc, "{{.}} is not numeric (type: {typeof(.)})" := is.numeric)

bc3(.5i, ".2")
#> Error: bc3(x = 0+0.5i, y = ".2")
#> 1) x is not numeric (type: complex)
#> 2) y is not numeric (type: character)
```

### Express input validations using tidyverse idioms

rong supports [quasiquotation](http://rlang.tidyverse.org/reference/quasiquotation.html) and [splicing](http://rlang.tidyverse.org/reference/quasiquotation.html) semantics for specifying input validation checks. Checks and (custom) error messages are captured as [quosures](http://rlang.tidyverse.org/reference/quosure.html), to ensure that validations, and their error reports, are hygienically evaluated in the intended scope—transparently to the user.

``` r
z <- 0
in_triangle <- vld_spec(
  "{{.}} is not positive (value is {.})" :=
    {isTRUE(. > !! z)}(x, y, 1 - x - y)
)

bc4 <- firmly(bc, is.numeric, !!! in_triangle)

bc4(.5, .2)
#> [1] 0.5 0.2 0.3

bc4(.5, .6)
#> Error: bc4(x = 0.5, y = 0.6)
#> 1 - x - y is not positive (value is -0.1)
```

This reads as follows:

-   `vld_spec()` encapsulates the condition that `x`, `y`, `1 - x - y` are positive, as a formula [definition](http://rlang.tidyverse.org/reference/quosures.html#details). The predicate itself is succinctly expressed using [magrittr](https://github.com/tidyverse/magrittr)’s shorthand for anonymous functions. The unquoting operator `!!` ensures that the *value* of `z` is “burned into” the check.

-   The additional condition that `(x, y)` lies in a triangle is imposed by splicing it in with the `!!!` operator.

### Use the same grammar to validate objects

Validating an object (say, a data frame) is nothing other than applying an input-validated identity function to it. The function `validate()` provides a shorthand for this.

``` r
# All assumptions OK, mtcars returned invisibly
validate(mtcars,
         is.data.frame,
         chk_lt(100, nrow(.)),
         chk_has_names(c("mpg", "cyl")))

validate(mtcars,
         is.data.frame,
         chk_gt(100, nrow(.)),
         chk_has_name("cylinders"))
#> Error: validate(. = mtcars)
#> 1) nrow(.) is not greater than 100
#> 2) . does not have name "cylinders"
```

### Clarify code structure

Instead of writing

``` r
bc_cluttered <- function(x, y) {
  if (!is.numeric(x) || length(x) != 1)
    stop("x is not a number")
  if (!is.numeric(y) || length(y) != 1)    
    stop("y is not a number")
  if (!isTRUE(x > 0))
    stop("x is not positive")
  if (!isTRUE(y > 0))
    stop("y is not in the upper-half plane")
  if (!isTRUE(1 - x - y > 0))
    stop("1 - x - y is not positive")

  c(x, y, 1 - x - y)
}
```

use `fasten()` to highlight the core logic, while keeping input assumptions in sight:

``` r
bc_clean <- fasten(
  "{{.}} is not a number" := {is.numeric(.) && length(.) == 1},
  "{{.}} is not positive" :=
    {isTRUE(. > 0)}(x, "y is not in the upper-half plane" := y, 1 - x - y)
)(
  function(x, y) {
    c(x, y, 1 - x - y)
  }
)

bc_clean(.5, .2)
#> [1] 0.5 0.2 0.3

bc_clean(c(.5, .5), -.2)
#> Error: bc_clean(x = c(0.5, 0.5), y = -0.2)
#> 1) x is not positive
#> 2) 1 - x - y is not positive
#> 3) y is not in the upper-half plane
#> 4) x is not a number
```

In addition to having cleaner code, you can:

-   reduce duplication, by using the splicing operator `!!!` to reuse common input validations

-   recover the underlying “lean” function, at any time, using `loosely()`:

    ``` r
    loosely(bc_clean)
    #> function(x, y) {
    #>     c(x, y, 1 - x - y)
    #>   }
    ```

Related packages
----------------

-   rong provides a basic set of predicate functions—prefixed `chk_` for easy lookup—to specify common kinds of checks, e.g., type and property checks, comparisons, etc.

    To enrich rong’s vocabulary of predicate functions, use:

    -   specialized collections of predicate functions, such as [assertive](https://bitbucket.org/richierocks/assertive), [assertthat](https://github.com/hadley/assertthat), [checkmate](https://github.com/mllg/checkmate)

    -   [vetr](https://github.com/brodieG/vetr), which provides a concise declarative syntax to create custom predicate functions

-   Other non-functional approaches to input validation: [argufy](https://github.com/gaborcsardi/argufy), [ensurer](https://github.com/smbache/ensurer), [typeCheck](https://github.com/jimhester/typeCheck)

Acknowledgement
---------------

rong makes essential use of the [rlang](https://github.com/tidyverse/rlang) package by [Lionel Henry](https://github.com/lionel-) and [Hadley Wickham](https://github.com/hadley), which provides the engine for quasiquotation and expression capture. The [glue](https://github.com/tidyverse/glue) package by [Jim Hester](https://github.com/jimhester) enables string interpolation of error messages.

License
-------

MIT Copyright © 2017 [Eugene Ha](https://github.com/egnha)
