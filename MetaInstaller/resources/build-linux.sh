######################## Build C components for Linux ######################################################

cd ./linuxComponents/features
./build.sh
cp features.o ../../scripts/linux || _die "Failed to copy the features.o"

cd ../getDynaTune
./build.sh
cp dynaTuneClient.o ../../scripts/linux || _die "Failed to copy the dynaTuneClient.o"
cp -r lib/ ../../scripts/linux || _die "Failed to copy the lib directory"

cd ../isUserValidated
./build.sh
cp isUserValidated.o ../../scripts/linux || _die "Failed to copy the isUserValidated.o"
cp -r lib/ ../../scripts/linux || _die "Failed to copy the lib directory"

cd ../modifyPostgresql
./build.sh
cp modifyPostgresql.o ../../scripts/linux || _die "Failed to copy the modifyPostgresql.o"

cd ../validateUser
./build.sh
cp validateUserClient.o ../../scripts/linux || _die "Failed to copy the validateUserClient.o"
cp -r lib/ ../../scripts/linux || _die "Failed to copy the lib directory"

