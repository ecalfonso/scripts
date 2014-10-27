#!/bin/bash

# Put all git directories into array
array=(`ls -1 -d ./*/`)

# iterate through directories
for i in ${array[*]}; do
	if [[ -d "./$1" ]]; then
		# Go in
		cd $i
		# Check if it has git
		if [[ -d ".git" ]]; then
			# Print out current directory
			pwd
			git fetch upstream &> tmp

			# If fetch'd cm-11.0 updates
			if cat tmp | grep -q "stable/cm-11.0"; then
				echo "Needs updates"
				# Attempt to merge
				# git merge upstream/cm-11.0 &> tmp2
                git merge upstream/cm-11.0 2>&1 | tee tmp2				

				# Check for merge errors
				if 	cat tmp2 | grep -q "error"; then
					echo "Merge conflicts"
					rm tmp2
					exit 1
				fi
				rm tmp
				rm tmp2	
				# Assuming merge was good, push to git
				git push

			fi # if cat tmp
			rm tmp
		fi # if -d git
		cd ..
	fi # if -d ./$1
done
