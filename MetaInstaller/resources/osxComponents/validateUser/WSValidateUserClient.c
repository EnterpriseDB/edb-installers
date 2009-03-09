#include "soapH.h"
#include "AuthenticationServiceSoapBinding.nsmap"

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





int main(int argcounter, char **args){  
   struct soap soap; 
   char *result;
   const char *soap_endpoint = "https://services.enterprisedb.com/authws/services/AuthenticationService";
   char *dbserver_guid =args[1];   
   char *features =args[2];
   char *install_tuning =args[3];
   char *update_notification =args[4];

   struct ArrayOf_USCORExsd_USCOREstring paramList;
	
	//the parameters that will be passed to ArrayOf_USCORExsd_USCOREstring
	//the array should be initialized using following sequence. All string should be converted to hex strings
	//dbserver_guid, installer_type, language, feature_selection, install_tuning_str, update_notification_str, dbserver_version, os, number_of_processes_str, 
	//processor_architecture, checked_count_str, processor_type, ram_gb_str, disk_gb_str, shared_memory_mb_str, existing_user_email, existing_user_password
	char *params[19];
	
	char installer_type[6]="edbpg";
	char *language=args[5];
	char *os=args[6];
	char *processor_no=args[7];
	char *processor_arch=args[8];
	char checked_count_str[4]="1"; //defaults to 1
	char *processor_type=args[9];
	char *ram_gb = args[10];
	char disk_gb[2]="0"; //defaults to 0
	char *shared_mem_mb=args[11];
	char *server_utilization = convertToHexString("0");
	char *dbserver_ver ="8.3";
	char *userEmail =args[12];
	char *password =args[13];
	

	
	
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
	
	
	

   soap_init(&soap); // initialize runtime environment (only once)


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

   if (soap_call_ns2__validateUser(&soap, soap_endpoint, NULL, &paramList, &result) == SOAP_OK)  
      printf("%s\n", result); 
   else // an error occurred  
      soap_print_fault(&soap, stderr); // display the SOAP fault on the stderr stream  
	  
   soap_destroy(&soap); // delete deserialized class instances (for C++ only)
   soap_end(&soap); // remove deserialized data and clean up
   soap_done(&soap); // detach the gSOAP environment 
   return 0;
}


