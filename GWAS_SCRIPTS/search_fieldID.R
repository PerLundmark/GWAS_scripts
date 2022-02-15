#!/usr/bin/env Rscript


# uwe.menzel@medsci.uu.se 




## +++ Find a UKBB field ID by keyword:





## +++ Call:
#
# search_fieldID  <keyword>  [notes] 
#
# search_fieldID  British
#
# search_fieldID  white  notes 







## +++ Functions, Libraries 

# "getpt" searches Field variable for keywords, case-independent  

# required: 
# pt = get(load("/castor/project/home/umenzel/Desktop/UKBB_phenotype_descriptions.RData"))


# Usage: 
# source("~/Desktop/R/getpt.R") 
# getpt("British")  # No results for searchterm British
# getpt("white")    # Description : Average weekly champagne plus white wine intake  (and a dozen more) 
# getpt("European") # No results for searchterm European 
# getpt("Waist")    # Category 100010 FieldID : 48   Field : Waist circumference (and another one) 


getpt <- function(searchterm, show.notes = FALSE) {
  if(!is.logical(show.notes)) stop(paste("\n\n getpt : Parameter 'show.notes' must be TRUE or FALSE.\n\n")) 
  scripts = Sys.getenv("SCRIPT_FOLDER")
  fn = paste(scripts, "UKBB_phenotype_descriptions.RData", sep="/") # phenotypes
  # fn = "~/Desktop/R/UKBB_phenotype_descriptions.RData"  # phenotypes
  if(!file.exists(fn)) stop(paste("\n\n  ERROR(getpt) : Could not find file '", fn, "'.\n\n"))  
  pt = get(load(fn))
  rowindx = which(grepl(searchterm, pt$Field, ignore.case = TRUE))
  if(identical(rowindx, integer(0))) {
    cat(paste("  No results for searchterm '", searchterm, "'\n"))
    invisible(-1)
  } 
  for(indx in rowindx) { 
    cat    = pt[indx,]$Category
    id     = pt[indx,]$FieldID 
    field  = pt[indx,]$Field 
    # coding = pt[indx,]$Coding
    if(show.notes) {
      notes  = pt[indx,]$Notes 
      cat(paste("  Category", cat, "\tFieldID :", id, "\tField :", field, "\tNotes :", notes, "\n"))
    } else {
      cat(paste("  Category", cat, "\tFieldID :", id, "\tField :", field, "\n"))    
    }
  }
} 


# Mail Claire Loftus, UK Biobank  5/9/2019
# see "get_phenotypes.R"   # umenzel   
# ==> UKBB_phenotype_descriptions.xls 
# ==> UKBB_phenotype_descriptions.RData
# uwe.menzel@medsci.uu.se 






## +++ Command line parameters   

args = commandArgs(trailingOnly = TRUE)   # args = c("white", "notes")  

if(length(args) < 1) {
  cat("\n")
  cat("  Usage: search_fieldID  <keyword>  [notes]\n")  
  cat("\n")
  quit("no")
}

kword  = args[1]
show.notes = FALSE

if(length(args) > 1) {
  if(args[2] == "notes")  show.notes = TRUE
}






## +++ Search


cat(paste("\n  Searching for keyword '", kword, "'\n\n"))

getpt(kword, show.notes = show.notes)

cat("\n\n")


# uwe.menel@medsci.uu.se






