// PostgreSQL server service user validation proglet for Windows
// Dave Page, EnterpriseDB

#define WIN32_LEAN_AND_MEAN
#define SECURITY_WIN32
#include <windows.h>
#include <ntsecapi.h>
#include <lm.h>
#include <stdio.h>
#include <sspi.h>
#include <lmcons.h>
#include <tchar.h>

// Older versions of WinError.h do not have SEC_I_COMPLETE_NEEDED #define.
// So, in such an SDK environment setup, we will include issperr.h which has the
// definition for SEC_I_COMPLETE_NEEDED. Include issperr.h only if
// SEC_I_COMPLETE_NEEDED is not defined.

#ifndef SEC_I_COMPLETE_NEEDED
#include <issperr.h>
#endif

typedef struct _AUTH_SEQ 
{
   BOOL fInitialized;
   BOOL fHaveCredHandle;
   BOOL fHaveCtxtHandle;
   CredHandle hcred;
   struct _SecHandle hctxt;
} AUTH_SEQ, *PAUTH_SEQ;

// Function pointers
ACCEPT_SECURITY_CONTEXT_FN       _AcceptSecurityContext     = NULL;
ACQUIRE_CREDENTIALS_HANDLE_FN    _AcquireCredentialsHandle  = NULL;
COMPLETE_AUTH_TOKEN_FN           _CompleteAuthToken         = NULL;
DELETE_SECURITY_CONTEXT_FN       _DeleteSecurityContext     = NULL;
FREE_CONTEXT_BUFFER_FN           _FreeContextBuffer         = NULL;
FREE_CREDENTIALS_HANDLE_FN       _FreeCredentialsHandle     = NULL;
INITIALIZE_SECURITY_CONTEXT_FN   _InitializeSecurityContext = NULL;
QUERY_SECURITY_PACKAGE_INFO_FN   _QuerySecurityPackageInfo  = NULL;
QUERY_SECURITY_CONTEXT_TOKEN_FN  _QuerySecurityContextToken = NULL;

#define CheckAndLocalFree(ptr) \
            if (ptr != NULL) \
            { \
               LocalFree(ptr); \
               ptr = NULL; \
            }

#pragma comment(lib, "netapi32.lib")

// Check whether or not a user account exists
bool CheckUserExists(LPTSTR domain, LPTSTR username)
{
	TCHAR qualifiedname[1024];
	DWORD refsize = 0;
	SID_NAME_USE peUse;
	DWORD sidsize = 0;

	wsprintf(qualifiedname, "%s\\%s", domain, username);
	
	if (LookupAccountName(NULL,
						  qualifiedname,
						  NULL,
						  &sidsize,
						  NULL,
						  &refsize,
						  &peUse))
		return true;

	if (GetLastError() == ERROR_INSUFFICIENT_BUFFER)
		// account existed but buffer too small - that's expected!
		return true;

	return false;
}

// Verify that an account can be logged in to
bool TestLogin(LPTSTR domain, LPTSTR username, LPTSTR password)
{
    HANDLE token;
    if (!LogonUser(username,
                   domain,
                   password,
                   LOGON32_LOGON_NETWORK,
                   LOGON32_PROVIDER_DEFAULT,
                   &token))
    {
        CloseHandle(token);
        return false;
    }
    CloseHandle(token);

    return true;
}

		
// Check the domain
bool CheckDomain(TCHAR *domain, DWORD domainsize, bool *isWin2k)
{
	OSVERSIONINFOEX verinfo;

    ZeroMemory(&verinfo,sizeof(verinfo));
    verinfo.dwOSVersionInfoSize = sizeof(verinfo);

    if (!GetVersionEx((OSVERSIONINFO*)&verinfo))
    {
		fprintf(stderr,"Failed to retrieve the operating system version.");
		return false;
    }
	
	
	if(verinfo.dwMajorVersion == 5 && verinfo.dwMinorVersion == 0)
		*isWin2k = true;
	else
		*isWin2k = false;
	
	if (strcmp(domain, "") == 0 || strcmp(domain, ".") == 0)
	{
		if (verinfo.wProductType == VER_NT_DOMAIN_CONTROLLER)
		{
			// Machine is a domain controller. So get the domain name 
			WKSTA_INFO_100 *wkinfo = NULL;
			NET_API_STATUS status;

			status = NetWkstaGetInfo(NULL, 100, (LPBYTE*)&wkinfo);
			if (status != NERR_Success)
			{
				fprintf(stderr,"Failed to retrieve workstation information.");
				return false;
			}
			
			if (wkinfo != NULL)
				NetApiBufferFree(wkinfo);
				
			WideCharToMultiByte(CP_ACP, 0, (LPCWSTR)wkinfo->wki100_langroup, -1, domain, domainsize, NULL, NULL);
		}
		else
		{
			GetComputerName(domain, &domainsize);
		}
	}
	return true;
}


