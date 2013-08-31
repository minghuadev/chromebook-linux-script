#!/bin/bash

#downlaod-cr48-data.sh derived from install-ubuntu-1204-9.sh
#to be run on a host just to save all the files to data/.

baselink=http://cr-48-ubuntu.googlecode.com/files

#create data/
if [ ! -d data ]; then mkdir data; fi

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

    correct_sha1_is_valid=0
    while [ $correct_sha1_is_valid -ne 1 ]; do
        if [ ! -f data/$FILENAME.sha1 ]; then
            wget -O data/$FILENAME.sha1 $baselink/$FILENAME.sha1
        fi
        correct_sha1=`cat data/$FILENAME.sha1 | awk '{print $1}'`
        correct_sha1_length="${#correct_sha1}"
        if [ "$correct_sha1_length" -eq "40" ]; then
            correct_sha1_is_valid=1
        else
            echo -e "\nError downloading $FILENAME.sha1. Retrying...\n\n"
            sleep 3
            rm data/$FILENAME.sha1
            exit 1
        fi
    done
    echo -e "\n\nDownloading $FILENAME\n\n"
    get_cmd="wget -O data/$FILENAME $baselink/$FILENAME"
    write_is_valid=0
    while [ $write_is_valid -ne 1 ]; do
        $get_cmd 
        current_sha1=`bunzip2 -c data/$FILENAME | sha1sum | cut -f1 -d' '`
        if [ "$correct_sha1" = "$current_sha1" ]; then
            echo -e "\n$FILENAME was downloaded correctly...\n\n"
            write_is_valid=1
        else
            echo -e -n "\nError downloading $FILENAME. "
            echo "should be: $correct_sha1 is:$current_sha1. Retrying...\n\n"
            sleep 3
            rm data/$FILENAME
            exit 1
        fi
    done

  done
done

finishtime=`date +%s`; finishdate=`date`

seconds=$(($finishtime - $starttime))

echo -e -n "\n\nSuccess downloading all files. seconds $seconds\n"
echo "  start time: $startdate"
echo " finish time: $finishdate"

