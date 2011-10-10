/*

gsoapWinInet2.h

WinInet plugin - supports Windows WinInet transport

Purpose: Allow gsoap clients (not servers) to direct all communications 
         through the WinInet API. This automatically provides all of the 
         proxy and authentication features supported by the control panel 
         'Internet Options' dialog to the client. As these options are 
         shared by IE, this means that "if IE works, gsoap works."

Features:
         + gsoap plugin - extremely easy to use
         + complete support for:
             - HTTP/1.0 and HTTP/1.1
             - HTTPS (no extra libraries are required)
             - HTTP authentication
             - Proxy servers (simple, automatic discovery, etc)
             - Proxy authentication (basic, NTLM, etc)
         + authentication prompts and HTTPS warnings (e.g. invalid HTTPS CA) 
             can be resolved by the user via standard system dialog boxes.
         + message size is limited only by available memory
         + connect, receive and send timeouts are used 
         + supports all SOAP_IO types (see limitations)
         + written completely in C, can be used in C, C++, and MFC projects
             without modification (anywhere that gsoap is used)
         + can be used in both MBCS and UNICODE projects
         + compiles cleanly at warning level 4 (if gsoap uses SOAP_SOCKET
             for the definition of sockets instead of int, it will also
             compile without win64 warnings).
         + all debug trace goes to the gsoap TEST.log file 
         + supports multiple threads (all plugin data is stored in the 
             soap structure - no static variables)

Limitations:
         - DIME attachments are not supported
         - may internally buffer the entire outgoing message before sending
             (if the serialized message is larger then SOAP_BUFLEN, or if 
             SOAP_IO_CHUNK mode is being used then the entire message will 
             be buffered)

Usage:   Add the gsoapWinInet2.h and gsoapWinInet2.cpp files to your project 
         (if you have a C project, rename gsoapWinInet2.cpp to .c and use
         it as is). Ensure that you turn off precompiled headers for the 
         .cpp file.

         In your source, just after calling soap_init(), register this 
         plugin with soap_register_plugin( soap, wininet_plugin ). 

         e.g.
             struct soap soap;
             soap_init( &soap );
             soap_register_plugin( &soap, wininet_plugin );
             soap.connect_timeout = 5; // this will be used by wininet too
             ...
             soap_done(&soap);

Notes:   For extra control, you may also register this plugin using the 
         soap_register_plugin_arg() function, and supply as the argument 
         flags which you wished to be passed to HttpOpenRequest. 

         e.g.
             struct soap soap;
             soap_init( &soap );
             soap_register_plugin_arg( &soap, wininet_plugin,
                 (void*) INTERNET_FLAG_IGNORE_CERT_CN_INVALID );

         See the MSDN documentation on HttpOpenRequest for details of 
         available flags. The <wininet.h> header file is required for the 
         definitions of the flags. Some flags which may be useful are:

             INTERNET_FLAG_KEEP_CONNECTION
             Uses keep-alive semantics, if available, for the connection. 
             This flag is required for Microsoft Network (MSN), NT LAN 
             Manager (NTLM), and other types of authentication. 
             ++ Note that this flag is used automatically when soap.omode 
             has the SOAP_IO_KEEPALIVE flag set. ++

             INTERNET_FLAG_IGNORE_CERT_CN_INVALID
             Disables Microsoft Win32 Internet function checking of SSL/PCT-
             based certificates that are returned from the server against 
             the host name given in the request. 

             INTERNET_FLAG_IGNORE_CERT_DATE_INVALID
             Disables Win32 Internet function checking of SSL/PCT-based 
             certificates for proper validity dates.

         This plugin uses the following callback functions and is not 
         compatible with any other plugin that uses these functions.

             soap->fopen
             soap->fposthdr
             soap->fsend
             soap->frecv
             soap->fclose

         If there are errors in sending the HTTP request which would 
         cause a dialog box to be displayed in IE (for instance, invalid
         certificates on an HTTPS connection), then a dialog will also
         be displayed by this library. At the moment is is not possible
         to disable the UI. If you wish to remove the UI then you will 
         need to hack the source to remove the dialog box and resolve the
         errors programmatically, or supply the appropriate flags in
         soap_register_plugin_arg() to disable the unwanted warnings.

         Because messages are buffered internally to gsoapWinInet2 plugin
         it is recommended that the SOAP_IO_STORE flag is not used otherwise
         the message may be buffered twice on every send. Use the default
         flag SOAP_IO_BUFFER, or SOAP_IO_FLUSH.

License and redistribution: 
         This code is released under the gSOAP public license.

	 The contents of this file are subject to the gSOAP Public License
	 Version 1.3 (the "License"); you may not use this file except in
	 compliance with the License. You may obtain a copy of the License at
	 http://www.cs.fsu.edu/~engelen/soaplicense.html Software distributed
	 under the License is distributed on an "AS IS" basis, WITHOUT
	 WARRANTY OF ANY KIND, either express or implied. See the License for
	 the specific language governing rights and limitations under the
	 License.

Developers:
         26 May 2003: Jack Kustanowitz (jackk@atomica.com)
         Original version

         29 September 2003: Brodie Thiesfield (bt@jellycan.com)
         Rewritten as C plugin for gsoap. Bugs fixed and features added.

         14 January 2004: Brodie Thiesfield (bt@jellycan.com)
         Bug fix.

*/

#ifndef INCLUDED_gsoapWinInet2_h
#define INCLUDED_gsoapWinInet2_h

/*#include <stdsoap2.h>*/
#include <wininet.h>

#ifdef __cplusplus
extern "C" {
#endif 

typedef enum {
	rseFalse = 0,
	rseTrue,
	rseDisplayDlg
} wininet_rseReturn;

typedef wininet_rseReturn(*wininet_rse_callback)(HINTERNET a_hHttpRequest, DWORD a_dwErrorCode);

extern void wininet_set_rse_callback(struct soap *a_pSoap, wininet_rse_callback	a_pRseCallback);

extern int wininet_plugin(struct soap *a_pSoap, struct soap_plugin *a_pPluginData, void *a_pUnused);

#ifdef __cplusplus
}
#endif 

#endif // INCLUDED_gsoapWinInet2_h
