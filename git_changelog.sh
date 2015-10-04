#!/bin/bash
# Goes through all repos to generate cahngelog

# Logging variables
DATE=$(date +"%Y%m%d")
LOGNAME="changelog.$DATE"

# Last changelog time
LAST_RUN=`cat .changelog_last_run`

# Remember the top of the source tree
HOME=`pwd`

# Generate changelog
echo "Generating git log since $LAST_RUN" > $LOGNAME

# Traverse source tree
for dir in `find . -type d -name \.git`;
do
	# Go into directory
	cd $dir && cd ..
	
	# Strip the leading "./" and trailing "/.git"
	dir=`echo "${dir:2:-5}"`

	# Check if there's any recent commit
	GITLOG=`git log --oneline --after="$LAST_RUN" --before="2015-9-23" | cat`
	NUM=$(echo "$GITLOG" | wc -l)

	if [[ $NUM -gt 1 ]]; then
		echo -e "\n$dir" #> "$LOGNAME"
		echo -e "$GITLOG" #> "$LOGNAME"
	fi

	# Go home for good measure
	cd $HOME
done
