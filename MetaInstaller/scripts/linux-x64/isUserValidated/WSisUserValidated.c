#include "soapH.h"
#include "AuthenticationServiceSoapBinding.nsmap"

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
   int result = 0;
   const char *soap_endpoint = "https://services.enterprisedb.com/authws/services/AuthenticationService";
   char *hexedEmail = convertToHexString(args[1]); 
   char *proxyHost=args[2];
   char *proxyPort=args[3];

   enum xsd__boolean validUserResponse;
   soap_init(&soap); // initialize runtime environment (only once)

   if (strcmp(proxyHost, "") && strcmp(proxyPort, ""))
   {
       soap.proxy_host = proxyHost; 
       soap.proxy_port = strtol(proxyPort, NULL, 10);
       soap.proxy_userid = "anonymous";
       soap.proxy_passwd = "";  
   }

   soap_ssl_init(); /* init OpenSSL (just once) */

   if (soap_ssl_client_context(&soap,
                               SOAP_SSL_NO_AUTHENTICATION,	/* use SOAP_SSL_DEFAULT in production code, we don't want the host name checks since these will change from machine to machine */
                               NULL, 		/* keyfile: required only when client must authenticate to server (see SSL docs on how to obtain this file) */
                               NULL, 		/* password to read the keyfile */
                               NULL,	/* optional cacert file to store trusted certificates, use cacerts.pem for all public certificates issued by common CAs */
                               NULL,		/* optional capath to directory with trusted certificates */
                               NULL		/* if randfile!=NULL: use a file with random data to seed randomness */ 
     ))
      { soap_print_fault(&soap, stderr);
       exit(1);
      }

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
