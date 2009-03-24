#include "soapH.h"
#include "AuthenticationServiceSoapBinding.nsmap"
#include "gsoapWinInet.h"
#include "gsoapWinInet.c"
#include "rpc.h"
#pragma comment(lib, "rpcrt4.lib")

/*
* IsAllHex determine if a String contains valid hex values
* param must_be_hex is char *
* returns 0 for false - non zero for true.
* WARNING - no NULL check enforced on param.
*/
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
Generate GUID as ansi string like "XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX"
*/
RPC_CSTR genguid();

/*
*Release the GUID String generated from genguid
*/
void releaseguid(RPC_CSTR * str);

/*
* Returns total system memory in GB in String format (floating point)
*/
char *getTotalMemoryInGB();

/*
* Returns total system memory in MB in String format (numeric)
*/
char *getTotalMemoryInMB();

/*
*This method returns LocaleName for current system.
* It obtains the default LCID and then obtain the locale string from Windows registry.
*/
char* getLocaleName();




/*
* IsAllHex determine if a String contains valid hex values
* param must_be_hex is char *
* returns 0 for false - non zero for true.
* WARNING - no NULL check enforced on param.
*/
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
	char hex[2];
	char *newstr;
	int i,j;

	if(str == NULL) {
		fprintf(stderr,"Invalid Hex String:%s\n", str);
		return NULL;
	}

	stringLen=strlen(str);

	//check if its not odd and valid characters
	if(((stringLen & 0x1) != 0) && !IsAllHex(str)) {
		fprintf(stderr,"Invalid Hex String:%s\n", str);
		return NULL;
	}

	newstr = (char *)malloc((stringLen/2)+1);


	for(i=0,j=0; i<stringLen; i+=2,j++) {
       hex[0] = str[i];
	   hex[1] = str[i+1];
	   newstr[j] = strtol(hex, NULL,16);
	}
    newstr[stringLen/2] = '\0';
    return(newstr);
}

RPC_CSTR genguid() {

UUID uuid;
RPC_CSTR str;

// create UUID
UuidCreate(&uuid);

// create ansi string like "XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX"

UuidToStringA(&uuid, &str);

return str;


}

void releaseguid(RPC_CSTR * str) {
// clean up
RpcStringFreeA(str);
}

char *getTotalMemoryInGB() {
	MEMORYSTATUSEX statex;
	float tmInGB;
	DWORDLONG totalMemory;
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
	float tmInGB;
	DWORDLONG totalMemory;
    double DIV = 1048576;
	long ans;
	char *cAns = (char *)malloc(sizeof(char)*11);

    statex.dwLength = sizeof (statex);
    GlobalMemoryStatusEx (&statex);
	ans = statex.ullTotalPhys/DIV;
	_snprintf(cAns,10,"%d",ans);
	return cAns;
}

/*
*This method returns LocaleName for current system.
* It obtains the default LCID and then obtain the locale string from Windows registry.
*/
char* getLocaleName() {
    LCID  lcid=GetSystemDefaultLCID();
	char hexCLID[64];
	char lszValue[255];

	HKEY hKey;
    LONG returnStatus;
    DWORD dwType=REG_SZ;
    DWORD dwSize=255;

	char *language=(char *)malloc(sizeof(char)*10);
	int n;

	//convert it to 4 digit hex value
    sprintf(hexCLID, "%04x",lcid);

    //obtain it from registry
     returnStatus = RegOpenKeyEx(HKEY_LOCAL_MACHINE, "SOFTWARE\\Classes\\MIME\\Database\\Rfc1766", 0L,  KEY_ALL_ACCESS, &hKey);
     if (returnStatus == ERROR_SUCCESS)
     {
          returnStatus = RegQueryValueEx(hKey, hexCLID, NULL, &dwType,(LPBYTE)&lszValue, &dwSize);
          if (returnStatus == ERROR_SUCCESS)
          {
			   //parse at first ;
			   sscanf(lszValue,"%9[^;]%n",language,&n);
		  }else {
			sprintf(language,"Unknown");
		  }
	 }else {
		sprintf(language,"Unknown");
	 }
     RegCloseKey(hKey);
	 return language;
}





