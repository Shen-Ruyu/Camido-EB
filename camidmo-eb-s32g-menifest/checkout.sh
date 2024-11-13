#!/bin/bash

# Please enable long path support
# git config --global core.longpaths true

set -e

# Check if XML-file-path, username and password parameters have been passed in
if [ $# -ne 3 ]; then
    echo "Please enter XML-file-path, username and password as input parameters. For example ./import/camido-eb-s32g.xml username password"
    exit 1
fi
MANIFEST_FILE="$1"
username=$2
password=$3

if [ ! -f "$MANIFEST_FILE" ]; then
    echo "No such file: $MANIFEST_FILE"
    exit 1
fi

# Detecting operating system
os_type=$(uname)

# Set GHS compiler download link and path
if [[ "$os_type" == "Linux" ]]; then
    ghs_compiler_package="ghs2020.1.4-arm-linux.tar.xz"
    ghs_download_url="https://artifactory.geo.conti.de/artifactory/rm_swp_vc_hpc_art_generic_snap_v/supplies/ghs2020.1.4-arm-linux.tar.xz"
else
    ghs_compiler_package="ghs2020.1.4-arm-windows.tar.xz"
    ghs_download_url="https://artifactory.geo.conti.de/artifactory/rm_swp_vc_hpc_art_generic_snap_v/supplies/ghs2020.1.4-arm-windows.tar.xz"
fi

# Download and unzip GHS compiler
if [ ! -e "$ghs_compiler_package" ]; then
    echo "Downloading GHS compiler package: $ghs_compiler_package" 
    wget --user="$username" --password="$password" "$ghs_download_url"
    if [ $? -eq 0 ]; then
        echo "GHS compiler package downloaded successfully."
    else
        echo "Failed to download GHS compiler package."
        exit 1
    fi
fi

ghs_compiler_path="camido-eb-s32g/ghs_arm"
if [ ! -d "$ghs_compiler_path" ]; then
    echo "Extracting GHS compiler package"
    mkdir -p "$ghs_compiler_path"
    tar -xf "$ghs_compiler_package" -C ./
    if [ $? -eq 0 ]; then
        mv "${ghs_compiler_package%.tar.xz}" "$ghs_compiler_path/ghs"
        echo "GHS compiler package extracted successfully."
        mv "$ghs_compiler_package" targz-folder
    else
        echo "Failed to extract GHS compiler package."
        exit 1
    fi
fi

# Download and unzip EB Tresos
tresos_version="29.6.0"
tresos_package="tresos-$tresos_version.tar.gz"
tresos_download_url="https://artifactory.geo.conti.de/artifactory/rm_swp_vc_hpc_art_generic_snap_v/supplies/eb_tresos_acp/tresos-$tresos_version.tar.gz"
tresos_base_path="camido-eb-s32g/tresos"

if [ ! -e "targz-folder/$tresos_package" ]; then
    echo "Downloading EB Tresos package: $tresos_package"
    wget --user="$username" --password="$password" "$tresos_download_url" -O targz-folder
    if [ $? -eq 0 ]; then
        echo "EB Tresos package downloaded successfully."
    else
        echo "Failed to download EB Tresos package."
        exit 1
    fi
fi

if [ ! -d "$tresos_base_path" ]; then
    echo "Extracting EB Tresos package"
    mkdir -p "$tresos_base_path"
    tar -xf "targz-folder/$tresos_package" -C "$tresos_base_path"
    if [ $? -eq 0 ]; then
        echo "EB Tresos package extracted successfully."
    else
        echo "Failed to extract EB Tresos package."
        exit 1
    fi
fi

# Download and unzip EB ACP
acp_version="9.2.3"
acp_package="acp-$acp_version.tar.gz"
acp_download_url="https://artifactory.geo.conti.de/artifactory/rm_swp_vc_hpc_art_generic_snap_v/supplies/eb_tresos_acp/acp-$acp_version.tar.gz"
acp_base_path="camido-eb-s32g/eb_acp"

if [ ! -e "targz-folder/$acp_package" ]; then
    echo "Downloading EB ACP package: $acp_package"
    wget --user="$username" --password="$password" "$acp_download_url" -O targz-folder
    if [ $? -eq 0 ]; then
        echo "EB ACP package downloaded successfully."
    else
        echo "Failed to download EB ACP package."
        exit 1
    fi
fi

if [ ! -d "$acp_base_path" ]; then
    echo "Extracting EB ACP package"
    mkdir -p "$acp_base_path"
    tar -xf "targz-folder/$acp_package" -C "$acp_base_path"
    if [ $? -eq 0 ]; then
        echo "EB ACP package extracted successfully."
    else
        echo "Failed to extract EB ACP package."
        exit 1
    fi
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

    # If the name ends in .git, remove the .git suffix
    name="${name%.git}"
    
    # Get remote repository URL
    remote_url="${REMOTES[$remote]}"
    
    # Check if the remote repository exists
    if [ -z "$remote_url" ]; then
        echo "The URL for the remote repository $remote was not found. Skip the project $name."
        continue
    fi

    # Create download path directory
    mkdir -p "$path"
    
    # Execute git clone and switch to the specified branch
    echo "Cloning $name to $path (revision: $revision)"
    git clone -b "$revision" "$remote_url$name.git" "$path"
    
    if [ $? -ne 0 ]; then
        echo "Failed to clone $name."
    else
        echo "$name cloned successfully."
    fi
done

echo "All necessary packages and repositories have been set up."