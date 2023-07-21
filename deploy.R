.libPaths("/usr/local/lib/R/site-library")
cat("loading packages from:", paste("\n - ", .libPaths(), collapse = ""), "\n\n")

# set up some helper functions for fetching environment variables
defined <- function(name) {
  !is.null(Sys.getenv(name)) && Sys.getenv(name) != ""
}
required <- function(name) {
  if (!defined(name)) {
    stop("!!! input or environment variable '", name, "' not set")
  }
  Sys.getenv(name)
}
optional <- function(name) {
  if (!defined(name)) {
    return(NULL)
  }
  Sys.getenv(name)
}

# set up Repositories
setRepositories(ind = c(1,2,3,4,5))

# manually install some packages
if (!require("BiocManager", quietly = TRUE)){install.packages("BiocManager")}

BiocManager::install(c("pcaMethods", "impute"))

install.packages(c("shiny","shinyjs","shinyBS","shinyWidgets","ggplot2","ggrepel","plotly", "colourpicker","ggseqlogo","pheatmap","survminer","survival","zip","stringr","dplyr","DT","png", "svglite","ggplotify","bslib","qpdf", "rrcovNA", "e1071", "heatmaply"))

install.packages('devtools')
require(devtools)

githubPAT <- optional("INPUT_GITHUBPAT")
Sys.setenv(GITHUB_PAT = githubPAT)
install_github('evocellnet/ksea', force = TRUE)
install_github('omarwagih/rmotifx', force = TRUE)
install_github('ecnuzdd/PhosMap', force = TRUE)

# use renv to detect and install required packages.
if (file.exists("renv.lock")) {
  renv::restore(prompt = FALSE)
} else {
  renv::hydrate()
}


# resolve app dir
# Note that we are likely already executing from the app dir, as
# github sets the working directory to the workspace path on starting
# the docker image.
appDir <- ifelse(
  defined("INPUT_APPDIR"),
  required("INPUT_APPDIR"),
  required("GITHUB_WORKSPACE")
)

# required inputs
appName <- required("INPUT_APPNAME")
accountName <- required("INPUT_ACCOUNTNAME")
accountToken <- required("INPUT_ACCOUNTTOKEN")
accountSecret <- required("INPUT_ACCOUNTSECRET")

# optional inputs
appFiles <- optional("INPUT_APPFILES")
appFileManifest <- optional("INPUT_APPFILEMANIFEST")
appTitle <- optional("INPUT_APPTITLE")
logLevel <- optional("INPUT_LOGLEVEL")

# process appFiles
if (!is.null(appFiles)) {
  appFiles <- unlist(strsplit(appFiles, ",", TRUE))
}

# set up account
cat("checking account info...")
rsconnect::setAccountInfo(accountName, accountToken, accountSecret)
cat(" [OK]\n")

# terminate, archive and purge existing app
rsconnect::terminateApp(appName = appName)
rsconnect::purgeApp(appName = appName)

# deploy application
rsconnect::deployApp(
  appDir = appDir,
  appFiles = appFiles,
  appFileManifest = appFileManifest,
  appName = appName,
  appTitle = appTitle,
  account = accountName
)
