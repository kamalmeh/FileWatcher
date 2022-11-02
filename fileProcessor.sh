#!/bin/bash
################################################################################
# Program Name	: fileProcessor
# Author	: Kamal Mehta
# Create Date	: 31/Jul/2018
# Function	: 
#		  
# Version	: 1.0
# Change Log	:
#		  Date	Version	Author	Description
#		  31/Jul/2018	1.0	Kamal Mehta	Initial Version
#
# Bugs		:
#		  Let me know
#
################################################################################
export VERSION="v1.0"
export SCRIPT_ROOT=$(dirname $0)
export PROGRAM=$(basename $0)

#Load All Global Variables
. "${SCRIPT_ROOT}/GlobalVariables.sh"
#Load All Library Functions
. "${SCRIPT_ROOT}/functions.fnc"

HELP()
{
        echo "USAGE:  ${PROGRAM} [Options] <-f <File Name>>"
        echo    
        echo "  OPTIONS:"
        echo "          -f Trasnfer File Name" 
        echo "          -v Display Version Information" 
        echo "          -h Display Help for this program"
        echo
        exit 6
}

#########################################
####### PARSE COMMAND LINE OPTIONS ######
#########################################
while getopts ":f:vh" OPTION
do
        case ${OPTION} in
                f ) export FILENAME=${OPTARG};;
                v ) echo "Version: ${VERSION}";;
                h ) HELP;;
                \? ) HELP;;
        esac
done

if [[ ! -f ${CONFIG_FILE} ]]
then
	echo "ERROR: Configuration File Missing"
	echo "Create the File Transfer configuration file in below format"
	echo "FirstColumn|SecondColumn|ThirdColumn|ForthColumn|FifthColumn|SixthColumn|SeventhColumn"
	echo "Source Path|Source File Name|Target Path|Target File Name|Target Host|Target User|transfer Mode"
	echo "Seventh Column value is either 'live' or 'test'"
	echo "Exiting..."
	exit 3
fi

if [[ -f ${HALT_TOKEN} ]]
then
	echo "${HALT_TOKEN} is present. No file trasnfer will happen until this file is removed"
	exit 0
fi

## Start a sub process if there is no GLOBAL HALT flag present
FILE_EXISTS_OB ${FILENAME}
RC=$?
if [[ ${RC} -ne 0 ]]
then
	exit ${RC}
fi
CREATE_CTL_FILE ${FILENAME}
RC=$?
if [[ ${RC} -ne 0 ]]
then
	exit ${RC}
fi
ARCHIVE_OB ${FILENAME}
RC=$?
if [[ ${RC} -ne 0 ]]
then
	exit ${RC}
fi
CONFIG_CHECK ${FILENAME}
exit $? 
