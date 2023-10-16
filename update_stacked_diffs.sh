#!/bin/bash


# Get the list of commit SHAs from the rebase todo list
commit_list=$(git log --oneline master..HEAD | cut -d' ' -f1)

# Iterate through the commit SHAs and update each diff
for sha in $commit_list; do
    # Get the diff URL associated with the commit
    commit_message=$(git show --format=%B -s "$sha")
    #diff_url=$(git show --format=%B -s "$sha" | grep "Differential Revision:" | awk '{print $3}')
    diff_url=$(echo "$commit_message" | grep "Differential Revision:" | awk '{print $3}')

    heading=$(echo "$commit_message" | head -n 1)
    
    # Extract the diff ID from the URL
    diff_id=$(basename "$diff_url")
    
    if [ -n "$diff_id" ]; then
        # Update the diff
	echo "Updating diff: $diff_id ( $heading )"
	arc diff --update "$diff_id" --nounit  --skip-staging --message="rebase"

	#echo "y" | arc call-conduit differential.updateunit --revision_id "$diff_id" --add-untracked; # --skip-binaries
    fi
done

