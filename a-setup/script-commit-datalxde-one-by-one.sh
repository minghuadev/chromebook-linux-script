#!/bin/bash

flist=`cat conf-filelist | xargs`

sdata=`date`
for FILENAME in $flist ; do

    echo
    echo "#################################################"
    echo "  File: $FILENAME $FILENAME-sha1 "
    echo

      if [ ! -f $FILENAME ]; then echo "ERROR: no file $FILENAME"; exit 1; fi
      if [ ! -f $FILENAME-sha1 ]; then echo "ERROR: no file $FILENAME-sha1"; exit 1; fi

    echo "  Local commit: "
    echo

      git add $FILENAME $FILENAME-sha1
      git commit -m "file $FILENAME $FILENAME-sha1"

    while true ; do
      issync=`git status | grep ahead`
     if [[ "$issync" =~ "ahead" ]]; then
    echo
    echo -n "  sleep 10  "; sleep 10
    echo "  Remote push: "
    echo
      git push origin master

      if [ $? -ne 0 ]; then
          echo "ERROR: push failed file $FILENAME"
          echo "  retry ...."
      fi
     else
       break
     fi
    done

    echo
      issync=`git status | grep ahead`
      if [[ "$issync" =~ "ahead" ]]; then
          echo "ERROR: local ahead for file $FILENAME"
          edata=`date`
          echo "  start: $sdata"
          echo "  done:  $edata"
          exit 1
      else
          echo "  File: $one $two  status in sync "
      fi

    echo

  done
done
          edata=`date`
          echo "  start: $sdata"
          echo "  done:  $edata"

