#include "soapH.h"
#include "AuthenticationServiceSoapBinding.nsmap"
#include "gsoapWinInet.h"
#include "gsoapWinInet.c"
#include "rpc.h"
#pragma comment(lib, "rpcrt4.lib")

char *convertToHexString(char *str);

/*
* convertToHexString converts standard string into hex string.
* returns NULL in case of NULL input parameter.
* Caller should call free on returned string after its been used.
*/
char *convertToHexString(char *str) {

    char *newstr;
    char *cpold;
    char *cpnew;

	if(str == NULL) {
		fprintf(stderr,"StrToHexStr: NULL Input String\n");
		return NULL;
	}

	newstr = (char *)malloc((strlen(str)*2)+1);
	cpold = str;
	cpnew = newstr;

    while('\0' != *cpold) {
            sprintf(cpnew, "%02X", (unsigned char)(*cpold++));
            cpnew+=2;
    }
    *(cpnew) = '\0';

    return(newstr);
}


int main(int argcounter, char **args){
   struct soap soap;
   const char *soap_endpoint = "https://services.enterprisedb.com/authws/services/AuthenticationService";
   int result = 0;
   char *hexedEmail = convertToHexString(args[1]);
   enum xsd__boolean validUserResponse;
   soap_init(&soap); // initialize runtime environment (only once)
   soap_register_plugin( &soap, wininet_plugin );//SSL support plugin

   if (soap_call_ns2__isUserValidated(&soap, soap_endpoint, NULL,hexedEmail, &validUserResponse)== SOAP_OK){
      result = validUserResponse;
	  }else{
		// an error occurred
		soap_print_fault(&soap, stderr); // display the SOAP fault on the stderr stream
		result = -1;
	  }

   printf("%d", result);
   soap_destroy(&soap); // delete deserialized class instances (for C++ only)
   soap_end(&soap); // remove deserialized data and clean up
   soap_done(&soap); // detach the gSOAP environment
   return 0;
}