int main(int argcounter, char **args){
   struct soap soap;
   char *result;
   const char *soap_endpoint = "https://services.enterprisedb.com/authws/services/AuthenticationService";
   char *features =args[1];
   char *install_tuning =args[2];
   char *update_notification =args[3];

   struct ArrayOf_USCORExsd_USCOREstring paramList;

	//the parameters that will be passed to ArrayOf_USCORExsd_USCOREstring
	//the array should be initialized using following sequence. All string should be converted to hex strings
	//dbserver_guid, installer_type, language, feature_selection, install_tuning_str, update_notification_str, dbserver_version, os, number_of_processes_str,
	//processor_architecture, checked_count_str, processor_type, ram_gb_str, disk_gb_str, shared_memory_mb_str, existing_user_email, existing_user_password
	char *params[19];

	char installer_type[6]="edbpg";
	char *language=getLocaleName();
	char os[64];//determine via environment variable
	char processor_no[10];//determine via environment variable
	char processor_arch[64];//determine via environment variable
	char checked_count_str[4]="1"; //defaults to 1
	char processor_type[256];////determine via environment variable
	char *ram_gb = getTotalMemoryInGB();
	char disk_gb[2]="0"; //defaults to 0
	char *shared_mem_mb=getTotalMemoryInMB();
	char *server_utilization = convertToHexString("0");
	char *dbserver_ver ="8.3";
	char *userEmail =args[4];
	char *password =args[5];
	char *dbserver_guid =args[6];

	DWORD dwRet, dwErr;
	/*
	printf("installer_type=%s\n", installer_type);
	printf("language=%s\n", language);
	printf("checked_count=%s\n", checked_count_str);
	printf("ram_gb=%s\n", ram_gb);
	printf("disk_gb=%s\n", disk_gb);
	printf("shared_mem_mb=%s\n", shared_mem_mb);
	printf("server_utilization=%s\n", server_utilization);
	printf("dbserver_ver=%s\n", dbserver_ver);
	printf("userEmail=%s\n", userEmail);
	printf("password=%s\n", password);
	*/
	/*
	int i;
	for(i=0; i<argcounter; i++){
		printf("output=%s\n", args[i]);
	}
	*/
	dwRet = GetEnvironmentVariable ("OS", os, sizeof(os));
	if(0 == dwRet)
    {
        dwErr = GetLastError();
        if( ERROR_ENVVAR_NOT_FOUND == dwErr )
        {
            printf("Environment variable does not exist.\n");

        }
    }

	GetEnvironmentVariable ("NUMBER_OF_PROCESSORS", processor_no, sizeof(processor_no));
	GetEnvironmentVariable ("PROCESSOR_ARCHITECTURE", processor_arch, sizeof(processor_arch));
	GetEnvironmentVariable ("PROCESSOR_IDENTIFIER", processor_type, sizeof(processor_type));
	/*
	printf("os=%s\n", os);
	printf("processor_no=%s\n", &processor_no);
	printf("processor_arch=%s\n", &processor_arch);
	printf("processor_type=%s\n", &processor_type);
	*/

	/*
	MsgBox(0,NULL,L"%S\n%S\n%S\n%S\n%S\n%S\n%S\n%S\n%S\n%S\n%S\n%S\n%S\n%S\n%S\n%S\n%S",
	dbserver_guid,installer_type,language,features,
	install_tuning,update_notification,dbserver_ver,os,
	processor_no,processor_arch,checked_count_str,processor_type,
	ram_gb,disk_gb,shared_mem_mb,userEmail,password);
	*/


	//initialize params with hexed strings
    params[0] = convertToHexString(dbserver_guid);
	params[1] = convertToHexString(installer_type);
	params[2] = convertToHexString(language);
	params[3] = convertToHexString(features);
	params[4] = convertToHexString(install_tuning);
	params[5] = convertToHexString(update_notification);
	params[6] = convertToHexString(dbserver_ver);
	params[7] = convertToHexString(os);
	params[8] = convertToHexString(processor_no);
	params[9] = convertToHexString(processor_arch);
	params[10] = convertToHexString(checked_count_str);
	params[11] = convertToHexString(processor_type);
	params[12] = convertToHexString(ram_gb);
	params[13] = convertToHexString(disk_gb);
	params[14] = convertToHexString(shared_mem_mb);
	params[15] = convertToHexString(userEmail);
	params[16] = convertToHexString(password);
	params[17] = server_utilization;
	params[18] = "";
	paramList.__ptr = params;
	paramList.__size = 19;

	/*
	MsgBox(0,NULL,L"%S\n%S\n%S\n%S\n%S\n%S\n%S\n%S\n%S\n%S\n%S\n%S\n%S\n%S\n%S\n%S\n%S\n",
	params[0],params[1],params[2],params[3],
	params[4],params[5],params[6],params[7],
	params[8],params[9],params[10],params[11],
	params[12],params[13],params[14],params[15],params[16]);
	*/


   soap_init(&soap); // initialize runtime environment (only once)
   soap_register_plugin( &soap, wininet_plugin );//SSL support plugin

   if (soap_call_ns2__validateUser(&soap, soap_endpoint, NULL, &paramList, &result) == SOAP_OK)
      printf("%s\n", result);
   else // an error occurred
      soap_print_fault(&soap, stderr); // display the SOAP fault on the stderr stream

   soap_destroy(&soap); // delete deserialized class instances (for C++ only)
   soap_end(&soap); // remove deserialized data and clean up
   soap_done(&soap); // detach the gSOAP environment
   return 0;
}


