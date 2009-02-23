#include <windows.h>
#include <stdio.h>
#include <userenv.h>
#include <io.h>
#include <direct.h>
#include <wchar.h>

FILE *fPGPASSConf = NULL;
HANDLE  hToken    = NULL;
LPVOID  lpvEnv    = NULL;


void DisplayError(LPCSTR pszAPI)
{
    LPVOID lpvMessageBuffer;

    FormatMessage(FORMAT_MESSAGE_ALLOCATE_BUFFER | 
        FORMAT_MESSAGE_FROM_SYSTEM,
        NULL, GetLastError(), 
        MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT), 
        (LPSTR)&lpvMessageBuffer, 0, NULL);

    fprintf(stderr, "ERROR: API        = %s.\n", pszAPI);
    fprintf(stderr, "       error code = %d.\n", GetLastError());
    fprintf(stderr, "       message    = %s.\n", (LPSTR)lpvMessageBuffer);

    LocalFree(lpvMessageBuffer);
    if (fPGPASSConf)
        fclose(fPGPASSConf);
    if (lpvEnv)
        DestroyEnvironmentBlock(lpvEnv);
    if (hToken)
        CloseHandle(hToken);
    ExitProcess(GetLastError());
}


int main(int argc, char **argv)
{
    DWORD dwSize;
	int   res;
    char  szUserProfile[256] = "";
	char  szConfstr[1024] = {0};
	DWORD dwBytesToWrite = 0;
    DWORD dwBytesWritten = 0;
   
    if (argc != 8)
    {
        fprintf(stderr, "Usage: %s [user] [password] [hostname] [port] [database] [pguser] [pgpassword]\n\r", argv[0]);
		return -1;
    }

    if (!LogonUser(argv[1], ".", argv[2], LOGON32_LOGON_INTERACTIVE, 
            LOGON32_PROVIDER_DEFAULT, &hToken))
        DisplayError("LogonUser");

    if (!CreateEnvironmentBlock(&lpvEnv, hToken, TRUE))
        DisplayError("CreateEnvironmentBlock");

    dwSize = sizeof(szUserProfile)/sizeof(char);

    if (!GetUserProfileDirectory(hToken, (LPSTR)szUserProfile, &dwSize))
        DisplayError("GetUserProfileDirectory");

    if (_chdir(szUserProfile) == -1)
        DisplayError("ChangeToUserProfile");

    if (_chdir("Application Data") == -1)
    {
        if (_chdir("AppData") == -1)
            DisplayError("ChangeToAppData");
        else if (_chdir("Roaming") == -1)
            DisplayError("ChangeToAppDataRoaming");
    }

	res = _mkdir("postgresql");

	/* ERROR 183 : already exists directory */
	if (res == 0 || GetLastError() == 183)
	{
        if (_chdir("postgresql") == -1)
            DisplayError("ChangeToUserProfile");    
	}
	else
		DisplayError("CreatePostgresqlDir");

	res = fopen_s(&fPGPASSConf, "pgpass.conf", "a");
	
	if (fPGPASSConf == 0)
		DisplayError("OpenPGPASSConf");

    /* hostname:port:database:username:password */
	sprintf_s(szConfstr, 1023, "%s:%s:%s:%s:%s\r\n", argv[3], argv[4], argv[5], argv[6], argv[7]);
	if (szConfstr == NULL)
		DisplayError("ConvertingUnicodeToAnsi");

	dwBytesToWrite = (DWORD)strlen(szConfstr);

	if (fwrite(szConfstr, sizeof(char), dwBytesToWrite, fPGPASSConf) != dwBytesToWrite)
	{
		fprintf(stderr, "Could not write to pgpass.conf:ERROR CODE:%d", GetLastError());
	}

	if (!DestroyEnvironmentBlock(lpvEnv))
        DisplayError("DestroyEnvironmentBlock");
        
	fclose(fPGPASSConf);
    CloseHandle(hToken);

	fprintf(stdout, "%s ran to completion", argv[0]);
	return 0;
}

