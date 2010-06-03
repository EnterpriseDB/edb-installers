#!/bin/bash

# Postgres Plus installer script (extract-only mode) for linux and osx
# Ashesh Vashi, EnterpriseDB

##################
# Initialization #
##################

## Fetch the absolute directory of the script
RAR_OLD_PWD=$PWD
cd `dirname $0`
RAR_WD=$PWD
cd ${RAR_OLD_PWD}

## Number of processed command-line arguments
NO_PROCD_CMD=0

RAR_SHELL_BASH=0
RAR_SHELL=`ps e | grep $$ | grep -v grep | awk '{print $5}'`
if [ x"${RAR_SHELL}" = x"/bin/bash" -o x"${RAR_SHELL}" = x"bash" -o x"${RAR_SHELL}" = x"-bash" ];
then
  RAR_SHELL_BASH=1
fi
RAR_DEBUG=0
RAR_LOG_FILE=/tmp/rar_$$.log

## Check presence of tput utility on the system
RAR_TPUT_PRESENT=0
which tput > /dev/null 2>&1
if [ $? -eq 0 -a ${RAR_SHELL_BASH} -eq 1 ]
then
  RAR_TPUT_PRESENT=1
fi

## Non-interactive mode (DEFAULT: Disabled)
RAR_UNATTNDED_MODE=0

## Check presence of stty utility on the system
RAR_STTY_PRESENT=0
which stty > /dev/null 2>&1
if [ $? -eq 0 -a ${RAR_SHELL_BASH} -eq 1 ]
then
  RAR_STTY_PRESENT=1
fi
RAR_STTY_OUTPUT=

## Initialize the default value
PG_RAR_DEV_INSTALL_DIR=$PWD
PG_RAR_DEV_DATA_DIR=$PWD/data
PG_RAR_DEV_PORT=5432
PG_RAR_DEV_LOCALE=DEFAULT
PG_RAR_SUPERUSER=postgres
PG_RAR_SUPERPASSWORD=postgres
PG_RAR_DATABASE=postgres
RAR_DEV_DATA_DIR=
PG_RAR_SERVICENAME=

RAR_INSTALL_POSTGIS=Y
RAR_INSTALL_SLONY=Y
RAR_INSTALL_PGAGENT=Y
RAR_INSTALL_PSQLODBC=Y
RAR_INSTALL_PGBOUNCER=Y
RAR_INSTALL_NPGSQL=Y
RAR_INSTALL_PGMEMCACHE=Y
RAR_INSTALL_SBP=Y

#########################
# Functions Declaration #
#########################

# Fatal error handler
_die()
{
  echo ""
  if [ ${RAR_TPUT_PRESENT} -eq 1 -a $# -gt 0 ]
  then
    echo -e "\E[31;49m"FATAL ERROR: "\E[33;49m"$* && tput sgr0
  else
    echo FATAL ERROR: $*
  fi
  echo ""
  cd ${RAR_WD}
  echo FATAL ERROR: $* >> ${RAR_LOG_FILE}
  exit 1
}

_title()
{
  LRAR_SHOW_IN_ANYCASE=$1
  if [ x"${LRAR_SHOW_IN_ANYCASE}" = x"1" ]
  then
    shift
  elif [ ${RAR_UNATTNDED_MODE} -eq 1 ]
  then
    return
  fi
  if [ ${RAR_TPUT_PRESENT} -eq 1 -a $# -gt 0 ]
  then
    echo -e "\E[35;49m"$* && tput sgr0
  else
    echo $*
  fi
  echo TITLE: $* >> ${RAR_LOG_FILE}
}

_que()
{
  if [ ${RAR_TPUT_PRESENT} -eq 1 -a $# -eq 2 ]
  then
    echo -e "\E[34;49m"$1 "\E[32;49m"[ $2 ] "\E[34;49m": && tput sgr0
  elif [ ${RAR_TPUT_PRESENT} -eq 1 -a $# -gt 0 ]
  then
    echo -e "\E[34;49m"$* && tput sgr0
  else
    echo $*
  fi
  echo QUE: $* >> ${RAR_LOG_FILE}
}

_info()
{
  LRAR_SHOW_IN_ANYCASE=$1
  if [ x"${LRAR_SHOW_IN_ANYCASE}" = x"1" ]
  then
    shift
  elif [ ${RAR_UNATTNDED_MODE} -eq 1 ]
  then
    return
  fi
  if [ ${RAR_TPUT_PRESENT} -eq 1 -a $# -gt 0 ]
  then
    echo -e "\E[32;49m""$*" && tput sgr0
  else
    echo $*
  fi
  echo INFO: $* >> ${RAR_LOG_FILE}
}

_note()
{
  LRAR_SHOW_IN_ANYCASE=$1
  if [ x"${LRAR_SHOW_IN_ANYCASE}" = x"1" ]
  then
    shift
  elif [ ${RAR_UNATTNDED_MODE} -eq 1 ]
  then
    return
  fi
  if [ ${RAR_TPUT_PRESENT} -eq 1 -a $# -gt 0 ]
  then
    echo -e "\E[31;49m""NOTE: " "\E[32;49m"$* && tput sgr0
  else
    echo NOTE: $*
  fi
  echo NOTE: $* >> ${RAR_LOG_FILE}
}

_warn()
{
  if [ ${RAR_TPUT_PRESENT} -eq 1 -a $# -gt 0 ]
  then
    echo -e "\E[33;49m"WARNING: "\E[32;49m"$* && tput sgr0
  else
    echo "WARNING: $*"
  fi
  echo WARNING: $* >> ${RAR_LOG_FILE}
}

_log()
{
  if [ ${RAR_DEBUG} -eq 1 ]
  then
    echo $* | tee -a ${RAR_LOG_FILE}
  else
    echo $* >> ${RAR_LOG_FILE}
  fi
}

_logfile()
{
 if [ ${RAR_DEBUG} -eq 1 ]
 then
   cat ${*} | tee -a "${RAR_LOG_FILE}"
 else
   cat ${*} >> "${RAR_LOG_FILE}"
 fi
}

_save_options_file ()
{
  local LRAR_COMPS=

  if [ ${RAR_INSTALL_POSTGIS} = y -o ${RAR_INSTALL_POSTGIS} = Y ]
  then
    LRAR_COMPS="${LRAR_COMPS},postgis"
  fi
  if [ ${RAR_INSTALL_SLONY} = y -o ${RAR_INSTALL_SLONY} = Y ]
  then
    LRAR_COMPS="${LRAR_COMPS},slony"
  fi
  if [ ${RAR_INSTALL_PGAGENT} = y -o ${RAR_INSTALL_PGAGENT} = Y ]
  then
    LRAR_COMPS="${LRAR_COMPS},pgagent"
  fi
  if [ ${RAR_INSTALL_PSQLODBC} = y -o ${RAR_INSTALL_PSQLODBC} = Y ]
  then
    LRAR_COMPS="${LRAR_COMPS},psqlodbc"
  fi
  if [ ${RAR_INSTALL_PGBOUNCER} = y -o ${RAR_INSTALL_PGBOUNCER} = Y ]
  then
    LRAR_COMPS="${LRAR_COMPS},pgbouncer"
  fi
  if [ ${RAR_INSTALL_NPGSQL} = y -o ${RAR_INSTALL_NPGSQL} = Y ]
  then
    LRAR_COMPS="${LRAR_COMPS},npgsql"
  fi
  if [ ${RAR_INSTALL_PGMEMCACHE} = y -o ${RAR_INSTALL_PGMEMCACHE} = Y ]
  then
    LRAR_COMPS="${LRAR_COMPS},pgmemcache"
  fi
  LRAR_COMPS=`echo ${LRAR_COMPS} | sed -e 's/^,//g'`

  cat <<EOT > $PWD/.rar_options_$$
superuser=${PG_RAR_SUPERUSER}
superpassword=${PG_RAR_SUPERPASSWORD}
servicename=${PG_RAR_SERVICENAME}
datadir=${PG_RAR_DEV_DATA_DIR}
installdir=${PG_RAR_DEV_INSTALL_DIR}
locale=${PG_RAR_DEV_LOCALE}
port=${PG_RAR_DEV_PORT}
pgbouncer-port=${PG_RAR_PGBOUNCER_PORT}
components=${LRAR_COMPS}
EOT
  _info "Options saved in '$PWD/.rar_options_$$' file."
}

usage()
{
   LRAR_SCRIPTNAME=`basename $0`
   _title 1 "USAGE: ${RAR_WD}/${LRAR_SCRIPTNAME} <options>"
   _info  1 "options:"
   _info  1 "   -i  | --installdir       <Installation Directory> - Directory containing previously extracted installation files"
   _info  1 "                                                       (Default: Current Working Directory. i.e. $PWD)"
   _info  1 "   -su | --superuser        <super-user>             - Database Super User"
   _info  1 "   -sp | --superpassword    <super-password>         - Database Password for the Super User"
   _info  1 "                                                       (Default: postgres)"
   _info  1 "   -sn | --servicename      <service-name>           - Database Service name"
   _info  1 "                                                       (Default: pgsql-\${PG_MAJOR_VERSION}"
   _info  1 "   -d  | --datadir          <data directory>         - Data Directory"
   _info  1 "   -p  | --port             <port>                   - Port"
   _info  1 "                                                       (Default: 5432)"
   _info  1 "   -l  | --locale           <locale>                 - Locale"
   _info  1 "   -pb | --pgbouncer-port   <port>                   - Port for pgBouncer"
   _info  1 "                                                       (Default: 6453)"
   _info  1 "   -c  | --components       <component_list>         - comma seperated component list"
   _info  1 "                                                       (Default: postgis,slony,pgagent,psqlodbc,pgbouncer,npgsql,pgmemcache)"
   _info  1 "   -f  | --options-file     <options-file>           - Options File"
   _info  1 "   -u  | --unattended                                - Non-interactive mode"
   _info  1 "   -h  | --help             <help>                   - Shows this help."

   if [ x"$1" != x"" ]
   then
     exit $1
   fi
}

_reset_component_selection ()
{
  RAR_INSTALL_POSTGIS=N
  RAR_INSTALL_SLONY=N
  RAR_INSTALL_PGAGENT=N
  RAR_INSTALL_PSQLODBC=N
  RAR_INSTALL_PGBOUNCER=N
  RAR_INSTALL_NPGSQL=N
  RAR_INSTALL_PGMEMCACHE=N
}

_component_selection ()
{
  local LRAR_COMPONENTS=${1}
  local LRAR_NO_COMPONENTS=`echo ${LRAR_COMPONENTS} | awk -F, '{print NF}'`
  local LRAR_INDEX=1
  _reset_component_selection
  while ((LRAR_INDEX <= ${LRAR_NO_COMPONENTS}))
  do
    local LRAR_COMPONENT=`echo ${LRAR_COMPONENTS} | cut -d, -f${LRAR_INDEX}`
    (( LRAR_INDEX = LRAR_INDEX + 1));
    case ${LRAR_COMPONENT} in
    postgis)
      RAR_INSTALL_POSTGIS=Y
      ;;
    slony)
      RAR_INSTALL_SLONY=Y
      ;;
    pgagent)
      RAR_INSTALL_PGAGENT=Y
      ;;
    psqlodbc)
      RAR_INSTALL_PSQLODBC=Y
      ;;
    pgbouncer)
      RAR_INSTALL_PGBOUNCER=Y
      ;;
    npgsql)
      RAR_INSTALL_NPGSQL=Y
      ;;
    pgmemcache)
      RAR_INSTALL_PGMEMCACHE=Y
      ;;
    *)
      if [ x"${LRAR_COMPONENT}" != x"" ]; then
        _die "'${LRAR_COMPONENT}' is not a valid component."
      fi
      ;;
    esac
  done
}

