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


int main(int argcounter, char **args){
	struct soap soap;
	const char *soap_endpoint = "https://services.enterprisedb.com/authws/services/AuthenticationService";
	char *hexedUUID=convertToHexString(args[1]);
	char *hexedSU=convertToHexString(args[2]);
	char *hexedWP=convertToHexString(args[3]);
	char *ram_gb=getTotalMemoryInGB();
	char *ram_mb=getTotalMemoryInMB();
	char *hexedRAMGB=convertToHexString(ram_gb);
	char *hexedRAMMB=convertToHexString(ram_mb);

	char *dynatuneParams[] = {hexedUUID,hexedSU,hexedRAMMB,hexedRAMGB,hexedWP};

	//contains returned parameters
	char **dynatune=(char **)malloc(sizeof(char *)*17);
	char *param;
	char *key;
	char *val;

	struct ArrayOf_USCORExsd_USCOREstring dynaParamList;
	struct ns2__getDynaTuneInfoResponse dynatuneResponse;
	struct ArrayOfArrayOf_USCORExsd_USCOREstring * dynatuneArrayofArray;

	//parameters list for dynatune
	dynaParamList.__ptr = dynatuneParams;
	dynaParamList.__size = 5;



    soap_init(&soap); // initialize runtime environment (only once)
    soap_register_plugin( &soap, wininet_plugin );//SSL support plugin

   if(soap_call_ns2__getDynaTuneInfo(&soap, soap_endpoint, NULL, &dynaParamList,&dynatuneResponse) == SOAP_OK) {
		dynatuneArrayofArray = dynatuneResponse._getDynaTuneInfoReturn;
		if(dynatuneArrayofArray->__size != 17) {
			//MsgBox(0,NULL,L"Dynatune variables list has been modified, please contact support for this error");
			free(dynatune);
			dynatune = NULL;
			printf("Error, invalid arguments recieved");
		}else {
			//obtain parameters list
			param = (char *)malloc(sizeof(char)*200);
			sprintf(param,"%s=%s",key=HexStrToStr(dynatuneArrayofArray->__ptr[0].__ptr[0]),val=HexStrToStr(dynatuneArrayofArray->__ptr[0].__ptr[1]));
			dynatune[0] = param;
			printf("%s\n",param);
			ZeroMemory(param,sizeof(param));
			//free(param);
			free(key);
			free(val);
			param = (char *)malloc(sizeof(char)*200);
			sprintf(param,"%s=%s",key=HexStrToStr(dynatuneArrayofArray->__ptr[1].__ptr[0]),val=HexStrToStr(dynatuneArrayofArray->__ptr[1].__ptr[1]));
			dynatune[1] = param;
			printf("%s\n",param);
			ZeroMemory(param,sizeof(param));
			//free(param);
			free(key);
			free(val);

			param = (char *)malloc(sizeof(char)*200);
			sprintf(param,"%s=%s",key=HexStrToStr(dynatuneArrayofArray->__ptr[2].__ptr[0]),val=HexStrToStr(dynatuneArrayofArray->__ptr[2].__ptr[1]));
			dynatune[2] = param;
			printf("%s\n",param);
			ZeroMemory(param,sizeof(param));
			//free(param);
			free(key);
			free(val);

			param = (char *)malloc(sizeof(char)*200);
			sprintf(param,"%s=%s",key=HexStrToStr(dynatuneArrayofArray->__ptr[3].__ptr[0]),val=HexStrToStr(dynatuneArrayofArray->__ptr[3].__ptr[1]));
			dynatune[3] = param;
			printf("%s\n",param);
			ZeroMemory(param,sizeof(param));
			//free(param);
			free(key);
			free(val);

			param = (char *)malloc(sizeof(char)*200);
			sprintf(param,"%s=%s",key=HexStrToStr(dynatuneArrayofArray->__ptr[4].__ptr[0]),val=HexStrToStr(dynatuneArrayofArray->__ptr[4].__ptr[1]));
			dynatune[4] = param;
			printf("%s\n",param);
			ZeroMemory(param,sizeof(param));
			//free(param);
			free(key);
			free(val);

			param = (char *)malloc(sizeof(char)*200);
			sprintf(param,"%s=%s",key=HexStrToStr(dynatuneArrayofArray->__ptr[5].__ptr[0]),val=HexStrToStr(dynatuneArrayofArray->__ptr[5].__ptr[1]));
			dynatune[5] = param;
			printf("%s\n",param);
			ZeroMemory(param,sizeof(param));
			//free(param);
			free(key);
			free(val);

			param = (char *)malloc(sizeof(char)*200);
			sprintf(param,"%s=%s",key=HexStrToStr(dynatuneArrayofArray->__ptr[6].__ptr[0]),val=HexStrToStr(dynatuneArrayofArray->__ptr[6].__ptr[1]));
			dynatune[6] = param;
			printf("%s\n",param);
			ZeroMemory(param,sizeof(param));
			//free(param);
			free(key);
			free(val);

			param = (char *)malloc(sizeof(char)*200);
			sprintf(param,"%s=%s",key=HexStrToStr(dynatuneArrayofArray->__ptr[7].__ptr[0]),val=HexStrToStr(dynatuneArrayofArray->__ptr[7].__ptr[1]));
			dynatune[7] = param;
			printf("%s\n",param);
			ZeroMemory(param,sizeof(param));
			//free(param);
			free(key);
			free(val);

			param = (char *)malloc(sizeof(char)*200);
			sprintf(param,"%s=%s",key=HexStrToStr(dynatuneArrayofArray->__ptr[8].__ptr[0]),val=HexStrToStr(dynatuneArrayofArray->__ptr[8].__ptr[1]));
			dynatune[8] = param;
			printf("%s\n",param);
			ZeroMemory(param,sizeof(param));
			//free(param);
			free(key);
			free(val);

			param = (char *)malloc(sizeof(char)*200);
			sprintf(param,"%s=%s",key=HexStrToStr(dynatuneArrayofArray->__ptr[9].__ptr[0]),val=HexStrToStr(dynatuneArrayofArray->__ptr[9].__ptr[1]));
			dynatune[9] = param;
			printf("%s\n",param);
			ZeroMemory(param,sizeof(param));
			//free(param);
			free(key);
			free(val);

			param = (char *)malloc(sizeof(char)*200);
			sprintf(param,"%s=%s",key=HexStrToStr(dynatuneArrayofArray->__ptr[10].__ptr[0]),val=HexStrToStr(dynatuneArrayofArray->__ptr[10].__ptr[1]));
			dynatune[10] = param;
			printf("%s\n",param);
			ZeroMemory(param,sizeof(param));
			//free(param);
			free(key);
			free(val);

			param = (char *)malloc(sizeof(char)*200);
			sprintf(param,"%s=%s",key=HexStrToStr(dynatuneArrayofArray->__ptr[11].__ptr[0]),val=HexStrToStr(dynatuneArrayofArray->__ptr[11].__ptr[1]));
			dynatune[11] = param;
			printf("%s\n",param);
			ZeroMemory(param,sizeof(param));
			//free(param);
			free(key);
			free(val);

			param = (char *)malloc(sizeof(char)*200);
			sprintf(param,"%s=%s",key=HexStrToStr(dynatuneArrayofArray->__ptr[12].__ptr[0]),val=HexStrToStr(dynatuneArrayofArray->__ptr[12].__ptr[1]));
			dynatune[12] = param;
			printf("%s\n",param);
			ZeroMemory(param,sizeof(param));
			//free(param);
			free(key);
			free(val);

			param = (char *)malloc(sizeof(char)*200);
			sprintf(param,"%s=%s",key=HexStrToStr(dynatuneArrayofArray->__ptr[13].__ptr[0]),val=HexStrToStr(dynatuneArrayofArray->__ptr[13].__ptr[1]));
			dynatune[13] = param;
			printf("%s\n",param);
			ZeroMemory(param,sizeof(param));
			//free(param);
			free(key);
			free(val);

			param = (char *)malloc(sizeof(char)*200);
			sprintf(param,"%s=%s",key=HexStrToStr(dynatuneArrayofArray->__ptr[14].__ptr[0]),val=HexStrToStr(dynatuneArrayofArray->__ptr[14].__ptr[1]));
			dynatune[14] = param;
			printf("%s\n",param);
			ZeroMemory(param,sizeof(param));
			//free(param);
			free(key);
			free(val);

			param = (char *)malloc(sizeof(char)*200);
			sprintf(param,"%s=%s",key=HexStrToStr(dynatuneArrayofArray->__ptr[15].__ptr[0]),val=HexStrToStr(dynatuneArrayofArray->__ptr[15].__ptr[1]));
			dynatune[15] = param;
			printf("%s\n",param);
			ZeroMemory(param,sizeof(param));
			//free(param);
			free(key);
			free(val);

			param = (char *)malloc(sizeof(char)*200);

			sprintf(param,"%s=%s",key=HexStrToStr(dynatuneArrayofArray->__ptr[16].__ptr[0]),val=HexStrToStr(dynatuneArrayofArray->__ptr[16].__ptr[1]));
			dynatune[16] = param;
			printf("%s\n",param);
			ZeroMemory(param,sizeof(param));
			//free(param);
			free(key);
			free(val);
		}//else 17
	}else {
		soap_print_fault(&soap, stderr); // display the SOAP fault message on the stderr stream
		//MsgBox(0,NULL,L"Error in calling Dynatune web service");
		ZeroMemory(dynatune,sizeof(dynatune));
		//free(dynatune);
		//dynatune = NULL;
	}

	//printf("Dynatune[0]=%s", dynatune[0]);
	//free resources
	free(ram_gb);
	free(ram_mb);
	free(hexedUUID);
	free(hexedSU);
	free(hexedWP);
	free(hexedRAMGB);
	free(hexedRAMMB);
	//cleanWebService();
   	soap_destroy(&soap); // delete deserialized class instances (for C++ only)
   	soap_end(&soap); // remove deserialized data and clean up
   	soap_done(&soap); // detach the gSOAP environment
   	return 0;
}
