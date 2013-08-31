#!/bin/bash

flist=`cat conf-filelist | xargs`

for x in $flist
do
  echo file $x $x-sha1
  sha1sum $x > $x-sha1
done

