#!/bin/ksh
####################################################################################################
# Purpose: To gather data stored in the APM database 
#   Name : GetApmData.sh 
# Author : Subhechha Paul
# Origin : 2013/12/18 - SP - Initial development
####################################################################################################

####################################################################################################
# Load the environment and common functions.
####################################################################################################
UNIXLOGIN=`/usr/bin/whoami`
version="$Id: GetApmData.sh,v 1.0 2013/12/18 14:23:45 v612896 Exp $"

PROG=`basename $0`
PROGNAME=`basename $0| cut -d"." -f1`

####################################################################################################
# Print out the usage.
####################################################################################################
usage ()
{
    #eval ${DEBUG_FN:+set -x}
    echo "Usage:" >&2
    echo "${PROG} <-R MOM Repository> <-T MOM Port> <-H Host Name> <-S StartTime> <-E EndTime> <[-I Sample Interval] [-U UserName] [-P UserPassword]" >&2
    echo "     -R = MOM Repository" >&2
    echo "     -T = MOM Repository Port" >&2
    echo "     -H = Host Name" >&2
    echo "     -S = Start Time (E.g. '2013-02-18 00:01:00')" >&2
    echo "     -E = End Time (E.g. '2013-02-18 00:04:00')" >&2
    echo "     -I = Sample Interval (Default:60 sec)" >&2
    echo "     -U = UserName" >&2
    echo "     -P = Password" >&2
    echo "     -O = Output Directory (Default:Current Directory)" >&2
    echo "     -M = Mail To (Comma separated mailing list)" >&2
    echo "      [-O Outputdirectory] -M[Mail To (Comma separated mailing list)] -[vh]\n" >&2
    return 0
}

####################################################################################################
# Validate and parse all the command line options.
####################################################################################################
#
COUNTER=0
while getopts R:T:H:S:E:I:U:P:O:M:vh opt
do
   case $opt in
      R) MOMS=$OPTARG
         ((COUNTER = COUNTER + 1))
         ;;
      T) MPORT=$OPTARG
         echo $MPORT | tr [:lower:] [:upper:] | grep [A-Z] > /dev/null 2>&1
         if [ $? -eq 0 ]; then echo "\n\nPort address should be numeric."; usage; exit 1; fi;
         ((COUNTER = COUNTER + 1))
         ;;
      H) HNAME=$OPTARG
         ((COUNTER = COUNTER + 1))
         ;;
      S) STTIME=$OPTARG
         ((COUNTER = COUNTER + 1))
         ;;
      E) ENDTIME=$OPTARG
         ((COUNTER = COUNTER + 1))
         ;;
      I) SAMPLEINT=$OPTARG
         echo $SAMPLEINT | tr [:lower:] [:upper:] | grep [A-Z] > /dev/null 2>&1
         if [ $? -eq 0 ]; then echo "\n\nSample Interval should be numeric."; usage; exit 1; fi;
         ((COUNTER = COUNTER + 1))
         ;;
      U) USERNAME=$OPTARG
         ((COUNTER = COUNTER + 1))
         ;;
      P) USERPASSWD=$OPTARG
         ((COUNTER = COUNTER + 1))
         ;;
      O) OUTPUTDIR=$OPTARG
         ((COUNTER = COUNTER + 1))
         ;;
      M) MAILTO=$OPTARG
         ((COUNTER = COUNTER + 1))
         ;;
      v) echo "Version $version" && exit 0;;
      h|*) usage && exit 1;;
   esac
done

