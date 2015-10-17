#!/bin/bash
# Script in the github repository directory
# Iterates through each repo, looking for the UPSTREAM file
# Fetches upstream and syncs, exits of failure

# Bash colors
R='\033[0;31m'; G='\033[0;32m'; NC='\033[0m'

# ____ Functions ____
function syncRepo() {
	UPSTREAM=$(sed '1q;d' UPSTREAMS)
	BRANCH=$(sed '2q;d' UPSTREAMS)

	echo $UPSTREAM
	echo $BRANCH

	git fetch $UPSTREAM $BRANCH || exit 1
	git merge --no-edit upstream/$BRANCH || exit 1
	git push || exit 1
} # syncRepo()

# ____ Begin script ____
for repo in `ls | grep android_`
do
	if [[ -e $repo/UPSTREAMS ]]
	then
		cd $repo
		syncRepo
		cd ..
	fi
done
