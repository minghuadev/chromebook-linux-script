#!/bin/bash

#downlaod-cr48-data.sh derived from install-ubuntu-1204-9.sh
#to be run on a host just to save all the files to data/.

baselink=http://cr-48-ubuntu.googlecode.com/files

#create data/
if [ ! -d data ]; then mkdir data; fi

starttime=`date +%s`; startdate=`date`

model=mario
FILE1=$model-x64-modules.tar.bz2

  wget -O data/$FILE1 $baselink/$FILE1
  cat data/$FILE1 | sha1sum > data/$FILE1.sha1

FILE2=$model-x64-kernel-partition.bz2

  wget -O data/$FILE2 $baselink/$FILE2
  cat data/$FILE2 | sha1sum > data/$FILE2.sha1

finishtime=`date +%s`; finishdate=`date`

seconds=$(($finishtime - $starttime))

echo -e -n "\n\nSuccess downloading all files. seconds $seconds\n"
echo "  start time: $startdate"
echo " finish time: $finishdate"

