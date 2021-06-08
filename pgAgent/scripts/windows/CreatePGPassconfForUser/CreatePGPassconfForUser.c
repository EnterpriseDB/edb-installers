#include <windows.h>
#include <tchar.h>
#include <stdio.h>
#include <fcntl.h>
#include <io.h>
#include <direct.h>
#include <userenv.h>
#include <stdlib.h>

FILE *fPGPASSConf = NULL;
FILE *fPGPASSConfTemp = NULL;
HANDLE  hToken    = NULL;
char szLine[5000];
char szLineToWrite[1024] = {0};
char szPart [5000] = {0};
char szCombined [5000] = {0};
int len	= 0;
int ret = 0;
int pos = 0;
int i = 0;
int countofreduntantlines = 0;
int countoftotallines = 0;
int countoflinestobecopied = 0;
int onwhichline = 0;
DWORD dwBytesToWrite = 0;
DWORD dwBytesWritten = 0;


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
    if (fPGPASSConf)
        fclose(fPGPASSConf);
    if (hToken)
        CloseHandle(hToken);
    ExitProcess(GetLastError());
}

int CountRedundantEntries(_TCHAR **argv)
{
	//Check for file existence.Count existing enteries having same argv[3], argv[4], argv[5], argv[6]
	fPGPASSConf = NULL;
	countofreduntantlines = 0;

    ret = fopen_s(&fPGPASSConf, "pgpass.conf", "r");
    if (fPGPASSConf == 0)
	{
		//File not available for reading
	}
	else
	{
		memset(szCombined,'\0',sizeof(szCombined));
		strcat(szCombined,argv[3]);
		strcat(szCombined,":");
		strcat(szCombined,argv[4]);
		strcat(szCombined,":");
		strcat(szCombined,argv[5]);
		strcat(szCombined,":");
		strcat(szCombined,argv[6]);
		strcat(szCombined,":");

		fseek(fPGPASSConf, 0L, SEEK_SET);
		while ( fgets ( szLine, sizeof szLine, fPGPASSConf ) != NULL )
		{
			memset(szPart,'\0',sizeof(szPart));
			len = strlen(szLine);
			while(len > 0)
			{
				if(szLine[len] == ':')
					break;

				len--;
			}
			memcpy(szPart,szLine,len+1);

			//Ignore line if contains same entry
			if(strcmp(szPart,szCombined)==0)
			{
				countofreduntantlines++;
			}
			else
			{
				//ignore it
			}
			memset(szLine,'\0',sizeof(szLine));
		}
		fclose(fPGPASSConf);
	}

	return countofreduntantlines;
}

int CountTotalEntries(_TCHAR **argv)
{
	//Check for file existence.Count existing enteries having same argv[3], argv[4], argv[5], argv[6]
	fPGPASSConf = NULL;
	countoftotallines = 0;

    ret = fopen_s(&fPGPASSConf, "pgpass.conf", "r");
    if (fPGPASSConf == 0)
	{
		//File not available for reading
	}
	else
	{
		fseek(fPGPASSConf, 0L, SEEK_SET);
		while ( fgets ( szLine, sizeof szLine, fPGPASSConf ) != NULL )
		{
			countoftotallines++;
		}
		fclose(fPGPASSConf);
	}

	return countoftotallines;
}

