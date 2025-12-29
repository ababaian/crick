!#/bin/bash

FILE=$1
FILE='fold_scm6_3mer_nolipid'

convert $FILE.png $FILE.pgm

aview \
  minwidth=256 -eight \
  $FILE.pgm

