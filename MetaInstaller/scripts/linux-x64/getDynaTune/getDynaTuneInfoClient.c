#include "soapH.h"
#include "AuthenticationServiceSoapBinding.nsmap"


int IsAllHex (const char* const must_be_hex);

/*
* convertToHexString converts standard string into hex string.
* returns NULL in case of NULL input parameter.
* Caller should call free on returned string after its been used.
*/
char *convertToHexString(char *str);

/*
* HexStrToStr converts hex string into standard string.
* returns NULL in case of NULL/invalid input parameter.
* Caller should call free on returned string after its been used.
*/
char *HexStrToStr(const char *str);



int IsAllHex (const char* const must_be_hex)
{
  char *copy_of_param = (char *)malloc((strlen(must_be_hex))+1);
  int result;
  result = strtok (strcpy(copy_of_param, must_be_hex),"0123456789ABCDEFabcdef-") == 0;
  free(copy_of_param);
  return result;
}

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
		fprintf(stderr, "StrToHexStr: NULL Input String\n");
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

/*
* HexStrToStr converts hex string into standard string.
* returns NULL in case of NULL/invalid input parameter.
* Caller should call free on returned string after its been used.
*/
char *HexStrToStr(const char *str) {

	int stringLen; //this must be even value
	char hex[3];
	char *newstr;
	int i,j;
	hex[0] = hex[1] = hex[2] ='\0';

	if(str == NULL) {
		fprintf(stderr, "Invalid Hex String:%s\n", str);
		return NULL;
	}

	stringLen=strlen(str);

	//check if its not odd and valid characters
	if(((stringLen & 0x1) != 0) && !IsAllHex(str)) {
		fprintf(stderr, "Invalid Hex String:%s\n", str);
		return NULL;
	}

	newstr = (char *)malloc((stringLen/2)+1);


	for(i=0,j=0; i<stringLen; i+=2,j++) {
       	   hex[0] = str[i];
	   hex[1] = str[i+1];
	   newstr[j] = strtol(hex, NULL,16);
	   hex[0] = hex[1] = hex[2] ='\0';
	}
    newstr[stringLen/2] = '\0';
    return(newstr);
}

void printHexedKeyValuePair(const char* hexedKey, const char* hexedVal)
{
	char *key=HexStrToStr(hexedKey),
	     *val=HexStrToStr(hexedVal);
	fprintf(stdout, "%s=%s\n", key, val);
	free(key);
	free(val);
}

int main(int argcounter, char **args)
{
	struct soap soap;
#ifndef STAGING_SERVER
        const char *soap_endpoint = "https://services.enterprisedb.com/authws/services/AuthenticationService?wsdl";
#else
        const char *soap_endpoint = "http://services.staging.enterprisedb.com/authws/services/AuthenticationService?wsdl";
#endif /* STAGING_SERVER */
	char *hexedUUID=convertToHexString(args[1]);
	char *hexedSU=convertToHexString(args[2]);
	char *hexedWP=convertToHexString(args[3]);
	char *ram_gb=args[4];
	char *ram_mb=args[5];
#if defined(__alpha__)\
   ||defined(__ia64__)\
   ||defined(__ia64)\
   ||defined(__s390x__)\
   ||defined(__x86_64__)
	char *hexedOSArch=convertToHexString("64");
	char *hexedPGArch=convertToHexString("64");
#else
	char *hexedOSArch=convertToHexString("32");
	char *hexedPGArch=convertToHexString("32");
#endif

	char *hexedRAMGB=convertToHexString(ram_gb);
	char *hexedRAMMB=convertToHexString(ram_mb);
	char *proxyHost=args[6];
	char *proxyPort=args[7];

	/*
	 * Remove this STAGING_SERVER (#if-#else-#endif) once the 64 bit support
	 * (FB#14846) is added to production server.
	 */
#ifndef STAGING_SERVER
	char *dynatuneParams[] = {hexedUUID, hexedSU, hexedRAMMB, hexedRAMGB, hexedWP};
#else
	char *dynatuneParams[] = {hexedUUID, hexedSU, hexedRAMMB, hexedRAMGB, hexedWP, hexedOSArch, hexedPGArch};
#endif

	struct ArrayOf_USCORExsd_USCOREstring dynaParamList;
	struct ns2__getDynaTuneInfoResponse dynatuneResponse;
	struct ArrayOfArrayOf_USCORExsd_USCOREstring * dynatuneArrayofArray;

	//parameters list for dynatune
	dynaParamList.__ptr = dynatuneParams;
	/*
	 * Remove this STAGING_SERVER (#if-#else-#endif) once the 64 bit support
	 * (FB#14846) is added to production server.
	 */
#ifndef STAGING_SERVER
	dynaParamList.__size = 5;
#else
	dynaParamList.__size = 7;
#endif

	soap_init(&soap); // initialize runtime environment (only once)

	if (strcmp(proxyHost, "") && strcmp(proxyPort, ""))
	{
		soap.proxy_host = proxyHost;
		soap.proxy_port = strtol(proxyPort, NULL, 10);
		soap.proxy_userid = "anonymous";
		soap.proxy_passwd = "";
	}

	soap_ssl_init(); /* init OpenSSL (just once) */

	if (soap_ssl_client_context(&soap, SOAP_SSL_NO_AUTHENTICATION, NULL, NULL, NULL, NULL, NULL))
	{
		soap_print_fault(&soap, stderr);
		exit(1);
	}

	if(soap_call_ns2__getDynaTuneInfo(&soap, soap_endpoint, NULL, &dynaParamList,&dynatuneResponse) == SOAP_OK)
	{
		dynatuneArrayofArray = dynatuneResponse._getDynaTuneInfoReturn;
		if(dynatuneArrayofArray->__size != 17)
		{
			fprintf(stderr, "Error, invalid arguments recieved");
		}
		else
		{
			//obtain parameters list
			int index = 0;
			for (; index < 17; index++)
			{
				printHexedKeyValuePair(dynatuneArrayofArray->__ptr[index].__ptr[0], dynatuneArrayofArray->__ptr[index].__ptr[1]);
			}
		}
	}
	else
	{
		soap_print_fault(&soap, stderr); // display the SOAP fault message on the stderr stream
	}

	//free resources
	free(hexedUUID);
	free(hexedSU);
	free(hexedWP);
	free(hexedRAMGB);
	free(hexedRAMMB);
	free(hexedOSArch);
	free(hexedPGArch);
	soap_destroy(&soap); // delete deserialized class instances (for C++ only)
	soap_end(&soap); // remove deserialized data and clean up
	soap_done(&soap); // detach the gSOAP environment

   	return 0;
}