int RemoveRedundantEntries(_TCHAR **argv)
{
	//Check for file existence.Remove existing enteries having same argv[3], argv[4], argv[5], argv[6]
	fPGPASSConf = NULL;
	fPGPASSConfTemp = NULL;

    ret = fopen_s(&fPGPASSConf, "pgpass.conf", "r");
    if (fPGPASSConf == 0)
	{
		//File not available for reading
        DisplayError("OpenPGPASSConf");
	}
	else
	{
	    ret = fopen_s(&fPGPASSConfTemp, "pgpass.conftemp", "w");
		if (fPGPASSConfTemp == 0)
		{
			//File not available for reading
			DisplayError("OpenPGPASSConfTemp");
		}

		memset(szCombined,'\0',sizeof(szCombined));
		strcat(szCombined,argv[3]);
		strcat(szCombined,":");
		strcat(szCombined,argv[4]);
		strcat(szCombined,":");
		strcat(szCombined,argv[5]);
		strcat(szCombined,":");
		strcat(szCombined,argv[6]);
		strcat(szCombined,":");

		fseek(fPGPASSConf, 0L, SEEK_SET);
		while ( fgets ( szLine, sizeof szLine, fPGPASSConf ) != NULL )
		{
			memset(szPart,'\0',sizeof(szPart));
			len = strlen(szLine);
			while(len > 0)
			{
				if(szLine[len] == ':')
					break;

				len--;
			}
			memcpy(szPart,szLine,len+1);

			//Ignore line if contains same entry
			if(strcmp(szPart,szCombined)==0)
			{

			}
			//Write lines in different file
			else
			{
				//Increment line number
				onwhichline++;

				memset(szLineToWrite,'\0',sizeof(szLineToWrite));
				dwBytesToWrite = 0;
				dwBytesWritten = 0;
				if(onwhichline == countoflinestobecopied)
				{
					for(i = 0; i < strlen(szLine); i++)
					{
						if(szLine[i] == '\n')
						{
							szLine[i] = '\0';
							break;
						}
					}
					//We don't have to write CR\LF(ASCII value 10) on last line which is being picked by fgets
					sprintf_s(szLineToWrite, 1023, "%s", szLine);
				}
				else
				{
					sprintf_s(szLineToWrite, 1023, "%s", szLine);
				}

				dwBytesToWrite = (DWORD)strlen(szLineToWrite);

				if (fwrite(szLineToWrite, sizeof(char), dwBytesToWrite, fPGPASSConfTemp) != dwBytesToWrite)
				{
					fprintf(stderr, "Could not write to pgpass.conftemp:ERROR CODE:%d", GetLastError());
				}
			}
			memset(szLine,'\0',sizeof(szLine));
		}

		// Move to the end of file
		pos=0;
	    fseek(fPGPASSConfTemp, 0L, SEEK_END);
	    fgetpos(fPGPASSConfTemp, &pos);
		fclose(fPGPASSConf);
		fclose(fPGPASSConfTemp);

		if (pos == 0L)
		{
			//Nothing found to be replaced
			system("del -F pgpass.conftemp");
		}
		else
		{
			//system("copy - /Y pgpass.conftemp pgpass.conf");
			system("del -F pgpass.conf");
			system("copy /Y pgpass.conftemp pgpass.conf");
			system("del -F pgpass.conftemp");
		}
	}
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


    // Check for the required command-line arguments
    if (argc != 8)
    {
        fprintf_s(stderr, "Usage: %s [user] [password] [hostname] [port] [database] [pguser] [pgpassword]\n\r", argv[0]);
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

    res = _mkdir("postgresql");

    /* ERROR 183 : already exists directory */
    if (res == 0 || GetLastError() == 183)
    {
        if (_chdir("postgresql") == -1)
            DisplayError("ChangeToUserProfile");    
    }
    else
        DisplayError("CreatePostgresqlDir");

	countoftotallines = CountTotalEntries(argv);
	if ( countoftotallines > 0 )
	{
		countofreduntantlines = CountRedundantEntries(argv);
		if ( countofreduntantlines > 0)
		{
			countoflinestobecopied = countoftotallines - countofreduntantlines;
			if ( countoflinestobecopied > 0)
			{
				RemoveRedundantEntries(argv);
			}
		}
	}

	//If whole file is filled previously with same entries then we don't need it at all.
	//Opening file in w mode to overwrite.
	if( countoftotallines == countofreduntantlines)
	{
		res = fopen_s(&fPGPASSConf, "pgpass.conf", "w");
	}
	else
	{
		res = fopen_s(&fPGPASSConf, "pgpass.conf", "a");
	}

    if (fPGPASSConf == 0)
        DisplayError("OpenPGPASSConf");

	dwBytesToWrite = 0;
	dwBytesWritten = 0;

    // Move to the end of file
    fseek(fPGPASSConf, 0L, SEEK_END);
    fgetpos(fPGPASSConf, &pos);

	if (pos == 0L)
			sprintf_s(szConfstr, 1023, "%s:%s:%s:%s:%s", argv[3], argv[4], argv[5], argv[6], argv[7]);
	else
			sprintf_s(szConfstr, 1023, "\n%s:%s:%s:%s:%s", argv[3], argv[4], argv[5], argv[6], argv[7]);

    dwBytesToWrite = (DWORD)strlen(szConfstr);

    if (fwrite(szConfstr, sizeof(char), dwBytesToWrite, fPGPASSConf) != dwBytesToWrite)
    {
        fprintf(stderr, "Could not write to pgpass.conf:ERROR CODE:%d", GetLastError());
    }

    fclose(fPGPASSConf);
    CloseHandle(hToken);

    fprintf(stdout, "%s ran to completion", argv[0]);

    return 0;
}
