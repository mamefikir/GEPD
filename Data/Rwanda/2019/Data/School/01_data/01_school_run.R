# Purpose:  Run file to pull data from Survey Solutions Server and save it to GEPD-Confidential Drive
# Author: Brian Stacy
# This file will run four R scripts in order.
# Each file can be run independently, but you will be prompted for certain paths that may not be specified
# This file will sequency the R scripts the correct way to produce an
# R markdown html file with high frequency and data quality checks for the school survey.
# 1. school_api.R                       #This file will access the Survey Solutions API and pull rawdata and paradata  
# 2. school_data_cleaner.R              #This file opens the raw data and cleans it to produce our indicators for the Dashboard

# 4. school_data_quality_checks.Rmd     #This file produces an R Markdown report containing several quality checks.

######################################
# Load Required Packages#
######################################
library(here)
library(knitr)
library(markdown)
library(rmarkdown)
######################################
# User Inputs for Run File #
######################################
# Here you need to indicate the path where you replicated the folder structures on your own computer
here() #"C:/Users/wb469649/Documents/Github/GEPD"




#Country name
country <-'RWA'
country_name <- "Rwanda"
year <- '2020'

#########################
# File paths #
#########################
#The download_folder will be the location of where raw data is downloaded from the API
#The save_folder will be the location of where cleaned data is stored



if (Sys.getenv("USERNAME") == "wb469649"){
  #project_folder  <- "//wbgfscifs01/GEDEDU/datalib-edu/projects/gepd"
  project_folder  <- "//wbgfscifs01/GEDEDU/datalib-edu/projects/GEPD-Confidential/CNT/"
  download_folder <-file.path(paste(project_folder,country,paste(country,year,"GEPD", sep="_"),paste(country,year,"GEPD_v01_RAW", sep="_"),"Data/raw/School", sep="/"))
  confidential_folder <- file.path(paste(project_folder,country,paste(country,year,"GEPD", sep="_"),paste(country,year,"GEPD_v01_RAW", sep="_"),"Data/confidential/School", sep="/"))
  save_folder <- file.path(paste(project_folder,country,paste(country,year,"GEPD", sep="_"),paste(country,year,"GEPD_v01_RAW", sep="_"),"Data/anonymized/School", sep="/"))
  backup_onedrive="no"
  save_folder_onedrive <- file.path(paste("C:/Users/wb469649/WBG/Ezequiel Molina - Dashboard (Team Folder)/Country_Work/",country_name,year,"Data/clean/School", sep="/"))
  
} else {
  download_folder <- choose.dir(default = "", caption = "Select folder to open data downloaded from API")
  save_folder <- choose.dir(default = "", caption = "Select folder to save final data")

}



#########################
# Launch Code
########################
#move working directory to github main folder
setwd(dirname(rstudioapi::getSourceEditorContext()$path))

# #launch file to access data from API
need_api=1
school_file<-"EPDash_RWA.dta"

source('02_school_api.R', local=TRUE)
 
# #launch file to clear data=
source('03_school_data_cleaner.R', local=TRUE)

source('04_school_anonymizer.R', local=TRUE)


