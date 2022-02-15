#!/usr/bin/env bash


# uwe.menzel@medsci.uu.se  



## === tar and gzip a folder and send it to the wharf ===   



## +++ Hardcoded settings & and defaults 

limit=5000   # kB      if bigger than that, ask for confirmation
user=`whoami`
account=$( echo $HOSTNAME | awk 'BEGIN{FS="-"} {print $1}' )
wharf="/proj/${account}/nobackup/wharf/${user}/${user}-${account}" # $wrf






## +++ Command line parameters:

prog=$( basename "$0" )

if [ "$#" -lt 2 ]; then
  prog=$( basename "$0" )
  echo ""
  echo "  Usage: ${prog} --dir <folder> "
  echo ""
  exit 0
fi


while [ "$#" -gt 0 ]
do
  case $1 in
        --dir)
          folder=$2
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


# folder="TEST"






## +++ check if folder exists

if [ ! -d "$folder" ];then
  echo ""
  echo "  Sorry, that folder does not exist."
  echo ""
  exit 1
fi




## +++ Check size of the folder and ask

echo ""
size=$( du -sk $folder | awk '{print $1}' ) # kB
if [ "$size" -gt "$limit" ];then
  echo "  Folder is bigger than ${limit} kilobytes."
  read -p "  Do you want to proceed ? (y/n): "   
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]; then 
    echo "  Okay, going ahead ..."; echo
  else
    echo "  Bye."; echo
    exit 0
  fi
fi






## +++ tar, zip

newname="${folder}.tar"
tar -cvf ${newname} ${folder} 

echo ""
if [ -s "${newname}" ];then
  echo "  Archived to: ${newname}"
  echo -n "  "
  ls -l ${newname}
  echo ""
else
  echo "  Sorry, tar did not work."
  echo ""
  exit 1
fi

gzip -f ${newname}
zipfile="${newname}.gz"
echo ""
if [ -s "${zipfile}" ];then
  echo "  Gzipped to: ${zipfile}"
  echo -n "  "
  ls -l ${zipfile}
  echo ""
else
  echo "  Sorry, gzip did not work."
  echo ""
  exit 1
fi





##  +++ Copy to wharf

cp ${zipfile}  ${wharf}
echo ""
echo "  Copied to wharf"
echo -n "  "
ls -l ${wharf}/${zipfile}
echo ""




## +++ Ask if tar should be deleted

read -p "  Delete the local tar.gz ? (y/n): "   
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then 
  rm -f ${zipfile}
else
  echo "  Okay, keeping the file."
fi

echo ""









