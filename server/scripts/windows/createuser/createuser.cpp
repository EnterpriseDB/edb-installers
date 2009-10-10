// PostgreSQL server service user creation proglet for Windows
// Dave Page, EnterpriseDB

#define WIN32_LEAN_AND_MEAN
// #define _WIN32_WINNT 0x0502   // Windows Server 2003 family
// #define _WIN32_WINNT 0x0501      // Windows XP
#define _WIN32_WINNT 0x0500   // Windows 2000
// #define _WIN32_WINNT 0x0400   // Windows NT 4.0
// #define _WIN32_WINDOWS 0x0500 // Windows ME
// #define _WIN32_WINDOWS 0x0410 // Windows 98
// #define _WIN32_WINDOWS 0x0400 // Windows 95
#include "windows.h"
#include "ntsecapi.h"
#include "lm.h"
#include "aclapi.h"
#include "stdio.h"
#include "stdlib.h"

#ifndef STATUS_SUCCESS
#define STATUS_SUCCESS 0
#endif

// Just get the last error as a system formatted string
TCHAR *lasterror_string()
{
    int e = GetLastError();
    TCHAR *newstr = NULL;

    if (!FormatMessage(FORMAT_MESSAGE_ALLOCATE_BUFFER | FORMAT_MESSAGE_FROM_SYSTEM, NULL, e, MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT), (LPTSTR)&newstr, 10, NULL))
    {
        newstr = (TCHAR *)LocalAlloc(0, 128);
        sprintf_s(newstr, 128, "Unknown error %i", e);
    }
    return newstr;
}

void HideUserFromLogon(LPTSTR pszUserName)
{
    HKEY    hkey;
    DWORD   dwData;
    TCHAR   szBuf[MAX_PATH];

    wsprintf(szBuf, "Software\\Microsoft\\Windows NT\\CurrentVersion\\Winlogon\\SpecialAccounts\\UserList");

    if (RegCreateKey(HKEY_LOCAL_MACHINE, szBuf, &hkey) != STATUS_SUCCESS)
    {
        fprintf(stdout, "User may not be hidden on logon screen. Reason:\nCouldn't open the registry key 'Software\\Microsoft\\Windows NT\\CurrentVersion\\Winlogon\\SpecialAccounts\\UserList'\n");
        return;
    }

    dwData=0;
    if(RegSetValueEx( hkey, pszUserName, 0, REG_DWORD, (LPBYTE) &dwData, sizeof(DWORD)) != STATUS_SUCCESS)
    {
        fprintf(stdout, "User may not be hidden on logon screen. Reason:\nCouldn't set value for the user '%s' to 0 in UserList (SpecialAccounts)'\n");
        RegCloseKey(hkey);
        return;
    }
    fprintf(stdout, "Successfully Hide the user '%s' on the logon screen.\n", pszUserName);
    RegCloseKey(hkey);
}

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

