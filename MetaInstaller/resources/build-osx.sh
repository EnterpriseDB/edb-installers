######################## Build C components for OSX ######################################################

cd ./osxComponents/features
./build.sh
cp features.o ../../scripts/osx || _die "Failed to copy the features.o"

cd ../getDynaTune
./build.sh
cp dynaTuneClient.o ../../scripts/osx || _die "Failed to copy the dynaTuneClient.o"

cd ../isUserValidated
./build.sh
cp isUserValidated.o ../../scripts/osx || _die "Failed to copy the isUserValidated.o"

cd ../modifyPostgresql
./build.sh
cp modifyPostgresql.o ../../scripts/osx || _die "Failed to copy the modifyPostgresql.o"

cd ../validateUser
./build.sh
cp validateUserClient.o ../../scripts/osx || _die "Failed to copy the validateUserClient.o"

