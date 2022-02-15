#!/usr/bin/env bash


# run shinySVM on Bianca 

# uwe.menzel$medsci.uu.se  


echo ""
echo "  === Run the Support Vector Machine ==="
echo ""

echo -n "  Loadung R modules ..."  
module load R_packages/3.6.1 
echo "  Done."


port=$(( 1 + RANDOM%10000 ))

R -e "shiny::runApp('/proj/sens2019016/nobackup/umenzel/shinySVM_Dist', port=$port)" &    

firefox http://127.0.0.1:$port


#  ooffice Test_prediction.xlsx  to look at the spreadsheet 
# xdg-open http://127.0.0.1:7440  # very simple (default) browser  
 
