///////////////////////////////////////////////////////////////////////////////////////////
// START OF SSPI AUTHENTICATION CODE
// 
// This code has been taken from http://support.microsoft.com/kb/180548
///////////////////////////////////////////////////////////////////////////////////////////
LPVOID RetrieveTokenInformationClass(HANDLE hToken, TOKEN_INFORMATION_CLASS InfoClass, LPDWORD lpdwSize)
{
   LPVOID pInfo = NULL;
   BOOL fSuccess = FALSE;

   __try
   {
      *lpdwSize = 0;

      //
      // Determine the size of the buffer needed
      //

      GetTokenInformation(
            hToken,
            InfoClass,
            NULL,
            *lpdwSize, lpdwSize);
      if (GetLastError() != ERROR_INSUFFICIENT_BUFFER)
      {
         _tprintf(_T("GetTokenInformation failed with %d\n"), GetLastError());
         __leave;
      }

      //
      // Allocate a buffer for getting token information
      //
      pInfo = LocalAlloc(LPTR, *lpdwSize);
      if (pInfo == NULL)
      {
         _tprintf(_T("LocalAlloc failed with %d\n"), GetLastError());
         __leave;
      }

      if (!GetTokenInformation(
            hToken,
            InfoClass,
            pInfo,
            *lpdwSize, lpdwSize))
      {
         _tprintf(_T("GetTokenInformation failed with %d\n"), GetLastError());
         __leave;
      }

      fSuccess = TRUE;
   }
   __finally
   {
      // Free pDomainAndUserName only if failed
      // Otherwise, the caller has to free after use
      if (fSuccess == FALSE)
      {
         CheckAndLocalFree(pInfo);
      }
   }

   return pInfo;
}


PSID GetUserSidFromWellKnownRid(DWORD Rid)
{
    PUSER_MODALS_INFO_2 umi2;
    NET_API_STATUS nas;

    UCHAR SubAuthorityCount;
    PSID pSid = NULL;

    BOOL bSuccess = FALSE; // assume failure

    nas = NetUserModalsGet(NULL, 2, (LPBYTE *)&umi2);

    if (nas != NERR_Success)
    {
		fprintf(stderr,"NetUserModalsGet failed with error code : [%d]\n", nas);
        SetLastError(nas);
        return NULL;
    }

    SubAuthorityCount = *GetSidSubAuthorityCount
                       (umi2->usrmod2_domain_id);

    // 
    // Allocate storage for new Sid. account domain Sid + account Rid
    // 

    pSid = (PSID)LocalAlloc(LPTR,
          GetSidLengthRequired((UCHAR)(SubAuthorityCount + 1)));

    if (pSid != NULL)
    {
        if (InitializeSid(
              pSid,
              GetSidIdentifierAuthority(umi2->usrmod2_domain_id),
              (BYTE)(SubAuthorityCount+1)
              ))
        {
            DWORD SubAuthIndex = 0;

            // 
            // Copy existing subauthorities from account domain Sid into
            // new Sid
            // 

            for (; SubAuthIndex < SubAuthorityCount ; SubAuthIndex++)
            {
                *GetSidSubAuthority(pSid, SubAuthIndex) =
                *GetSidSubAuthority(umi2->usrmod2_domain_id,
                                  SubAuthIndex);
            }

            // 
            // Append Rid to new Sid
            // 

            *GetSidSubAuthority(pSid, SubAuthorityCount) = Rid;
        }
    }

    NetApiBufferFree(umi2);

    return pSid;
}


BOOL IsGuest(HANDLE hToken)
{
    BOOL fGuest = FALSE;
    PSID pGuestSid = NULL;
    PSID pUserSid = NULL;
    TOKEN_USER *pUserInfo = NULL;
    DWORD dwSize = 0;

    pGuestSid = GetUserSidFromWellKnownRid(DOMAIN_USER_RID_GUEST);
    if (pGuestSid == NULL)
        return fGuest;

    //
    // Get user information
    //

    pUserInfo = (TOKEN_USER *)RetrieveTokenInformationClass(hToken, TokenUser, &dwSize);
    if (pUserInfo != NULL)
    {
        if (EqualSid(pGuestSid, pUserInfo->User.Sid))
            fGuest = TRUE;
    }

    CheckAndLocalFree(pUserInfo);
    CheckAndLocalFree(pGuestSid);

    return fGuest;
}


