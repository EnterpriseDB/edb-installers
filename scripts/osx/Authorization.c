#include <CoreFoundation/CoreFoundation.h>
#include <Security/Authorization.h>
#include <Security/AuthorizationTags.h>
#include <asl.h>
#include <unistd.h>
#include <fcntl.h>

OSStatus AcquireRight(AuthorizationRef gAuthorization, const char *rightName);

OSStatus AcquireRight(AuthorizationRef gAuthorization, const char *rightName)
    // This routine calls Authorization Services to acquire
    // the specified right.
{
    OSStatus                         err;
    static const AuthorizationFlags  kFlags =
                  kAuthorizationFlagInteractionAllowed
                | kAuthorizationFlagExtendRights
                | kAuthorizationFlagPreAuthorize;
    AuthorizationItem   kActionRight = { rightName, 0, 0, 0 };
    AuthorizationRights kRights      = { 1, &kActionRight };

    assert(gAuthorization != NULL);

    // Request the application-specific right.

    err = AuthorizationCopyRights(
        gAuthorization,         // authorization
        &kRights,               // rights
        NULL,                   // environment
        kFlags,                 // flags
        NULL                    // authorizedRights
    );

    return err;
}

int main(int argc, char** argv) {
    OSStatus status;
    AuthorizationFlags flags = kAuthorizationFlagDefaults;              // 1
    AuthorizationRef authorizationRef;                                  // 2

    if (argc < 2)
    {
        fprintf(stderr, "\nPleave provide the command to execute\n");
        fprintf(stderr, "\nUsage: %s <absolute_path_to_executable> <arguments_to_the_executable>\n\n", argv[0]);
        return -1;
    }
 
    status = AuthorizationCreate(NULL, kAuthorizationEmptyEnvironment,  // 3
                                   flags, &authorizationRef);

    if (status != errAuthorizationSuccess)
        return status;
    do
    {
        status = AcquireRight(authorizationRef, kAuthorizationRightExecute);
 
        if (status != errAuthorizationSuccess)
            break;
        {
            char cmdToolPath[1024]      = {0};
            char **cmdArguments         = NULL;
            FILE *cmdCommunicationsPipe = NULL;
            char cmdReadBuffer[128];
            int index, no_args = argc - 2;

            strncpy(cmdToolPath, argv[1], 1023);

            if (no_args > 0)
                cmdArguments = (char**)calloc(no_args, sizeof(char*));

            for (index=0; index < no_args; index++)
            {
                cmdArguments[index] = (char*)calloc(256, sizeof(char));
                strncpy(cmdArguments[index], argv[index+2], 255);
            }

            flags = kAuthorizationFlagDefaults;                          // 8
            status = AuthorizationExecuteWithPrivileges                  // 9
                    (authorizationRef, cmdToolPath, flags, cmdArguments,
                    &cmdCommunicationsPipe);

            if (status == errAuthorizationSuccess)
                for(;;)
                {
                    int bytesRead = read (fileno (cmdCommunicationsPipe),
                            cmdReadBuffer, sizeof (cmdReadBuffer));
                    if (bytesRead < 1) break;
                    write (fileno (stdout), cmdReadBuffer, bytesRead);
                }
        }

    } while (0);
 

    AuthorizationFree (authorizationRef, kAuthorizationFlagDefaults);    // 10
    if (status)
        printf("Status: %ld\n", status);
    return status;
}

