#!/bin/bash

# Please enable long path support
# git config --global core.longpaths true

# XML file path
if [ -z "$1" ]; then
    echo "Please input a file path as a parameter. For example \"./import/camido-eb-s32g.xml\""
    exit 1
fi
MANIFEST_FILE="$1"
VC_HPC_FETCH="ssh://git@github-vni.geo.conti.de/rm-swp-vc-hpc/"

if [ ! -f "$MANIFEST_FILE" ]; then
    echo "No such file: $MANIFEST_FILE"
    exit 1
fi

# Analyze remote repository information
declare -A REMOTES
while read -r line; do
    # Get the name and fetch of the remote
    remote_name=$(echo "$line" | sed -n 's/.*name="\([^"]*\)".*/\1/p')
    remote_fetch=$(echo "$line" | sed -n 's/.*fetch="\([^"]*\)".*/\1/p')
    echo "remote name: "$remote_name "fetch: "$remote_fetch

    # Store name and fetch in array
    if [[ -n "$remote_name" && -n "$remote_fetch" ]]; then
        REMOTES["$remote_name"]="$remote_fetch"
    fi
done < <(grep "<remote " "$MANIFEST_FILE")

# Analyze project information and execute git clone
grep "<project " "$MANIFEST_FILE" | while read -r line; do
    # Get name, remote, path and revision
    name=$(echo "$line" | sed -n 's/.*name="\([^"]*\)".*/\1/p')
    remote=$(echo "$line" | sed -n 's/.*remote="\([^"]*\)".*/\1/p')
    path=$(echo "$line" | sed -n 's/.*path="\([^"]*\)".*/\1/p')
    revision=$(echo "$line" | sed -n 's/.*revision="\([^"]*\)".*/\1/p')
    upstream=$(echo "$line" | sed -n 's/.*upstream="\([^"]*\)".*/\1/p') # Extract upstream if available

    # If the name ends in .git, remove the .git suffix
    name="${name%.git}"
    
    # Get remote repository URL
    remote_url="${REMOTES[$remote]}"

    # Check if the remote repository exists
    if [ -z "$remote_url" ]; then
        echo "The URL for the remote repository $remote was not found. Skip the project $name."
        continue
    fi

    echo "Cloning $name to $path"
    git clone "$remote_url$name.git" "$path"
    
    cd "$path"
    if [ -n "$upstream" ]; then
        echo "Cloning $name to $path (branch: $upstream)"
        git clone -b "$upstream" "$remote_url$name.git" "$path"
        echo "Checking out revision $revision"
        git checkout "$revision"
    else 
        echo "Cloning $name to $path"
        git clone "$remote_url$name.git" "$path"
        echo "Checking out revision $revision"
        git checkout "$revision"
    fi
    cd -
    
    if [ $? -ne 0 ]; then
        echo "Failed to clone $name."
    else
        echo "$name cloned successfully."
    fi
done

