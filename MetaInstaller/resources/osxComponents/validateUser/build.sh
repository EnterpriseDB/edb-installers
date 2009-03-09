g++ -DWITH_OPENSSL -I. -o validateUserClient.o -isysroot /Developer/SDKs/MacOSX10.4u.sdk -arch ppc -arch i386 WSValidateUserClient.c soapC.c soapClient.c stdsoap2.c -lssl -lcrypto

