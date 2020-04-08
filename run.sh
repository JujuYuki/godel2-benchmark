#!/bin/bash

set -e

echo "This script runs each example once using the proposed Docker image."
echo "See https://github.com/JujuYuki/godel2/ for details on how to install if you did not pull the Docker image already."
echo "The main examples are run first, including dine3-chan-* but *excluding* dine5-chan-*."
echo "This is because, while the main examples finish within seconds to minutes each,"
echo "and should take under 20mn for all of them to complete, the last two have"
echo "a lot of states and take a very long time to check."
echo "There will be a prompt before the last two to ask you whether you want to continue."

askmain()
{
	read -n 1 -p "Do you want to Continue? [Y/n]" continuemain
	echo

	if [[ $continuemain =~ ^(n|N)$ ]]; then
		echo "Aborting..." && exit 0
	elif [[ $continuemain =~ ^(y|Y)$ ]]; then
		echo
	else
		echo "Invalid input"
		askmain
	fi
}

askmain

checkgodel()
{
	NAME="$1"
	shift
	echo "## Godel ## benchmark $NAME"
	docker run -ti --rm -v $(pwd)/$NAME:/root jgabet/godel2:latest Godel $* test-run.cgo
	echo
}

infer()
{
	NAME="$1"
	shift
	echo "## migoinfer ## benchmark $NAME"
	docker run -ti --rm -v $(pwd)/$NAME:/root jgabet/godel2:latest migoinfer main.go > $NAME/test-run.cgo
	echo "## inference done, result is in $NAME/test-run.cgo and will be tested by Godel next."
	echo
}

BMS="no-race no-race-mut no-race-mut-bad simple-race simple-race-mut-fix deposit-race deposit-fix channel-race channel-fix channel-bad prod-cons-race prod-cons-fix dine5-unsafe dine5-deadlock dine5-fix dine3-chan-race dine3-chan-fix"
for bmark in $BMS
do
	echo "$bmark"
	infer $bmark && checkgodel $bmark
done

echo "Main tests done, the next two tests are the 5-participant versions of Dining Philosophers with channels."
echo "These two take a *very* long time to run, up to 10 hours on our benchmark machine."
read -n 1 -p "Do you want to continue? [y/N]" continuedine
echo

if [[ $continuedine =~ ^(n|N)$ ]]; then
	echo "Stopping here." && exit 0
elif [[ $continuedine =~ ^(y|Y)$ ]]; then
	echo "Continuing to the last two examples, if you want to stop cancel, stop execution with ^C."
else
	echo "Invalid input. Default to N." && exit 0
fi

DINE="dine5-chan-race dine5-chan-fix"
for bmark in $DINE
do
	echo "$bmark"
	infer $bmark && checkgodel $bmark
done
