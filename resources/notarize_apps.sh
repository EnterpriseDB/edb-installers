#!/bin/sh

export dev_asc_provider=EnterpriseDBCorporation
export dev_account=packages@enterprisedb.com
export dev_password_keychain_name=packages-app-notarization
export dev_primary_bundle_id=$1
export dev_installer_name_prefix=$2

echo =======================================================================
echo Notarize the appbundle
echo =======================================================================

# functions
requeststatus() { # $1: requestUUID
    requestUUID=${1?:"need a request UUID"}
    req_status=$(xcrun altool --notarization-info "$requestUUID" \
                              --username $dev_account \
                              --password "@keychain:${dev_password_keychain_name}" \
                              --asc-provider $dev_asc_provider \
                              2>&1 \
                 | awk -F ': ' '/Status:/ { print $2; }' )
    echo "$req_status"
}

requestUUID=$(xcrun altool --notarize-app -f ${dev_installer_name_prefix}*.dmg --asc-provider $dev_asc_provider --primary-bundle-id $dev_primary_bundle_id -u $dev_account -p "@keychain:${dev_password_keychain_name}" 2>&1 | awk '/RequestUUID/ { print $NF; }')

if [[ $requestUUID == "" ]]; then
	echo "ERROR:could not upload for notarization"
	exit 1
fi

echo "Notarization RequestUUID: $requestUUID"

# wait for status to be not "in progress" any more
request_status="in progress"
while [[ "$request_status" == "in progress" ]]; do
	echo "waiting... "
	sleep 30
	request_status=$(requeststatus "$requestUUID")
	echo "request_status = $request_status"
done

# print status information
xcrun altool 	--notarization-info $requestUUID \
				--username $dev_account \
				--password "@keychain:${dev_password_keychain_name}"

if [[ $request_status != "success" ]]; then
	echo "ERROR:could not notarize"
	exit 1
fi

echo "Staple PostgreSQL DMG"

xcrun stapler staple ${dev_installer_name_prefix}*.dmg

if [ $? != 0 ]; then
	echo "ERROR: could not staple ${dev_installer_name_prefix} DMG"
    exit 1
fi

echo "Notarization done successfully"
