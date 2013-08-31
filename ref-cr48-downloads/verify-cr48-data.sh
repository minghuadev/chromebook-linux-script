#!/bin/bash

#downlaod-cr48-data.sh derived from install-ubuntu-1204-9.sh
#to be run on a host just to save all the files to data/.


#create data/
if [ ! -d data ]; then 
    echo "Error: no data/"
    exit 1
fi

starttime=`date +%s`; startdate=`date`

# Download ubuntu root filesystem, keep track of successful parts so we can resume
FILESIZE=102400
for one in a b; do
  for two in a b c d e f g h i j k l m n o p q r s t u v w x y z; do
    # last file is smaller than the rest...
    if [ "$one$two" = "bz" ]; then FILESIZE=20480;  fi
    FILENAME="ubuntu-1204.bin$one$two.bz2"

    echo -e "\n\n #####################################################"
    echo -e "   File:  $one $two \n"

        if [ ! -f data/$FILENAME.sha1 ]; then
            echo "Error: no data/$FILENAME.sha1"
            exit 1
        fi
        correct_sha1=`cat data/$FILENAME.sha1 | awk '{print $1}'`
        correct_sha1_length="${#correct_sha1}"
        if [ "$correct_sha1_length" -ne "40" ]; then
            echo "Error: file data/$FILENAME.sha1"
            exit 1
        fi
    echo -e "\n\nChecking $FILENAME\n\n"
    
        if [ ! -f data/$FILENAME ]; then
            echo "Error: no data/$FILENAME"
            exit 1
        fi
        current_sha1=`bunzip2 -c data/$FILENAME | sha1sum | cut -f1 -d' '`
        if [ "$correct_sha1" = "$current_sha1" ]; then
            echo -e "\n$FILENAME was downloaded correctly...\n\n"
        else
            echo -e -n "\nError downloaded $FILENAME. "
            echo "should be: $correct_sha1 is:$current_sha1. Retrying...\n\n"
            exit 1
        fi

  done
done

finishtime=`date +%s`; finishdate=`date`

seconds=$(($finishtime - $starttime))

echo -e -n "\n\nSuccess downloading all files. seconds $seconds\n"
echo "  start time: $startdate"
echo " finish time: $finishdate"

