#!/usr/bin/env Rscript
options(repos = structure(BiocManager::repositories()))
rsconnect::deployApp(
  appDir  = "./",
  appName = "PathwayExplorer",
  account = "rwelch2",
  server  = "data-viz.it.wisc.edu")
