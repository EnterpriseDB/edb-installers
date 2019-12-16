#!/bin/sh

export dev_asc_provider=EnterpriseDBCorporation
export dev_account=packages@enterprisedb.com
export dev_password_keychain_name=packages-app-notarization
export package_name=$1
export dev_installer_name_prefix=$2
export dev_primary_bundle_id=${package_name%.*}

echo =======================================================================
echo Notarize the appbundle
echo "package name is: $package_name"
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

if [ "${package_name##*.}" = "zip" ]; then
       # Zip cannot be stapled. Also, we can't unzip the notarized archive and then staple. Hence, use ditto
       unzip $package_name && rm -f $package_name
       ditto -c -k --keepParent ${dev_primary_bundle_id}.app $package_name
fi

requestUUID=$(xcrun altool --notarize-app -f $package_name --asc-provider $dev_asc_provider --primary-bundle-id $dev_primary_bundle_id -u $dev_account -p "@keychain:${dev_password_keychain_name}" 2>&1 | awk '/RequestUUID/ { print $NF; }')

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

echo "Staple $package_name"

if [[ "${package_name##*.}" == "zip" ]]; then
       xcrun stapler staple ${dev_primary_bundle_id}.app
       ditto -c -k --keepParent ${dev_primary_bundle_id}.app $package_name
else
       xcrun stapler staple $package_name
fi

if [ $? != 0 ]; then
	echo "ERROR: could not staple $package_name"
    exit 1
fi

echo "Notarization done successfully"
