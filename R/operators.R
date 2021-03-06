error_class_chk <- vld_spec(
  "'error_class' must be NULL or a character vector without NAs" :=
    {is.null(.) || is.character(.) && !anyNA(.)}(error_class)
)

fasten_ <- local({
  deduplicate <- function(xs, by) {
    xs[rev(!duplicated(rev(xs[[by]]))), , drop = FALSE]
  }
  as_firm_closure <- function(f) {
    if (!is_firm(f))
      class(f) <- c("firm_closure", class(f))
    f
  }
  with_sig <- function(f, sig, attrs) {
    formals(f) <- sig
    attributes(f) <- attrs
    f
  }
  function(..., error_class = NULL) {
    checks <- parse_checks(...)
    assemble_checks <- function(checks_prev, args) {
      check_all_args <- check_at_args(args)
      chks <- do.call("rbind", c(
        list(checks_prev),
        list(checks$local),
        list(check_all_args(checks$global))
      ))
      deduplicate(chks, by = "call")
    }
    error_class <- error_class[nzchar(error_class)]
    fasten_checks <- function(f, chks, sig, args) {
      error_class <- error_class %|||% vld_error_cls(f) %|||% "inputValidationError"
      fn_fastened <- validation_closure(loosely(f), chks, sig, args, error_class)
      as_firm_closure(with_sig(fn_fastened, sig, attributes(f)))
    }
    function(f) {
      sig <- formals(f)
      args <- nomen(sig)
      is_errcls_irrelevant <- is_empty(firm_checks(f)) || is_empty(error_class)
      if (is_empty(args) || is_empty(checks) && is_errcls_irrelevant)
        return(f)
      chks <- assemble_checks(firm_checks(f), args)
      fasten_checks(f, chks, sig, args)
    }
  }
})

firm_closure_extractor <- function(this) {
  force(this)
  function(f) {
    if (is_firm(f))
      .subset2(environment(f), this)
    else
      NULL
  }
}
#' @export
vld_error_cls <- firm_closure_extractor("error_class")
firm_checks   <- firm_closure_extractor("chks")
firm_core     <- firm_closure_extractor("f")

#' @export
loosely <- function(f) {
  if (!is.function(f))
    abort("'f' must be a function")
  else if (is_firm(f))
    .subset2(environment(f), "f")
  else
    f
}
#' @export
is_firm <- check_is_class("firm_closure")

#' @export
fasten <- fasten_(!!!error_class_chk)(fasten_)

#' @export
firmly <- fasten(
  "'f' must be a function" := is.function(f),
  !!!error_class_chk
)(
  function(f, ..., error_class = NULL) {
    if (is.primitive(f))
      f <- as_closure(f)
    fasten_(..., error_class = error_class)(f)
  }
)

#' @export
validate <- fasten(
  !!!error_class_chk
)(
  function(., ..., error_class = NULL) {
    validate <- firm_core(validator)(..., error_class = error_class)
    eval(bquote(validate(.(substitute(.)))))
  }
)

#' @export
validator <- fasten(
  !!!error_class_chk
)(
  function(..., error_class = NULL) {
    error_class <- error_class %|||% "objectValidationError"
    `class<-`(
      fasten_(..., error_class = error_class)(function(.) invisible(.)),
      "validator"
    )
  }
)

#' @export
print.firm_closure <- function(x, ...) {
  cat("<firm_closure>\n")
  cat("\n* Core function:\n")
  print.default(firm_core(x))
  cat("\n* Checks (<predicate>:<error message>):\n")
  chks <- firm_checks(x)
  if (length(chks)) {
    labels <- paste0(chks$call, ":\n", encodeString(chks$msg, quote = "\""))
    cat(enumerate_many(labels))
  } else {
    cat("None\n")
  }
  cat("\n* Error subclass for check errors:\n")
  subclass <- vld_error_cls(x)
  if (!is.null(subclass))
    cat(paste(subclass, collapse = ", "), "\n")
  else
    cat("None\n")
  invisible(x)
}

#' @export
print.validator <- function(x, ...) {
  cat("<validator>\n")
  cat("\n* Validation (<predicate>:<error message>):\n")
  chks <- firm_checks(x)
  if (length(chks)) {
    labels <- paste0(chks$call, ":\n", encodeString(chks$msg, quote = "\""))
    cat(enumerate_many(labels))
  } else {
    cat("None\n")
  }
  cat("\n* Error subclass for validation errors:\n")
  subclass <- vld_error_cls(x)
  if (!is.null(subclass))
    cat(paste(subclass, collapse = ", "), "\n")
  else
    cat("None\n")
  invisible(x)
}

