#!/bin/bash

#downlaod-cr48-data.sh derived from install-ubuntu-1204-9.sh
#to be run on a host just to save all the files to data/.


#create data/
if [ ! -d data ]; then 
    echo "Error: no data/"
    exit 1
fi

starttime=`date +%s`; startdate=`date`

model=mario
FILE1=$model-x64-modules.tar.bz2

  correct_sha1_11=`cat data/$FILE1.sha1     | awk '{print $1}'`
  correct_sha1_12=`cat data/$FILE1-dl1.sha1 | awk '{print $1}'`
  found_sha1_1=`cat data/$FILE1 | sha1sum   | awk '{print $1}'`

  if [ ${#found_sha1_1} -eq 40 -a $found_sha1_1 = $correct_sha1_11 \
                                -a $found_sha1_1 = $correct_sha1_12 ]; then
      echo -e "\n  $FILE1 was downloaded correctly.\n\n"
  else
      echo -e "\n  $FILE1 was downloaded incorrectly...\n"
      echo    "    should be  $correct_sha1_11"
      echo    "           or  $correct_sha1_12"
      echo    "        found  $found_sha1_1"
  fi

FILE2=$model-x64-kernel-partition.bz2

  correct_sha1_21=`cat data/$FILE2.sha1     | awk '{print $1}'`
  correct_sha1_22=`cat data/$FILE2-dl1.sha1 | awk '{print $1}'`
  found_sha1_2=`cat data/$FILE2 | sha1sum   | awk '{print $1}'`

  if [ ${#found_sha1_2} -eq 40 -a $found_sha1_2 = $correct_sha1_21 \
                               -a $found_sha1_2 = $correct_sha1_22 ]; then
      echo -e "\n  $FILE2 was downloaded correctly.\n\n"
  else
      echo -e "\n  $FILE2 was downloaded incorrectly...\n"
      echo    "    should be  $correct_sha1_21"
      echo    "           or  $correct_sha1_22"
      echo    "        found  $found_sha1_2"
  fi


finishtime=`date +%s`; finishdate=`date`

seconds=$(($finishtime - $starttime))

echo -e -n "\n\nSuccess downloading all files. seconds $seconds\n"
echo "  start time: $startdate"
echo " finish time: $finishdate"

