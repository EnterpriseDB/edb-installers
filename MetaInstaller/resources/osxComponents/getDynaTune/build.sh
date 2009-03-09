gcc -DWITH_OPENSSL -I. -O0 -o dynaTuneClient.o -isysroot /Developer/SDKs/MacOSX10.4u.sdk -arch ppc -arch i386 getDynaTuneInfoClient.c soapC.c stdsoap2.c soapClient.c -lssl -lcrypto
