#' Data manipulation for ffdf.
#'
#' @param .data a ffdf
#' @param ... variables interpreted in the context of \code{.data}
#' @param inplace if \code{FALSE} (the default) the data frame will be copied
#'   prior to modification to avoid changes propagating via reference.
#' @examples
#' if (require("ffbase") && require("hflights")) {
#' # If you start with a ffdf, you end up with a ffdf
#' hflights <- as.ffdf(hflights)
#' filter(hflights, Month == 1, DayofMonth == 1, Dest == "DFW")
#' head(select(hflights, Year:DayOfWeek))
#' summarise(hflights, delay = mean(ArrDelay, na.rm = TRUE), n = length(ArrDelay))
#' head(mutate(hflights, gained = ArrDelay - DepDelay))
#' head(arrange(hflights, Dest, desc(ArrDelay)))
#'
#' # If you start with a tbl, you end up with a tbl
#' hflights2 <- as.tbl(hflights)
#' filter(hflights2, Month == 1, DayofMonth == 1, Dest == "DFW")
#' head(select(hflights2, Year:DayOfWeek))
#' summarise(hflights2, delay = mean(ArrDelay, na.rm = TRUE), n = length(ArrDelay))
#' head(mutate(hflights2, gained = ArrDelay - DepDelay))
#' head(arrange(hflights2, Dest, desc(ArrDelay)))
#' }
#' @name manip_ffdf
NULL

and_expr <- function(exprs) {
  assert_that(is.list(exprs))
  if (length(exprs) == 0) return(TRUE)
  if (length(exprs) == 1) return(exprs[[1]])

  left <- exprs[[1]]
  for (i in 2:length(exprs)) {
    left <- substitute(left & right, list(left = left, right = exprs[[i]]))
  }
  left
}

#' @rdname manip_ffdf
#' @export
filter.ffdf <- function(.data, ..., env=parent.frame()) {
  expr <- and_expr(dots(...))
  idx <- ffwhich(.data, as.expression(expr), envir=env)
  .data[idx, ]
}

#' @rdname manip_ffdf
#' @export
filter.tbl_ffdf <- function(.data, ..., env=parent.frame()) {
  tbl_ffdf(
    filter.ffdf(.data, ..., env=env)
  )
}

#' @rdname manip_ffdf
#' @export
summarise.ffdf <- function(.data, ...) {
  cols <- named_dots(...)
  
  data_env <- list2env(physical(.data), parent = parent.frame())
  data_env$count <- function() nrow(.data)
  
  for (col in names(cols)) {
    data_env[[col]] <- as.ff(eval(cols[[col]], data_env))
  }
  
  do.call("ffdf", (mget(names(cols), data_env)))
#   quote
#   l <- list()
#   for (col in names(cols)){
#     a <- substitute(.data$col, list(col=col))
#   }
#   a
}

#' @rdname manip_ffdf
#' @export
summarise.tbl_ffdf <- function(.data, ...) {
  tbl_ffdf(
    summarise.ffdf(.data$obj, ...)
  )
}

#' @rdname manip_ffdf
#' @export
mutate.ffdf <- function(.data, ..., inplace = FALSE) {
  if (!inplace) .data <- clone(.data)
  eval(substitute(transform.ffdf(.data, ...)))
}

#' @rdname manip_ffdf
#' @export
mutate.tbl_ffdf <- function(.data, ...) {
  tbl_ffdf(
    mutate.ffdf(.data, ...)
  )
}

#' @rdname manip_ffdf
#' @export
arrange.ffdf <- function(.data, ...) {
  vars <- dots(...)
  vars <- sapply(vars, function(v){substitute(.data$v, list(v=v))})
  idx <- eval(substitute(do.call("fforder", vars)))
  .data[idx,]
}

#' @rdname manip_ffdf
#' @export
arrange.tbl_ffdf <- function(.data, ...) {
  tbl_ffdf(
    arrange.ffdf(.data, ...)
  )
}

#' @rdname manip_ffdf
#' @export
select.ffdf <- function(.data, ...) {
  input <- var_eval(dots(...), .data, parent.frame())
  .data[input]
}

#' @rdname manip_ffdf
#' @export
select.tbl_ffdf <- function(.data, ...) {
  tbl_ffdf(
    select.ffdf(.data, ...)
  )
}

#' @rdname manip_ffdf
#' @export
do.ffdf <- function(.data, .f, ...) {
  list(.f(as.data.frame(.data), ...))
}

#' @rdname manip_ffdf
#' @export
do.tbl_ffdf <- function(.data, .f, ...) {
  list(.f(as.data.frame(.data$obj), ...))
}
