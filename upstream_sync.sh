#!/bin/bash
# Script in the github repository directory
# Iterates through each repo, looking for the UPSTREAM file
# Fetches upstream and syncs, exits of failure

# ____ bash colors ____
R='\033[0;31m'; G='\033[0;32m'; NC='\033[0m'

function redEcho() {
	echo -e "${R}$1${NC}"
}

function greEcho() {
	echo -e "${G}$1${NC}"
}

# ____ Functions ____
function fetchUp() {
	# Check input
	if [[ -z "$1" ]]; then
		redEcho "	Error: No branch found!"
		return 1
	else
		git fetch upstream $1 &>/dev/null
		if [[ ! $? -eq 0 ]]; then
			# There was an error fetching
			redEcho "	Error fetching!"
			return 1
		fi
		echo -e "	Fetched upstream"
		return 0
	fi	
} # fetchUp()

function mergeUp() {
	# Check input
	if [[ -z "$1" ]]; then
		redEcho "	Error: No branch found!"
		return 1
	else
		git merge --no-edit upstream/$BRANCH &>/dev/null
		if [[ ! $? -eq 0 ]]; then
			redEcho "	Error fetching!"
			return 1
		fi
		echo -e "	Merged to upstream"
		return 0
	fi
} # mergeUp()

function pushUp() {
	# Check input
	if [[ -z "$1" ]]; then
		redEcho "	Error: No branch found!"
		return 1
	else
		git push &>/dev/null
		if [[ ! $? -eq 0 ]]; then
			redEcho "	Error fetching!"
			return 1
		fi
		echo -e "	Pushed to origin!"
		return 0
	fi
} # pushUp()

# ____ Begin script ____
for repo in `ls | grep android_`
do
	if [[ -e $repo/UPSTREAMS ]]
	then
		# Enter repo dir
		echo -e "${G}Checking $repo...${NC}"
		cd $repo

		# Get upstream branch
		BRANCH=$(sed '1q;d' UPSTREAMS)

		# Fetch, merge then push -- if no error
		fetchUp $BRANCH
		if [[ $? -eq 0 ]]; then
			mergeUp $BRANCH
			if [[ $? -eq 0 ]]; then
				pushUp $BRANCH
			fi
		fi

		# Go back to github dir
		cd ..
	fi
done