NET_API_STATUS CreateUser(LPTSTR servername, LPTSTR username, LPTSTR password, TCHAR *errbuf, DWORD errsize)
{
	USER_INFO_1 ui;
	DWORD dwLevel = 1;
	DWORD dwError = 0;
	NET_API_STATUS nStatus;
	int nLen;
	char comment[] = "PostgreSQL service account";
	WCHAR wServerName[100], wUsername[100], wPassword[100], wComment[100];
	
	nLen = MultiByteToWideChar(CP_ACP, 0, username, -1, NULL, (int)NULL);
	MultiByteToWideChar(CP_ACP, 0, 	username, -1, wUsername, nLen);
	
	nLen = MultiByteToWideChar(CP_ACP, 0, password, -1, NULL, (int)NULL);
	MultiByteToWideChar(CP_ACP, 0, 	password, -1, wPassword, nLen);

	nLen = MultiByteToWideChar(CP_ACP, 0, comment, -1, NULL, (int)NULL);
	MultiByteToWideChar(CP_ACP, 0, 	comment, -1, wComment, nLen);
    
	nLen = MultiByteToWideChar(CP_ACP, 0, servername, -1, NULL, (int)NULL);
	MultiByteToWideChar(CP_ACP, 0, 	servername, -1, wServerName, nLen);
	
	ui.usri1_name = wUsername;
	ui.usri1_password = wPassword;
	ui.usri1_priv = USER_PRIV_USER;
	ui.usri1_home_dir = NULL;
	ui.usri1_comment = wComment;
	ui.usri1_flags = UF_SCRIPT | UF_DONT_EXPIRE_PASSWD | UF_PASSWD_CANT_CHANGE;
	ui.usri1_script_path = NULL;

	nStatus = NetUserAdd(wServerName, 
				dwLevel, 
				(LPBYTE)&ui, 
				&dwError);
	
	if (nStatus != NERR_Success)
	{
		TCHAR *accterr;
		switch (nStatus)
		{
			case ERROR_ACCESS_DENIED: 
				accterr = "Access Denied.";
				break;
			case NERR_InvalidComputer: 
				accterr = "The computer name is invalid.";
				break;
			case NERR_NotPrimary: 
				accterr = "The operation is allowed only on the primary domain controller of the domain.";
				break;
			case NERR_GroupExists: 
				accterr = "The group already exists.";
				break;
			case NERR_UserExists: 
				accterr = "The user account already exists.";
				break;
			case NERR_PasswordTooShort: 
				accterr = "The password is too short or not complex enough.";
				break;
			default: 
				accterr = "Unknown error.";
				break;
		}

		sprintf_s(errbuf, errsize, "The service user account '%s' could not be created: %s\n",  username, accterr);

	}
	else
	{
		// Hide this user on Logon Screen
		HideUserFromLogon(username);
	}

    return nStatus;
}

static struct _privInfo {
	char *privname;
	WCHAR *friendlyname;
	BOOL has;
} _privileges[3] = {
	{ SE_SERVICE_LOGON_NAME, L"Log on as a service", FALSE },
	{ SE_NETWORK_LOGON_NAME, L"Access this computer from the network", FALSE },
	{ SE_INTERACTIVE_LOGON_NAME, L"Log on locally", FALSE}
};

static void InitLsaString(PLSA_UNICODE_STRING LsaString, const char *string)
{
    size_t StringLength;

    if (string == NULL) {
        LsaString->Buffer = NULL;
        LsaString->Length = 0;
        LsaString->MaximumLength = 0;
        return;
    }

    StringLength = strlen(string);
    LsaString->Buffer = (PWSTR)malloc((StringLength+1) * sizeof(WCHAR));
	_snwprintf_s(LsaString->Buffer, StringLength+1, _TRUNCATE, L"%S", string);
    LsaString->Length = (USHORT) StringLength * sizeof(WCHAR);
    LsaString->MaximumLength=(USHORT)(StringLength+1) * sizeof(WCHAR);
}

