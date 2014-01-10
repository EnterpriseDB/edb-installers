/*-------------------------------------------------------------------------
*
* ServiceWrapper --- register/unregister a java application as windows service
* 
*-------------------------------------------------------------------------
*/

#ifdef WIN32
/*
* Need this to get defines for restricted tokens and jobs. And it
* has to be set before any header from the Win32 API is loaded.
*/
#define _WIN32_WINNT 0x0501
#endif

#include <locale.h>
#include <signal.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <process.h>
#include <windows.h>
#include <io.h>
#include <stdio.h>
#include <errno.h>
#include <TlHelp32.h>

#undef WIN32

#define BADCH   '?'
#define BADARG  ':'
#define EMSG	""
#define DEFAULT_WAIT                                      60
#define MAXPATH                                         1024
#define MAX_CHILD_PROCESS_COUNT                          128

typedef long pid_t;

typedef enum
{
	false,
	true
} bool;

typedef enum
{
	NO_COMMAND = 0,
	RESTART_COMMAND,
	REGISTER_COMMAND,
	UNREGISTER_COMMAND,
	RUN_AS_SERVICE_COMMAND
} CtlCommand;


static struct option
{
	const char *name;
	int		 has_arg;
	int		*flag;
	int		 val;
};


static CtlCommand ctl_command = NO_COMMAND;
static char *exec_opts = NULL;
static char *service_desc = NULL;
static const char *progname;
static char *exec_path = NULL;
static char *register_servicename = NULL;
static char *register_username = NULL;
static char *register_password = NULL;
static char *working_directory = NULL;
static char *argv0 = NULL;

int opterr;
int optind;
int optopt;
char *optarg;
int optreset;

static void
	write_stderr(const char *fmt,...);

static char *xstrdup(const char *s);
static void do_advice(void);
static void do_help(void);
static void print_msg(const char *msg);

static bool IsInstalled(SC_HANDLE);
static char *CommandLine(bool);
static void doRegister(void);
static void doUnregister(void);
static void WS_SetServiceStatus(DWORD);
static void WINAPI ServiceHandler(DWORD);
static void WINAPI ServiceMain(DWORD, LPTSTR *);
static void doRunAsService(void);

static SERVICE_STATUS status;
static SERVICE_STATUS_HANDLE hStatus = (SERVICE_STATUS_HANDLE) 0;
static HANDLE shutdownHandles[2];
static pid_t execPID = -1;

#define shutdownEvent	  shutdownHandles[0]
#define execProcess shutdownHandles[1]
#define no_argument 0
#define required_argument 1

int
	getopt_long(int argc, char *const argv[],
	const char *optstring,
	const struct option * longopts, int *longindex)
{
	static char *place = EMSG;	/* option letter processing */
	char	   *oli;			/* option letter list index */

	if (optreset || !*place)
	{							/* update scanning pointer */
		optreset = 0;

		if (optind >= argc)
		{
			place = EMSG;
			return -1;
		}

		place = argv[optind];

		if (place[0] != '-')
		{
			place = EMSG;
			return -1;
		}

		place++;

		if (place[0] && place[0] == '-' && place[1] == '\0')
		{						/* found "--" */
			++optind;
			place = EMSG;
			return -1;
		}

		if (place[0] && place[0] == '-' && place[1])
		{
			/* long option */
			size_t		namelen;
			int			i;

			place++;

			namelen = strcspn(place, "=");
			for (i = 0; longopts[i].name != NULL; i++)
			{
				if (strlen(longopts[i].name) == namelen
					&& strncmp(place, longopts[i].name, namelen) == 0)
				{
					if (longopts[i].has_arg)
					{
						if (place[namelen] == '=')
							optarg = place + namelen + 1;
						else if (optind < argc - 1)
						{
							optind++;
							optarg = argv[optind];
						}
						else
						{
							if (optstring[0] == ':')
								return BADARG;
							if (opterr)
								fprintf(stderr,
								"%s: option requires an argument -- %s\n",
								argv[0], place);
							place = EMSG;
							optind++;
							return BADCH;
						}
					}
					else
					{
						optarg = NULL;
						if (place[namelen] != 0)
						{
							/* XXX error? */
						}
					}

					optind++;

					if (longindex)
						*longindex = i;

					place = EMSG;

					if (longopts[i].flag == NULL)
						return longopts[i].val;
					else
					{
						*longopts[i].flag = longopts[i].val;
						return 0;
					}
				}
			}

			if (opterr && optstring[0] != ':')
				fprintf(stderr,
				"%s: illegal option -- %s\n", argv[0], place);
			place = EMSG;
			optind++;
			return BADCH;
		}
	}

	/* short option */
	optopt = (int) *place++;

	oli = strchr(optstring, optopt);
	if (!oli)
	{
		if (!*place)
			++optind;
		if (opterr && *optstring != ':')
			fprintf(stderr,
			"%s: illegal option -- %c\n", argv[0], optopt);
		return BADCH;
	}

	if (oli[1] != ':')
	{							/* don't need argument */
		optarg = NULL;
		if (!*place)
			++optind;
	}
	else
	{							/* need an argument */
		if (*place)				/* no white space */
			optarg = place;
		else if (argc <= ++optind)
		{						/* no arg */
			place = EMSG;
			if (*optstring == ':')
				return BADARG;
			if (opterr)
				fprintf(stderr,
				"%s: option requires an argument -- %c\n",
				argv[0], optopt);
			return BADCH;
		}
		else
			/* white space */
			optarg = argv[optind];
		place = EMSG;
		++optind;
	}
	return optopt;
}

