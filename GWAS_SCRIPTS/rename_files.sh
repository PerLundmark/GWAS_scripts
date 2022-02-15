#!/usr/bin/env bash

# uwe.menzel@medsci.uu.se  



## === Rename files




prog=$( basename "$0" )

if [ "$#" -lt 4 ]; then
  echo ""
  echo "  Usage: ${prog}"
  echo "         --old <string>    no default"
  echo "         --new <string>    no default"
  echo ""
  exit 1
fi

while [ "$#" -gt 0 ]
do
  case $1 in
      --old)
          old=$2
          shift
          ;;
      --new)
          new=$2
          shift
          ;;
      *)
          echo ""
	  echo "  Invalid argument: $1"
	  echo ""
	  exit 1
          ;;
  esac
  shift
done


echo ""
echo "  Change ${old} to ${new} in the following file names:"
echo ""
   
oldfiles=$(ls *${old}*) 

ls $oldfiles

echo ""

read -p "  Do you want to rename these files? (y/n): " # -n 1 -r  
echo  ""
if [[ $REPLY =~ ^[Yy]$ ]]; then 
  echo ""
  echo "  Renaming ..."; echo
else
  echo; echo "  Bye."; echo
  exit 0
fi


for file in `ls $oldfiles`; do

  newfile=$( echo $file | sed "s/${old}/${new}/" ) 
  # echo "${file} ==> ${newfile}"
  
  read -p "  ${file} ==> ${newfile} ? (y/n): "    # -n 1 -r    
  if [[ $REPLY =~ ^[Yy]$ ]]; then 
    mv -i ${file} ${newfile}
    echo "  ok."
  else
    echo "  skipping."  
  fi 
   
done


echo ""






  
  