static void CheckDefaultPrivileges(LSA_HANDLE PolicyHandle)
{
	int i;
	PSID defaultSids[6];
	SID_IDENTIFIER_AUTHORITY WorldAuthority = { SECURITY_WORLD_SID_AUTHORITY };
	SID_IDENTIFIER_AUTHORITY NtAuthority = { SECURITY_NT_AUTHORITY };

	if (!AllocateAndInitializeSid(&WorldAuthority, 1, SECURITY_WORLD_RID, 0, 0,0,0,0,0,0, &defaultSids[0]))
		defaultSids[0]=NULL;
	if (!AllocateAndInitializeSid(&NtAuthority, 1, SECURITY_AUTHENTICATED_USER_RID, 0,0,0,0,0,0,0,&defaultSids[1]))
		defaultSids[1]=NULL;
	if (!AllocateAndInitializeSid(&NtAuthority, 2, SECURITY_BUILTIN_DOMAIN_RID, DOMAIN_GROUP_RID_USERS, 0,0,0,0,0,0, &defaultSids[2]))
		defaultSids[2]=NULL;
	if (!AllocateAndInitializeSid(&NtAuthority, 2, SECURITY_BUILTIN_DOMAIN_RID, DOMAIN_ALIAS_RID_USERS, 0,0,0,0,0,0, &defaultSids[3]))
		defaultSids[3]=NULL;
	if (!AllocateAndInitializeSid(&NtAuthority, 1, SECURITY_SERVICE_RID, 0,0,0,0,0,0,0,&defaultSids[4]))
		defaultSids[4]=NULL;
	if (!AllocateAndInitializeSid(&NtAuthority, 1, SECURITY_INTERACTIVE_RID, 0,0,0,0,0,0,0,&defaultSids[5]))
		defaultSids[5]=NULL;


	for (i=0;i<sizeof(_privileges)/sizeof(_privileges[0]);i++)
	{
		LSA_UNICODE_STRING priv;
		NTSTATUS status;
		LSA_ENUMERATION_INFORMATION *info = NULL;
		ULONG count, j;

		InitLsaString(&priv, _privileges[i].privname);

		status = LsaEnumerateAccountsWithUserRight(PolicyHandle, &priv, (LPVOID *)&info, &count);
		if (status == STATUS_SUCCESS)
		{
			for (j=0; j < count; j++)
			{
				int k;
				for (k=0; k < sizeof(defaultSids)/sizeof(defaultSids[0]); k++)
				{
					if (EqualSid(info[j].Sid, defaultSids[k]))
					{
						_privileges[i].has=TRUE;
						break;
					}
				}
				if (_privileges[i].has)
					break;
			}
			LsaFreeMemory(info);
		}
	}
	for (i=0; i < sizeof(defaultSids)/sizeof(defaultSids[0]); i++)
		FreeSid(defaultSids[i]);
}

