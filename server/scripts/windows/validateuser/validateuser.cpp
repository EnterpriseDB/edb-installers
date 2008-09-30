// PostgreSQL server service user validation proglet for Windows
// Dave Page, EnterpriseDB

#define WIN32_LEAN_AND_MEAN
#include "windows.h"
#include "stdio.h"

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
                   LOGON32_LOGON_SERVICE,
                   LOGON32_PROVIDER_DEFAULT,
                   &token))
    {
        CloseHandle(token);
        return false;
    }
    CloseHandle(token);

    return true;
}


int main(int argc, TCHAR * argv[])
{
	TCHAR domain[256], username[256], password[256];

	// Check the command line
	if (argc != 4)
	{
		fprintf(stderr, "Usage: %s <Domain> <Username> <Password>", argv[0]);
		return 127;
	}

	// Cleanup the command line arguments
	if (strcmp(argv[1], ".") == 0)
	{
		DWORD size=sizeof(domain);
		GetComputerName(domain, &size);
	}
	else
		sprintf_s(domain, sizeof(domain), argv[1]);

	sprintf_s(username, sizeof(username), argv[2]);
	sprintf_s(password, sizeof(password), argv[3]);

	// Check to see if the user account exists
	if (!CheckUserExists(domain, username))
	{
		fprintf(stdout, "User account '%s\\%s' does not exist.", domain, username);
		return 0;
	}

	// Check the password
	if (!TestLogin(domain, username, password))
	{
		fprintf(stdout, "Incorrect password for user '%s\\%s'.", domain, username);
		return 1;		
	}

	fprintf(stdout, "%s ran to completion", argv[0]);
	return 0;
}


