#!/bin/bash
set -e

# Artifactory server and identity token
ARTIFACTORY_SERVER=https://artifactory.geo.conti.de
ARTIFACTORY_IDENTITY_TOKEN=cmVmdGtuOjAxOjE3NjMwMDEwMzk6RWNnejhIUTl2VGpqSWVRMG5hMVJxMEw2RFB4

# GHS compiler download link
GHS_LINUX_PATH="artifactory/rm_swp_vc_hpc_art_generic_snap_v/supplies/ghs2020.1.4-arm-linux.tar.xz"
GHS_WINDOWS_PATH="artifactory/rm_swp_vc_hpc_art_generic_snap_v/supplies/ghs2020.1.4-arm-windows.tar.xz"

# Set packages download link and path
declare -A PACKAGES=(
    ["artifactory/rm_swp_vc_hpc_art_generic_snap_v/supplies/eb_tresos_acp/tresos-29.6.0.tar.gz"]="camido-eb-s32g/eb_tresos_studio"
)
# ["artifactory/rm_swp_vc_hpc_art_generic_snap_v/supplies/eb_tresos_acp/acp-9.2.3.tar.gz"]="camido-eb-s32g/eb_acp"

function download_and_extract() {
    local file_path=$1
    local target_dir=$2
    local file_name=$(basename "$file_path")

    # Check if the target directory already exists and is not empty
    if [ -d "$target_dir" ] && [ "$(ls -A "$target_dir")" ]; then
        echo "$file_name has been downloaded and extracted to $target_dir, skip the download."
        return 0
    fi

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