bool CheckUserPrivileges(LPTSTR domain, LPTSTR username, TCHAR *errbuf, DWORD errsize)
{
	char uname[1024];
	SID_NAME_USE peUse;
	PSID sid;
	DWORD sidsize = sizeof(sid);
	char refdom[MAX_PATH];
	DWORD refsize = sizeof(refdom);

	LSA_OBJECT_ATTRIBUTES ObjectAttributes;
	LSA_HANDLE PolicyHandle;
	NTSTATUS status;
	PLSA_UNICODE_STRING rightList=NULL;
	ULONG rightCount =0;
	ULONG i,j;

	LSA_UNICODE_STRING servicePriv;

	wsprintf(uname, "%s\\%s", domain, username);

	if (LookupAccountName(NULL,
						  uname,
						  NULL,
						  &sidsize,
						  refdom,
						  &refsize,
						  &peUse))
	{
		sprintf_s(errbuf, errsize, "The account name specified could not be found.\n", errsize);
		return false;
	}
	if (GetLastError() != 122)
	{
		sprintf_s(errbuf, errsize, "Internal account lookup failure: %s\n", lasterror_string());
		return false;
	}
	sid = malloc(sidsize);
	refsize = sizeof(refdom);
	if (!sid)
	{
		sprintf_s(errbuf, errsize, "Failed to allocate memory to hold a SID.\n", errsize);
		return false;
	}

	if (!LookupAccountName(NULL,
						  uname,
						  sid,
						  &sidsize,
						  refdom,
						  &refsize,
						  &peUse))
	{
		sprintf_s(errbuf,errsize, "Failed to lookup account SID: %s\n", lasterror_string());
		free(sid);
		return false;
	}

	ZeroMemory(&ObjectAttributes,sizeof(ObjectAttributes));
	status = LsaOpenPolicy(NULL, &ObjectAttributes, POLICY_LOOKUP_NAMES | POLICY_VIEW_LOCAL_INFORMATION | POLICY_WRITE, &PolicyHandle);

	if (status != STATUS_SUCCESS)
	{
		sprintf_s(errbuf, errsize, "Failed to open local computer policy. Unable to determine user account rights: %i\n", (int)LsaNtStatusToWinError(status));
		free(sid);
		return TRUE;
	}

	status = LsaEnumerateAccountRights(PolicyHandle, sid, &rightList, &rightCount);
	if (status != STATUS_SUCCESS && LsaNtStatusToWinError(status) != 2)
	{
		sprintf_s(errbuf, errsize, "Failed to enumerate account rights. Unable to determine user account rights: %i\n", (int)LsaNtStatusToWinError(status));
		LsaClose(PolicyHandle);
		free(sid);
		return TRUE;
	}

	if (status == STATUS_SUCCESS)
	{
		/* Found one or more privs. Error 2 = no privs on this account */
		for (i = 0; i < rightCount; i++)
		{
			char privname[256];
			wsprintf(privname, "%S", rightList[i].Buffer);

			for (j=0; j < sizeof(_privileges)/sizeof(_privileges[0]); j++)
				if (!strcmp(privname, _privileges[j].privname))
					_privileges[j].has=TRUE;
		}
	}

	LsaFreeMemory(rightList);

	CheckDefaultPrivileges(PolicyHandle);

	for (j=0; j < sizeof(_privileges)/sizeof(_privileges[0]); j++)
	{
		if (!_privileges[j].has)
		{
			// Grant this right
			InitLsaString(&servicePriv, _privileges[j].privname);

			status = LsaAddAccountRights(PolicyHandle, sid, &servicePriv, 1);
			if (status != STATUS_SUCCESS)
			{
				sprintf_s(errbuf, errsize, "Failed to grant the '%S' right to '%s\\%s': %i\n", _privileges[j].friendlyname, domain, username, (int)LsaNtStatusToWinError(status));
				LsaClose(PolicyHandle);
				free(sid);
				return FALSE;
			}
			else
			{
				fprintf(stdout, "Granted the '%S' right to '%s\\%s'\n", _privileges[j].friendlyname, domain, username);
			}
		}
	}

	LsaClose(PolicyHandle);
	free(sid);

	return TRUE;
}

