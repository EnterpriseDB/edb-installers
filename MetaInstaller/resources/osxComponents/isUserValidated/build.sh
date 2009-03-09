g++ -DWITH_OPENSSL -I. -o isUserValidated.o -isysroot /Developer/SDKs/MacOSX10.4u.sdk -arch ppc -arch i386 WSisUserValidated.c soapC.c soapClient.c stdsoap2.c -lssl -lcrypto

