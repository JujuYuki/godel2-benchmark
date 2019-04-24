#!/bin/bash

set -e

BENCHMARK_COUNT=100
echo "BMARK,AVG_TIME,BMARK_COUNT,BMARK_TIMES" | tee -a timing.csv

checkterm()
{
	if [ ! -f Godel ]; then echo "Put Godel in $(pwd)" && exit 1; fi
	echo "## Gocel checkterm ## benchmark $1"
	./Godel -T $1/main.cgo
	echo
}

checkgodel()
{
	NAME="$1"
	shift
	echo "## Godel ## benchmark $NAME"
	./Godel $* $NAME/main.cgo
	echo
}

BMS="no-race no-race-mut no-race-mut-bad simple-race simple-race-mut-fix deposit-race deposit-fix channel-race channel-fix channel-bad prod-cons-race prod-cons-fix"
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
DINE="dinephil5-race dinephil5-fix"
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
