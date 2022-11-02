#!/bin/bash
################################################################################
# Program Name	: fileWatcher
# Author	: Kamal Mehta
# Create Date	: 30/Jul/2018
# Function	: This script monitors the directory for any new files and
#		  returns the file name to caller function
# Version	: 1.0
# Change Log	:
#		  Date	Version	Author	Description
#		  30/Jul/2018	1.0	Kamal Mehta	Initial Version
#
# Bugs		:
#		  Let me know
#
################################################################################

export VERSION="v1.0"
export SCRIPT_ROOT=$(dirname $0)
export PROGRAM=$(basename $0)
export LOGDIR="/opt/infa/Log"

#This is the lading directory of the files and is monitored by this script
export WATCH_DIR="/opt/infpcuscgtsld/ISGHub/Outbound"
#Directory scan is repeated after this duration
export WATCH_INTERVAL=120

#Transferred files will be moved to this directory to avoid re-transmission of 
#the same file
export PROC_DIR="/opt/infpcuscgtsld/ISGHub/processed"

#Time to sleep in seconds if there is halt flag is present.
export HALT_SLEEP=300
#Halt flag should be created as "/var/tmp/halt_watcher"
export HALT_FLAG="/var/tmp/halt_watcher"

#Flag to shutdown the script normally
#Create below flag if you want to shutdown the script.
export SHUTDOWN="/var/tmp/shutdown"

#Configuration file for transfer [ Call it a File Transfer Rule ].
#Any change in this file structure will require change in script in CHECK_AND_TRANSFER function
#FORMAT: 
#FirstColumn|SecondColumn|ThirdColumn|ForthColumn|FifthColumn|SixthColumn
#Source Path|Source File Name|Target Path|Target File Name|Target Host|Target User
export CONFIG_FILE="/opt/infpcuscgtsld/ISGHub/TRANSFER_RULES.cfg"

#Source the Library Functions
. ${SCRIPT_ROOT}/libFunctions

HELP()
{
        echo "USAGE:  ${PROGRAM} [OPTIONS]"
        echo    
        echo "  OPTIONS:"
        echo "          -f Remove Shutdown flag file" 
        echo "          -v Display Version Information" 
        echo "          -h Display Help for this program"
        echo
        exit 6
}

#########################################
####### PARSE COMMAND LINE OPTIONS ######
#########################################
while getopts ":fvh" OPTION
do
        case ${OPTION} in
                f ) rm -f ${SHUTDOWN};;
                v ) echo "Version: ${VERSION}";;
                h ) HELP;;
                \? ) HELP;;
        esac
done

if [[ -f ${SHUTDOWN} ]]
then
	if [[ $FORCE ]]
	then
		echo "INFO: Shutdown flag [${SHUTDOWN}] found."
		echo "Removing Shutdown flag..."
		rm -f ${SHUTDOWN}
		if [[ $? -ne 0 ]]
		then
			echo "ERROR: Removing shutdown flag."
			echo "ERROR: If you want to forcestart the script, remove the shutdown flag manually."
			exit 1
		else
			echo "INFO: Shutdown flag removal successful"
		fi
	else
		echo "INFO: Confused. Found shutdown flag [${SHUTDOWN}]"
		echo "ERROR: If you want to forcestart the script, remove the shutdown flag."
		echo "Or pass the '-f' option as to the script"
		echo "USAGE: ${PROGRAM} -f"
		exit 2
	fi
fi

if [[ ! -f ${CONFIG_FILE} ]]
then
	echo "ERROR: Configuration File Missing"
	echo "Create the File Transfer configuration file in below format"
	echo "FirstColumn|SecondColumn|ThirdColumn|ForthColumn|FifthColumn|SixthColumn|SeventhColumn"
	echo "Source Path|Source File Name|Target Path|Target File Name|Target Host|Target User|transfer Mode"
	echo "Seventh Column value is either 'live' or any random word or empty"
	echo "Exiting..."
	exit 3
fi

while [[ ! -f ${SHUTDOWN} ]]
do
	if [[ -f ${HALT_FLAG} ]]
	then
		echo "${HALT_FLAG} is present. No file trasnfer will happen until this file is removed"
		echo "Sleeping for ${HALT_SLEEP} Seconds"
		sleep ${HALT_SLEEP}
		continue
	fi

	FILELIST=$(ls -tr ${WATCH_DIR})
	for file in ${FILELIST}
	do
		CHECK_AND_TRANSFER ${file} 2>${LOGDIR}/${file}.$(date '+%Y%m%d%H%M%S').err >${LOGDIR}/${file}.$(date '+%Y%m%d%H%M%S').log &
	done
	sleep ${WATCH_INTERVAL}
done
