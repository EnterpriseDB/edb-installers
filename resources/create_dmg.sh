#!/bin/bash
  
# A simple shell script to create a compressed, read-only DMG from a folder.

# --- Usage and Input Validation ---
if [ "$#" -ne 4 ]; then
    echo "Usage: $0 <source_folder> <app_bundle_name> <output_dmg_name> <volume_name>"
    echo "Example: $0 ./build/MyApp ./MyApp.app MyApp.dmg 'My Application'"
    exit 1
fi

# --- Configuration ---
# The script now takes the following inputs from the command line:
SOURCE_FOLDER="${1}"
APP_BUNDLE="${2}"
DMG_NAME="${3}"
VOLUME_NAME="${4}"

# The name of the temporary read/write DMG created during the process.
TEMP_DMG_NAME="temp.dmg"
MAX_CREATE_RETRIES=5
RETRY_DELAY=2

# --- Main Script ---
set -e

# Check if the source folder exists
if [ ! -d "${SOURCE_FOLDER}" ]; then
    echo "Error: Source folder '${SOURCE_FOLDER}' not found."
    exit 1
fi

# Check if the app bundle exists within the source folder
if [ ! -d "${SOURCE_FOLDER}/${APP_BUNDLE}" ]; then
    echo "Error: App bundle '${APP_BUNDLE}' not found inside '${SOURCE_FOLDER}'."
    exit 1
fi

# Step 1: Create a ZIP archive of the app bundle.
echo "Creating a ZIP archive of the app bundle..."
pushd "${SOURCE_FOLDER}"
zip -r "../${APP_BUNDLE%.*}.zip" "${APP_BUNDLE}"
popd

# Step 2: Determine the size of the app bundle and create a blank, writable temporary image.
# This avoids "Resource busy" errors by not reading the source directory during creation.
echo "Calculating size of app bundle..."
# Get the size in megabytes and add a buffer
BUNDLE_SIZE=$(du -sk "${SOURCE_FOLDER}/${APP_BUNDLE}" | awk '{print $1}')
DMG_SIZE_MB=$((BUNDLE_SIZE / 1024 + 100)) # Add a 100MB buffer

echo "Creating a temporary blank disk image of size ${DMG_SIZE_MB}MB..."
for i in $(seq 1 ${MAX_CREATE_RETRIES}); do
    if hdiutil create -size "${DMG_SIZE_MB}m" \
                      -volname "${VOLUME_NAME}" \
                      -anyowners \
                      -fs HFS+J \
                      -o "${TEMP_DMG_NAME}"; then
        echo "Temporary DMG created successfully."
        break
    else
        echo "Attempt $i of ${MAX_CREATE_RETRIES} failed: hdiutil create failed. Retrying in ${RETRY_DELAY} seconds..."
        sleep "${RETRY_DELAY}"
    fi
done

# Check if the temporary DMG was created successfully after all retries
if [ ! -f "${TEMP_DMG_NAME}" ]; then
    echo "Error: Failed to create temporary DMG file after ${MAX_CREATE_RETRIES} attempts. Manual intervention may be required."
    exit 1
fi

# Step 3: Attach the newly created temporary disk image.
echo "Attaching the temporary disk image..."
hdiutil attach "${TEMP_DMG_NAME}" -nobrowse -mountpoint "/Volumes/${VOLUME_NAME}"

# Check if the volume was mounted successfully
if [ ! -d "/Volumes/${VOLUME_NAME}" ]; then
    echo "Error: Failed to mount the temporary DMG."
    hdiutil detach "/Volumes/${VOLUME_NAME}" 2>/dev/null
    rm -f "${TEMP_DMG_NAME}"
    exit 1
fi

# Step 4: Copy the app bundle into the mounted image.
echo "Copying app bundle into the mounted image..."
cp -r "${SOURCE_FOLDER}/${APP_BUNDLE}" "/Volumes/${VOLUME_NAME}/"

# Step 5: Detach the temporary disk image with a force option.
echo "Detaching the temporary disk image..."
hdiutil detach "/Volumes/${VOLUME_NAME}" || {
    echo "Failed to detach. Attempting a forced detach..."
    hdiutil detach -force "/Volumes/${VOLUME_NAME}" || {
        echo "Error: Failed to force detach the temporary DMG. Manual intervention may be required."
        rm -f "${TEMP_DMG_NAME}"
        exit 1
    }
}

# Step 6: Convert the temporary read/write DMG to a compressed, read-only DMG.
# This is the final, distributable file.
# The `-quiet` flag suppresses the progress bar.
echo "Converting to a compressed, read-only disk image..."
for i in $(seq 1 ${MAX_CREATE_RETRIES}); do
    if hdiutil convert "${TEMP_DMG_NAME}" \
                      -format UDZO \
                      -o "${DMG_NAME}" \
                      -quiet; then
        echo "Conversion successful."
        break
    else
        echo "Attempt $i of ${MAX_CREATE_RETRIES} failed: hdiutil convert failed. Retrying in ${RETRY_DELAY} seconds..."
        sleep "${RETRY_DELAY}"
    fi
done

# Step 7: Clean up the temporary file.
echo "Cleaning up temporary files..."
rm -f "${TEMP_DMG_NAME}"

echo "The final DMG is '${DMG_NAME}'."
echo "The final ZIP is '${APP_BUNDLE%.*}.zip'."
echo "Done!"
