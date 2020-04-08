#!/bin/bash

set -e

if [ ! -f Godel ]; then echo "Put Godel in $(pwd). This script is intended for use with a local build to time execution of the toolchain." && exit 1; fi
if [ ! -f migoinfer ]; then echo "Put migoinfer in $(pwd). This script is intended for use with a local build to time execution of the toolchain." && exit 1; fi

BENCHMARK_COUNT=100
echo "BMARK,AVG_TIME,BMARK_COUNT,BMARK_TIMES" | tee -a timing.csv

checkgodel()
{
	NAME="$1"
	shift
	echo "## Godel ## benchmark $NAME"
	./Godel $* $NAME/main.cgo
	echo
}

BMS="no-race no-race-mut no-race-mut-bad simple-race simple-race-mut-fix deposit-race deposit-fix channel-race channel-fix channel-bad prod-cons-race prod-cons-fix dine5-unsafe dine5-deadlock dine5-fix dine3-chan-race dine3-chan-fix"
for bmark in $BMS
do
	echo "$bmark"
	
	GODEL_TIME_SUM=0
	GODEL_TIME_AVG=0
	GODEL_TIME_DATA=""
	for i in $(seq 1 $BENCHMARK_COUNT)
	do
		GODEL_START=$(date +%s%3N)
		./migoinfer $bmark/main.go > /dev/null && checkgodel $bmark
		GODEL_END=$(date +%s%3N)
		GODEL_TIME=$(echo "scale=3; ($GODEL_END - $GODEL_START)" | bc -l)
		GODEL_TIME_SUM=$(($GODEL_TIME_SUM + $GODEL_TIME))
		GODEL_TIME_DATA="$GODEL_TIME_DATA,$GODEL_TIME"
	done
	GODEL_TIME_AVG=$(echo "scale=3; $GODEL_TIME_SUM / $BENCHMARK_COUNT" | bc -l)
	GODEL_TIME_DATA="$GODEL_TIME_AVG,$BENCHMARK_COUNT$GODEL_TIME_DATA"
	echo "$bmark-godel,$GODEL_TIME_DATA" | tee -a timing.csv
done

BENCHMARK_COUNT=20
DINE="dine5-chan-race dine5-chan-fix"
for bmark in $DINE
do
	echo "$bmark"

	GODEL_TIME_SUM=0
	GODEL_TIME_AVG=0
	GODEL_TIME_DATA=""
	for i in $(seq 1 $BENCHMARK_COUNT)
	do
		GODEL_START=$(date +%s%3N)
		./migoinfer $bmark/main.go > /dev/null && checkgodel $bmark
		GODEL_END=$(date +%s%3N)
		GODEL_TIME=$(echo "scale=3; ($GODEL_END - $GODEL_START)" | bc -l)
		GODEL_TIME_SUM=$(($GODEL_TIME_SUM + $GODEL_TIME))
		GODEL_TIME_DATA="$GODEL_TIME_DATA,$GODEL_TIME"
	done
	GODEL_TIME_AVG=$(echo "scale=3; $GODEL_TIME_SUM / $BENCHMARK_COUNT" | bc -l)
	GODEL_TIME_DATA="$GODEL_TIME_AVG,$BENCHMARK_COUNT$GODEL_TIME_DATA"
	echo "$bmark-godel,$GODEL_TIME_DATA" | tee -a timing.csv
done
