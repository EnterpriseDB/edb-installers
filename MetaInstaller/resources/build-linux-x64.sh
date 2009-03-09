######################## Build C components for Linux ######################################################

cd ./linux-x64Components/features
./build.sh
cp features.o ../../scripts/linux-x64 || _die "Failed to copy the features.o"

cd ../getDynaTune
./build.sh
cp dynaTuneClient.o ../../scripts/linux-x64 || _die "Failed to copy the dynaTuneClient.o"
cp -r lib/ ../../scripts/linux-x64 || _die "Failed to copy the lib directory"

cd ../isUserValidated
./build.sh
cp isUserValidated.o ../../scripts/linux-x64 || _die "Failed to copy the isUserValidated.o"
cp -r lib/ ../../scripts/linux-x64 || _die "Failed to copy the lib directory"

cd ../modifyPostgresql
./build.sh
cp modifyPostgresql.o ../../scripts/linux-x64 || _die "Failed to copy the modifyPostgresql.o"

cd ../validateUser
./build.sh
cp validateUserClient.o ../../scripts/linux-x64 || _die "Failed to copy the validateUserClient.o"
cp -r lib/ ../../scripts/linux-x64 || _die "Failed to copy the lib directory"

