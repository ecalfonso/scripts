#!/bin/bash
# Goes through all repos to generate cahngelog

# Last changelog time format: yyyy-mm-dd
if [[ -z $1 ]]; then
	echo "$0 missing time argument"
	echo "	usage: $0 yyyy-mm-dd"
	exit 1
else
	TIME_BEGIN=$1
fi

# Remember the top of the source tree
HOME=`pwd`

# Generate changelog
echo "Generating git log since $TIME_BEGIN" > $LOGNAME

# Traverse source tree
for dir in `find . -type d -name \.git`;
do
	# Go into directory
	cd $dir && cd ..
	
	# Strip the leading "./" and trailing "/.git"
	dir=`echo "${dir:2:-5}"`

	# Check if there's any recent commit
	GITLOG=`git log --oneline --after="$TIME_BEGIN" | cat`
	NUM=$(echo "$GITLOG" | wc -l)

	if [[ $NUM -gt 1 ]]; then
		echo -e "\n$dir" #> "$LOGNAME"
		echo -e "$GITLOG" #> "$LOGNAME"
	fi

	# Go home for good measure
	cd $HOME
done