readIniSection ()
{
  LRAR_INI_FILE=${1}
  LRAR_INI_VARIABLE=${2}
  LRAR_INI_INPUT_VAR=${3}
  LRAR_INI_SECTION=${4}

  # Global section
  if [ ${#} -eq 3 ]
  then
    eval $LRAR_INI_INPUT_VAR=`sed -e 's/[[:space:]]*\=[[:space:]]*/=/g' \
      -e 's/;.*$//' \
      -e 's/[[:space:]]*$//' \
      -e 's/^[[:space:]]*//' \
      -e "s/^\(.*\)=\([^\"']*\)$/\1=\"\2\"/" \
     < "${LRAR_INI_FILE}" \
      | sed -n -e "1,/^\s*\[/{/^[^;].*\=.*/p;}" | sed -n -e "/^${LRAR_INI_VARIABLE}=/p" | sed -e "s/^${LRAR_INI_VARIABLE}=//"`
  elif [ ${#} -eq 4 ]
  then
    eval $LRAR_INI_INPUT_VAR=`sed -e 's/[[:space:]]*\=[[:space:]]*/=/g' \
      -e 's/;.*$//' \
      -e 's/[[:space:]]*$//' \
      -e 's/^[[:space:]]*//' \
      -e "s/^\(.*\)=\([^\"']*\)$/\1=\"\2\"\n/" \
     < "${LRAR_INI_FILE}" \
      | sed -n -e "/^\[${LRAR_INI_SECTION}\]/,/^\s*\[/{/^[^;].*\=.*/p;}" | sed -n -e "/^${LRAR_INI_VARIABLE}=/p" | sed -e "s/^${LRAR_INI_VARIABLE}=//"`
  fi
}

loadOptionFile ()
{
  local LRAR_INDEX=0
  local LRAR_NO_OPTIONS=0
  ### options are saved as a pair option-name & option-handler
  for LRAR_OPT in installdir PG_RAR_DEV_INSTALL_DIR datadir PG_RAR_DEV_DATA_DIR superuser PG_RAR_SUPERUSER superpassword PG_RAR_SUPERPASSWORD \
                  servicename PG_RAR_SERVICENAME datadir PG_RAR_DEV_DATA_DIR port PG_RAR_DEV_PORT locale PG_RAR_DEV_LOCALE \
                  components LRAR_COMPONENTS pgbouncer-port PG_RAR_PGBOUNCER_PORT
  do
    LRAR_OPTIONS[${LRAR_INDEX}]=${LRAR_OPT}
    let "LRAR_INDEX += 1"
    LRAR_NO_OPTIONS=${LRAR_INDEX}
  done

  LRAR_INDEX=0
  while [ ${LRAR_INDEX} -lt ${LRAR_NO_OPTIONS} ]
  do
    LRAR_OPT=${LRAR_OPTIONS[LRAR_INDEX]}
    let "LRAR_INDEX += 1"
    LRAR_VAR_HANDLER=${LRAR_OPTIONS[LRAR_INDEX]}
    let "LRAR_INDEX += 1"
    readIniSection ${1} ${LRAR_OPT} ${LRAR_VAR_HANDLER}
  done

  if [ x"${LRAR_COMPONENTS}" != x"" ]
  then
    _component_selection ${LRAR_COMPONENTS}
  fi
}



_process_command_line()
{
  RAR_NO_PROCD_CMD=1
  case $1 in
  -su|--superuser)
     if [ $# -lt 2 ]
     then
       usage 2
     fi
     PG_RAR_SUPERUSER=$2
     RAR_NO_PROCD_CMD=2
     ;;
  -sp|--superpassword)
     if [ $# -lt 2 ]
     then
       usage 2
     fi
     PG_RAR_SUPERPASSWORD=$2
     RAR_NO_PROCD_CMD=2
     ;;
  -sn|--servicename)
     if [ $# -lt 2 ]
     then
       usage 2
     fi
     PG_RAR_SERVICENAME=${2}
     RAR_NO_PROCD_CMD=2
     ;;
  -d|--datadir)
     if [ $# -lt 2 ]
     then
       usage 2
     fi
     RAR_DEV_DATA_DIR=$2
     PG_RAR_DEV_DATA_DIR=$2
     RAR_NO_PROCD_CMD=2
     ;;
  -p|--port)
     if [ $# -lt 2 ]
     then
       usage 2
     fi
     PG_RAR_DEV_PORT=$2
     RAR_NO_PROCD_CMD=2
     ;;
  -pb|--pgbouncer-port)
     PG_RAR_PGBOUNCER_PORT=$2
     RAR_NO_PROCD_CMD=2
     ;;
  -l|--locale)
     if [ $# -lt 2 ]
     then
       usage 2
     fi
     PG_RAR_DEV_LOCALE=$2
     RAR_NO_PROCD_CMD=2
     ;;
  -h|--help)
     usage 0
     ;;
  -i|--installdir)
     if [ $# -lt 2 ]
     then
       usage 2
     fi
     PG_RAR_DEV_INSTALL_DIR=$2
     RAR_NO_PROCD_CMD=2
     ;;
  -f|--options-file)
     if [ ${#} -lt 2 ]
     then
       usage 2
     fi
     if [ -f ${2} ]
     then
       loadOptionFile ${2}
     else
       _die "Option file could not be found!"
     fi
     RAR_NO_PROCD_CMD=2
     ;;
  -c|--components)
     if [ ${#} -lt 2 ]
     then
       usage 2
     fi
     _component_selection ${2}
     RAR_NO_PROCD_CMD=2
     ;;
  -u|--unattended)
     RAR_UNATTNDED_MODE=1
     RAR_NO_PROCD_CMD=1
     ;;
  --debug)
     RAR_DEBUG=1
     ;;
  *)
     RAR_NO_PROCD_CMD=0
     _info "Unknown command-line argument:'$1' (Ignored)"
     usage 1
     ;;
  esac
}

# Search & replace in a file - _replace($find, $replace, $file)
_replace() {
    sed -e "s^$1^$2^g" "$3" > "/tmp/$$.tmp" 2>/dev/null || return 0
    cat "/tmp/$$.tmp" > "${3}"
    rm -f "/tmp/$$.tmp"
    return 1
}

backupFile ()
{
  LRAR_FILE=$1
  LRAR_BACKUP_FILE=

  if [ ! -f "${LRAR_FILE}" ]
  then
    return 1
  fi

  if [ ! -f "${LRAR_FILE}.bak" ]
  then
    cp ${LRAR_FILE} ${LRAR_FILE}.bak
    return 1
  fi

  LRAR_INDEX=0
  while [ ${LRAR_INDEX} != 65535 ]; do
    if [ ! -f "${LRAR_FILE}.bak-${LRAR_INDEX}" ]
    then
      LRAR_BACKUP_FILE="${LRAR_FILE}.bak-${LRAR_INDEX}"
      break
    fi
    LRAR_INDEX=`expr ${LRAR_INDEX} + 1`
  done

  cp ${LRAR_FILE} ${LRAR_BACKUP_FILE}

  return 1
}

readValue()
{
  LRAR_QUE=${1}
  LRAR_VAR=${2}
  LRAR_DEF_VAL=${3}
  LRAR_VALIDATOR=${4}
  LRAR_REP_VAR=${5}
  LRAR_DONE=0

  if [ ${RAR_UNATTNDED_MODE} -eq 1 ]
  then
    eval ${LRAR_VAR}=${LRAR_DEF_VAL}
    if [ x"${LRAR_VALIDATOR}" != x"" -a x"${LRAR_VALIDATOR}" != x" " ]
    then
       ${LRAR_VALIDATOR} "${!LRAR_VAR}" 1
       if [  $? -ne 1 ]
       then
          _die "\"${!LRAR_VAR}\" is not valid value for the variable \"${LRAR_REP_VAR}\""
       fi
    fi
    return 1
  fi

  while [ ${LRAR_DONE} -ne 1 ]; do
    _que "${1}" "${LRAR_DEF_VAL}"
    LRAR_DONE=1
    read ${LRAR_VAR}
    # if no input provided, set the variable value to the default value (if any)
    if [ x"${!LRAR_VAR}" = x"" -a x"${LRAR_DEF_VAL}" != x"" ]
    then
      eval ${LRAR_VAR}=${LRAR_DEF_VAL}
    fi
    if [ x"${LRAR_VALIDATOR}" != x"" -a x"${LRAR_VALIDATOR}" != x" " ]
    then
       ${LRAR_VALIDATOR} "${!LRAR_VAR}" 1
       LRAR_DONE=$?
    fi
  done
  return ${LRAR_DONE}
}

readPassword()
{
  if [ ${RAR_STTY_PRESENT} -eq 1 ]
  then
    RAR_STTY_OUTPUT=`stty -g`
    stty -echo
    readValue "${1}" "${2}" "${3}" "${4}" "${5}"
    stty ${RAR_STTY_OUTPUT}
    RAR_STTY_OUTPUT=
  else
    readValue "${1}" "${2}" "${3}" "${4}" "${5}"
  fi
}

############################
# Check supported platform #
############################
RAR_PLATFORM=`uname -s`
case $RAR_PLATFORM in
Darwin)
  _title 1 "Running the script on OSX..."
  ;;
Linux)
  _title 1 "Running the script on linux..."
  ;;
*)
  _note 1 "Script is not yet supported for this platform (${RAR_PLATFORM})"
  exit 1
  ;;
esac

#######################
# TESTED ONLY ON BASH #
#######################
if [ ${RAR_SHELL_BASH} -ne 1 ]
then
  _die "Please run this script with /bin/bash. Not Tested on other SHELL."
fi