static void
	write_eventlog(int level, const char *line)
{
	static HANDLE evtHandle = INVALID_HANDLE_VALUE;

	if (evtHandle == INVALID_HANDLE_VALUE)
	{
		evtHandle = RegisterEventSource(NULL, "ServiceWrapper");
		if (evtHandle == NULL)
		{
			evtHandle = INVALID_HANDLE_VALUE;
			return;
		}
	}

	ReportEvent(evtHandle,
		level,
		0,
		0,				/* All events are Id 0 */
		NULL,
		1,
		0,
		&line,
		NULL);
}


/*
* Write errors to stderr (or by equal means when stderr is
* not available).
*/
static void
	write_stderr(const char *fmt,...)
{
	va_list		ap;

	va_start(ap, fmt);


	/*
	* On Win32, we print to stderr if running on a console, or write to
	* eventlog if running as a service
	*/
	if (!_isatty(_fileno(stderr)))	/* Running as a service */
	{
		char		errbuf[2048];		/* Arbitrary size? */

		vsnprintf(errbuf, sizeof(errbuf), fmt, ap);

		write_eventlog(EVENTLOG_ERROR_TYPE, errbuf);
	}
	else
		/* Not running as service, write to stderr */
		vfprintf(stderr, fmt, ap);

	va_end(ap);
}



/*
* routines to check memory allocations and fail noisily.
*/


static char *
	xstrdup(const char *s)
{
	char	   *result;

	result = strdup(s);
	if (!result)
	{
		write_stderr("%s: out of memory\n", progname);
		exit(1);
	}
	return result;
}

/*
* Given an already-localized string, print it to stdout unless the
* user has specified that no messages should be printed.
*/
static void
	print_msg(const char *msg)
{
	fputs(msg, stdout);
	fflush(stdout);
}


static bool
	IsInstalled(SC_HANDLE hSCM)
{
	SC_HANDLE	hService = OpenService(hSCM, register_servicename, SERVICE_QUERY_CONFIG);
	bool		bResult = (hService != NULL);

	if (bResult)
		CloseServiceHandle(hService);
	return bResult;
}

static char *
	CommandLine(bool registration)
{
	static char cmdLine[MAXPATH];

	if (registration)
	{
		/* TO DO: Find the Absolute path of the Service Wrapper */
		strcpy(cmdLine, argv0);

		strcat(cmdLine, " runservice -n ");
		strcat(cmdLine, "\"");
		strcat(cmdLine, register_servicename);
		strcat(cmdLine, "\"");
		strcat(cmdLine, " -c \"");
		strcat(cmdLine, exec_path);
		strcat(cmdLine, "\"");
		if (exec_opts)
		{
			strcat(cmdLine, " -o \"");
			strcat(cmdLine, exec_opts);
			strcat(cmdLine, "\"");
		}
		if (working_directory) 
		{
			strcat(cmdLine, " -w \"");
			strcat(cmdLine, working_directory);
			strcat(cmdLine, "\"");
		}
	}
	else
	{
		strcpy(cmdLine, "\"");
		strcat(cmdLine, exec_path);
		strcat(cmdLine, "\" ");

		if (exec_opts)
		{
			strcat(cmdLine, exec_opts);
		}
	}

	return cmdLine;
}

