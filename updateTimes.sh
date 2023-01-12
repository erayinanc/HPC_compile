#!/bin/bash
# -*- coding: utf-8 -*-
# info: updates timestamp of files with subfiles if file is owned
# author: ei
# version: 230101a
# notes: usually, old files are deleted in HPC sys, run this script to update the timestamps
# copy to a folder and run this script

tt=$(eval 'date +"%Y%m%d%H%M"')
echo "stamped time: $tt"

find -print | while read filename; do
  uname2="$(stat --format '%U' "$filename")"
  if [ "x${uname2}" = "x${USER}" ]; then
    echo "file: $filename, owner: $uname2"
    touch -t $tt "$filename"
  fi
done

#eof
