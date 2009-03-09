gcc -DWITH_OPENSSL -I. -o dynaTuneClient.o getDynaTuneInfoClient.c soapC.c soapClient.c stdsoap2.c -lssl -lcrypto

if [ -e ./lib ];
    then
      echo "Removing existing lib directory"
      rm -rf ./lib
fi

mkdir ./lib

cp -r /lib/libssl.so* ./lib/.
cp -r /lib/libcrypto.so* ./lib/.
