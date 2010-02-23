#!/bin/bash

# Server Control Script for Postgres Plus HQ Agent
# Author: Ashesh Vashi, EnterpriseDB

JAVA_HOME=@@JAVAHOME@@
HQ_JAVA_HOME=@@JAVAHOME@@
export JAVA_HOME

CURRENTDATE=`date "+%Y%m%d%H%M%S"`

DEBUG=0
WAITONEXIT=1
SCRIPTNAME=${0}

# Check user has permission to write logs
touch "@@INSTALLDIR@@/agent-@@PPHQVERSION@@/log/agent_startup_${CURRENTDATE}.log"2>/dev/null
if [ $? -ne 0 ];
then
  echo "The current user does not have permission to write to '@@INSTALLDIR@@/agent-@@PPHQVERSION@@/log' directory"
  exit 1
fi


if [ ! -d "@@INSTALLDIR@@/agent-@@PPHQVERSION@@/logs" ];
then
  mkdir -p "@@INSTALLDIR@@/agent-@@PPHQVERSION@@/logs"
fi

function usage()
{
  log "USAGE: ${SCRIPTNAME} [--no-debug|--no-wait] [start|stop|restart|status|ping]"
}

function log()
{
  if [ ${DEBUG} -eq 1 ];
  then
    echo "$*"
  fi
  echo "$*" >> "@@INSTALLDIR@@/agent-@@PPHQVERSION@@/log/agent_startup_${CURRENTDATE}.log"
}

function stopAgent()
{
  log "Stopping Postgres Plus HQ Agent..."
  LOGMSG=`"@@INSTALLDIR@@/agent-@@PPHQVERSION@@/bin/pphq-agent.sh" stop`
  log "${LOGMSG}"
}

function startAgent()
{
  log "Starting Postgres Plus HQ Agent..."
  LOGMSG=`"@@INSTALLDIR@@/agent-@@PPHQVERSION@@/bin/pphq-agent.sh" start`
  log "${LOGMSG}"
}

function restartAgent()
{
  log "Restarting Postgres Plus HQ Agent..."
  LOGMSG=`"@@INSTALLDIR@@/agent-@@PPHQVERSION@@/bin/pphq-agent.sh" restart`
  log "${LOGMSG}"
}

function check()
{
  log "Check status of Postgres Plus HQ Agent..."
  LOGMSG=`"@@INSTALLDIR@@/agent-@@PPHQVERSION@@/bin/pphq-agent.sh" status`
  log "${LOGMSG}"
}

function pingAgent()
{
  log "Pinging the Postgres Plus HQ Agent..."
  LOGMSG=`"@@INSTALLDIR@@/agent-@@PPHQVERSION@@/bin/pphq-agent.sh" ping`
  log "${LOGMSG}"
}

function gotSignal()
{
  log "Got SIGKILL/SIGTERM/SIGHUP/SIGINT signal.."
  stopAgent
  exit 0 
}

trap gotSignal SIGHUP SIGINT SIGKILL SIGTERM

log "$0 got called with option ($*) at `date "+%Y-%m-%d %H:%M:%S"`"
DEBUG=1

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
    startAgent
    ;;
  stop)
    stopAgent
    ;;
  restart)
    restartAgent
    ;;
  status)
    check
    ;;
  ping)
    pingAgent
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