int main(int argc, TCHAR * argv[])
{
	TCHAR domain[256], username[256], password[256], errmsg[1024], servername[256];
        OSVERSIONINFOEX verinfo;

	// Check the command line
	if (argc != 4)
	{
		fprintf(stderr, "Usage: %s <Domain> <Username> <Password>\n", argv[0]);
		return 127;
	}

	// Cleanup the command line arguments
	if (strcmp(argv[1], ".") == 0)
	{
		// If this is a domain controller, we need to use the domain
		// name, otherwise, we use the computer name.
		ZeroMemory(&verinfo,sizeof(verinfo));
		verinfo.dwOSVersionInfoSize = sizeof(verinfo);

		if (!GetVersionEx((OSVERSIONINFO*)&verinfo))
		{
			fprintf(stderr, "Failed to retrieve the operating system version information.\n");
			return 1;	
		}

		if (verinfo.wProductType == VER_NT_DOMAIN_CONTROLLER)
		{
			// It's a DC
			WKSTA_INFO_100 *wkinfo = NULL;
			NET_API_STATUS status;
			LPWSTR buffer;

			status = NetWkstaGetInfo(NULL, 100, (LPBYTE*)&wkinfo);
			if (status != NERR_Success)
			{
			    fprintf(stderr, "Failed to retrieve workstation information.\n");
			    return 1;	
			}
			status = NetGetDCName( NULL, NULL, (LPBYTE *)&buffer);
			if (status != NERR_Success)
			{
			    fprintf(stderr, "Failed to retrieve Primary Domain Controller name.\n");
			    return 1;	
			}
			sprintf_s(domain, sizeof(domain), "%S", wkinfo->wki100_langroup);
			sprintf_s(servername, sizeof(servername), "%S", buffer);

			if (wkinfo != NULL)
				NetApiBufferFree(wkinfo);

			if (buffer != NULL)
				NetApiBufferFree(buffer);
		}
		else
		{
			// It's a workstation or server
			DWORD size=sizeof(servername);
			GetComputerName(servername, &size);
			sprintf_s(domain, sizeof(domain), "%s", servername);
			
		}
	}
	else
	{
		DWORD size=sizeof(servername);
		GetComputerName(servername, &size);
		sprintf_s(domain, sizeof(domain), "%s", argv[1]);
	}

	sprintf_s(username, sizeof(username), "%s", argv[2]);
	sprintf_s(password, sizeof(password), "%s", argv[3]);

	// Check to see if the user account exists
	if (!CheckUserExists(servername, username))
	{
		NET_API_STATUS status;
		status = CreateUser(servername, username, password, errmsg, sizeof(errmsg)/sizeof(TCHAR) - 1);
		if (status != NERR_Success)
		{
		    fprintf(stderr, errmsg);
		    return status;
		}
	}
	else
	{
		fprintf(stdout, "User account '%s\\%s' already exists.\n", domain, username);
	}

	// Make sure the user has the correct privileges
	if (!CheckUserPrivileges(domain, username, errmsg, sizeof(errmsg)/sizeof(TCHAR) - 1))
	{
		fprintf(stderr, errmsg);
		return 1;	
	}

	// Make sure - it is member of BUILTIN\Users group
	{
		LOCALGROUP_MEMBERS_INFO_3 grp;
		NET_API_STATUS nStatus;
		TCHAR qualifiedUser[200];
		WCHAR wQualifiedUser[200], wGroupName[20], wServerName[100];
		int nLen = 0;
		
		sprintf_s(qualifiedUser, sizeof(qualifiedUser), "%s\\%s", domain, username);
		
		nLen = MultiByteToWideChar(CP_ACP, 0, username, -1, NULL, (int)NULL);
		MultiByteToWideChar(CP_ACP, 0,  username, -1, wQualifiedUser, nLen);
		
		nLen = MultiByteToWideChar(CP_ACP, 0, "Users", -1, NULL, (int)NULL);
		MultiByteToWideChar(CP_ACP, 0,  "Users", -1, wGroupName, nLen);
		
		nLen = MultiByteToWideChar(CP_ACP, 0, servername, -1, NULL, (int)NULL);
		MultiByteToWideChar(CP_ACP, 0,  servername, -1, wServerName, nLen);
		
		grp.lgrmi3_domainandname = wQualifiedUser;

		nStatus = NetLocalGroupAddMembers(wServerName, wGroupName, 3, (LPBYTE)&grp, 1);
		

		switch(nStatus)
		{
			case NERR_Success:
				fprintf(stdout, "User account '%s' added to 'Users' group.\n", qualifiedUser);
				break;
			case ERROR_MEMBER_IN_ALIAS:
				fprintf(stdout, "User '%s' already member of 'Users' group.\n", qualifiedUser);
				break;
			case ERROR_ACCESS_DENIED:
				fprintf(stderr, "Access Denied (Adding '%s' to 'Users' group.)\n", qualifiedUser);
				return nStatus;
			case ERROR_NO_SUCH_MEMBER:
				fprintf(stderr, "No member exists called '%s'. Therefore, no new members were added to 'Users'.\n", qualifiedUser);
				return nStatus;
			case ERROR_INVALID_MEMBER:
				fprintf(stderr, "User '%s' cannot be added to 'Users' group because its account type is invalid.\n", qualifiedUser);
				return nStatus;
		}
	}

	fprintf(stdout, "%s ran to completion\n", argv[0]);
	return 0;
}


