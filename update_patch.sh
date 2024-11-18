#!/bin/bash

# Directory of patch file and target folder
PATCH_DIR="vc_hpc/third_party/elektrobit/acp/patches" 
TARGET_DIR="camido-eb-s32g/eb_acp"

if [ ! -d "$TARGET_DIR" ]; then
    echo "No such file: $TARGET_DIR"
    exit 1
fi

# Retrieve patch file list and sort by sequence number
patch_files=($(ls "$PATCH_DIR" | sort -t'-' -k1,1n))

# Apply patches in sorted order
for patch in "${patch_files[@]}"; do
    PATCH_FILE="$PATCH_DIR/$patch"
    echo "Applying patch: $PATCH_FILE"
    patch -N -p1 -d "$TARGET_DIR" < "$PATCH_FILE"
    if [ $? -ne 0 ]; then
        echo "Failed to apply patch $PATCH_FILE."
        exit 1
    fi
    echo "Patch $PATCH_FILE successfully applied."
done
