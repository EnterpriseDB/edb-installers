#!/bin/sh

export DEVELOPER_TEAM_ID=26QKX55P9K
export DEVELOPER_USER=sandeep.thakkar@enterprisedb.com
export NOTARY_KEYCHAIN_PROFILE=notarytool-password
export PACKAGE_NAME=$1
export INSTALLER_NAME_PREFIX=$2
export PRIMARY_BUNDLE_ID=${PACKAGE_NAME%.*}
source common.sh
source settings.sh

echo =======================================================================
echo Notarize the appbundle
echo "package name is: ${PACKAGE_NAME}"
echo =======================================================================

if [ "${PACKAGE_NAME##*.}" = "zip" ]; then
	# Zip cannot be stapled. Also, we can't unzip the notarized archive and then staple. Hence, use ditto
	rm -rf ${PRIMARY_BUNDLE_ID}.app
	unzip ${PACKAGE_NAME} && rm -f ${PACKAGE_NAME}
	ditto -c -k --keepParent ${PRIMARY_BUNDLE_ID}.app ${PACKAGE_NAME}
fi

if [ "${PACKAGE_NAME##*.}" = "dmg" ]; then
	security unlock-keychain -p $KEYCHAIN_PASSWD ~/Library/Keychains/login.keychain;codesign --verbose --verify --deep -f -i 'com.edb.postgresql' -s 'Developer ID Application: EnterpriseDB Corporation' --options runtime ${PACKAGE_NAME} || _die "Failed to codesign ${PACKAGE_NAME}"
	echo "${PACKAGE_NAME} Code signed done successfully"
fi

# unlock keychain
security unlock-keychain -p $KEYCHAIN_PASSWD ~/Library/Keychains/login.keychain
STATUS=$(xcrun notarytool submit "${PACKAGE_NAME}" \
                              --team-id "${DEVELOPER_TEAM_ID}" \
                              --apple-id "${DEVELOPER_USER}" \
                              --keychain-profile "${NOTARY_KEYCHAIN_PROFILE}" 2>&1)

# Get the submission ID
SUBMISSION_ID=$(echo "${STATUS}" | awk -F ': ' '/id:/ { print $2; exit; }')
echo "Notarization submission ID: ${SUBMISSION_ID}"

echo "Waiting for Notarization to be completed ..."
xcrun notarytool wait "${SUBMISSION_ID}" \
             --team-id "${DEVELOPER_TEAM_ID}" \
             --apple-id "${DEVELOPER_USER}" \
             --keychain-profile "${NOTARY_KEYCHAIN_PROFILE}"

# Print status information
REQUEST_STATUS=$(xcrun notarytool info "${SUBMISSION_ID}" \
             --team-id "${DEVELOPER_TEAM_ID}" \
             --apple-id "${DEVELOPER_USER}" \
             --keychain-profile "${NOTARY_KEYCHAIN_PROFILE}" 2>&1 | \
        awk -F ': ' '/status:/ { print $2; }')

if [[ "${REQUEST_STATUS}" != "Accepted" ]]; then
    echo "Notarization failed."
    exit 1
fi

# Staple the notarization
echo "Stapling the notarization to the ${PACKAGE_NAME}..."
if [[ "${PACKAGE_NAME##*.}" == "zip" ]]; then
        xcrun stapler staple ${PRIMAY_BUNDLE_ID}.app
        ditto -c -k --keepParent ${PRIMARY_BUNDLE_ID}.app ${PACKAGE_NAME}
else
	 xcrun stapler staple ${PACKAGE_NAME}
fi

if [ $? != 0 ]; then
	echo "ERROR: could not staple ${PACKAGE_NAME}"
        exit 1
fi

echo "Notarization done successfully"
