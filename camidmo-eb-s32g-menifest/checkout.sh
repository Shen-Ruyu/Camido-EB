#!/bin/bash
#
# This script downloads GHS Compiler, EB Tresos, and EB ACP packages from artifactory based on the operating system type.

set -e

# Ensure the XML file exists
XML_FILE="$1"
if [ ! -f "$XML_FILE" ]; then
    echo "Error: No such file $XML_FILE"
    exit 1
fi

# Artifactory server and identity token
ARTIFACTORY_SERVER=https://artifactory.geo.conti.de
ARTIFACTORY_IDENTITY_TOKEN="your_identity_token_here"

# GHS compiler download link
GHS_LINUX_PATH="artifactory/rm_swp_vc_hpc_art_generic_snap_v/supplies/ghs2020.1.4-arm-linux.tar.xz"
GHS_WINDOWS_PATH="artifactory/rm_swp_vc_hpc_art_generic_snap_v/supplies/ghs2020.1.4-arm-windows.tar.xz"

# Set packages download link and path
declare -A PACKAGES=(
    ["artifactory/rm_swp_vc_hpc_art_generic_snap_v/supplies/eb_tresos_acp/tresos-29.6.0.tar.gz"]="camido-eb-s32g/tresos"
    ["artifactory/rm_swp_vc_hpc_art_generic_snap_v/supplies/eb_tresos_acp/acp-9.2.3.tar.gz"]="camido-eb-s32g/eb_acp"
)

function download_and_extract() {
    local file_path=$1
    local target_dir=$2
    local file_name=$(basename "$file_path")

    mkdir -p "$target_dir"
    if [ ! -f "$DOWNLOAD_DIR/$file_name" ]; then
        echo "Downloading $file_name"
        curl -f -H "Authorization: Bearer $ARTIFACTORY_IDENTITY_TOKEN" -O "$ARTIFACTORY_SERVER/$file_path" --create-dirs -o "$file_name"
        if [ $? -ne 0 ]; then
            echo "Failed to download $file_name"
            exit 1
        fi
    fi

    echo "Extracting $file_name to $target_dir"
    if [ "$file_name" = "ghs2020.1.4-arm-linux.tar.xz" ] || [ "$file_name" = "ghs2020.1.4-arm-windows.tar.xz" ]; then
        tar -xf "$file_name" --strip-components=1 -C "$target_dir"
    else
        tar -xf "$file_name" -C "$target_dir"
    fi
    if [ $? -eq 0 ]; then
        echo "$file_name extracted successfully."
        rm $file_name
    else
        echo "Failed to extract $file_name."
        exit 1
    fi
}

function usage() {
    echo "Usage: $0 <XML-file-path>"
    echo "Example: $0 ./import/camido-eb-s32g.xml"
    exit 1
}

# Check input parameters
if [ $# -ne 1 ]; then
    usage
fi

# Operating system detection
os_type=$(uname)
if [[ "$os_type" == "Linux" ]]; then
    ghs_path="$GHS_LINUX_PATH"
else
    ghs_path="$GHS_WINDOWS_PATH"
fi

# Download and unzip GHS compiler
download_and_extract "$ghs_path" "camido-eb-s32g/ghs"


# Download and extract packages
for file_path in "${!PACKAGES[@]}"; do
    target_dir="${PACKAGES[$file_path]}"
    download_and_extract "$file_path" "$target_dir"
done

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
done < <(grep "<remote " "$XML_FILE")

# Analyze project information and execute git clone
grep "<project " "$XML_FILE" | while read -r line; do
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

    # If upstream exists, use the upstream URL for cloning
    if [ -n "$upstream" ]; then
        echo "Upstream repository found for $name. Cloning from upstream."
        remote_url="$upstream"
        if [ -z "$remote_url" ]; then
            echo "The URL for the upstream repository $upstream was not found. Skipping project $name."
            continue
        fi
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

echo "All packages downloaded and extracted successfully."
