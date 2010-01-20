#include <windows.h>
#include <tchar.h>
#include <stdio.h>
#include <fcntl.h>
#include <io.h>
#include <direct.h>
#include <userenv.h>

FILE *fEDBREPLConf = NULL;
HANDLE  hToken    = NULL;

void DisplayError(LPCSTR pszAPI)
{
    LPVOID lpvMessageBuffer;

    FormatMessage(FORMAT_MESSAGE_ALLOCATE_BUFFER | 
            FORMAT_MESSAGE_FROM_SYSTEM,
            NULL, GetLastError(), 
            MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT), 
            (LPSTR)&lpvMessageBuffer, 0, NULL);

    fprintf_s(stderr, "ERROR: API        = %s.\n", pszAPI);
    fprintf_s(stderr, "       error code = %d.\n", GetLastError());
    fprintf_s(stderr, "       message    = %s.\n", (LPSTR)lpvMessageBuffer);

    LocalFree(lpvMessageBuffer);
    if (fEDBREPLConf)
        fclose(fEDBREPLConf);
    if (hToken)
        CloseHandle(hToken);
    ExitProcess(GetLastError());
}


#ifdef __cplusplus
extern "C"
#endif
int _tmain(int argc, _TCHAR **argv, _TCHAR **envp)
{
    PROFILEINFO  pi;
    TCHAR        szProfilePath[1024];
    DWORD        cchPath   = 1024;
    int          res       = 0;
    fpos_t       pos;
    char         szConfstr[1024] = {0};
    DWORD        dwBytesToWrite = 0;
    DWORD        dwBytesWritten = 0;


    // Check for the required command-line arguments
    if (argc != 9)
    {
		fprintf_s(stderr, "Usage: %s [user] [password] [hostname] [port] [database] [pguser] [pgpassword] [dbtype]\n\r", argv[0]);
        return -1;
    }

    // Do a network logon because most systems do not grant new users
    // the right to logon interactively (SE_INTERACTIVE_LOGON_NAME)
    // but they do grant the right to do a network logon
    // (SE_NETWORK_LOGON_NAME). A network logon has the added advantage
    // of being quicker.

    // NOTE: To call LogonUser(), the current user must have the
    // SE_TCB_NAME privilege
    if ( !LogonUser(
                argv[1],                  // user name
                _T("."),                  // domain or server
                argv[2],                  // password
                LOGON32_LOGON_NETWORK,    // type of logon operation
                LOGON32_PROVIDER_DEFAULT, // logon provider
                &hToken))                 // pointer to token handle
    {
        DisplayError(_T("LogonUser"));
        return -1;
    }

    // Set up the PROFILEINFO structure that will be used to load the
    // new user's profile
    ZeroMemory(&pi, sizeof(pi));

    pi.dwSize = sizeof(pi);
    pi.lpUserName = argv[1];
    pi.dwFlags = PI_NOUI;

    // Load the profile. Since it doesn't exist, it will be created
    if (!LoadUserProfile(hToken, &pi))
    {
        DisplayError(_T("LoadUserProfile"));
        return -1;
    }

    // Unload the profile when it is no longer needed
    if (!UnloadUserProfile(hToken, pi.hProfile))
    {
        DisplayError(_T("UnloadUserProfile"));
        return -1;
    }

    // Retrieve the new user's profile directory
    if (!GetUserProfileDirectory(hToken, szProfilePath, &cchPath))
    {
        DisplayError(_T("GetUserProfileDirectory"));
        return -1;
    }

    _chdir(szProfilePath);

    if (_chdir("Application Data") == -1)
    {
        if (_chdir("AppData") == -1)
            DisplayError("ChangeToAppData");
        else if (_chdir("Roaming") == -1)
            DisplayError("ChangeToAppDataRoaming");
    }

    res = _mkdir("EnterpriseDB");

    /* ERROR 183 : already exists directory */
    if (res == 0 || GetLastError() == 183)
    {
        if (_chdir("EnterpriseDB") == -1)
            DisplayError("ChangeToUserProfile");    
    }
    else
        DisplayError("CreateEnterpriseDBDir");

    res = fopen_s(&fEDBREPLConf, "edb-repl.conf", "w");

    if (fEDBREPLConf == 0)
        DisplayError("OpenEDBREPLConf");

    // Move to the end of file
    fseek(fEDBREPLConf, 0L, SEEK_END);
    fgetpos(fEDBREPLConf, &pos);

    sprintf_s(szConfstr, 1023, "user=%s\nport=%s\npassword=%s\ntype=%s\nhost=%s\ndatabase=%s\n", argv[6], argv[4], argv[7], argv[8], argv[3], argv[5]);
    
    dwBytesToWrite = (DWORD)strlen(szConfstr);

    if (fwrite(szConfstr, sizeof(char), dwBytesToWrite, fEDBREPLConf) != dwBytesToWrite)
    {
        fprintf(stderr, "Could not write to edb-repl.conf:ERROR CODE:%d", GetLastError());
    }

    fclose(fEDBREPLConf);
    CloseHandle(hToken);

    fprintf(stdout, "%s ran to completion", argv[0]);

    return 0;
}

