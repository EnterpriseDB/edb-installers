#!/bin/bash

# Server Control Script for Postgres Plus HQ
# Author: Ashesh Vashi, EnterpriseDB

JAVA_HOME=@@JAVAHOME@@
export JAVA_HOME

CURRENTDATE=`date "+%Y%m%d%H%M%S"`

DEBUG=1
WAITONEXIT=1
SCRIPTNAME=${0}

# Check user has permission to write logs
touch "@@INSTALLDIR@@/server-@@PPHQVERSION@@/logs/server_startup_${CURRENTDATE}.log"2>/dev/null
if [ $? -ne 0 ];
then
  echo "The current user does not have permission to write to '@@INSTALLDIR@@/server-@@PPHQVERSION@@/logs' directory"
  exit 1
fi

function usage()
{
  log "USAGE: ${SCRIPTNAME} [--no-debug|--no-wait] [start|stop|restart]"
}

function log()
{
  if [ ${DEBUG} -eq 1 ];
  then
    echo "$*"
  fi
  echo "$*" >> "@@INSTALLDIR@@/server-@@PPHQVERSION@@/logs/server_startup_${CURRENTDATE}.log"
}

function stopServer()
{
  log "Stopping Postgres HQ server..."
  LOGMSG=`"@@INSTALLDIR@@/server-@@PPHQVERSION@@/bin/@@PPHQSERVERSCRIPT@@" stop`
  log "${LOGMSG}"
}

function startServer()
{
  log "Starting Postgres HQ Server..."
  LOGMSG=`"@@INSTALLDIR@@/server-@@PPHQVERSION@@/bin/@@PPHQSERVERSCRIPT@@" start`
  log "${LOGMSG}"
}

function gotSignal()
{
  log "Got SIGKILL/SIGTERM/SIGHUP/SIGINT signal.."
  stopServer
  exit 0 
}

trap gotSignal SIGHUP SIGINT SIGKILL SIGTERM
while [ $# -ne 0 ];
do
  RAR_NO_PROCD_CMD=0
  case $1 in
  --no-debug)
    DEBUG=0
    ;;
  --no-wait)
    WAITONEXIT=0
    ;;
  start)
    startServer
    ;;
  stop)
    stopServer
    ;;
  restart)
    startServer
    stopServer
    ;;
  *)
    log "Unknow option: $1"
    usage
    exit 127
  esac
  shift
done

if [ $WAITONEXIT -eq 1 ];
then
  echo "Press Any key to finish..."
  read dummy
fi

