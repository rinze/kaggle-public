#!/bin/bash

for zf in *.zip; do
    echo "Processing ${zf}"
    unzip $zf
    bzip2 $(basename $zf .zip)
    rm $zf
done

rm -rf __MACOSX