void UnloadSecurityDll(HMODULE hModule) {

   if (hModule)
      FreeLibrary(hModule);

   _AcceptSecurityContext      = NULL;
   _AcquireCredentialsHandle   = NULL;
   _CompleteAuthToken          = NULL;
   _DeleteSecurityContext      = NULL;
   _FreeContextBuffer          = NULL;
   _FreeCredentialsHandle      = NULL;
   _InitializeSecurityContext  = NULL;
   _QuerySecurityPackageInfo   = NULL;
   _QuerySecurityContextToken  = NULL;
}


HMODULE LoadSecurityDll() {

   HMODULE hModule;
   BOOL    fAllFunctionsLoaded = FALSE;
   TCHAR   lpszDLL[MAX_PATH];
   OSVERSIONINFO VerInfo;

   //  Find out which security DLL to use, depending on
   //  whether we are on Windows NT or Windows 95, Windows 2000, Windows XP, or Windows Server 2003
   //  We have to use security.dll on Windows NT 4.0.
   //  All other operating systems, we have to use Secur32.dll

   VerInfo.dwOSVersionInfoSize = sizeof (OSVERSIONINFO);
   if (!GetVersionEx (&VerInfo))   // If this fails, something has gone wrong
   {
      return FALSE;
   }

   if (VerInfo.dwPlatformId == VER_PLATFORM_WIN32_NT &&
      VerInfo.dwMajorVersion == 4 &&
      VerInfo.dwMinorVersion == 0)
   {
      lstrcpy (lpszDLL, _T("security.dll"));
   }
   else
   {
      lstrcpy (lpszDLL, _T("secur32.dll"));
   }


   hModule = LoadLibrary(lpszDLL);
   if (!hModule)
      return NULL;

   __try {

      _AcceptSecurityContext = (ACCEPT_SECURITY_CONTEXT_FN)
            GetProcAddress(hModule, "AcceptSecurityContext");
      if (!_AcceptSecurityContext)
         __leave;

#ifdef UNICODE
      _AcquireCredentialsHandle = (ACQUIRE_CREDENTIALS_HANDLE_FN)
            GetProcAddress(hModule, "AcquireCredentialsHandleW");
#else
      _AcquireCredentialsHandle = (ACQUIRE_CREDENTIALS_HANDLE_FN)
            GetProcAddress(hModule, "AcquireCredentialsHandleA");
#endif
      if (!_AcquireCredentialsHandle)
         __leave;

      // CompleteAuthToken is not present on Windows 9x Secur32.dll
      // Do not check for the availablity of the function if it is NULL;
      _CompleteAuthToken = (COMPLETE_AUTH_TOKEN_FN)
            GetProcAddress(hModule, "CompleteAuthToken");

      _DeleteSecurityContext = (DELETE_SECURITY_CONTEXT_FN)
            GetProcAddress(hModule, "DeleteSecurityContext");
      if (!_DeleteSecurityContext)
         __leave;

      _FreeContextBuffer = (FREE_CONTEXT_BUFFER_FN)
            GetProcAddress(hModule, "FreeContextBuffer");
      if (!_FreeContextBuffer)
         __leave;

      _FreeCredentialsHandle = (FREE_CREDENTIALS_HANDLE_FN)
            GetProcAddress(hModule, "FreeCredentialsHandle");
      if (!_FreeCredentialsHandle)
         __leave;

#ifdef UNICODE
      _InitializeSecurityContext = (INITIALIZE_SECURITY_CONTEXT_FN)
            GetProcAddress(hModule, "InitializeSecurityContextW");
#else
      _InitializeSecurityContext = (INITIALIZE_SECURITY_CONTEXT_FN)
            GetProcAddress(hModule, "InitializeSecurityContextA");
#endif
      if (!_InitializeSecurityContext)
         __leave;

#ifdef UNICODE
      _QuerySecurityPackageInfo = (QUERY_SECURITY_PACKAGE_INFO_FN)
            GetProcAddress(hModule, "QuerySecurityPackageInfoW");
#else
      _QuerySecurityPackageInfo = (QUERY_SECURITY_PACKAGE_INFO_FN)
            GetProcAddress(hModule, "QuerySecurityPackageInfoA");
#endif
      if (!_QuerySecurityPackageInfo)
         __leave;

	  _QuerySecurityContextToken = (QUERY_SECURITY_CONTEXT_TOKEN_FN)
            GetProcAddress(hModule, "QuerySecurityContextToken");
      if (!_QuerySecurityContextToken)
         __leave;

      fAllFunctionsLoaded = TRUE;

   } __finally {

      if (!fAllFunctionsLoaded) {
         UnloadSecurityDll(hModule);
         hModule = NULL;
      }

   }

   return hModule;
}


