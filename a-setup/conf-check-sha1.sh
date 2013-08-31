#!/bin/bash

flist=`cat conf-filelist | xargs`

for x in $flist
do
  echo -n "  file $x $x-sha1  "
  sha1sum -c $x-sha1
  if [ $? -ne 0 ]; then
    echo "Error: file failed sha1 check! $x"
  fi
done

exit 0

