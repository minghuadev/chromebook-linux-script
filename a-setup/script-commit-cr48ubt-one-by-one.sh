#!/bin/bash

sdata=`date`
for one in a b; do
  for two in a b c d e f g h i j k l m n o p q r s t u v w x y z;   do

    echo
    echo "#################################################"
    echo "  File: $one $two "
    echo

    FILENAME="ubuntu-1204.bin$one$two.bz2"
      if [ ! -f data/$FILENAME ]; then echo "ERROR: no file $FILENAME"; exit 1; fi
      if [ ! -f data/$FILENAME.sha1 ]; then echo "ERROR: no file $FILENAME.sha1"; exit 1; fi

    echo "  Local commit: $one $two "
    echo

      git add data/$FILENAME data/$FILENAME.sha1
      git commit -m "file $FILENAME $FILENAME.sha1"

    echo
    echo "  Remote push: $one $two "
    echo
      git push origin master

      if [ $? -ne 0 ]; then
          echo "ERROR: no file $FILENAME"
          edata=`date`
          echo "  start: $sdata"
          echo "  done:  $edata"
          exit 1
      fi

    echo
      issync=`git status | grep ahead`
      if [ "$issync" == "ahead" ]; then
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

