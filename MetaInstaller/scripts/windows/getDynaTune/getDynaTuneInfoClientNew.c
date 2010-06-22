#include "soapH.h"
#include "AuthenticationServiceSoapBinding.nsmap"
#include "gsoapWinInet.h"
#include "gsoapWinInet.c"

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
char *HexStrToStr(char *str);

/*
* Returns total system memory in GB in String format (floating point)
*/
char *getTotalMemoryInGB();

/*
* Returns total system memory in MB in String format (numeric)
*/
char *getTotalMemoryInMB();

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

/*
* HexStrToStr converts hex string into standard string.
* returns NULL in case of NULL/invalid input parameter.
* Caller should call free on returned string after its been used.
*/
char *HexStrToStr(char *str) {

	int stringLen; //this must be even value
	char hex[3];
	char *newstr;
	int i,j;
	hex[0]=hex[1]=hex[2]='\0';

	if(str == NULL) {
		fprintf(stderr,"Invalid Hex String:%s\n", str);
		return NULL;
	}

	stringLen=(int)strlen(str);

	//check if its not odd and valid characters
	if(((stringLen & 0x1) != 0) && !IsAllHex(str)) {
		fprintf(stderr,"Invalid Hex String:%s\n", str);
		return NULL;
	}

	newstr = (char *)malloc((stringLen/2)+1);


	for(i=0,j=0; i<stringLen; i+=2,j++) {
       hex[0] = str[i];
	   hex[1] = str[i+1];
	   newstr[j] =(char) strtol(hex, NULL,16);
	   hex[0]=hex[1]=hex[2]='\0';
	}
    newstr[stringLen/2] = '\0';
    return(newstr);
}

char *getTotalMemoryInGB() {
	MEMORYSTATUSEX statex;
	//float tmInGB;
	//DWORDLONG totalMemory;
    double DIV = 1073741824.0;
	double ans;
	char *cAns = (char *)malloc(sizeof(char)*11);

    statex.dwLength = sizeof (statex);
    GlobalMemoryStatusEx (&statex);
	ans = statex.ullTotalPhys/DIV;
	_snprintf(cAns,10,"%.2f",ans);
	return cAns;
}

char *getTotalMemoryInMB() {
	MEMORYSTATUSEX statex;
	//float tmInGB;
	//DWORDLONG totalMemory;
    double DIV = 1048576;
	long ans;
	char *cAns = (char *)malloc(sizeof(char)*11);

    statex.dwLength = sizeof (statex);
    GlobalMemoryStatusEx (&statex);
	ans = (long)(statex.ullTotalPhys/DIV);
	_snprintf(cAns,10,"%d",ans);
	return cAns;
}

void printHexedKeyValuePair(const char* hexedKey, const char* hexedVal)
{
	char    *key=HexStrToStr(hexedKey),
        	*val=HexStrToStr(hexedVal);
	fprintf(stdout, "%s=%s\n", key, val);
	free(key);
	free(val);
}

bool isRunningOn64bitWindows()
{
#if defined(__WIN64__)
	 return true; //64 bit application running on 64 bit windows.
#else
	 typedef BOOL (WINAPI *IW64PFP)(HANDLE, BOOL *);

	 BOOL res = FALSE;

	 IW64PFP IW64P = (IW64PFP)GetProcAddress(GetModuleHandle(L"kernel32"), "IsWow64Process");

	 if(IW64P != NULL)
		 IW64P(GetCurrentProcess(), &res);

	 return res != FALSE;  // 32 bit application running on 64 bit windows.
#endif
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
	char *ram_gb=getTotalMemoryInGB();
	char *ram_mb=getTotalMemoryInMB();
	char *hexedRAMGB=convertToHexString(ram_gb);
	char *hexedRAMMB=convertToHexString(ram_mb);
        char *proxyHost=args[4];
        char *proxyPort=args[5];
#ifdef __WIN64__
        char *hexedPgArch = convertToHexString("64");
        char *hexedOsArch = convertToHexString("64");
#else
        char *hexedPgArch = convertToHexString("32");
        char *hexedOsArch = isRunningOn64bitWindows() ? convertToHexString("64") : convertToHexString("32");
#endif

	char *dynatuneParams[] = {hexedUUID, hexedSU, hexedRAMMB, hexedRAMGB, hexedWP, hexedOsArch, hexedPgArch};

	struct ArrayOf_USCORExsd_USCOREstring dynaParamList;
	struct ns2__getDynaTuneInfoResponse dynatuneResponse;
	struct ArrayOfArrayOf_USCORExsd_USCOREstring * dynatuneArrayofArray;

	//parameters list for dynatune
	dynaParamList.__ptr = dynatuneParams;
	dynaParamList.__size = 7;

	soap_init(&soap); // initialize runtime environment (only once)

	if (strcmp(proxyHost, "") && strcmp(proxyPort, ""))
	{
		soap.proxy_host = proxyHost;
		soap.proxy_port = strtol(proxyPort, NULL, 10);
		soap.proxy_userid = "anonymous";
		soap.proxy_passwd = "";
	}

	//SSL support plugin
	soap_register_plugin( &soap, wininet_plugin );

	if(soap_call_ns2__getDynaTuneInfo(&soap, soap_endpoint, NULL, &dynaParamList,&dynatuneResponse) == SOAP_OK)
        {
		dynatuneArrayofArray = dynatuneResponse._getDynaTuneInfoReturn;
		if(dynatuneArrayofArray->__size != 17)
			fprintf(stderr, "Error, Invalid arguments recieved");
		else
			//obtain parameters list
			for( int index = 0; index < 17; index++ )
				printHexedKeyValuePair(dynatuneArrayofArray->__ptr[0].__ptr[0],dynatuneArrayofArray->__ptr[0].__ptr[1]);
	}
	else
		soap_print_fault(&soap, stderr); // display the SOAP fault message on the stderr stream

	free(ram_gb);
	free(ram_mb);
	free(hexedUUID);
	free(hexedSU);
	free(hexedWP);
	free(hexedRAMGB);
	free(hexedRAMMB);
	free(hexedPgArch);
	free(hexedOsArch);
   	soap_destroy(&soap); // delete deserialized class instances (for C++ only)
   	soap_end(&soap); // remove deserialized data and clean up
   	soap_done(&soap); // detach the gSOAP environment

   	return 0;
}