stopinstallation ()
{
  echo
  # Reset stty
  if [ ${RAR_STTY_PRESENT} -eq 1 -a x"${RAR_STTY_OUTPUT}" != x"" ];
  then
     stty ${RAR_STTY_OUTPUT}
  fi
  _note "Installation was interrupted."

  # TODO: Save the option in temp file and notify
  _save_options_file
  exit 1
}
trap 'stopinstallation' INT HUP TERM

##################################
# Process command line arguments #
##################################
while [ $# -ne 0 ];
do
   RAR_NO_PROCD_CMD=0
   _process_command_line $*
   INDEX=0
   while [ "$INDEX" != "${RAR_NO_PROCD_CMD}" ]; do
     shift
     INDEX=`expr $INDEX + 1`
   done
done

########################
# Running As root user #
########################
if [ `whoami` != "root" ];
then
   _die "Run this script as root user only"
fi


###################################
# Validation Function Declaration #
###################################
validatedbserverDarwin () {
  echo "Need to do nothing here" > /dev/null
  return 1
}

validatedbserverLinux ()
{
  LRAR_INSTALLDIR=$1
  LRAR_RET_VAL=1
  if [ ! -f "${LRAR_INSTALLDIR}/installer/server/runpgcontroldata.sh" ]
  then
     LRAR_DBG_INFO="No psql found in the given installation directory (${LRAR_INSTALLDIR}/bin)"
     LRAR_RET_VAL=0
  fi
  return ${LRAR_RET_VAL}
}

validateDevInstallDir () {
  LRAR_INSTALLDIR=$1
  LRAR_SHOW_INFO=$2
  LRAR_RET_VAL=1
  if [ ! -f "${LRAR_INSTALLDIR}/bin/psql" ]
  then
     LRAR_DBG_INFO="No psql found in the given installation directory (${LRAR_INSTALLDIR}/bin)"
     LRAR_RET_VAL=0
  elif [ ! -f "${LRAR_INSTALLDIR}/bin/postgres" ]
  then
     LRAR_DBG_INFO="No 'postgres' found in the given installation directory (${LRAR_INSTALLDIR}/bin)"
     LRAR_RET_VAL=0
  elif [ ! -f "${LRAR_INSTALLDIR}/bin/postmaster" ]
  then
     LRAR_DBG_INFO="No 'postmaster' found in the given installation directory (${LRAR_INSTALLDIR}/bin)"
     LRAR_RET_VAL=0
  elif [ ! -f "${LRAR_INSTALLDIR}/bin/pg_controldata" ]
  then
     LRAR_DBG_INFO="No 'pg_controldata' found in the given installation directory (${LRAR_INSTALLDIR}/bin)"
     LRAR_RET_VAL=0
  elif [ ! -f "${LRAR_INSTALLDIR}/installer/server/createshortcuts.sh" ]
  then
     LRAR_DBG_INFO="Not valid PostgreSQL/PostgresPlus installer path. Couldn't find '${LRAR_INSTALLDIR}/installer/server/createshortcuts.sh'."
     LRAR_RET_VAL=0
  elif [ ! -f "${LRAR_INSTALLDIR}/installer/server/createuser.sh" ]
  then
     LRAR_DBG_INFO="Not valid PostgreSQL/PostgresPlus installer path. Couldn't find '${LRAR_INSTALLDIR}/installer/server/createuser.sh'."
     LRAR_RET_VAL=0
  elif [ ! -f "${LRAR_INSTALLDIR}/installer/server/getlocales.sh" ]
  then
     LRAR_DBG_INFO="Not valid PostgreSQL/PostgresPlus installer path. Couldn't find '${LRAR_INSTALLDIR}/installer/server/getlocales.sh'."
     LRAR_RET_VAL=0
  elif [ ! -f "${LRAR_INSTALLDIR}/installer/server/initcluster.sh" ]
  then
     LRAR_DBG_INFO="Not valid PostgreSQL/PostgresPlus installer path. Couldn't find '${LRAR_INSTALLDIR}/installer/server/initcluster.sh'."
     LRAR_RET_VAL=0
  elif [ ! -f "${LRAR_INSTALLDIR}/installer/server/loadmodules.sh" ]
  then
     LRAR_DBG_INFO="Not valid PostgreSQL/PostgresPlus installer path. Couldn't find '${LRAR_INSTALLDIR}/installer/server/loadmodules.sh'."
     LRAR_RET_VAL=0
  elif [ ! -f "${LRAR_INSTALLDIR}/installer/server/startupcfg.sh" ]
  then
     LRAR_DBG_INFO="Not valid PostgreSQL/PostgresPlus installer path. Couldn't find '${LRAR_INSTALLDIR}/installer/server/startupcfg.sh'."
     LRAR_RET_VAL=0
  else
     validatedbserver${RAR_PLATFORM} ${LRAR_INSTALLDIR} ${LRAR_SHOW_INFO}
     if [ $? -eq 0 ]
     then
       return 0
     fi
     RAR_OSUSERLIST=
     if [ ${RAR_PLATFORM} = Linux ]
     then
       RAR_OSUSERLIST=`cat /etc/passwd | grep -v "#" | cut -d: -f 1`
     elif [ ${RAR_PLATFORM} = Darwin ]
     then
       RAR_OSUSERLIST=`dscl . -list /users|cut -f2 -d' '`
     fi

     RAR_USER_OF_FILE=${LRAR_INSTALLDIR}/bin/postgres
     if [ -f "${PG_RAR_DEV_DATA_DIR}/postgresql.conf" ]
     then
       RAR_USER_OF_FILE=${PG_RAR_DEV_DATA_DIR}/postgresql.conf
     fi

     for LRAR_USR in $RAR_OSUSERLIST
     do
       PG_RAR_SERVICEACCOUNT=`find "${RAR_USER_OF_FILE}" -user ${LRAR_USR} 2>/dev/null`
       if [ x"${PG_RAR_SERVICEACCOUNT}" != x"" ]
       then
         PG_RAR_SERVICEACCOUNT=${LRAR_USR}
         break
       fi
     done
  fi

  if [ x"${LRAR_SHOW_INFO}" != x"1" ]
  then
    LRAR_SHOW_INFO=0
  fi
  if [ ${LRAR_SHOW_INFO} -eq 1 -a ${LRAR_RET_VAL} -eq 0 ]
  then
    _warn ${LRAR_DBG_INFO}
  fi
  if [ ${LRAR_RET_VAL} -eq 1 ]
  then
     PG_RAR_LIB_PATH=`${LRAR_INSTALLDIR}/bin/pg_config --libdir`
     PG_RAR_PKG_LIB_PATH=`${LRAR_INSTALLDIR}/bin/pg_config --pkglibdir`
     PG_RAR_SHARE_PATH=`${LRAR_INSTALLDIR}/bin/pg_config --sharedir`
     PG_RAR_VERSION=`${PG_RAR_DEV_INSTALL_DIR}/bin/pg_config --version | cut -d' ' -f 2`
     PG_RAR_MAJOR_VERSION=`echo ${PG_RAR_VERSION} | cut -d. -f 1,2`
     PG_RAR_MINOR_VERSION=`echo ${PG_RAR_VERSION} | cut -d. -f 3,4`
     if [ x"${PG_RAR_SERVICENAME}" = x"" ]
     then
       PG_RAR_SERVICENAME=pgsql-${PG_RAR_MAJOR_VERSION}
     fi
     PG_RAR_BRANDING="Postgres Plus ${PG_RAR_MAJOR_VERSION}"
  fi
  return ${LRAR_RET_VAL}
}

validateDevDataDir ()
{
  LRAR_RET_VAL=1
  if [ -d "$1" ]
  then
    HAS_FILES=`find "$1" | wc -l`
    if [ $HAS_FILES -gt 1 -a ! -f "$1/postgresql.conf" ]
    then
      LRAR_RET_VAL=0
      _warn "Not a valid PostgreSQL data directory ($1). Data directory should be empty or valid datadirectory"
    fi
  elif [ -f "$1" ]
  then
    _warn \"$1\" is not a directory.
    LRAR_RET_VAL=0
  fi
  return ${LRAR_RET_VAL}
}

validateDevPort ()
{
  LRAR_PORT=$1
  echo ${LRAR_PORT} | egrep '^[0-9]+$' >/dev/null 2>&1
  if [ $? -eq 1 ]
  then
    _warn \"${LRAR_PORT}\" is not a valid port number.
    return 0
  fi
  if [ ${LRAR_PORT} -lt 1000 -o ${LRAR_PORT} -gt 65535 ]
  then
     _warn Please enter port within 1000 to 65535
     return 0
  fi
  return 1
}

validateDevLocale ()
{
  if [ x"$1" = x"DEFAULT" ]
  then
    return 1
  fi
  locale -a | grep "^$1\$" > /dev/null 2>&1
  if [ $? -eq 0 ]
  then
    return 1
  fi
  _warn "Not a valid locale ($1)"
  return 0
}

validatePostGIS ()
{
  LRAR_INSTALLDIR="${1}"
  LRAR_RET_VAL=1
  if [ ! -d "${LRAR_INSTALLDIR}/PostGIS" ]
  then
    LRAR_RET_VAL=0
  elif [ ! -f "${LRAR_INSTALLDIR}/PostGIS/installer/PostGIS/createpostgisdb.sh" ]
  then
    LRAR_RET_VAL=0
  elif [ ! -f "${LRAR_INSTALLDIR}/PostGIS/installer/PostGIS/createshortcuts.sh" ];then
    LRAR_RET_VAL=0
  elif [ ! -f "${LRAR_INSTALLDIR}/PostGIS/installer/PostGIS/createtemplatedb.sh" ]
  then
    LRAR_RET_VAL=0
  elif [ ! -f "${LRAR_INSTALLDIR}/bin/pgsql2shp" ]
  then
    LRAR_RET_VAL=0
  elif [ ! -f "${LRAR_INSTALLDIR}/bin/shp2pgsql" ]
  then
    LRAR_RET_VAL=0
  elif [ ! -f "${PG_RAR_SHARE_PATH}/contrib/postgis.sql" ]
  then
    LRAR_RET_VAL=0
  elif [ ! -f "${PG_RAR_SHARE_PATH}/contrib/spatial_ref_sys.sql" ]
  then
    LRAR_RET_VAL=0
  elif [ ! -f "${PG_RAR_SHARE_PATH}/contrib/postgis_upgrade.sql" ]
  then
    LRAR_RET_VAL=0
  else
    LRAR_FILES=`find "${PG_RAR_LIB_PATH}"/postgis* 2>/dev/null| wc -l`
    if [ ${LRAR_FILES} -eq 0 ]
    then
      LRAR_RET_VAL=0
    fi
  fi
  return ${LRAR_RET_VAL}
}

configurePostGIS()
{
  LRAR_PGIS_INSTALLDIR=${PG_RAR_DEV_INSTALL_DIR}

  readValue "Found PostGIS. Do you want to configure PostGIS? (Y/n)" RAR_INSTALL_POSTGIS "${RAR_INSTALL_POSTGIS}" " "
  if [ x"${RAR_INSTALL_POSTGIS}" != x"Y" -a x"${RAR_INSTALL_POSTGIS}" != x"y" ]
  then
    return
  fi

  ## TODO: Create shortcuts
  PGHOST=localhost
  PGUSER=${PG_RAR_SUPERUSER}
  PGPASSWORD=${PG_RAR_SUPERPASSWORD}
  PGPORT=${PG_RAR_DEV_PORT}
  PGDATABASE=postgres

  export PGHOST PGUSER PGPASSWORD PGPORT PGDATABASE

  HAS_TEMPLATE_DATABASE=`"${PG_RAR_DEV_INSTALL_DIR}/bin/psql" -t -c "SELECT d.datname FROM pg_catalog.pg_database d WHERE d.datname='template_postgis'" 2>/dev/null`

  if [ x"$HAS_TEMPLATE_DATABASE" = x"" -a $? -eq 0 ];
  then
    _title 1 "Configuring PostGIS..."
    ## Create back of the configuration files
    backupFile "${PG_RAR_SHARE_PATH}/contrib/postgis.sql"
    _replace \$libdir ${PG_RAR_LIB_PATH} "${PG_RAR_SHARE_PATH}/contrib/postgis.sql"

    backupFile "${PG_RAR_SHARE_PATH}/contrib/postgis.sql"
    _replace \$libdir ${PG_RAR_LIB_PATH} "${PG_RAR_SHARE_PATH}/contrib/postgis_upgrade.sql"

    ### CREATE TEMPLATE DATABASE
    _title 1 "\tCreating template_postgis database..."
    if [ ${RAR_DEBUG} -eq 1 ]
    then
      echo "Executing: "${PG_RAR_DEV_INSTALL_DIR}/bin/psql" -t -c "CREATE DATABASE template_postgis"" | tee -a ${RAR_LOG_FILE}
      "${PG_RAR_DEV_INSTALL_DIR}/bin/psql" -t -c "CREATE DATABASE template_postgis" 2>&1 | tee -a ${RAR_LOG_FILE}
    else
      echo "Executing: "${PG_RAR_DEV_INSTALL_DIR}/bin/psql" -t -c "CREATE DATABASE template_postgis"" >> ${RAR_LOG_FILE}
      "${PG_RAR_DEV_INSTALL_DIR}/bin/psql" -t -c "CREATE DATABASE template_postgis" >> ${RAR_LOG_FILE} 2>&1
    fi
    if [ $? -eq 0 ];
    then
      _note 1 "\tSuccessfully created 'template_postgis' database..."
    fi

    if [ ${RAR_DEBUG} -eq 1 ]
    then
      echo "Executing: "${PG_RAR_DEV_INSTALL_DIR}/bin/psql" -t -c "UPDATE pg_database SET datistemplate='t' WHERE datname='template_postgis'"" | tee -a ${RAR_LOG_FILE}
      "${PG_RAR_DEV_INSTALL_DIR}/bin/psql" -t -c "UPDATE pg_database SET datistemplate='t' WHERE datname='template_postgis'" 2>&1 | tee -a ${RAR_LOG_FILE}
    else
      echo "Executing: "${PG_RAR_DEV_INSTALL_DIR}/bin/psql" -t -c "UPDATE pg_database SET datistemplate='t' WHERE datname='template_postgis'"" >> ${RAR_LOG_FILE}
      "${PG_RAR_DEV_INSTALL_DIR}/bin/psql" -t -c "UPDATE pg_database SET datistemplate='t' WHERE datname='template_postgis'" >> ${RAR_LOG_FILE} 2>&1
    fi

    ## CREATE plpgsql LANGUAGE
    PGDATABASE=template_postgis
    export PGDATABASE
    _title 1 "Create language 'plpgsql'"
    if [ ${RAR_DEBUG} -eq 1 ]
    then
      echo ""${PG_RAR_DEV_INSTALL_DIR}/bin/psql" -t -c "CREATE LANGUAGE 'plpgsql'"" | tee -a ${RAR_LOG_FILE}
      "${PG_RAR_DEV_INSTALL_DIR}/bin/psql" -t -c "CREATE LANGUAGE 'plpgsql'" 2>&1 | tee -a ${RAR_LOG_FILE}
    else
      echo ""${PG_RAR_DEV_INSTALL_DIR}/bin/psql" -t -c "CREATE LANGUAGE 'plpgsql'"" >> ${RAR_LOG_FILE}
      "${PG_RAR_DEV_INSTALL_DIR}/bin/psql" -t -c "CREATE LANGUAGE 'plpgsql'" >> ${RAR_LOG_FILE} 2>&1
    fi
    if [ $? -eq 0 ];
    then
      _note 1 "\tSuccessfully created 'plpgsql' language..."
    fi

    ### INSTALL postgis.sql script
    _title 1 "\tRunning postgis.sql in template_postgis database..."
    if [ ${RAR_DEBUG} -eq 1 ]
    then
      echo ""${PG_RAR_DEV_INSTALL_DIR}/bin/psql" -t -f "${PG_RAR_SHARE_PATH}/contrib/postgis.sql"" | tee -a ${RAR_LOG_FILE}
      "${PG_RAR_DEV_INSTALL_DIR}/bin/psql" -t -f "${PG_RAR_SHARE_PATH}/contrib/postgis.sql" 2>&1 | tee -a ${RAR_LOG_FILE}
    else
      echo ""${PG_RAR_DEV_INSTALL_DIR}/bin/psql" -t -f "${PG_RAR_SHARE_PATH}/contrib/postgis.sql"" >> ${RAR_LOG_FILE}
      "${PG_RAR_DEV_INSTALL_DIR}/bin/psql" -t -f "${PG_RAR_SHARE_PATH}/contrib/postgis.sql" 1>> ${RAR_LOG_FILE} 2>&1
    fi

    _title 1 "\tRunning spatial_ref_sys.sql in template_postgis database..."
    if [ ${RAR_DEBUG} -eq 1 ]
    then
      echo ""${PG_RAR_DEV_INSTALL_DIR}/bin/psql" -t -f "${PG_RAR_SHARE_PATH}/contrib/spatial_ref_sys.sql"" | tee -a ${RAR_LOG_FILE}
      "${PG_RAR_DEV_INSTALL_DIR}/bin/psql" -t -f "${PG_RAR_SHARE_PATH}/contrib/spatial_ref_sys.sql" 2>&1 | tee -a ${RAR_LOG_FILE}
    else
      echo ""${PG_RAR_DEV_INSTALL_DIR}/bin/psql" -t -f "${PG_RAR_SHARE_PATH}/contrib/spatial_ref_sys.sql"" >> ${RAR_LOG_FILE}
      "${PG_RAR_DEV_INSTALL_DIR}/bin/psql" -t -f "${PG_RAR_SHARE_PATH}/contrib/spatial_ref_sys.sql" >> ${RAR_LOG_FILE} 2>&1
    fi

    _title 1 "\tRunning postgis_comments.sql in template_postgis database..."
    if [ ${RAR_DEBUG} -eq 1 ]
    then
      echo ""${PG_RAR_DEV_INSTALL_DIR}/bin/psql" -t -f "${PG_RAR_SHARE_PATH}/contrib/postgis_comments.sql"" | tee -a ${RAR_LOG_FILE}
      "${PG_RAR_DEV_INSTALL_DIR}/bin/psql" -t -f "${PG_RAR_SHARE_PATH}/contrib/postgis_comments.sql" 2>&1 | tee -a ${RAR_LOG_FILE}
    else
      echo ""${PG_RAR_DEV_INSTALL_DIR}/bin/psql" -t -f "${PG_RAR_SHARE_PATH}/contrib/postgis_comments.sql"" >> ${RAR_LOG_FILE}
      "${PG_RAR_DEV_INSTALL_DIR}/bin/psql" -t -f "${PG_RAR_SHARE_PATH}/contrib/postgis_comments.sql" >> ${RAR_LOG_FILE} 2>&1
    fi

  fi

  PGHOST=localhost
  PGUSER=${PG_RAR_SUPERUSER}
  PGPASSWORD=${PG_RAR_SUPERPASSWORD}
  PGPORT=${PG_RAR_DEV_PORT}
  PGDATABASE=postgres
  export PGHOST PGUSER PGPASSWORD PGPORT PGDATABASE

}

validateSlony ()
{
  LRAR_INSTALLDIR=$1
  LRAR_RET_VAL=1
  if [ ! -d "${LRAR_INSTALLDIR}/Slony" ]
  then
    LRAR_RET_VAL=0
  elif [ ! -f "${LRAR_INSTALLDIR}/Slony/installer/Slony/configureslony.sh" ]
  then
    LRAR_RET_VAL=0
  elif [ ! -f "${LRAR_INSTALLDIR}/Slony/installer/Slony/createshortcuts.sh" ];then
    LRAR_RET_VAL=0
  elif [ ! -f "${LRAR_INSTALLDIR}/bin/slon" ]
  then
    LRAR_RET_VAL=0
  elif [ ! -f "${LRAR_INSTALLDIR}/bin/slonik" ]
  then
    LRAR_RET_VAL=0
  elif [ ! -f "${LRAR_INSTALLDIR}/bin/slony_logshipper" ]
  then
    LRAR_RET_VAL=0
  elif [ ! -f "${LRAR_INSTALLDIR}/share/Slony/slony1_base.sql" ]
  then
    LRAR_RET_VAL=0
  elif [ ! -f "${LRAR_INSTALLDIR}/share/Slony/slony1_funcs.sql" ]
  then
    LRAR_RET_VAL=0
  elif [ ! -f "${LRAR_INSTALLDIR}/share/Slony/slony1_base.v83.sql" ]
  then
    LRAR_RET_VAL=0
  elif [ ! -f "${LRAR_INSTALLDIR}/share/Slony/slony1_funcs.v83.sql" ]
  then
    LRAR_RET_VAL=0
  elif [ ! -f "${LRAR_INSTALLDIR}/lib/slony1_funcs.so" ]
  then
    LRAR_RET_VAL=0
  fi
  return ${LRAR_RET_VAL}
}

configureSlony ()
{
  _title 1 "Configuring Slony ..."
  if [ ${RAR_DEBUG} -eq 1 ]
  then
    echo "${PG_RAR_DEV_INSTALL_DIR}/Slony/installer/Slony/configureslony.sh "${PG_RAR_DEV_INSTALL_DIR}"" | tee -a ${RAR_LOG_FILE}
    ${PG_RAR_DEV_INSTALL_DIR}/Slony/installer/Slony/configureslony.sh "${PG_RAR_DEV_INSTALL_DIR}" 2>&1 | tee -a ${RAR_LOG_FILE}
  else
    echo "${PG_RAR_DEV_INSTALL_DIR}/Slony/installer/Slony/configureslony.sh "${PG_RAR_DEV_INSTALL_DIR}"" >> ${RAR_LOG_FILE}
    ${PG_RAR_DEV_INSTALL_DIR}/Slony/installer/Slony/configureslony.sh "${PG_RAR_DEV_INSTALL_DIR}" >> ${RAR_LOG_FILE} 2>&1
  fi

  ### TODO: Create shortcuts
}

validatepgAgent ()
{
  LRAR_INSTALLDIR=$1
  LRAR_RET_VAL=1
  if [ ! -d "${LRAR_INSTALLDIR}" ]
  then
    LRAR_RET_VAL=0
  elif [ ! -f "${LRAR_INSTALLDIR}/installer/pgAgent/startupcfg.sh" ]
  then
    LRAR_RET_VAL=0
  elif [ ! -f "${LRAR_INSTALLDIR}/bin/pgagent" ]
  then
    LRAR_RET_VAL=0
  elif [ ! -f "${LRAR_INSTALLDIR}/share/pgagent.sql" ]
  then
    LRAR_RET_VAL=0
  fi
  return ${LRAR_RET_VAL}
}

configurepgAgent()
{
  LRAR_INSTALLDIR=${1}

  PGHOST=localhost
  PGUSER=${PG_RAR_SUPERUSER}
  PGPASSWORD=${PG_RAR_SUPERPASSWORD}
  PGPORT=${PG_RAR_DEV_PORT}
  PGDATABASE=${PG_RAR_DATABASE}
  export PGHOST PGUSER PGPASSWORD PGPORT PGDATABASE

  HAS_SCHEMA=`"${PG_RAR_DEV_INSTALL_DIR}/bin/psql" -t -A -c "SELECT has_schema_privilege('pgagent', 'USAGE')" 2>/dev/null`

  if [ x"$HAS_SCHEMA" = x"" ]
  then
    _title 1 "\tCreating plpgsql.."
    if [ ${RAR_DEBUG} -eq 1 ]
    then
      echo ""${PG_RAR_DEV_INSTALL_DIR}/bin/psql" -t -c "CREATE LANGUAGE 'plpgsql'"" | tee -a ${RAR_LOG_FILE}
      "${PG_RAR_DEV_INSTALL_DIR}/bin/psql" -t -c "CREATE LANGUAGE 'plpgsql'" 2>&1 | tee -a ${RAR_LOG_FILE}
    else
      echo ""${PG_RAR_DEV_INSTALL_DIR}/bin/psql" -t -c "CREATE LANGUAGE 'plpgsql'"" >> ${RAR_LOG_FILE}
      "${PG_RAR_DEV_INSTALL_DIR}/bin/psql" -t -c "CREATE LANGUAGE 'plpgsql'" >> ${RAR_LOG_FILE} 2>&1
    fi
    _title 1 "\tRunning pgagent script.."
    if [ ${RAR_DEBUG} -eq 1 ]
    then
      echo ""${PG_RAR_DEV_INSTALL_DIR}/bin/psql" -t -f "${LRAR_INSTALLDIR}/share/pgagent.sql"" | tee -a ${RAR_LOG_FILE}
      "${PG_RAR_DEV_INSTALL_DIR}/bin/psql" -t -f "${LRAR_INSTALLDIR}/share/pgagent.sql" 2>&1 | tee -a ${RAR_LOG_FILE}
    else
      echo ""${PG_RAR_DEV_INSTALL_DIR}/bin/psql" -t -f "${LRAR_INSTALLDIR}/share/pgagent.sql"" >> ${RAR_LOG_FILE}
      "${PG_RAR_DEV_INSTALL_DIR}/bin/psql" -t -f "${LRAR_INSTALLDIR}/share/pgagent.sql" >> ${RAR_LOG_FILE} 2>&1
    fi
  else
    _title 1 "\tRunning pgagent upgrade script..."
    if [ ${RAR_DEBUG} -eq 1 ]
    then
      echo ""${PG_RAR_DEV_INSTALL_DIR}/bin/psql" -t -f "${LRAR_INSTALLDIR}/share/pgagent_upgrade.sql"" | tee -a ${RAR_LOG_FILE}
      "${PG_RAR_DEV_INSTALL_DIR}/bin/psql" -t -f "${LRAR_INSTALLDIR}/share/pgagent_upgrade.sql" 2>&1 | tee -a ${RAR_LOG_FILE}
    else
      echo ""${PG_RAR_DEV_INSTALL_DIR}/bin/psql" -t -f "${LRAR_INSTALLDIR}/share/pgagent_upgrade.sql"" >> ${RAR_LOG_FILE}
      "${PG_RAR_DEV_INSTALL_DIR}/bin/psql" -t -f "${LRAR_INSTALLDIR}/share/pgagent_upgrade.sql" >> ${RAR_LOG_FILE} 2>&1
    fi
  fi

  if [ -f /etc/init.d/pgagent -a ${RAR_PLATFORM} = Linux ]
  then
    _note 1 "Service (/etc/init.d/pgagent) already exists..."
    return 1
  elif [ -f /Library/LaunchDaemons/com.edb.launchd.pgagent.plist -a ${RAR_PLATFORM} = Darwin ]
  then
    _note 1 "Service (/Library/LaunchDaemons/com.edb.launchd.pgagent.plist) already exists..."
    return 1
  fi

  _title "Creating pgagent service..."
  echo "localhost:${PG_RAR_DEV_PORT}:*:${PG_RAR_SUPERUSER}:${PG_RAR_SUPERPASSWORD}" > "${PG_RAR_DEV_INSTALL_DIR}/pgAgent/installer/pgAgent/pgpass"
  if [ ${RAR_DEBUG} -eq 1 ]
    then
      echo ""${PG_RAR_DEV_INSTALL_DIR}/pgAgent/installer/pgAgent/startupcfg.sh" localhost ${PG_RAR_DEV_PORT} ${PG_RAR_SUPERUSER} ${PG_RAR_SERVICEACCOUNT} "${PG_RAR_DEV_INSTALL_DIR}/pgAgent" ${PGDATABASE}" | tee -a ${RAR_LOG_FILE}
      "${PG_RAR_DEV_INSTALL_DIR}/pgAgent/installer/pgAgent/startupcfg.sh" localhost ${PG_RAR_DEV_PORT} ${PG_RAR_SUPERUSER} ${PG_RAR_SERVICEACCOUNT} "${PG_RAR_DEV_INSTALL_DIR}/pgAgent" ${PGDATABASE} 2>&1 | tee -a ${RAR_LOG_FILE}
    else
      echo ""${PG_RAR_DEV_INSTALL_DIR}/pgAgent/installer/pgAgent/startupcfg.sh" localhost ${PG_RAR_DEV_PORT} ${PG_RAR_SUPERUSER} ${PG_RAR_SERVICEACCOUNT} "${PG_RAR_DEV_INSTALL_DIR}/pgAgent" ${PGDATABASE}" >> ${RAR_LOG_FILE}
      "${PG_RAR_DEV_INSTALL_DIR}/pgAgent/installer/pgAgent/startupcfg.sh" localhost ${PG_RAR_DEV_PORT} ${PG_RAR_SUPERUSER} ${PG_RAR_SERVICEACCOUNT} "${PG_RAR_DEV_INSTALL_DIR}/pgAgent" ${PGDATABASE} >> ${RAR_LOG_FILE} 2>&1
    fi
  # Remove the temporary pgpass file
  rm -f "${PG_RAR_DEV_INSTALL_DIR}/pgAgent/installer/pgAgent/pgpass"

  _title "Starting pgagent service..."
  if [ ${RAR_PLATFORM} = Linux ]; then
    _replace SYSTEM_USER ${PG_RAR_SERVICEACCOUNT} /etc/init.d/pgagent
    /etc/init.d/pgagent start
  elif [ ${RAR_PLATFORM} = Darwin ]; then
    launchctl load /Library/LaunchDaemons/com.edb.launchd.pgagent.plist
  fi

  ### TODO: Create Shortcuts
}

validatepsqlodbc ()
{
  LRAR_INSTALLDIR=$1
  LRAR_RET_VAL=1
  if [ ! -d "${LRAR_INSTALLDIR}" ]
  then
    LRAR_RET_VAL=0
  elif [ ! -f "${LRAR_INSTALLDIR}/lib/psqlodbcw.so" ]
  then
    LRAR_RET_VAL=0
  elif [ ! -f "${LRAR_INSTALLDIR}/installer/psqlODBC/configpsqlodbc.sh" ];then
    LRAR_RET_VAL=0
  elif [ ! -f "${LRAR_INSTALLDIR}/installer/psqlODBC/createshortcuts.sh" -a ${RAR_PLATFORM} = Linux ];then
    LRAR_RET_VAL=0
  fi
  return ${LRAR_RET_VAL}
}

configurepsqlodbcDarwin ()
{
##############################################
# TODO: Do not have support to write ini. :( #
##############################################
  _note "Found psqlodbc. You may need to install the driver manually."
}

configurepsqlodbcLinux ()
{
  LRAR_INSTALLDIR=${1}
  LRAR_PSQLODBCLIB=${1}/lib/psqlodbcw.so

  LRAR_HAS_UNIXODBC=`which odbcinst 2>/dev/null`

  if [ x"${LRAR_HAS_UNIXODBC}" = x"" ]
  then
    _warn "Couldn't find 'odbcinst' on your system. Please install unixODBC in order to install psqlODBC"
    return
  fi

  RAR_ODBCDRIVER_INSTALLED=`su - ${PG_RAR_SERVICEACCOUNT} -c "odbcinst -q -d 2>/dev/null | grep \"[[psqlodbc-${PG_RAR_MAJOR_VERSION}]]\""`
  if [ x"$RAR_ODBCDRIVER_INSTALLED" = x"[psqlodbc-${PG_RAR_MAJOR_VERSION}]" ]
  then
    _note 1 "psqlodbc driver (psqlodbc-${PG_RAR_MAJOR_VERSION}) is already been registered."
    return
  fi

  readValue "Found psqlODBC. Do you want to configure psqlODBC? (Y/n)" RAR_INSTALL_PSQLODBC "${RAR_INSTALL_PSQLODBC}" " "

  if [ x"${RAR_INSTALL_PSQLODBC}" = x"Y" -o x"${RAR_INSTALL_PSQLODBC}" = x"y" ]
  then
    _title 1 "Configuring psqlodbc-${PG_RAR_MAJOR_VERSION}.."
  else
    return
  fi

  cat <<EOT > /tmp/rar_psqlodbc_${PG_RAR_MAJOR_VERSION}.$$
[psqlodbc-${PG_RAR_MAJOR_VERSION}]
Description=PostgreSQL 8.4 ODBC Driver
Driver=${LRAR_INSTALLDIR}/lib/psqlodbcw.so

EOT

  _title 1 "Installing psqlODBC driver..."
  _log CONTENTS "(/tmp/rar_psqlodbc_${PG_RAR_MAJOR_VERSION}.$$)"
  _log --------------------------------------------------------------------------------------------------
  _logfile /tmp/rar_psqlodbc_${PG_RAR_MAJOR_VERSION}.$$
  _log --------------------------------------------------------------------------------------------------
  _log EXECUTING: odbcinst -i -d -f /tmp/rar_psqlodbc_${PG_RAR_MAJOR_VERSION}.$$
  odbcinst -i -d -f /tmp/rar_psqlodbc_${PG_RAR_MAJOR_VERSION}.$$ > /tmp/rar_psqlodbc_log_$$ 2>&1
  _logfile /tmp/rar_psqlodbc_log_$$
  rm -f /tmp/rar_psqlodbc_log_$$ /tmp/rar_psqlodbc_${PG_RAR_MAJOR_VERSION}.$$

}

validateNpgsql ()
{
  LRAR_INSTALLDIR=$1
  LRAR_RET_VAL=1
  if [ ! -d "${LRAR_INSTALLDIR}/Npgsql" ]
  then
    LRAR_RET_VAL=0
  elif [ ! -f "${LRAR_INSTALLDIR}/Npgsql/bin/Npgsql.dll" ]
  then
    LRAR_RET_VAL=0
  elif [ ! -f "${LRAR_INSTALLDIR}/Npgsql/installer/npgsql/createshortcuts.sh" ];then
    LRAR_RET_VAL=0
  fi
  return ${LRAR_RET_VAL}
}

validatepgBouncer ()
{
  LRAR_INSTALLDIR=$1
  LRAR_RET_VAL=1
  if [ ! -d "${LRAR_INSTALLDIR}" ]
  then
    LRAR_RET_VAL=0
  elif [ ! -f "${LRAR_INSTALLDIR}/bin/pgbouncer" ]
  then
    LRAR_RET_VAL=0
  elif [ ! -f "${LRAR_INSTALLDIR}/installer/pgbouncer/startupcfg.sh" ];then
    LRAR_RET_VAL=0
  elif [ ! -f "${LRAR_INSTALLDIR}/share/pgbouncer.ini" ];then
    LRAR_RET_VAL=0
  fi

  return ${LRAR_RET_VAL}
}

validatepgmemcache ()
{
  LRAR_INSTALLDIR=$1
  LRAR_RET_VAL=1
  if [ ! -f "${LRAR_INSTALLDIR}/lib/libmemcached.so" -a ${RAR_PLATFORM} = Linux ]
  then
    LRAR_RET_VAL=0
  elif [ ! -f "${LRAR_INSTALLDIR}/lib/libmemcached.dylib" -a ${RAR_PLATFORM} = Darwin ]
  then
    LRAR_RET_VAL=0
  elif [ ! -f "${LRAR_INSTALLDIR}/share/pgmemcache.sql" ];then
    LRAR_RET_VAL=0
  fi

  return ${LRAR_RET_VAL}
}

validatesbp ()
{
  LRAR_INSTALLDIR=$1
  LRAR_RET_VAL=1
  LRAR_SBP_SCRIPT_LAUNCHSBP_MODIFIED=
  LRAR_SBP_SCRIPT_RUNSBP_MODIFIED=

  if [ ${RAR_PLATFORM} = Linux ]
  then

    if [ ! -f "${LRAR_INSTALLDIR}/bin/stackbuilderplus" ]
    then
      LRAR_RET_VAL=0
    elif [ ! -f "${LRAR_INSTALLDIR}/bin/UpdateManager" -a ${RAR_PLATFORM} = Linux ]
    then
      LRAR_RET_VAL=0
    elif [ ! -f "${LRAR_INSTALLDIR}/scripts/launchSBPUpdateMonitor.sh" ]
    then
      LRAR_RET_VAL=0
    elif [ ! -f "${LRAR_INSTALLDIR}/scripts/launchStackBuilderPlus.sh" ]
    then
      LRAR_RET_VAL=0
    elif [ ! -f "${LRAR_INSTALLDIR}/scripts/runStackBuilderPlus.sh" ]
    then
      LRAR_RET_VAL=0
    elif [ ! -f "${LRAR_INSTALLDIR}/scripts/xdg/edb-sbp-update-monitor.desktop" ]
    then
      LRAR_RET_VAL=0
    fi

  elif [ ${RAR_PLATFORM} = Darwin ]
  then

    if [ ! -f "${LRAR_INSTALLDIR}/StackBuilderPlus.app/Contents/MacOS/stackbuilderplus" -a ${RAR_PLATFORM} = Darwin ]
    then
      LRAR_RET_VAL=0
    elif [ ! -f "${LRAR_INSTALLDIR}/UpdateManager.app/Contents/MacOS/UpdateManager" -a ${RAR_PLATFORM} = Darwin ]
    then
      LRAR_RET_VAL=0
    elif [ ! -f "${LRAR_INSTALLDIR}/scripts/launchSBPUpdateMonitor.sh" ]
    then
      LRAR_RET_VAL=0
    elif [ ! -f "${LRAR_INSTALLDIR}/scripts/launchStackBuilderPlus.sh" ]
    then
      LRAR_RET_VAL=0
    elif [ ! -f "${LRAR_INSTALLDIR}/scripts/launchupdatemanager.applescript" ]
    then
      LRAR_RET_VAL=0
    elif [ ! -f "${LRAR_INSTALLDIR}/scripts/stackbuilderplus.applescript" ]
    then
      LRAR_RET_VAL=0
    fi

  fi

  return ${LRAR_RET_VAL}
}

configuresbp ()
{
  LRAR_INSTALLDIR=${1}

  _replace @@INSTALL_DIR@@ "${LRAR_INSTALLDIR}" "${LRAR_INSTALLDIR}/installer/StackBuilderPlus/createshortcuts.sh"
  _replace @@PG_VERSION@@ "${PG_RAR_MAJOR_VERSION}" "${LRAR_INSTALLDIR}/installer/StackBuilderPlus/createshortcuts.sh"
  _replace @@BRANDING@@ "${PG_RAR_BRANDING}" "${LRAR_INSTALLDIR}/installer/StackBuilderPlus/createshortcuts.sh"

  _replace @@INSTALL_DIR@@ "${LRAR_INSTALLDIR}" "${LRAR_INSTALLDIR}/scripts/xdg/edb-sbp-update-monitor.desktop"
  _replace @@PG_VERSION@@ "${PG_RAR_MAJOR_VERSION}" "${LRAR_INSTALLDIR}/scripts/xdg/edb-sbp-update-monitor.desktop"

  _replace INSTALL_DIR "${LRAR_INSTALLDIR}" "${LRAR_INSTALLDIR}/scripts/launchStackBuilderPlus.sh"
  _replace INSTALL_DIR "${LRAR_INSTALLDIR}" "${LRAR_INSTALLDIR}/scripts/runStackBuilderPlus.sh"

####################################################################
## NOTE: We do not write the information in /etc/postgres-reg.ini ##
##       Hence, StackBuilderPlus won't work                       ##
####################################################################
   _note "We have not updated or created  for the PostgresPlus details in '/etc/postgres-reg.ini'. Hence, StackBuilderPlus will not work."

#  LRAR_SERVICEACCOUNT_HOME=`su ${PG_RAR_SERVICEACCOUNT} -c "echo $HOME"`
#
#  if [ ! -d ${LRAR_SERVICEACCOUNT_HOME}/.config/autostart -a ${RAR_PLATFORM} = Linux ]
#  then
#    mkdir ${LRAR_SERVICEACCOUNT_HOME}/.config/autostart
#    chown ${PG_RAR_SERVICEACCOUNT} ${LRAR_SERVICEACCOUNT_HOME}/.config/autostart
#  fi
#  if [ ! -f ${LRAR_SERVICEACCOUNT_HOME}/.config/autostart/edb-sbp-update-monitor-${PG_RAR_MAJOR_VERSION}.desktop -a ${RAR_PLATFORM} = Linux ]
#  then
#    cp "${LRAR_INSTALLDIR}/scripts/xdg/edb-sbp-update-monitor.desktop" "${LRAR_SERVICEACCOUNT_HOME}/.config/autostart/edb-sbp-update-monitor-${PG_RAR_MAJOR_VERSION}.desktop"
#    chown ${PG_RAR_SERVICEACCOUNT} ${LRAR_SERVICEACCOUNT_HOME}/.config/autostart/edb-sbp-update-monitor-${PG_RAR_MAJOR_VERSION}.desktop
#  fi

#  _note 1 "Starting StackBuilder Plus Update Monitor..."
#  if [ ${RAR_DEBUG} -eq 1 ]
#  then
#    echo ""${LRAR_INSTALLDIR}/scritps/launchSBPUpdateMonitor.sh"" | tee -a ${RAR_LOG_FILE}
#    "${LRAR_INSTALLDIR}/scritps/launchSBPUpdateMonitor.sh" 2>&1 | tee -a ${RAR_LOG_FILE}
#  else
#    echo ""${LRAR_INSTALLDIR}/scritps/launchSBPUpdateMonitor.sh"" >> ${RAR_LOG_FILE}
#    "${LRAR_INSTALLDIR}/scritps/launchSBPUpdateMonitor.sh" >> ${RAR_LOG_FILE} 2>&1
#  fi

}

validatepgBouncerPort ()
{
  LRAR_PORT=$1
  echo ${LRAR_PORT} | egrep '^[0-9]+$' >/dev/null 2>&1
  if [ $? -eq 1 ]
  then
    _warn \"${LRAR_PORT}\" is not a valid port number.
    return 0
  fi
  if [ ${LRAR_PORT} -lt 1000 -a ${LRAR_PORT} -gt 65535 ]
  then
     _warn Please enter port within 1000 to 65535
     return 0
  fi
  if [ ${LRAR_PORT} -eq ${PG_RAR_DEV_PORT} ]
  then
     _warn Server port and pgBouncer port can not be same.
     return 0
  fi
  return 1
}

configurepgBouncer ()
{
  LRAR_INSTALLDIR="${PG_RAR_DEV_INSTALL_DIR}/pgbouncer"
  if [ x"${PG_RAR_PGBOUNCER_PORT}" = x"" ]
  then
    PG_RAR_PGBOUNCER_PORT=6543
  fi

  if [ -f /etc/init.d/pgbouncer -a $RAR_PLATFORM = Linux ]
  then
    _note 1 "Another vesion of pgbouncer service is installed."
    return
  elif [ -f /Library/LaunchDaemons/come.edb.launchd.pgbouncer.plist -a $RAR_PLATFORM = Darwin ]
  then
    _note 1 "Another vesion of pgbouncer service is installed."
    return
  fi
  readValue "Please enter the port on which pgbouncer will listen :" PG_RAR_PGBOUNCER_PORT "${PG_RAR_PGBOUNCER_PORT}" validatepgBouncerPort "pgBouncer Port"

  backupFile "${LRAR_INSTALLDIR}/share/pgbouncer.ini"
  _replace @@CON@@ "postgres = host=localhost port=${PG_RAR_DEV_PORT}" "${LRAR_INSTALLDIR}/share/pgbouncer.ini"
  _replace @@LISTENADDR@@ "*" "${LRAR_INSTALLDIR}/share/pgbouncer.ini"
  _replace @@LISTENPORT@@ "${PG_RAR_PGBOUNCER_PORT}" "${LRAR_INSTALLDIR}/share/pgbouncer.ini"
  _replace @@ADMINUSERS@@ "${PG_RAR_SUPERUSER}" "${LRAR_INSTALLDIR}/share/pgbouncer.ini"
  _replace @@STATSUSERS@@ "${PG_RAR_SUPERUSER}" "${LRAR_INSTALLDIR}/share/pgbouncer.ini"
  _replace @@LOGFILE@@ "${LRAR_INSTALLDIR}/log/pgbouncer.log" "${LRAR_INSTALLDIR}/share/pgbouncer.ini"
  _replace @@PIDFILE@@ "${LRAR_INSTALLDIR}/log/pgbouncer.pid" "${LRAR_INSTALLDIR}/share/pgbouncer.ini"
  _replace @@AUTHFILE@@ "${LRAR_INSTALLDIR}/etc/userlist.txt" "${LRAR_INSTALLDIR}/share/pgbouncer.ini"

  mkdir -p "${LRAR_INSTALLDIR}/etc"
  chown ${PG_RAR_SERVICEACCOUNT} "${LRAR_INSTALLDIR}/etc"
  mkdir -p "${LRAR_INSTALLDIR}/log"
  chown ${PG_RAR_SERVICEACCOUNT} "${LRAR_INSTALLDIR}/log"
  echo "\"${PG_RAR_SUPERUSER}\" \"${PG_RAR_SUPERPASSWORD}\"" > "${LRAR_INSTALLDIR}/etc/userlist.txt"
  backupFile "${LRAR_INSTALLDIR}/etc/userlist.txt"
  chown ${PG_RAR_SERVICEACCOUNT} "${LRAR_INSTALLDIR}/etc/userlist.txt"
  chmod 700 "${LRAR_INSTALLDIR}/etc"
  chmod 700 "${LRAR_INSTALLDIR}/etc/userlist.txt"
  chmod 700 "${LRAR_INSTALLDIR}/log"
  if [ ${RAR_DEBUG} -eq 1 ]
  then
    echo ""${LRAR_INSTALLDIR}/installer/pgbouncer/startupcfg.sh" "${LRAR_INSTALLDIR}" ${PG_RAR_SERVICEACCOUNT}" | tee -a ${RAR_LOG_FILE}
    "${LRAR_INSTALLDIR}/installer/pgbouncer/startupcfg.sh" "${LRAR_INSTALLDIR}" ${PG_RAR_SERVICEACCOUNT} 2>&1 | tee -a ${RAR_LOG_FILE}
  else
    echo ""${LRAR_INSTALLDIR}/installer/pgbouncer/startupcfg.sh" "${LRAR_INSTALLDIR}" ${PG_RAR_SERVICEACCOUNT}" >> ${RAR_LOG_FILE}
    "${LRAR_INSTALLDIR}/installer/pgbouncer/startupcfg.sh" "${LRAR_INSTALLDIR}" ${PG_RAR_SERVICEACCOUNT} >> ${RAR_LOG_FILE} 2>&1
  fi

  _title 1 "Starting pgbouncer service..."
  if [ $RAR_PLATFORM = Linux ]
  then
    if [ ${RAR_DEBUG} -eq 1 ]
    then
      echo "/etc/init.d/pgbouncer start" | tee -a ${RAR_LOG_FILE}
      /etc/init.d/pgbouncer start 2>&1 | tee -a ${RAR_LOG_FILE}
    else
      echo "/etc/init.d/pgbouncer start" >> ${RAR_LOG_FILE}
      /etc/init.d/pgbouncer start >> ${RAR_LOG_FILE} 2>&1
    fi
  elif [ $RAR_PLATFORM = Darwin ]
  then
    launchctl load /Library/LaunchDaemons/com.edb.launchd.pgbouncer.plist
  fi
}

###############
# User Inputs #
###############
_title =======================
_title INSTALLATION DIRECTORY
_title =======================

readValue "Please enter the installation directory:" PG_RAR_DEV_INSTALL_DIR "${PG_RAR_DEV_INSTALL_DIR}" validateDevInstallDir "Installation Directory"

_info 1 "Installation Directory: ${PG_RAR_DEV_INSTALL_DIR}"

_title ===============
_title DATA DIRECTORY
_title ===============
if [ x"${RAR_DEV_DATA_DIR}" = x"" ]
then
  PG_RAR_DEV_DATA_DIR=${PG_RAR_DEV_INSTALL_DIR}/data
fi
_note "If data directory exists and postgresql.conf file exists in that directory, we will not
      initial the cluster."

readValue "Please enter the data directory path:" PG_RAR_DEV_DATA_DIR "${PG_RAR_DEV_DATA_DIR}" validateDevDataDir "Data Directory"

_info 1 "Data Directory: ${PG_RAR_DEV_DATA_DIR}"

_title =====
_title PORT
_title =====
_note "We will not be able to examine, if port is currently used by other application."

if [ x"${PG_RAR_DEV_PORT}" = x"" ]
then
    PG_RAR_DEV_PORT=5432
fi
readValue "Please enter port:" PG_RAR_DEV_PORT "${PG_RAR_DEV_PORT}" validateDevPort "Port"

_info 1 "Port: ${PG_RAR_DEV_PORT}"

_title =======
_title LOCALE
_title =======

readValue "Please enter the locale:" PG_RAR_DEV_LOCALE "${PG_RAR_DEV_LOCALE}" validateDevLocale "Locale"

_info 1 "Locale: ${PG_RAR_DEV_LOCALE}"
SERVICEACCOUNTID=`id -u ${PG_RAR_SERVICEACCOUNT} 2>/dev/null`
if [ "${SERVICEACCOUNTID}" = "0" ]
then
   PG_RAR_SERVICEACCOUNT=postgres
fi
_info 1 "Service Account: ${PG_RAR_SERVICEACCOUNT}"
_info 1 "Super User: ${PG_RAR_SUPERUSER}"

_title ============================
_title DATABASE SUPERUSER PASSWORD
_title ============================

readPassword "Please provide password for the super-user(${PG_RAR_SUPERUSER}):" PG_RAR_SUPERPASSWORD "${PG_RAR_SUPERPASSWORD}" " " "Database super-user's password"

_info 1 "Super User Password: ${PG_RAR_SUPERPASSWORD}"

##############################
# START INSTALLATION PROCESS #
##############################

## Create User, if does not exist
_title 1 "Create User (if not exist): ${PG_RAR_SERVICEACCOUNT}"

_log EXECUTING: "${PG_RAR_DEV_INSTALL_DIR}/installer/server/createuser.sh "${PG_RAR_SERVICEACCOUNT}" "${PG_RAR_DEV_INSTALL_DIR}""
${PG_RAR_DEV_INSTALL_DIR}/installer/server/createuser.sh "${PG_RAR_SERVICEACCOUNT}" "${PG_RAR_DEV_INSTALL_DIR}" > /tmp/rar_createuser_$$ 2>&1
RAR_OUTPUT=$?
_logfile /tmp/rar_createuser_$$
rm -f /tmp/rar_createuser_$$ 2>/dev/null

if [ ${RAR_OUTPUT} -eq 127 ]
then
  _die "The script was called with an invalid command line."
elif [ ${RAR_OUTPUT} -eq 1 ]
then
  _die "The service user account '${PG_RAR_SERVICEACCOUNT}' could not be created."
elif [ ${RAR_OUTPUT} -ne 0 ]
then
  _die "Unknown error running the script - ${PG_RAR_DEV_INSTALL_DIR}/installer/server/createuser.sh"
fi

## Initialize cluster
if [ ! -f "${PG_RAR_DEV_DATA_DIR}/postgresql.conf" ]
then
  _title 1 "Initialize Cluster : ${PG_RAR_DEV_DATA_DIR}"
  _log EXECUTING: "${PG_RAR_DEV_INSTALL_DIR}/installer/server/initcluster.sh "${PG_RAR_SERVICEACCOUNT}" "${PG_RAR_SUPERUSER}" "${PG_RAR_SUPERPASSWORD}" "${PG_RAR_DEV_INSTALL_DIR}" "${PG_RAR_DEV_DATA_DIR}" ${PG_RAR_DEV_PORT} ${PG_RAR_DEV_LOCALE}"
   ${PG_RAR_DEV_INSTALL_DIR}/installer/server/initcluster.sh "${PG_RAR_SERVICEACCOUNT}" "${PG_RAR_SUPERUSER}" "${PG_RAR_SUPERPASSWORD}" "${PG_RAR_DEV_INSTALL_DIR}" "${PG_RAR_DEV_DATA_DIR}" ${PG_RAR_DEV_PORT} ${PG_RAR_DEV_LOCALE} > /tmp/rar_initclust_$$ 2>&1
  RAR_OUTPUT=$?
  _logfile /tmp/rar_initclust_$$
  rm -f /tmp/rar_initclust_$$ 2>/dev/null

  if [ ${RAR_OUTPUT} -eq 127 ]
  then
    _die "The script was called with an invalid command line."
  elif [ ${RAR_OUTPUT} -eq 1 ]
  then
    _die "The database cluster initialisation failed."
  elif [ ${RAR_OUTPUT} -eq 2 ]
  then
    _warn "A non-fatal error occured during cluster initialisation."
  fi
fi
if [ ! -d "${PG_RAR_DEV_DATA_DIR}/pg_log" ]
then
  mkdir "${PG_RAR_DEV_DATA_DIR}/pg_log"
  chown ${PG_RAR_SERVICEACCOUNT} "${PG_RAR_DEV_DATA_DIR}/pg_log"
fi

## Startup configuration
if [ $RAR_PLATFORM = Linux ]
then
  if [ ! -f "/etc/init.d/${PG_RAR_SERVICENAME}" ]
  then
    _title 1 "Creating Service: ${PG_RAR_SERVICENAME}"
    _log EXECUTING: "${PG_RAR_DEV_INSTALL_DIR}/installer/server/startupcfg.sh "${PG_RAR_MAJOR_VERSION}" "${PG_RAR_SERVICEACCOUNT}" "${PG_RAR_DEV_INSTALL_DIR}" "${PG_RAR_DEV_DATA_DIR}" "${PG_RAR_SERVICENAME}""
    ${PG_RAR_DEV_INSTALL_DIR}/installer/server/startupcfg.sh "${PG_RAR_MAJOR_VERSION}" "${PG_RAR_SERVICEACCOUNT}" "${PG_RAR_DEV_INSTALL_DIR}" "${PG_RAR_DEV_DATA_DIR}" "${PG_RAR_SERVICENAME}" > /tmp/rar_startupcfg_$$ 2>&1 
    RAR_OUTPUT=$?

    _logfile /tmp/rar_startupcfg_$$
    rm -f /tmp/rar_startupcfg_$$ 2>/dev/null

    if [ ${RAR_OUTPUT} -eq 127 ]
    then
      _die "The script was called with an invalid command line."
    elif [ ${RAR_OUTPUT} -eq 1 ]
    then
      _die "Failed to configure the database to auto-start at boot time."
    elif [ ${RAR_OUTPUT} -eq 2 ]
    then
      _warn "A non-fatal error occured during startup configuration."
    fi

    ## Modify pgAdmin III settings
    echo "PostgreSQLPath=${PG_RAR_DEV_INSTALL_DIR}/bin
    PostgreSQLHelpPath=file://${PG_RAR_DEV_INSTALL_DIR}/doc/postgresql/html" >> "${PG_RAR_DEV_INSTALL_DIR}/pgAdmin3/share/pgadmin3/settings.ini"
  else
    _note 1 "Service (${PG_RAR_SERVICENAME}) already exists."
  fi

  ## Start Server
  _title 1 "Starting server (Service:${PG_RAR_SERVICENAME})"
  _log EXECUTING: "${PG_RAR_DEV_INSTALL_DIR}/installer/server/startserver.sh "${PG_RAR_SERVICENAME}""

  ${PG_RAR_DEV_INSTALL_DIR}/installer/server/startserver.sh "${PG_RAR_SERVICENAME}" > /tmp/rar_startpgserver_$$ 2>&1
  RAR_OUTPUT=$?
  _logfile /tmp/rar_startpgserver_$$
  rm -f /tmp/rar_startpgserver_$$ 2>/dev/null

  if [ ${RAR_OUTPUT} -eq 127 ]
  then
    _die "The script was called with an invalid command line."
  elif [ ${RAR_OUTPUT} -eq 1 ]
  then
    _die "Failed to start the database server."
  fi

elif [ $RAR_PLATFORM = Darwin ]
then
  if [ ! -f "/Library/LaunchDaemons/com.edb.launchd.${PG_RAR_SERVICENAME}.plist" ]
  then
    _title 1 "Creating Service: ${PG_RAR_SERVICENAME}"
    _log EXECUTING: "${PG_RAR_DEV_INSTALL_DIR}/installer/server/startupcfg.sh "${PG_RAR_MAJOR_VERSION}" "${PG_RAR_SERVICEACCOUNT}" "${PG_RAR_DEV_INSTALL_DIR}" "${PG_RAR_DEV_DATA_DIR}" "${PG_RAR_SERVICENAME}""
    ${PG_RAR_DEV_INSTALL_DIR}/installer/server/startupcfg.sh "${PG_RAR_MAJOR_VERSION}" "${PG_RAR_SERVICEACCOUNT}" "${PG_RAR_DEV_INSTALL_DIR}" "${PG_RAR_DEV_DATA_DIR}" "${PG_RAR_SERVICENAME}" > /tmp/rar_startupcfg_$$ 2>&1
    RAR_OUTPUT=$?
    _logfile /tmp/rar_startupcfg_$$
    rm -f /tmp/rar_startupcfg_$$ 2>/dev/null

    if [ ${RAR_OUTPUT} -eq 127 ]
    then
      _die "The script was called with an invalid command line."
    elif [ ${RAR_OUTPUT} -eq 1 ]
    then
      _die "Failed to configure the database to auto-start at boot time."
    elif [ ${RAR_OUTPUT} -eq 2 ]
    then
      _warn "A non-fatal error occured during startup configuration."
    fi

    ## Modify pgAdmin III settings
    echo "PostgreSQLPath=${PG_RAR_DEV_INSTALL_DIR}/bin
PostgreSQLHelpPath=file://${PG_RAR_DEV_INSTALL_DIR}/doc/postgresql/html" >> "${PG_RAR_DEV_INSTALL_DIR}/pgAdmin3.app/Contents/SharedSupport/settings.ini"
  else
    _note 1 "Service (${PG_RAR_SERVICENAME}) already exists."

    ## Start Server
    _title 1 "Starting server (Service:${PG_RAR_SERVICENAME})"
    launchctl load /Library/LaunchDaemons/com.edb.launchd.${PG_RAR_SERVICENAME}.plist
  fi
fi

## Wait for 8 seconds - give 3 seconds to start the service completely
sleep 8

## TODO: Shortcuts Creation

## Load Modules
_title 1 "Loading Modules..."
  if [ ${RAR_DEBUG} -eq 1 ]
  then
    echo "Executing: ${PG_RAR_DEV_INSTALL_DIR}/installer/server/loadmodules.sh "${PG_RAR_SERVICEACCOUNT}" "${PG_RAR_SUPERUSER}" "${PG_RAR_SUPERPASSWORD}" "${PG_RAR_DEV_INSTALL_DIR}" ${PG_RAR_DEV_PORT} 1" | tee -a ${RAR_LOG_FILE}
    ${PG_RAR_DEV_INSTALL_DIR}/installer/server/loadmodules.sh "${PG_RAR_SERVICEACCOUNT}" "${PG_RAR_SUPERUSER}" "${PG_RAR_SUPERPASSWORD}" "${PG_RAR_DEV_INSTALL_DIR}" ${PG_RAR_DEV_PORT} 1 2>&1 | tee -a ${RAR_LOG_FILE}
  else
    echo "Executing: ${PG_RAR_DEV_INSTALL_DIR}/installer/server/loadmodules.sh "${PG_RAR_SERVICEACCOUNT}" "${PG_RAR_SUPERUSER}" "${PG_RAR_SUPERPASSWORD}" "${PG_RAR_DEV_INSTALL_DIR}" ${PG_RAR_DEV_PORT} 1" >> ${RAR_LOG_FILE}
    ${PG_RAR_DEV_INSTALL_DIR}/installer/server/loadmodules.sh "${PG_RAR_SERVICEACCOUNT}" "${PG_RAR_SUPERUSER}" "${PG_RAR_SUPERPASSWORD}" "${PG_RAR_DEV_INSTALL_DIR}" ${PG_RAR_DEV_PORT} 1 >> ${RAR_LOG_FILE} 2>&1
  fi

## TODO: Write to ini files

## Create pg_env.sh file
_title 1 "Creating pg_env.sh file.."
backupFile "${PG_RAR_DEV_INSTALL_DIR}/pg_env.sh"
cat <<EOT > "${PG_RAR_DEV_INSTALL_DIR}/pg_env.sh"
#!/bin/sh
# The script sets environment variables helpful for PostgreSQL

export PATH=\${PATH}:${PG_RAR_DEV_INSTALL_DIR}/bin
export PGDATA=${PG_RAR_DEV_DATA_DIR}
export PGDATABASE=postgres
export PGUSER=${PG_RAR_SUPERUSER}
export PGPORT=${PG_RAR_DEV_PORT}
export PGLOCALEDIR=${PG_RAR_DEV_INSTALL_DIR}/share/locale

EOT
chmod a+x pg_env.sh

validatePostGIS "${PG_RAR_DEV_INSTALL_DIR}"
if [ $? -eq 1 ]
then
  configurePostGIS
fi

validateSlony "${PG_RAR_DEV_INSTALL_DIR}"
if [ $? -eq 1 ]
then
  readValue "Found Slony. Do you want to configure Slony? (Y/n)" RAR_INSTALL_SLONY "${RAR_INSTALL_SLONY}" " "
  if [ x"${RAR_INSTALL_SLONY}" = x"Y" -o x"${RAR_INSTALL_SLONY}" = x"y" ]
  then
    configureSlony
  fi
fi

validatepgAgent "${PG_RAR_DEV_INSTALL_DIR}/pgAgent"
if [ $? -eq 1 ]
then
  readValue "Found pgAgent. Do you want to configure pgAgent? (Y/n)" RAR_INSTALL_PGAGENT "${RAR_INSTALL_PGAGENT}" " "
  if [ x"${RAR_INSTALL_PGAGENT}" = x"Y" -o x"${RAR_INSTALL_PGAGENT}" = x"y" ]
  then
    configurepgAgent "${PG_RAR_DEV_INSTALL_DIR}/pgAgent"
  fi
fi

validatepsqlodbc "${PG_RAR_DEV_INSTALL_DIR}/psqlODBC"

if [ $? -eq 1 ]
then
  configurepsqlodbc$RAR_PLATFORM "${PG_RAR_DEV_INSTALL_DIR}/psqlODBC"
fi

validateNpgsql "${PG_RAR_DEV_INSTALL_DIR}"
if [ $? -eq 1 ]
then
  _title 1 "Found Npgsql..."
  # Nothing to be done for configuration
fi

validatepgBouncer "${PG_RAR_DEV_INSTALL_DIR}/pgbouncer"
if [ $? -eq 1 ]
then
  readValue "Found pgbouncer. Do you want to configure pgbouncer? (Y/n)" RAR_INSTALL_PGBOUNCER "${RAR_INSTALL_PGBOUNCER}" " "
  if [ x"${RAR_INSTALL_PGBOUNCER}" = x"Y" -o x"${RAR_INSTALL_PGBOUNCER}" = x"y" ]
  then
    configurepgBouncer
  fi
fi

validatepgmemcache "${PG_RAR_DEV_INSTALL_DIR}"
if [ $? -eq 1 ]
then
  _title 1 "Found pgmemcache..."
  # Nothing to be done for configuration
fi

validatesbp "${PG_RAR_DEV_INSTALL_DIR}/StackBuilderPlus"
if [ $? -eq 1 ]
then
  readValue "Found StackBuilderPlus. Do you want to configure StackBuilder Plus? (Y/n)" RAR_INSTALL_SBP "${RAR_INSTALL_SBP}" " "
  if [ x"${RAR_INSTALL_SBP}" = x"Y" -o x"${RAR_INSTALL_SBP}" = x"y" ]
  then
    configuresbp ${PG_RAR_DEV_INSTALL_DIR}/StackBuilderPlus
  fi
elif [ $? -eq 2 ]
then
  _title 1 "Found StackBuilderPlus.. But, configuration is not required"
fi

_save_options_file