static void
	doRegister(void)
{
	SC_HANDLE	hService;
	SC_HANDLE	hSCM = OpenSCManager(NULL, NULL, SC_MANAGER_ALL_ACCESS);

	if (hSCM == NULL)
	{
		write_stderr("%s: could not open service manager\n", progname);
		exit(1);
	}
	if (IsInstalled(hSCM))
	{
		CloseServiceHandle(hSCM);
		write_stderr("%s: service \"%s\" already registered\n", progname, register_servicename);
		exit(1);
	}
	if ((hService = CreateService(hSCM, register_servicename, service_desc,
		SERVICE_ALL_ACCESS, SERVICE_WIN32_OWN_PROCESS,
		SERVICE_AUTO_START, SERVICE_ERROR_NORMAL,
		CommandLine(true),
		NULL, NULL, "\0", register_username, register_password)) == NULL)
	{
		CloseServiceHandle(hSCM);
		write_stderr("%s: could not register service \"%s\": error code %d\n", progname, register_servicename, (int) GetLastError());
		exit(1);
	}
	CloseServiceHandle(hService);
	CloseServiceHandle(hSCM);
}

static void
	doUnregister(void)
{
	SC_HANDLE	hService;
	SC_HANDLE	hSCM = OpenSCManager(NULL, NULL, SC_MANAGER_ALL_ACCESS);

	if (hSCM == NULL)
	{
		write_stderr("%s: could not open service manager\n", progname);
		exit(1);
	}
	if (!IsInstalled(hSCM))
	{
		CloseServiceHandle(hSCM);
		write_stderr("%s: service \"%s\" not registered\n", progname, register_servicename);
		exit(1);
	}

	if ((hService = OpenService(hSCM, register_servicename, DELETE)) == NULL)
	{
		CloseServiceHandle(hSCM);
		write_stderr("%s: could not open service \"%s\": error code %d\n", progname, register_servicename, (int) GetLastError());
		exit(1);
	}
	if (!DeleteService(hService))
	{
		CloseServiceHandle(hService);
		CloseServiceHandle(hSCM);
		write_stderr("%s: could not unregister service \"%s\": error code %d\n", progname, register_servicename, (int) GetLastError());
		exit(1);
	}
	CloseServiceHandle(hService);
	CloseServiceHandle(hSCM);
}

static void
	WS_SetServiceStatus(DWORD currentState)
{
	status.dwCurrentState = currentState;
	SetServiceStatus(hStatus, (LPSERVICE_STATUS) &status);
}

/* Terminate process and child processes 3 levels deep... */
bool TerminateProcessTree(DWORD dwProcessId, HANDLE hProcess, UINT uExitCode)
{
	PROCESSENTRY32 pe;
	HANDLE hSnapshot = NULL;
	DWORD adwChildProcessL2[MAX_CHILD_PROCESS_COUNT] = {-1};
	DWORD adwChildProcessL3[MAX_CHILD_PROCESS_COUNT] = {-1};
	INT32 iChildProcessL2Count = -1;
	INT32 iChildProcessL3Count = -1;
	INT32 I;

	memset(&pe, 0, sizeof(PROCESSENTRY32));
	pe.dwSize = sizeof(PROCESSENTRY32);

	hSnapshot = CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);

	// Terminate main process and L1 child processes...
	if( Process32First(hSnapshot, &pe) )
	{
		do
		{
			// Terminate child processes
			if( pe.th32ParentProcessID == dwProcessId )
			{
				HANDLE hChildProcess = OpenProcess(PROCESS_ALL_ACCESS, FALSE, pe.th32ProcessID);
				if( hChildProcess )
				{
					iChildProcessL2Count += (iChildProcessL2Count < MAX_CHILD_PROCESS_COUNT);		// This would ensure that array is not overflown...
					adwChildProcessL2[iChildProcessL2Count] = pe.th32ProcessID;

					TerminateProcess(hChildProcess, 1);
					CloseHandle(hChildProcess);
				}
			}
		}
		while( Process32Next(hSnapshot, &pe) );

		// Kill main process...
		TerminateProcess(hProcess, 1);
		CloseHandle(hProcess);
	}

	// Terminate L2 child processes...
	if( Process32First(hSnapshot, &pe) )
	{
		do
		{
			// Terminate any left over child processes of child processes...
			for(I = 0; I <= iChildProcessL2Count; I++)
			{
				if( pe.th32ParentProcessID == adwChildProcessL2[I] )
				{
					HANDLE hChildProcess = OpenProcess(PROCESS_ALL_ACCESS, FALSE, pe.th32ProcessID);
					if( hChildProcess )
					{
						iChildProcessL3Count += (iChildProcessL3Count < MAX_CHILD_PROCESS_COUNT);		// This would ensure that array is not overflown...
						adwChildProcessL3[iChildProcessL3Count] = pe.th32ProcessID;

						TerminateProcess(hChildProcess, 1);
						CloseHandle(hChildProcess);
					}
				}
			}
		}
		while( Process32Next(hSnapshot, &pe) );
	}

	// Terminate L3 child processes...
	if( Process32First(hSnapshot, &pe) )
	{
		do
		{
			// Terminate any left over child processes of child processes...
			for(I = 0; I <= iChildProcessL3Count; I++)
			{
				if( pe.th32ParentProcessID == adwChildProcessL3[I] )
				{
					HANDLE hChildProcess = OpenProcess(PROCESS_ALL_ACCESS, FALSE, pe.th32ProcessID);
					if( hChildProcess )
					{
						TerminateProcess(hChildProcess, 1);
						CloseHandle(hChildProcess);
					}
				}
			}
		}
		while( Process32Next(hSnapshot, &pe) );
	}

	CloseHandle(hSnapshot);
	return true;
}

