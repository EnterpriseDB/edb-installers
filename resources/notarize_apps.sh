#!/bin/sh

export dev_asc_provider=EnterpriseDBCorporation
export dev_account=packages@enterprisedb.com
export dev_password_keychain_name=packages-app-notarization
export package_name=$1
export dev_installer_name_prefix=$2
export dev_primary_bundle_id=${package_name%.*}
source common.sh
source settings.sh

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
	rm -rf ${dev_primary_bundle_id}.app
	unzip $package_name && rm -f $package_name
	ditto -c -k --keepParent ${dev_primary_bundle_id}.app $package_name
fi

if [ "${package_name##*.}" = "dmg" ]; then
	security unlock-keychain -p $KEYCHAIN_PASSWD ~/Library/Keychains/login.keychain;codesign --verbose --verify --deep -f -i 'com.edb.postgresql' -s 'Developer ID Application: EnterpriseDB Corporation' --options runtime $package_name || _die "Failed to codesign $package_name"
	echo "$package_name Code signed done successfully"
fi
cmd_status=0
for i in {1..3}; do
	echo "Trying attempt ($i/3) to upload/notarize $package_name file .. "
	notarize_app=$(xcrun altool --notarize-app -f $package_name --asc-provider $dev_asc_provider --primary-bundle-id $dev_primary_bundle_id -u $dev_account -p "@keychain:${dev_password_keychain_name}" 2>&1 | awk '/RequestUUID/ { print $NF; }')
	if [ $cmd_status != 0 ]; then
        	# Due to network latency or any other network issue if it fails
        	# then we need to retry at least 3 times
        	# notarize_app will contain error details
        	echo "## $notarize_app"
        else
        	# No need to retry again - it is sucessfully uploaded
        	break;
        fi
done
# print error if above command fails
if [ $cmd_status != 0 ]; then
        echo "## could not upload for notarization"
    exit 1
fi
requestUUID=$notarize_app
if [[ $requestUUID == "" ]]; then
	echo "ERROR:could not upload for notarization"
	exit 1
fi

echo "Notarization RequestUUID: $requestUUID"

# some time request_status gets empty status in between while fatching notarization-info
# so we need to atleast try 10 time to avoid daily build failure
# if everything is successful then we can break the loop
for i in {1..10}; do
        echo "Trying attempt ($i/10) to get notarize information .. "

	# wait for status to be not "in progress" any more
	request_status="in progress"
	while [[ "$request_status" == "in progress" ]]; do
		echo "waiting... "
		sleep 30
		request_status=$(requeststatus "$requestUUID")
		echo "request_status = $request_status"
	done

	# exit the loop if return status is success
	if [[ $request_status == "success" ]]; then
		break
	fi

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
