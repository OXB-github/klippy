#' @include html_dependencies.R
#' @import assertthat
#' @importFrom htmltools tags
#' @importFrom htmltools attachDependencies
#' @importFrom stringi stri_extract_all_words stri_detect_charclass
#' @importFrom grDevices col2rgb rgb
NULL

#' Insert copy to clipboard buttons in HTML documents
#'
#' `klippy` insert copy to clipboard buttons (or "klippies") in `R`
#' `Markdown` `HTML` documents. In the rendered document, "klippies"
#' are inserted in the upper left corner of the code chunks. `klippy()`
#' function is suited for a call in a `knitr` code chunk.
#'
#' `klippy()` function appends `JavaScript` functions and `CSS` in
#' the rendered document that:
#' \enumerate{
#' \item Add `klippy` to the class attribute of selected `<pre>`
#' elements.
#' \item Add a `<button>` element (a "klippy") as a child for all
#' `<pre>` elements with a `klippy` class attribute.
#' \item Instantiate `clipboard.js` event listeners and attach them to
#' `klippies`.}
#' `klippy` class can also be appended to a `<pre>` element using
#' [`knitr class.source` chunk
#' option](https://yihui.name/knitr/options/). "Klippy" buttons are not rendered if the browser does not support
#' `clipboard.js` library (see [here](https://clipboardjs.com/) for
#' details).
#'
#' @examples
#' tf <- tempfile(fileext = c(".Rmd", ".html"))
#' writeLines(
#'   c("```{r klippy, echo=FALSE, include=TRUE}",
#'     "klippy::klippy()",
#'     "```",
#'     "Insert this chunk in your `Rmd` file:",
#'     "````markdown",
#'     "`r ''````{r klippy, echo=FALSE, include=TRUE}",
#'     "klippy::klippy()",
#'     "```",
#'     "````"
#'   ),
#'   tf[1]
#' )
#'
#' rmarkdown::render(tf[1], "html_document", tf[2])
#'
#' @export
klippy <- function(lang = c("r", "markdown"),
                   all_precode = FALSE,
                   position = c("top", "left"),
                   color = "auto",
                   tooltip_message = "Copy code",
                   tooltip_success = "Copied!") {

  #' @param lang A character string or a vector of character strings with
  #'     language names. If a character string contains multiple languages
  #'     names, these names have to be separated by boundaries (e.g., spaces).
  #'     Void string can be passed to `lang` argument.
  assertthat::assert_that(is.character(lang))

  #' @param all_precode A logical scalar. If `TRUE`, a "klippy" is
  #'     added to all `HTML <pre>` elements having an `HTML <code>`
  #'     element as a child.
  assertthat::assert_that(
    is.logical(all_precode),
    assertthat::is.scalar(all_precode),
    assertthat::noNA(all_precode)
  )

  #' @param position A character vector with `klippy` position.
  #'     Accepted values are "top", "bottom", "left" and "right".
  #'     Abbreviated forms are allowed.
  position <- match.arg(position, c("top", "left", "bottom", "right"), several.ok = TRUE)
  handside <- NULL
  if ("right" %in% position)
    handside <- "right"
  if (is.null(handside))
    handside <- "left"
  if ("left" %in% position & handside == "right") {
    warning('\nKlippy positions are defined to "left".')
    handside <- "left"
  }

  headside <- NULL
  if ("bottom" %in% position)
    headside <- "bottom"
  if (is.null(headside))
    headside <- "top"
  if ("top" %in% position & headside == "bottom") {
    warning('\nKlippy positions are defined to "top".')
    headside <- "top"
  }

  #' @param color String of any of the three kinds of `R` color
  #'     specifications, i.e., either a color name (as listed by
  #'     [grDevices::colors()]), a hexadecimal string of the form
  #'     `"#rrggbb"` or `"#rrggbbaa"`
  #'     (see [grDevices::rgb()]), or a positive integer `i`
  #'     meaning `[palette][grDevices::palette]()[i]`. Default value is
  #'     `"auto"`: color is set to the anchor color of the document.
  assertthat::assert_that(
    assertthat::is.scalar(color)
  )
  if (color == "auto") {
    alpha <- 1
  } else {
    alpha <- get_color_opacity(color)
    color <- get_rgb_color(color)
  }

  #' @param tooltip_message String with the tooltip message.
  assertthat::assert_that(
    assertthat::is.string(tooltip_message),
    !stringi::stri_detect_charclass(tooltip_message, "[\\p{C}]")
  )

  #' @param tooltip_success String with the tooltip message shown when
  #'     code is successfully copied.
  assertthat::assert_that(
    assertthat::is.string(tooltip_success),
    !stringi::stri_detect_charclass(tooltip_success, "[\\p{C}]")
  )

  # Build JS script
  # Initialization:
  js_script <- ''

  if(all_precode) {
    # Add klippy class to <pre>...<code></code>...</pre> elements:
    js_script <- paste(js_script, '  addClassKlippyToPreCode();', sep = '\n')
  }

  # Add klippy class to <pre> elements with a class attribute in lang:
  classes <- unlist(stringi::stri_extract_all_words(lang))
  classes <- classes[!is.na(classes)]
  if(length(classes) > 0) {
    selector <- paste0('pre.', classes, collapse = ', ')
    js_script <- paste(
      js_script,
      paste0('  addClassKlippyTo("', selector, '");'),
      sep = '\n')
  }

  # Add a klippy button to all elements with klippy class attribute:
  js_script <- paste(
    js_script,
    sprintf(
      "  addKlippy('%s', '%s', '%s', '%s', '%s', '%s');\n",
      handside, headside, color, alpha, tooltip_message, tooltip_success
    ),
    sep = '\n'
  )

  #' @return An HTML tag object that can be rendered as HTML using
  #' [as.character()].
  # Attach dependencies to JS script:
  htmltools::attachDependencies(
    htmltools::tags$script(js_script),
    klippy_dependencies()
  )
}

get_rgb_color <- function(col) {
  col <- as.data.frame(t(grDevices::col2rgb(col)))
  with(col, grDevices::rgb(red, green, blue, maxColorValue = 255))
}

get_color_opacity <- function(col) {
  col <- as.data.frame(t(grDevices::col2rgb(col, alpha = TRUE)/255))
  col$alpha
}