static void WINAPI
	ServiceHandler(DWORD request)
{
	switch (request)
	{
		case SERVICE_CONTROL_STOP:
		case SERVICE_CONTROL_SHUTDOWN:
	
			/*
			* We only need a short wait hint here as it just needs to wait
			* for the next checkpoint. They occur every 5 seconds during
			* shutdown
			*/
			status.dwWaitHint = 10000;
			WS_SetServiceStatus(SERVICE_STOP_PENDING);
			TerminateProcessTree(execPID, execProcess, 0);
			WS_SetServiceStatus(SERVICE_STOPPED);
			return;
	
		case SERVICE_CONTROL_PAUSE:
			/* Win32 config reloading */
			status.dwWaitHint = 5000;
			return;
	
		case SERVICE_CONTROL_CONTINUE:
		case SERVICE_CONTROL_INTERROGATE:
		default:
			break;
	}
}

/* Start the Service */
bool startService()
{
	PROCESS_INFORMATION pi;
	STARTUPINFO si;

	ZeroMemory(&si, sizeof(si));
	si.cb = sizeof(si);

	memset(&pi, 0, sizeof(pi));

	/* Start the service */
	if (!CreateProcess(NULL, CommandLine(false), NULL, NULL, FALSE, 0, NULL, working_directory, &si, &pi))
	{
		WS_SetServiceStatus(SERVICE_STOPPED);
		return false;
	}

	execPID = pi.dwProcessId;
	execProcess = pi.hProcess;
	return true;
}


static void WINAPI
	ServiceMain(DWORD argc, LPTSTR *argv)
{
	/* Initialize variables */
	DWORD		   ret;
	status.dwWin32ExitCode = S_OK;
	status.dwCheckPoint = 0;
	status.dwWaitHint = 60000;
	status.dwServiceType = SERVICE_WIN32_OWN_PROCESS;
	status.dwControlsAccepted = SERVICE_ACCEPT_STOP | SERVICE_ACCEPT_SHUTDOWN | SERVICE_ACCEPT_PAUSE_CONTINUE;
	status.dwServiceSpecificExitCode = 0;
	status.dwCurrentState = SERVICE_START_PENDING;

	/* Register the control request handler */
	if ((hStatus = RegisterServiceCtrlHandler(register_servicename, ServiceHandler)) == (SERVICE_STATUS_HANDLE) 0)
		return;

	if ((shutdownEvent = CreateEvent(NULL, true, false, NULL)) == NULL)
	{
		WS_SetServiceStatus(SERVICE_STOPPED);
		return;
	} 

	if (startService())
	{
		WS_SetServiceStatus(SERVICE_RUNNING); 
	}

	ret = WaitForSingleObject(execProcess, INFINITE);

	WS_SetServiceStatus(SERVICE_STOPPED);

}

static void
	doRunAsService(void)
{
	SERVICE_TABLE_ENTRY st[] = {{register_servicename, ServiceMain},
	{NULL, NULL}};

	if (StartServiceCtrlDispatcher(st) == 0)
	{
		write_stderr("%s: could not start service \"%s\": error code %d\n", progname, register_servicename, (int) GetLastError());
		exit(1);
	}
}

static void
	do_advice(void)
{
	write_stderr("Try \"%s --help\" for more information.\n", progname);
}


