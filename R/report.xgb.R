#' Extreme Gradient Boosting HTML report
#'
#' This function creates an xgboost as a HTML file. Cross-validation is mandatory. Does NOT handle multiclass scenarios or non-regression/classification tasks. Does NOT handle gblinear. You cannot use \code{process_type}, \code{updater}, and \code{refresh_leaf} parameters. Add \code{quiet = TRUE} to the list of arguments to make the function "shut up" the massive verbose text.
#' 
#' @param data Type: data.table. The data to fit a xgboost model on.
#' @param label Type: vector. The label the data must fit to.
#' @param folds Type: list of numeric vectors. The folds used.
#' @param params Type: list. The parameters to pass to \code{report.xgb.helper}.
#' @param normalize Type: boolean. Whether features should be normalized before being fed to the xgboost model. Defaults to \code{TRUE}.
#' @param classification Type: boolean. Whether the task is a classification or not. Defaults to \code{TRUE}.
#' @param threshold Type: numeric. The binary threshold to use for statistics when using \code{classification == TRUE}. Defaults to \code{0.5}.
#' @param importance Type: boolean. Whether to perform feature importance computation or not. Defaults to \code{TRUE}.
#' @param unbiased Type: boolean. Whether to perform unbiased feature importance computation or not. This doubles (sometimes triples) the effective training time, therefore this must be used with caution (for the benefits of getting very accurate and unbiased feature importance from the final cross-validated models). Defaults to \code{TRUE}.
#' @param stats Type: boolean. Whether machine learning statistics should be output for model performance diagnosis. When \code{TRUE}, also returns the metrics and the out of fold predictions. Defaults to \code{TRUE}.
#' @param plots Type: boolean. Whether plotting of fitted values vs predicted values should be done. Defaults to \code{TRUE}.
#' @param plot_type Type: character. The type of plot to use for classification threshold calibration plots. \code{"p"} for points, \code{"l"} for lines, \code{"b"} for points+line, \code{"c"} for line without points, \code{"o"} for overplotted (points+line overlapping), \code{"h"} for high-density vertical lines (histogram-like), \code{"s"} for optimistic stair steps, \code{"S"} for pessimistic stair steps, \code{"n"} to plot nothing. Defaults to \code{"S"} for pessimistic stair step.
#' @param output_file Type: character. The output report file name. Defaults to \code{"report.lm.html"}.
#' @param output_dir Type: character. The output report directory name. Defaults to \code{getwd()}.
#' @param open_file Type: boolean. Whether to open the output report once it has finished computing. Defaults to \code{TRUE}.
#' @param quiet Type: boolean. Whether to "shut up" while rendering the HTML file or not. Defaults to \code{FALSE}.
#' @param ... Other arguments to pass to \code{rmarkdown::render}.
#' 
#' @return Returns a list with the machine learning metrics (\code{"Metrics"}), the machine learning probabilities (\code{"Probs"}), the folds \code{"Folds"}, the fitted values per fold (\code{"Fitted"}), the predicted values per fold (\code{"Predicted"}), the biased feature importance (\code{"BiasedImp"}), and the unbiased feature importance (\code{"UnbiasedImp"}) if they were computed. Otherwise, returns \code{TRUE}.
#' 
#' @examples
#' # No example.
#' \dontrun{
#'   library(Laurae)
#'   library(data.table)
#'   library(rmarkdown)
#'   library(xgboost)
#'   library(DT)
#'   library(formattable)
#'   library(matrixStats)
#'   library(lattice)
#'   library(R.utils)
#' }
#' 
#' @export

report.xgb <- function(data, label, folds, params, normalize = TRUE, classification = TRUE, threshold = 0.5, importance = TRUE, unbiased = TRUE, stats = TRUE, plots = TRUE, plot_type = "S", output_file = "report.xgb.html", output_dir = getwd(), open_file = TRUE, quiet = FALSE, ...) {
  
  fitted_xgb = stats_table = stats_probs = fitted_values = fitted_predicted = fitted_pre_importance = fitted_post_importance = 0 # Avoid CRAN issue
  
  # A numeric fold?
  if (length(folds) == 1) {
    folds <- kfold(y = label, k = folds, stratified = TRUE, seed = 0, named = TRUE)
  }
  
  # Create report
  reporting_file <- system.file("template_rmd/Xgboost.rmd", package = "Laurae")
  render(input = reporting_file,
         output_file = output_file,
         output_dir = output_dir,
         intermediates_dir = output_dir,
         params = list(data = data, label = label, folds = folds, params = params, classification = classification, threshold = threshold, normalize = normalize, stats = stats, plots = plots, plot_type = plot_type, fun_options = list()),
         envir = environment(),
         quiet = quiet,
         ...)
  
  # Open file?
  if (open_file) {
    report_path <- file.path(output_dir, output_file)
    browseURL(report_path)
  }
  
  # Return stats?
  if (stats) {
    return(list(Models = fitted_xgb, Metrics = stats_table, Probs = stats_probs, Folds = folds, Fitted = fitted_values, Predicted = fitted_predicted, BiasedImp = fitted_pre_importance, UnbiasedImp = fitted_post_importance))
  } else {
    return(TRUE)
  }
  
}
