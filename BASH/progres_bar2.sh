#!/bin/sh

BAR='#####################'   # this is full bar, e.g. 20 chars
NUMBER_OF_CHARACTER=${#BAR}
count=0

while [[ $count -lt $NUMBER_OF_CHARACTER ]]; do
   printf "${BAR:0:$i}" # print $i chars of $BAR from 0 position
#	echo -ne "\r${BAR:0:$count}"
    sleep 0.5              # wait 100ms between "frames"
	(( count++ ))
done
