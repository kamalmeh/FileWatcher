#!/bin/bash
export VERSION="v1.0"
export SCRIPT_ROOT=$(dirname $0)
if [[ ${SCRIPT_ROOT} == "." ]]
then
	export SCRIPT_ROOT=${PWD}
fi
PROGRAM=$(basename $0)

#Load All Global Variables
. "${SCRIPT_ROOT}/GlobalVariables.sh"
. "${SCRIPT_ROOT}/functions.fnc"


HELP()
{
        echo "USAGE:  ${PROGRAM} <-f <File Name>>"
        echo
        echo "  OPTIONS:"
        echo "          -s Source"
        echo "          -v Display Version Information"
        echo "          -h Display Help for this program"
        echo
        exit 1
}

#########################################
####### PARSE COMMAND LINE OPTIONS ######
#########################################
while getopts "f:vh" OPTION
do
        case ${OPTION} in
                f ) export SOURCE=${OPTARG};;
                v ) echo "Version: ${VERSION}";exit 0;;
                h ) HELP;;
                \? ) HELP;;
        esac
done

if [[ ${SOURCE} == "" ]]
then
	HELP
fi

if [[ ! -f ${CONFIG_FILE} ]]
then
        echo "ERROR: Configuration File Missing"
        echo "Create the File Transfer configuration file in below format"
        echo "FirstColumn|SecondColumn|ThirdColumn|ForthColumn|FifthColumn|SixthColumn"
        echo "Source Path|Source File Name|Target Path|Target File Name|Target Host|Target User"
        echo "Exiting..."
        exit 3
fi

export LOGFILE="${LOGDIR}/${SOURCE}.$(date '+%Y%m%d%H%M%S').log" 

{
FILELIST=$(grep ^${SOURCE} ${CONFIG_FILE} 2>/dev/null)
for src in ${FILELIST}
do
	FEED=$(echo ${src} | cut -d"|" -f1)
	file=$(echo ${src} | cut -d"|" -f2)
	file=$(find ${OUTBOUNDDIR} -type f -name ${file})
	FILENAME=$(basename ${file})
	CHECK_HALT_FLAG ${FEED} ${FILENAME}
	#${SCRIPT_ROOT}/fileProcessor.sh -f ${FILENAME}
	FILE_EXISTS_OB ${FILENAME}
	if [[ $? -ne 0 ]]
	then
		exit 0
	fi
done

echo "All Files arrived."

FILELIST=$(grep ^${SOURCE} ${CONFIG_FILE} 2>/dev/null)
for src in ${FILELIST}
do
	file=$(echo ${src} | cut -d"|" -f2)
	file=$(find ${OUTBOUNDDIR} -type f -name ${file})
	FILENAME=$(basename ${file})
	CREATE_CTL_FILE ${FILENAME}
	ARCHIVE_OB ${FILENAME}
	CONFIG_CHECK ${FILENAME}
done
} > ${LOGFILE} 2>&1
