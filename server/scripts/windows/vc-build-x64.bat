setlocal enabledelayedexpansion
ECHO Setting variables

rem Set fixed parameters from the command line arguments
@SET PROJECT_FILE=%1
@SET CONFIGURATION=%2
@SET PLATFORM=%3
@SET OUTDIR=%4
@SET TOOLSET=%5

rem Shift the fixed parameters to process additional options
shift
shift
shift
shift
shift

rem Run msbuild with all parameters and additional options
msbuild %PROJECT_FILE% /p:Configuration=%CONFIGURATION% /p:Platform=%PLATFORM% /p:OutDir=%OUTDIR% /p:PlatformToolset=%TOOLSET% %~1  || EXIT /B 1
GOTO end

:upgrade
devenv /upgrade %PROJECT_FILE%

:end