BASEDIR=`pwd`/${PROGNAME}
[ $# -lt 5 ] && usage && exit 1
if [ -z "${MOMS}" ]; then echo "MOM Repository Name Cannot be null."; usage; exit 1; fi;
if [ -z "${MPORT}" ]; then echo "MOM Server Port Address Cannot be null."; usage; exit 1; fi;
if [ -z "${HNAME}" ]; then echo "HostName Cannot be null."; usage; exit 1; fi;
if [ -z "${STTIME}" ]; then echo "Start Time Cannot be null."; usage; exit 1; fi;
if [ -z "${ENDTIME}" ]; then echo "End Time Cannot be null."; usage; exit 1; fi;
if [ -z "${SAMPLEINT}" ]; then SAMPLEINT=60; fi;
if [ -z ${USERNAME} ]; then USERNAME=`who am i`; fi;
if [ -z ${OUTPUTDIR} ]; then OUTPUTDIR=${BASEDIR}/Out; fi;
if [ -z ${MAILTO} ]; then MAILTO=$USERNAME; fi;
if [ -z ${TMPDIR} ]; then TMPDIR=${BASEDIR}/Tmp; fi;
if [ -z ${LOGDIR} ]; then LOGDIR=${BASEDIR}; fi;

if [ -z ${USERPASSWD} ]
then
    echo "User Name:$USERNAME , Password:\c"; stty -echo; read USERPASSWD; stty echo;
fi

####################################################################################################
# Set Local Variables
####################################################################################################
DTTS=`date +'%Y%m%d_%H%M'`
CURDT=`date +%Y%m%d`

if [ ! -d ${OUTPUTDIR}/${CURDT} ]
then
    mkdir -p ${OUTPUTDIR}/${CURDT}
    if [ $? -ne 0 ]; then echo "Error while creating directory.. Hence Exiting..."; exit 1; fi;
fi

if [ ! -d ${TMPDIR} ]
then
    mkdir -p ${TMPDIR}
    if [ $? -ne 0 ]; then echo "Error while creating directory.. Hence Exiting..."; exit 1; fi;
fi

USERPASSFILE=${TMPDIR}/.${PROGNAME}.${DTTS}$$.${HNAME}
if [ -f $USERPASSFILE ]; then rm -f $USERPASSFILE; fi;
echo $USERPASSWD > $USERPASSFILE; chmod 400 $USERPASSFILE

if [ ! -d ${LOGDIR} ]
then
    mkdir -p ${LOGDIR}
    if [ $? -ne 0 ]; then echo "Error while creating directory.. Hence Exiting..."; exit 1; fi;
fi
LOGFILE=${LOGDIR}/${PROGNAME}.log
touch $LOGFILE

####################################################################################################
# Set trap
####################################################################################################
#trap "
#    mailx -s "`uname -n`:${PROGNAME}: ERROR!!! has ended abnormally at `date`.!!!!!!" ${MAILTO} < /dev/null
#    echo "`date +'%Y%m%d_%H%M%S'`:${PROGNAME} has ended abnormally." >> $LOGFILE
#    rm -f $USERPASSFILE $TMPFILE > /dev/null > /dev/null
#    exit 1
#" 1 2 3 9 13 15 23
####################################################################################################


####################################################################################################
# Main Section
####################################################################################################

FrontEndData()
{
    #java -Xmx1024M -Duser="${USERNAME}" -Dpassword="${USERPASSWD}" -Dhost=fetfdpa2.verizon.com -Dport=5001 C:\Introscope\CLWorkstation.jar get historical data from agents matching \"vpbfrdgpa\d+\|WebLogic\|.*\" and metrics matching \"Frontends\|Apps\|([^\|:]+):(.*)\" between \"2013-02-18 00:01:00\" and \"2013-02-18 00:02:30\" with frequency of 90 seconds > C:\Introscope\Frontends.csv
    #java -Xmx1024M -Duser="${USERNAME}" -Dpassword="${USERPASSWD}" -Dhost=${MOMS} -Dport=${MPORT} -jar CLWorkstation.jar get historical data from agents matching "${HNAME}+|WebLogic|.*" and metrics matching "Frontends|Apps|([^\|]+):(.*)" between "${STTIME}" and "${ENDTIME}" with frequency of ${SAMPLEINT} seconds > ${OUTPUTDIR}/${CURDT}/FrontEndData_${DTTS}.csv
  
  java -Xmx1024M -Duser="${USERNAME}" -Dpassword="${USERPASSWD}" -Dhost=${MOMS} -Dport=5001 -jar CLWorkstation.jar get historical data from agents matching "${HNAME}+\.*.*" and metrics matching "Frontends\|.*.*" between "${STTIME}" and "${ENDTIME}" with frequency of ${SAMPLEINT} seconds > ${OUTPUTDIR}/${CURDT}/FrontEndData_${DTTS}.csv
}

BackEndData()
{
  java -Xmx1024M -Duser="${USERNAME}" -Dpassword="${USERPASSWD}" -Dhost=${MOMS} -Dport=5001 -jar CLWorkstation.jar get historical data from agents matching "${HNAME}+\.*.*" and metrics matching "Backends\|.*.*" between "${STTIME}" and "${ENDTIME}" with frequency of ${SAMPLEINT} seconds > ${OUTPUTDIR}/${CURDT}/BackEndData_${DTTS}.csv

	#java -Xmx1024M -Duser="${USERNAME}" -Dpassword="${USERPASSWD}" -Dhost=${MOMS} -Dport=5001  -jar CLWorkstation.jar get historical data from agents matching "${HNAME}|(.*)|.*" and metrics matching "Backends|vtbdb.*|SQL|(.*)|Query|(.*)" between "${STTIME}" and "${ENDTIME}" with frequency of ${SAMPLEINT} seconds > ${OUTPUTDIR}/${CURDT}/BackEndData_${DTTS}.csv
	#java -Xmx1024M -Duser="${USERNAME}" -Dpassword="${USERPASSWD}" -Dhost=${MOMS} -Dport=5001  -jar CLWorkstation.jar get historical data from agents matching "${HNAME}|(.*)|.*" and metrics matching "Backends|(.*)|SQL|(.*)|Query|(.*)" between "${STTIME}" and "${ENDTIME}" with frequency of ${SAMPLEINT} seconds > ${OUTPUTDIR}/${CURDT}/BackEndData_${DTTS}.csv
}

jvmCPUData()
{

  java -Xmx1024M -Duser="${USERNAME}" -Dpassword="${USERPASSWD}" -Dhost=${MOMS} -Dport=5001 -jar CLWorkstation.jar get historical data from agents matching "${HNAME}+\.*.*" and metrics matching "CPU:Utilization.*.*" between "${STTIME}" and "${ENDTIME}" with frequency of ${SAMPLEINT} seconds > ${OUTPUTDIR}/${CURDT}/jvmCPU_${DTTS}.csv

    #java -Xmx1024M -Duser="${USERNAME}" -Dpassword="${USERPASSWD}" -Dhost=${MOMS} -Dport=5001 -jar CLWorkstation.jar get historical data from agents matching "${HNAME}+|WebLogic|.*" and metrics matching "CPU:Utilization.*.*" between "${STTIME}" and "${ENDTIME}" with frequency of ${SAMPLEINT} seconds > ${OUTPUTDIR}/${CURDT}/jvmCPU${DTTS}.csv
}


#if [ -s $ERRFILE ]
#then
#    mailx -s "`uname -n`:${AUTOSERV}:${AUTO_JOB_NAME}:${PROGNAME}: WARNING!!! Replication Latency for ${HNAME} has crossed the threshold ${THRESHOLD} sec. !!! `date`.!!!!!!" ${MAILTO} < $ERRFILE
#fi

FrontEndData &
BackEndData &
jvmCPUData &

wait
rm -f $USERPASSFILE $TMPFILE > /dev/null > /dev/null

echo "All Good"
exit 0

