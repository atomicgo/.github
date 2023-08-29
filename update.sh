#!/bin/bash

# Array of repositories to exclude
EXCLUDED_REPOS=("ci" ".github" "template" "atomicgo")

# GitHub username
USERNAME="atomicgo"

# GitHub API URL for the user's repos
API_URL="https://api.github.com/users/$USERNAME/repos?per_page=100"

# File path
FILE_PATH="profile/README.md"

# Temporary file for the generated list
TEMP_MD_LIST=$(mktemp)

# Function to check if a value exists in an array
containsElement () {
  local e match="$1"
  shift
  for e; do [[ "$e" == "$match" ]] && return 0; done
  return 1
}

# Generate the list of repositories
curl -s "$API_URL" | jq -r '.[] | select(.private == false) | .name + "|" + .html_url + "|" + .description' | while IFS='|' read -r repo_name repo_url repo_description; do
  # Check if the repo is in the excluded list
  if containsElement "$repo_name" "${EXCLUDED_REPOS[@]}"; then
    continue
  fi

  # Append to the temporary Markdown list file
  echo "- [$repo_name]($repo_url): $repo_description" >> "$TEMP_MD_LIST"
done

# Insert the generated list between the comments in README.md
sed -i -e "/<!-- repos:start -->/,/<!-- repos:end -->/{ /<!-- repos:start -->/{p; r $TEMP_MD_LIST
}; /<!-- repos:end -->/p; d }" "$FILE_PATH"

# Remove temporary Markdown list file
rm "$TEMP_MD_LIST"