BOOL GenClientContext(PAUTH_SEQ pAS, PSEC_WINNT_AUTH_IDENTITY pAuthIdentity, PVOID pIn, DWORD cbIn, PVOID pOut, PDWORD pcbOut, PBOOL pfDone) 
{
/* 
Routine Description:
	Optionally takes an input buffer coming from the server and returns
	a buffer of information to send back to the server.  Also returns
	an indication of whether or not the context is complete.

	Return Value:
	Returns TRUE if successful; otherwise FALSE.
 */

   SECURITY_STATUS ss;
   TimeStamp       tsExpiry;
   SecBufferDesc   sbdOut;
   SecBuffer       sbOut;
   SecBufferDesc   sbdIn;
   SecBuffer       sbIn;
   ULONG           fContextAttr;

   if (!pAS->fInitialized) {

      ss = _AcquireCredentialsHandle(NULL, _T("NTLM"),
            SECPKG_CRED_OUTBOUND, NULL, pAuthIdentity, NULL, NULL,
            &pAS->hcred, &tsExpiry);
      if (ss < 0) {
         fprintf(stderr, "AcquireCredentialsHandle failed with %08X\n", ss);
         return FALSE;
      }

      pAS->fHaveCredHandle = TRUE;
   }

   // Prepare output buffer
   sbdOut.ulVersion = 0;
   sbdOut.cBuffers = 1;
   sbdOut.pBuffers = &sbOut;

   sbOut.cbBuffer = *pcbOut;
   sbOut.BufferType = SECBUFFER_TOKEN;
   sbOut.pvBuffer = pOut;

   // Prepare input buffer
   if (pAS->fInitialized)  {
      sbdIn.ulVersion = 0;
      sbdIn.cBuffers = 1;
      sbdIn.pBuffers = &sbIn;

      sbIn.cbBuffer = cbIn;
      sbIn.BufferType = SECBUFFER_TOKEN;
      sbIn.pvBuffer = pIn;
   }

   ss = _InitializeSecurityContext(&pAS->hcred,
         pAS->fInitialized ? &pAS->hctxt : NULL, NULL, 0, 0,
         SECURITY_NATIVE_DREP, pAS->fInitialized ? &sbdIn : NULL,
         0, &pAS->hctxt, &sbdOut, &fContextAttr, &tsExpiry);
   if (ss < 0)  {
      // <winerror.h>
      fprintf(stderr, "InitializeSecurityContext failed with %08X\n", ss);
      return FALSE;
   }

   pAS->fHaveCtxtHandle = TRUE;

   // If necessary, complete token
   if (ss == SEC_I_COMPLETE_NEEDED || ss == SEC_I_COMPLETE_AND_CONTINUE) {

      if (_CompleteAuthToken) {
         ss = _CompleteAuthToken(&pAS->hctxt, &sbdOut);
         if (ss < 0)  {
            fprintf(stderr, "CompleteAuthToken failed with %08X\n", ss);
            return FALSE;
         }
      }
      else {
         fprintf (stderr, "CompleteAuthToken not supported.\n");
         return FALSE;
      }
   }

   *pcbOut = sbOut.cbBuffer;

   if (!pAS->fInitialized)
      pAS->fInitialized = TRUE;

   *pfDone = !(ss == SEC_I_CONTINUE_NEEDED
         || ss == SEC_I_COMPLETE_AND_CONTINUE );

   return TRUE;
}