# Documentation -----------------------------------------------------------

#' Apply a function firmly
#'
#' @description The main functions of \pkg{rong} apply or undo input validation
#'   checks to functions.
#'
#'   - `firmly()` transforms a function into a function with input validation
#'     checks
#'   - `fasten()` takes a set of input validations and returns an _operator_
#'     that applies the input validations to functions (i.e., it
#'     [curries](https://en.wikipedia.org/wiki/Currying) `firmly()`)
#'   - `loosely()` undoes the application of `firmly()`, by returning the
#'     original function (without checks)
#'
#'   These are supplemented by:
#'
#'   - `vld_error_cls()`, which extracts the subclass of the error condition
#'     that is signaled when an input validation error occurs
#'   - `is_firm()`, which checks whether an object is a firmly applied function,
#'     i.e., is created by `firmly()`
#'
#' @aliases fasten firmly loosely vld_error_cls is_firm
#' @evalRd rd_usage(c("fasten", "firmly", "loosely", "vld_error_cls", "is_firm"))
#'
#' @param f Function.
#' @param ... Input validation checks (with support for quasiquotation).
#' @param error_class Subclass of the error condition to be raised when an input
#'   validation error occurs (character). If `NULL` (the default), the error
#'   subclass is `inputValidationError`.
#' @param x Object to test.
#'
#' @section How to specify validation checks: A _validation check_ is specified
#'   by a predicate function: if the predicate yields `TRUE`, the check passes,
#'   otherwise the check fails. Any predicate function will do, provided its
#'   first argument is the object to be checked.
#'
#'   \subsection{Apply a validation check to all arguments}{
#'   Simply write the predicate when you want to apply it to all (named)
#'   arguments.
#'
#'   **Example** — To transform the function
#'   ````
#'       add <- function(x, y, z) x + y + z
#'   ````
#'   so that every argument is checked to be numeric, use the predicate
#'   `is.numeric()`:
#'   ```
#'       add_num <- firmly(add, is.numeric)
#'       add_num(1, 2, 3)        # 6
#'       add_num(1, 2, "three")  # Error: 'FALSE: is.numeric(z)'
#'   ```
#'   }
#'
#'   \subsection{Restrict a validation check to specific expressions}{
#'   Specifiy expressions (of arguments) when you want to restrict the scope of
#'   a check.
#'
#'   **Example** — To require that `y` and `z` are numeric (but not `x`
#'   necessarily), specify them as arguments of `is.numeric()` (this is valid
#'   even though `is.numeric()`, as a function, only takes a single argument):
#'   ```
#'       add_num_yz <- firmly(add, is.numeric(y, z))
#'       add_num_yz(TRUE, 2, 3)     # 6
#'       add_num_yz(TRUE, TRUE, 3)  # Error: 'FALSE: is.numeric(y)'
#'   ```
#'   }
#'
#'   \subsection{Set predicate parameters}{
#'   If a predicate has (named) parameters, you can set them as part of the
#'   check. The format for setting the parameters of a predicate, as a
#'   validation check, is
#'   ```
#'       predicate(<params_wo_default_value>, ..., <params_w_default_value>)
#'   ```
#'   where `...` is filled by the expressions to check, which you may omit when
#'   you intend to check all arguments. The order of predicate arguments is
#'   preserved within the two groups (parameters without default value vs those
#'   with default value).
#'
#'   Thus the rule for setting the parameters of `predicate()` as a _validation
#'   check_ is the same as that of `predicate()` as a _function_.
#'
#'   **Example** — You can match a regular expression with the following wrapper
#'   around `grepl()`:
#'   ```
#'       matches_regex <- function(x, regex, case_sensitive = TRUE) {
#'         isTRUE(grepl(regex, x, ignore.case = !case_sensitive))
#'       }
#'   ```
#'   As a validation check, the format for setting the parameters of this
#'   predicate is
#'   ```
#'       matches_regex(regex, ..., case_sensitive = TRUE)
#'   ```
#'   Thus the value of `regex` must be set, and may be matched by position.
#'   Setting `case_sensitive` is optional, and must be done by name.
#'   ```
#'       scot <- function(me, you) {
#'         paste0("A'm ", me, ", whaur ye fae, ", you, "?")
#'       }
#'       scot <- firmly(scot, matches_regex("^mc.*$", case_sensitive = FALSE, me))
#'       scot("McDonald", "George")  # "A'm McDonald, whaur ye fae, George?"
#'       scot("o'neill", "George")   # Error
#'   ```
#'   }
#'
#'   \subsection{Succinctly express short predicates}{
#'   Short predicates of a single argument can be succinct expressed by their
#'   body alone (enclosed in curly braces). Use `.` (dot) to indicate the
#'   argument.
#'
#'   **Example** — Monotonicity of arguments can be expressed using an ordinary
#'   (anonymous) function declaration
#'   ```
#'       add_inc <- firmly(add, (function(.) isTRUE(. > 0))(y - x, z - y))
#'       add_inc(1, 2, 3)  # 6
#'       add_inc(1, 2, 2)  # Error: 'FALSE: (function(.) isTRUE(. > 0))(z - y)'
#'   ```
#'   or more succinctly like so
#'   ```
#'       add_inc <- firmly(add, {isTRUE(. > 0)}(y - x, z - y))
#'       add_inc(1, 2, 3)  # 6
#'       add_inc(1, 2, 2)  # Error: 'FALSE: (function (.) {isTRUE(. > 0)})(z - y)'
#'   ```
#'   }
#'
#' @section How to specify error messages: You don't have to specify them at
#'   all—they are automatically generated by default, and are typically
#'   informative enough to enable you to identify the cause of failure.
#'   Nonetheless, you can make errors more comprehensible, and poinpoint their
#'   source more quickly, by providing additional contextual information.
#'
#'   Generally, error messages for validation checks are set by attaching them
#'   to the predicate. The syntax is
#'   ```
#'       <error_message> := predicate
#'   ```
#'   In the simplest case, `<error_message>` is just a literal string, such as
#'   `"x is not positive"`. But it can also be a \dQuote{smart string,} which
#'   can encode context-specific information.
#'
#'   \subsection{Specify the error message of a predicate}{TODO}
#'
#'   \subsection{Specify an error message for a specific expression}{TODO}
#'
#'   \subsection{Context-aware string interpolation of error messages}{
#'     TODO:
#'     - scope/context of string interpolation (meaning of `{{.}}`)
#'     - Two interpretations of dot (is this best?)
#'     - use of pronouns `.expr`, `.value`
#'   }
#'
#' @seealso [vld_spec()], [vld_exprs()], [validate], [predicates],
#'   [new_vld_error_msg()]
#'
#' @examples
#' bc <- function(x, y) c(x, y, 1 - x - y)
#'
#' ## Ensure that inputs are numeric
#' bc1 <- firmly(bc, is.numeric)
#' bc1(.5, .2)
#' \dontrun{
#' bc1(.5, ".2")}
#'
#' ## Use custom error messages
#' bc2 <- firmly(bc, "{{.}} is not numeric (type: {typeof(.)})" := is.numeric)
#' \dontrun{
#' bc2(.5i, ".2")}
#'
#' ## Fix values using Tidyverse quasiquotation
#' z <- 0
#' in_triangle <- vld_spec(
#'   "{{.}} is not positive (value is {.})" :=
#'     {isTRUE(. > !! z)}(x, y, 1 - x - y)
#' )
#' bc3 <- firmly(bc, is.numeric, !!! in_triangle)
#' bc3(.5, .2)
#' \dontrun{
#' bc3(.5, .6)}
#'
#' ## Highlight the core logic with fasten()
#' bc_clean <- fasten(
#'   "{{.}} is not a number" := {is.numeric(.) && length(.) == 1},
#'   "{{.}} is not positive" :=
#'     {isTRUE(. > 0)}(x, "y is not in the upper-half plane" := y, 1 - x - y)
#' )(
#'   function(x, y) {
#'     c(x, y, 1 - x - y)
#'   }
#' )
#'
#' ## Recover the underlying function with loosely()
#' loosely(bc_clean)
#'
#' @name firmly
NULL

#' Validate objects
#'
#' @aliases validate validator
#' @evalRd rd_usage(c("validate", "validator"))
#'
#' @param . Object to validate.
#' @param ... Input validation checks.
#' @param error_class Character vector of the error subclass to signal if
#'   validation fails. If `NULL` (the default), the error subclass is
#'   `objectValidationError`.
#'
#' @examples
#' # All assertions valid: data frame returned (invisibly)
#' validate(mtcars,
#'          is.data.frame,
#'          chk_all_map(is.numeric),
#'          chk_gt(10, nrow(.)),
#'          chk_has_names(c("mpg", "cyl")))
#'
#' # Some assertions invalid: diagnostic error raised
#' \dontrun{
#' validate(mtcars,
#'          is.matrix,
#'          chk_all_map(is.numeric),
#'          chk_gt(1000, nrow(.)),
#'          chk_has_name("cylinders"))}
#'
#' @name validate
NULL