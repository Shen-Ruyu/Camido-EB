#!/bin/bash

# Ensure that the dos2Unix tool is installed on the system
# sudo apt install dos2unix

# Declare the associative array of patch and target
declare -A PATCH_TO_TARGET=(
    ["vc_hpc/third_party/elektrobit/acp/patches"]="camido-eb-s32g/eb_acp/eb_acp"
)

# Loop over the PATCH_TO_TARGET array
for PATCH_DIR in "${!PATCH_TO_TARGET[@]}"; do
    TARGET_DIR="${PATCH_TO_TARGET[$PATCH_DIR]}"

    # Check if PATCH_DIR exists
    if [ ! -d "$PATCH_DIR" ]; then
        echo "No such file: $PATCH_DIR."
        continue
    fi

    # Check the operating system and handle line ending conversion
    if [[ "$(uname -s)" == "Linux" ]]; then
        echo "Converting line endings to Linux format (LF)..."
        find $TARGET_DIR -type f -exec dos2unix -q {} > /dev/null 2>&1 \;
        find $PATCH_DIR -type f -exec dos2unix -q {} > /dev/null 2>&1 \;
        echo "Conversion completed."
    fi

    # Sort the patches by the first numeric part before the '-' character
    patch_files=($(ls "$PATCH_DIR" | sort -t'-' -k1,1n))

    # Check if there are patch files
    if [ ${#patch_files[@]} -eq 0 ]; then
        echo "No patch files found in '$PATCH_DIR'. Skipping."
        continue
    fi

    # Apply patches in sorted order
    echo "Processing patches in '$PATCH_DIR' for target '$TARGET_DIR':"
    for patch in "${patch_files[@]}"; do
        PATCH_FILE="$PATCH_DIR/$patch"

        echo "Applying patch: $PATCH_FILE"
        patch -N -l -p1 -d "$TARGET_DIR" < "$PATCH_FILE"
        if [ $? -ne 0 ]; then
            echo "Failed to apply patch $PATCH_FILE."
            exit 1
        fi
        echo "Patch $PATCH_FILE successfully applied."
    done
done