BOOL GenServerContext(PAUTH_SEQ pAS, PVOID pIn, DWORD cbIn, PVOID pOut, PDWORD pcbOut, PBOOL pfDone) 
{

/*
 Routine Description:
    Takes an input buffer coming from the client and returns a buffer
    to be sent to the client.  Also returns an indication of whether or
    not the context is complete.
 Return Value:
    Returns TRUE if successful; otherwise FALSE.
*/

   SECURITY_STATUS ss;
   TimeStamp       tsExpiry;
   SecBufferDesc   sbdOut;
   SecBuffer       sbOut;
   SecBufferDesc   sbdIn;
   SecBuffer       sbIn;
   ULONG           fContextAttr;

   if (!pAS->fInitialized)  {

      ss = _AcquireCredentialsHandle(NULL, _T("NTLM"),
            SECPKG_CRED_INBOUND, NULL, NULL, NULL, NULL, &pAS->hcred,
            &tsExpiry);
      if (ss < 0) {
         fprintf(stderr, "AcquireCredentialsHandle failed with %08X\n", ss);
         return FALSE;
      }

      pAS->fHaveCredHandle = TRUE;
   }

   // Prepare output buffer
   sbdOut.ulVersion = 0;
   sbdOut.cBuffers = 1;
   sbdOut.pBuffers = &sbOut;

   sbOut.cbBuffer = *pcbOut;
   sbOut.BufferType = SECBUFFER_TOKEN;
   sbOut.pvBuffer = pOut;

   // Prepare input buffer
   sbdIn.ulVersion = 0;
   sbdIn.cBuffers = 1;
   sbdIn.pBuffers = &sbIn;

   sbIn.cbBuffer = cbIn;
   sbIn.BufferType = SECBUFFER_TOKEN;
   sbIn.pvBuffer = pIn;

   ss = _AcceptSecurityContext(&pAS->hcred,
         pAS->fInitialized ? &pAS->hctxt : NULL, &sbdIn, 0,
		 SECURITY_NATIVE_DREP, &pAS->hctxt, &sbdOut, &fContextAttr,
         &tsExpiry);
   if (ss < 0)  {
      fprintf(stderr, "AcceptSecurityContext failed with %08X\n", ss);
      return FALSE;
   }

   pAS->fHaveCtxtHandle = TRUE;

   // If necessary, complete token
   if (ss == SEC_I_COMPLETE_NEEDED || ss == SEC_I_COMPLETE_AND_CONTINUE) {

      if (_CompleteAuthToken) {
         ss = _CompleteAuthToken(&pAS->hctxt, &sbdOut);
         if (ss < 0)  {
            fprintf(stderr, "CompleteAuthToken failed with %08X\n", ss);
            return FALSE;
         }
      }
      else {
         fprintf (stderr, "CompleteAuthToken not supported.\n");
         return FALSE;
      }
   }

   *pcbOut = sbOut.cbBuffer;

   if (!pAS->fInitialized)
      pAS->fInitialized = TRUE;

   *pfDone = !(ss == SEC_I_CONTINUE_NEEDED
         || ss == SEC_I_COMPLETE_AND_CONTINUE);

   return TRUE;
}