static void
	do_help(void)
{
	printf("%s is a utility to register and unregister java applications as windows service, \n", progname);
	printf("Usage:\n");
	printf("  %s register   [-n SERVICENAME] [-u USERNAME] [-p PASSWORD] \n"
		"					[-c Executable ] [-o \"OPTIONS\"]\n", progname);
	printf("  %s unregister [-n SERVICENAME]\n", progname);

	printf("\nCommon options:\n");
	printf("  --help				 show this help, then exit\n");
	printf("  --version			  output version information, then exit\n");

	printf("\nOptions for start or restart:\n");
	printf("  -c, java executable	Path to the java exe\n");
	printf("  -o OPTIONS			 command line options to pass to java\n");

	printf("\nOptions for register and unregister:\n");
	printf("  -n SERVICENAME  service name with which to register the java application\n");
	printf("  -d SERVICEDESC  service description\n");
	printf("  -p PASSWORD	 password of account to register \n");
	printf("  -u USERNAME	 user name of account to register\n");
	printf("  -w WORKING DIRECTORY  Working directory for the process\n");

}


int
	main(int argc, char **argv)
{
	static struct option long_options[] = {
		{"help", no_argument, NULL, '?'},
		{NULL, 0, NULL, 0}
	};

	int			option_index;
	int			c;


	setvbuf(stderr, NULL, _IONBF, 0);

	progname = argv[0];
	/*
	* save argv[0] so do_start() can look for the postmaster if necessary. we
	* don't look for postmaster here because in many cases we won't need it.
	*/
	argv0 = argv[0];

	umask(077);

	/* support --help */
	if (argc > 1)
	{
		if (strcmp(argv[1], "-h") == 0 || strcmp(argv[1], "--help") == 0 ||
			strcmp(argv[1], "-?") == 0)
		{
			do_help();
			exit(0);
		}
	}

	/*
	* 'Action' can be before or after args so loop over both. Some
	* getopt_long() implementations will reorder argv[] to place all flags
	* first (GNU?), but we don't rely on it. Our /port version doesn't do
	* that.
	*/
	optind = 1;

	/* process command-line options */
	while (optind < argc)
	{
		while ((c = getopt_long(argc, argv, "n:d:u:p:c:o:w:", long_options, &option_index)) != -1)
		{
			switch (c)
			{
				case 'n':
					register_servicename = xstrdup(optarg);
					break;
				case 'd':
					service_desc = xstrdup(optarg);
					break;
				case 'u':
	
					if (strchr(optarg, '\\'))
						register_username = xstrdup(optarg);
					else
						/* Prepend .\ for local accounts */
					{
	
						register_username = malloc(strlen(optarg) + 3);
						if (!register_username)
						{
							write_stderr("%s: out of memory\n", progname);
							exit(1);
						}
						strcpy(register_username, ".\\");
						strcat(register_username, optarg);
	
					}
					break;
				case 'p':
					register_password = xstrdup(optarg);
					break;
				case 'c':
					exec_path = xstrdup(optarg);
					break;
				case 'o':
					exec_opts = xstrdup(optarg);
					break;
				case 'w':
					working_directory = xstrdup(optarg);
					break;
				default:
					/* getopt_long already issued a suitable error message */
					do_advice();
					exit(1);
			}
		}

		/* Process an action */
		if (optind < argc)
		{
			if (ctl_command != NO_COMMAND)
			{
				write_stderr("%s: too many command-line arguments (first is \"%s\")\n", progname, argv[optind]);
				do_advice();
				exit(1);
			}
			else if (strcmp(argv[optind], "register") == 0)
				ctl_command = REGISTER_COMMAND;
			else if (strcmp(argv[optind], "unregister") == 0)
				ctl_command = UNREGISTER_COMMAND;
			else if (strcmp(argv[optind], "runservice") == 0)
				ctl_command = RUN_AS_SERVICE_COMMAND;
			else
			{
				write_stderr("%s: unrecognized operation mode \"%s\"\n", progname, argv[optind]);
				do_advice();
				exit(1);
			}
			optind++;
		}
	}

	if (ctl_command == NO_COMMAND)
	{
		write_stderr("%s: no operation specified\n", progname);
		do_advice();
		exit(1);
	}

	switch (ctl_command)
	{
		case REGISTER_COMMAND:
			doRegister();
			break;
		case UNREGISTER_COMMAND:
			doUnregister();
			break;
		case RUN_AS_SERVICE_COMMAND:
			doRunAsService();
			break;
		default:
			break;
	}

	exit(0);
}
