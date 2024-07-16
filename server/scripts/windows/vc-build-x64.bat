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

rem Initialize ADDITIONAL_OPTIONS as an empty variable
@SET ADDITIONAL_OPTIONS=

rem Loop to collect all additional options into ADDITIONAL_OPTIONS
:loop
if "%1"=="" goto done
@SET ADDITIONAL_OPTIONS=!ADDITIONAL_OPTIONS! %~1
shift
goto loop

:done

rem Remove double quotes
@SET ADDITIONAL_OPTIONS=%ADDITIONAL_OPTIONS:"=% 

IF "%CONFIGURATION%" == "UPGRADE" GOTO upgrade
IF "%TOOLSET%" == "" ( SET TOOLSET=v143
)

rem Run msbuild with all parameters and additional options
msbuild %PROJECT_FILE% /p:Configuration=%CONFIGURATION% /p:Platform=%PLATFORM% /p:OutDir=%OUTDIR% /p:PlatformToolset=%TOOLSET% %ADDITIONAL_OPTIONS%  || EXIT /B 1
GOTO end

:upgrade
devenv /upgrade %PROJECT_FILE%

:end