BOOL WINAPI SSPLogonUser(LPTSTR szDomain, LPTSTR szUser, LPTSTR szPassword) 
{

   AUTH_SEQ    asServer   = {0};
   AUTH_SEQ    asClient   = {0};
   BOOL        fDone      = FALSE;
   BOOL        fResult    = FALSE;
   DWORD       cbOut      = 0;
   DWORD       cbIn       = 0;
   DWORD       cbMaxToken = 0;
   PVOID       pClientBuf = NULL;
   PVOID       pServerBuf = NULL;
   PSecPkgInfo pSPI       = NULL;
   HMODULE     hModule    = NULL;

   SEC_WINNT_AUTH_IDENTITY ai;

   __try {

      hModule = LoadSecurityDll();
      if (!hModule)
         __leave;

      // Get max token size
      _QuerySecurityPackageInfo(_T("NTLM"), &pSPI);
      cbMaxToken = pSPI->cbMaxToken;
      _FreeContextBuffer(pSPI);

      // Allocate buffers for client and server messages
      pClientBuf = HeapAlloc(GetProcessHeap(), HEAP_ZERO_MEMORY, cbMaxToken);
      pServerBuf = HeapAlloc(GetProcessHeap(), HEAP_ZERO_MEMORY, cbMaxToken);

      // Initialize auth identity structure
      ZeroMemory(&ai, sizeof(ai));
#if defined(UNICODE) || defined(_UNICODE)
      ai.Domain = szDomain;
      ai.DomainLength = lstrlen(szDomain);
      ai.User = szUser;
      ai.UserLength = lstrlen(szUser);
      ai.Password = szPassword;
      ai.PasswordLength = lstrlen(szPassword);
      ai.Flags = SEC_WINNT_AUTH_IDENTITY_UNICODE;
#else
      ai.Domain = (unsigned char *)szDomain;
      ai.DomainLength = lstrlen(szDomain);
      ai.User = (unsigned char *)szUser;
      ai.UserLength = lstrlen(szUser);
      ai.Password = (unsigned char *)szPassword;
      ai.PasswordLength = lstrlen(szPassword);
      ai.Flags = SEC_WINNT_AUTH_IDENTITY_ANSI;
#endif

      // Prepare client message (negotiate) .
      cbOut = cbMaxToken;
      if (!GenClientContext(&asClient, &ai, NULL, 0, pClientBuf, &cbOut, &fDone))
         __leave;

      // Prepare server message (challenge) .
      cbIn = cbOut;
      cbOut = cbMaxToken;
      if (!GenServerContext(&asServer, pClientBuf, cbIn, pServerBuf, &cbOut,
            &fDone))
         __leave;
         // Most likely failure: AcceptServerContext fails with SEC_E_LOGON_DENIED
         // in the case of bad szUser or szPassword.
         // Unexpected Result: Logon will succeed if you pass in a bad szUser and
         // the guest account is enabled in the specified domain.

      // Prepare client message (authenticate) .
      cbIn = cbOut;
      cbOut = cbMaxToken;
      if (!GenClientContext(&asClient, &ai, pServerBuf, cbIn, pClientBuf, &cbOut,
            &fDone))
         __leave;

      // Prepare server message (authentication) .
      cbIn = cbOut;
      cbOut = cbMaxToken;
      if (!GenServerContext(&asServer, pClientBuf, cbIn, pServerBuf, &cbOut,
            &fDone))
         __leave;

      fResult = TRUE;

	  {
         HANDLE hToken = NULL;

         if (_QuerySecurityContextToken(&asServer.hctxt, &hToken) == 0)
         {
            if (IsGuest(hToken))
            {
				fprintf(stdout,"Logged in as Guest\n");
               fResult = FALSE;
            }
            else
               fprintf(stdout,"Logged in as the desired user\n");
            CloseHandle(hToken);
         }
      }
     
   } __finally {

      // Clean up resources
      if (asClient.fHaveCtxtHandle)
         _DeleteSecurityContext(&asClient.hctxt);

      if (asClient.fHaveCredHandle)
         _FreeCredentialsHandle(&asClient.hcred);

      if (asServer.fHaveCtxtHandle)
         _DeleteSecurityContext(&asServer.hctxt);

      if (asServer.fHaveCredHandle)
         _FreeCredentialsHandle(&asServer.hcred);

      if (hModule)
         UnloadSecurityDll(hModule);

      HeapFree(GetProcessHeap(), 0, pClientBuf);
      HeapFree(GetProcessHeap(), 0, pServerBuf);

   }

   return fResult;
}

///////////////////////////////////////////////////////////////////////////////////////////
// END OF SSPI AUTHENTICATION CODE
///////////////////////////////////////////////////////////////////////////////////////////


int main(int argc, TCHAR * argv[])
{
	TCHAR domain[256], username[256], password[256];
	bool isWin2k = false;

	// Check the command line
	if (argc != 4)
	{
		fprintf(stderr, "Usage: %s <Domain> <Username> <Password>", argv[0]);
		return 127;
	}
	
	sprintf_s(domain, sizeof(domain), argv[1]);

	// Check domain of system, either system is domain controller or not.
	if(CheckDomain(domain, sizeof(domain), &isWin2k))
	{

		sprintf_s(username, sizeof(username), argv[2]);
		sprintf_s(password, sizeof(password), argv[3]);

		// Check to see if the user account exists
		if (!CheckUserExists(domain, username))
		{
			fprintf(stdout, "User account '%s\\%s' does not exist.", domain, username);
			return 0;
		}

		// Check the password
		if(isWin2k)
		{
			if(!SSPLogonUser(domain, username, password))
			{
				fprintf(stderr, "Incorrect password for user '%s\\%s'.", domain, username);
				return 1;
			}
		}
		else
		{
			if (!TestLogin(domain, username, password))
			{
				fprintf(stdout, "Incorrect password for user '%s\\%s'.", domain, username);
				return 1;		
			}
		}

		fprintf(stdout, "%s ran to completion", argv[0]);
		return 0;
	}
	else
	{
		fprintf(stderr,"Failed to check get the domain info.");
		return 2;
	}
}


