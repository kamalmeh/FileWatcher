#!/bin/bash
#HALT_TOKEN is used to hold the trasnfer for all or particular file
export HALT_TOKEN="HALT_TRANSFER"
#Flag to shutdown the script normally
#Create below flag if you want to shutdown the script.
export SHUTDOWN="/var/tmp/shutdown"
#Configuration file for transfer [ Call it a File Transfer Rule ].
#Any change in this file structure will require change in script in CHECK_AND_TRANSFER function
#FORMAT: 
#FirstColumn|SecondColumn|ThirdColumn|ForthColumn|FifthColumn|SixthColumn|SeventhColumn
#Source|Source File Name|Target Path|Target File Name|Target Host|Target User|live or empty
export INBOUNDDIR="/opt/infpcuscgtsld/ISGHub/Inbound"
export OUTBOUNDDIR="/opt/infpcuscgtsld/ISGHub/Outbound"
export CONFIGDIR="/opt/infpcuscgtsld/ISGHub/Config"
export TEMPDIR="/opt/infpcuscgtsld/ISGHub/Temp"
export LOGDIR="/opt/infpcuscgtsld/ISGHub/Log"
export SRCFILEDIR="/opt/infpcuscgtsld/ISGHub/SrcFile"
export ARCHIVEDIR="/opt/infpcuscgtsld/ISGHub/Archive"
export SCRIPTSDIR="/opt/infpcuscgtsld/ISGHub/Scripts"
export CNTLDIR="/opt/infpcuscgtsld/ISGHub/Cntl"
export CONFIG_FILE="${CONFIGDIR}/TRANSFER_RULES.cfg"

## MAIL CONFIGURATION
MAIL=user@domain.com
