#!/bin/bash

#downlaod-fc19data.sh derived from download-cr48-data.sh 
# from install-ubuntu-1204-9.sh
#to be run on a host just to save all the files to data/.

baselink=http://chromebook-linux-data-fc19lxde.googlecode.com/git/data-acer-c7
cfg_reusefile=1

#create data/
if [ ! -d data ]; then mkdir data; fi

    function dlplainfile() {
        fn=$1
        if [ "$fn" == "" ]; then 
            echo -e "\nError no file name in dlplainfile\n\n"; exit 1
        fi
        file_is_valid=0
        while [ $file_is_valid -ne 1 ]; do
            rm data/$fn
            wget -O data/$fn $baselink/$fn
            if [ $? -eq 0 -a -f data/$fn ]; then 
                file_is_valid=1
            else
                echo -e "\nError downloading plain file $fn. Retrying...\n\n"
                sleep 3
                rm data/$fn
                exit 1
            fi
        done
    }
    
    function dlshafile() {
        fn=$1
        if [ "$fn" == "" ]; then 
            echo -e "\nError no file name in dlshafile\n\n"; 
            exit 1
        fi
        correct_sha1_is_valid=0
        while [ $correct_sha1_is_valid -ne 1 ]; do
            if [ ! -f data/$fn ]; then
                wget -O data/$fn $baselink/$fn
            fi
            correct_sha1=`cat data/$fn | awk '{print $1}'`
            if [ ${#correct_sha1} -eq 40 ]; then
                correct_sha1_is_valid=1
            else
                echo -e "\nError downloading sha file $fn. Retrying...\n\n"
                sleep 3
                rm data/$fn
                exit 1
            fi
        done
    }

    function dldatafile() {
        fn=$1
        shafn=$2
        if [ "$fn" == "" -o "$shafn" == "" ]; then 
            echo -e "\nError no file name in dldatafile\n\n"; 
            exit 1
        fi
        get_cmd="wget -O data/$fn $baselink/$fn"
        write_is_valid=0
        while [ $write_is_valid -ne 1 ]; do
            $get_cmd 
            echo -n '            '
            (cd data && sha1sum -c $shafn)
            if [ $? -eq 0 ]; then
                echo -e "\n            $fn was downloaded correctly..."
                write_is_valid=1
            else
                echo -e -n "\nError downloading $fn. "
                sleep 3
                rm data/$fn
                exit 1
            fi
        done
    }

file1=combine.sh
file2=conf-fc19lxde-sha1
file3=conf-filelist
lastonetwo=bd

echo '4a70550c1752c6b771c72d7f2363cf48ddf5c3d5  combine.sh' > data/conf-3files-sha1
echo 'edb6c06bab4cec0959af3a1c0f231ba8c1ce3754  conf-filelist' >> data/conf-3files-sha1
echo 'adb01a1982b6986aff63e0ac969d44af5884d016  conf-fc19lxde-sha1' >> data/conf-3files-sha1

starttime=`date +%s`; startdate=`date`

    echo -e "\n #####################################################"
    echo -e "   Files:  $file1 $file2 $file3\n"

    if [ $cfg_reusefile -eq 0 -o ! -f data/$file1 ] ; then dlplainfile $file1; fi
    if [ $cfg_reusefile -eq 0 -o ! -f data/$file3 ] ; then dlplainfile $file3; fi
    if [ $cfg_reusefile -eq 0 -o ! -f data/$file2 ] ; then dlshafile   $file2; fi
    if ! (cd data && sha1sum -c conf-3files-sha1) ; then 
        echo "Error checking sha1sums on the files."
        rm $file1 $file2 $file3
        exit 1
    fi
    
# Download fc19lxde root filesystem, keep track of successful parts so we can resume
for one in a b; do
  for two in a b c d e f g h i j k l m n o p q r s t u v w x y z; do

    echo -e "\n #####################################################"
    echo -e "   File:  $one $two"

    sumfile="fc19lxde-"$one$two"-sha1"
    datafile="fc19lxde-"$one$two
    
    while true ; do
        if [ $cfg_reusefile -ne 0 ] ; then
            if [ -f data/$sumfile -a -f data/$datafile ]; then
                echo -n '                '
                if (cd data && sha1sum -c $sumfile) ; then break; fi
            fi
        fi
        dlshafile $sumfile
        dldatafile $datafile $sumfile
        if [ -f data/fc19lxde.tgz ]; then rm data/fc19lxde.tgz; fi
        break;
    done

    # last file is ...
    if [ "$one$two" == "$lastonetwo" ]; then break;  fi
  done
done

    echo -e "\n #####################################################"
    echo -e "   Check:  \n"
    
    if [ $cfg_reusefile -ne 0 ] ; then
        if [ ! -f data/fc19lxde.tgz ]; then
            echo "Combine segments into the tarball..."
            (cd data && chmod u+x combine.sh && bash combine.sh)
        fi
    else
        echo "Combine segments into the tarball..."
        (cd data && chmod u+x combine.sh && bash combine.sh)
    fi 
    echo "Check the sha1sum on the tarball..."
    (cd data && sha1sum -c conf-fc19lxde-sha1)
    if [ $? -eq 0 ]; then 
        echo -e "   Check:  OK "
    else
        echo -e "   Check:  Failed. Files not useable. "
    fi

finishtime=`date +%s`; finishdate=`date`
seconds=$(($finishtime - $starttime))

echo -e -n "\nSuccess downloading all files in $seconds seconds.\n"
echo "  start time: $startdate"
echo " finish time: $finishdate"

