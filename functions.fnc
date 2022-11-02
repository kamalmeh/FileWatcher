#!/bin/ksh

###############################
#####  Function Library   #####
###############################

#########################################################################
# ALERT FUNCTION
# Description:   Sends Alert Messages
#########################################################################

SEND_ALERT()
  {
        MSG=$1
        echo "FILE PROCESSING FAILED WITH ERROR MSG: " ${MSG} >> $LOGDIR/$LOGFILE
        echo "FILE $FILENAME.$FILENUM PROCESSING ABORTED" >> $LOGDIR/$LOGFILE
        #exit 1
  }


#########################################################################
# EMAIL FUNCTION
# Description:   Sends Email Messages 
#########################################################################

SEND_EMAIL()
{

echo "Entering email..."
mailx -r $mailFrom -s "$1" -a $3 $mailList <<EOF
$2
EOF
exit 1
}

#########################################################################
# VALIDATE PARMS
# Description:   Validate the script parameters
#########################################################################
VALIDATE_PARMS()
{
	if [[ -z ${TYPE} ]]
	then
		MESSAGE="${MESSAGE} TYPE "
		ERROR=1
	fi
	if [[ -z ${FILENAME} ]] && [[ ${CALLER} == "VPAS" || ${CALLER} == "LCD" || ${CALLER} == "PACT" ]]
	then
		MESSAGE="${MESSAGE} FILENAME "
		ERROR=1
	fi
	if [[ -z ${FILENUM} ]] && [[ ${CALLER} == "VPAS" || ${CALLER} == "LCD" || ${CALLER} == "PACT" ]]
	then
		MESSAGE="${MESSAGE} FILENUM "
		ERROR=1
	fi
	if [[ ${CALLER} == "PACT" ]] 
	then
		if [[ -z ${DATE} ]]
		then
			MESSAGE="${MESSAGE} DATE "
			ERROR=1
		fi
	fi

	if [ "${FILENUM}" == '' ]; then
  		export FILENUM="01"
  		echo "Defaut value of second parameter is : $FILENUM" >> $LOGDIR/$LOGFILE
	fi

	if [ "${ERROR}" -eq 1 ]; then
  		echo "Error:PARAMETERS MISSING [ ${MESSAGE} ]" >> ${LOGDIR}/${PROGRAM}_${FILEID}.NOPARMS.${PID}.log
		SEND_ALERT "NO PARAMETERS WERE PASSED TO THE SCRIPT"
		SEND_EMAIL "ERROR: During processing of the file - $FILENAME.$FILENUM" "Please check the attached log file for further details." $LOGDIR/${PROGRAM}_${FILEID}.NOPARMS.${PID}.log
		exit 1
	else
		echo "[${CALLER} : Values of parameters passed are: $*]" >> ${LOGDIR}/${LOGFILE}
	fi

}





#########################################################################
# Function Name: FILE_EXISTS
# Description:   Check if the file exists
#########################################################################

# Need to check for file exist in the InBound Dir
FILE_EXISTS() 
{
  echo "Checking for FILE EXISTS"

  if [[ ${CALLER} == "SE2VAL" ]]
  then
	  EXT=".zip"
  elif [[ ${CALLER} == "PACT" ]]
  then
	  EXT=""
  elif [[ ${CALLER} == "SE2RECON" ]]
  then
	  EXT=".csv"
  elif [[ ${CALLER} == "LCD" ]]
  then
	  cp ${INBOUNDDIR}/${FILENAME}*ctl ${INBOUNDDIR}/${FILENAME}.ctl
	  cp ${INBOUNDDIR}/${FILENAME}*csv ${INBOUNDDIR}/${FILENAME}.csv
  	  EXT=".ctl"
  else
	  EXT=".done"
  fi

  if  [[ ! -f $INBOUNDDIR/${FILENAME}${EXT} ]]
  then
    echo "Error:SourceFile does not exist in the Inbound Dir" 
	SEND_ALERT "SOURCEFILES DOESNOT EXISTS IN INBOUND DIR - $INBOUNDDIR "
        SEND_EMAIL "ERROR: During processing of the file : $FILENAME.$FILENUM" "Please check the attached log file for further details." $LOGDIR/$LOGFILE
  else 
    echo "File Exists...Continuing">> $LOGDIR/$LOGFILE
    return 0
  fi
}


#########################################################################
# Function Name: ARCHIVE FILE
# Description:   Copy the incoming file to Archive
#########################################################################
ARCHIVE_FILE()
  {

  echo "Starting the Archival process to copy the files to archive Dir"

  if [[ ${CALLER} == "SE2VAL" ]]
  then
	  EXT=".zip"
	  COMPEXT=".zip"
  elif [[ ${CALLER} == "PACT" ]]
  then
	  FILENAME="PACT-DAILYCONTRACTS."${DATE}
	  EXT=".tar"
	  COMPEXT=".tar"
  elif [[ ${CALLER} == "SE2RECON" ]]
  then
	  EXT=".csv"
	  COMPEXT=".csv"

  elif [[ ${CALLER} == "LCD" ]]
  then
	  if [[ ${FILENAME#*".tar"} != ${FILENAME} ]]
	  then
		EXT=""
	  else
	  	EXT=".ctl"
		COMPEXT=".csv"
	  fi
#elif [[ ${CALLER} == "LCD" ]]
#then
#	  FILENAME=$1
#	  EXT=""
#	  COMPEXT=".tar"
  else
	  EXT=".done"
	  COMPEXT=".tar"
  fi

  cp ${INBOUNDDIR}/${FILENAME}${EXT} ${ARCHIVEDIR}/${FILENAME}.${PID}${EXT}
  cp ${INBOUNDDIR}/${FILENAME}${COMPEXT} ${ARCHIVEDIR}/${FILENAME}.${PID}${COMPEXT}
 
 if  [[ ! -f "$ARCHIVEDIR/${FILENAME}.${PID}${EXT}" ]]
  then
    echo "Error:The Files cannot be archived " 
	SEND_ALERT "FILES DID NOT COPIED TO THE ARCHIVE DIR - $ARCHIVEDIR"
        SEND_EMAIL "ERROR: During processing of the file : $FILENAME.$FILENUM" "Please check the attached log file for further details." $LOGDIR/$LOGFILE    
   return -1
  else 
    echo "Files Copied to Archive Dir...Continuing">> $LOGDIR/$LOGFILE
    return 0
  fi 
  return

 }
  
#########################################################################
# Function Name: COPY_TO_TEMP
# Description:   Copy the incoming file to Temp Dir
#########################################################################  
 COPY_TO_TEMP()
 {
  echo "Copying the files to Temp Dir for the file validation"
  if [[ ${CALLER} == "SE2VAL" ]]
  then
	  EXT=".zip"
	  COMPEXT=".zip"
  elif [[ ${CALLER} == "SE2RECON" ]]
  then
	  EXT=".csv"
	  COMPEXT=".tar"
  #elif [[ ${CALLER} == "PACT" ]]
  #then
  #	  EXT=""
  #	  COMPEXT=""
  elif [[ ${CALLER} == "LCD" ]]
  then
	  if [[ ${FILENAME#*".tar"} != ${FILENAME} ]]
	  then
		EXT=""
	  else
	  	EXT=".ctl"
		COMPEXT=".csv"
	  fi
  else
	  EXT=".done"
	  COMPEXT=".tar"
  fi

  cp ${INBOUNDDIR}/${FILENAME}${EXT} ${TEMPDIR}
  cp ${INBOUNDDIR}/${FILENAME}${COMPEXT} ${TEMPDIR}
 
  if  [[ ! -f "$TEMPDIR/${FILENAME}${EXT}" ]]
  then
    echo "Error:The Files does not exists in the Temp Dir " 
	SEND_ALERT "FILES DID NOT COPIED TO THE TEMP DIR FOR FILE VALIDATION- $TEMPDIR"
        SEND_EMAIL "ERROR: During processing of the file : $FILENAME.$FILENUM" "Please check the attached log file for further details." $LOGDIR/$LOGFILE
    #return -1
  else 
    echo "Files Copied to TEMP Dir for file validation Process...Continuing">> $LOGDIR/$LOGFILE
    #return 0
  fi 
  #return
  }


#########################################################################
# Function Name: DECOMPRESS_FILE
# Description:   DEcompress the file in Temp Dir for file validations
#########################################################################

DECOMPRESS_FILE()
{
 
  echo "Starting decompression of file..."
  if [[ ${CALLER} == "SE2VAL" ]]
  then
	  EXT=".zip"
	  COMPEXT=".zip"
	  UNCOMPRESS_CMD="`which unzip`"
  	  ${UNCOMPRESS_CMD} -o ${TEMPDIR}/${FILENAME}${COMPEXT} -d ${TEMPDIR} > /dev/null  2>&1
	  EXTRACTED_FILENAME=$(find $TEMPDIR -name 'vbas*')
	  EXTRACTED_FILENAME=${EXTRACTED_FILENAME##*/}
  elif [[ ${CALLER} == "LCD" ]]
  then
	  EXT=".ctl"
	  COMPEXT=""
	  UNCOMPRESS_CMD="`which tar`"
  	  ${UNCOMPRESS_CMD} -C ${TEMPDIR} -xf ${TEMPDIR}/${FILENAME}${COMPEXT} > /dev/null  2>&1
  else
	  EXT=".done"
	  COMPEXT=".tar"
	  UNCOMPRESS_CMD="`which tar`"
  	  ${UNCOMPRESS_CMD} -C ${TEMPDIR} -xf ${TEMPDIR}/${FILENAME}${COMPEXT} > /dev/null  2>&1
  fi



  if [[ $? -ne 0 ]]
   then
    echo "Error:Unable to Decompress File $FILENAME .tar" 
	SEND_ALERT "FILES DID NOT DECOMPRESS IN THE TEMP DIR - $TEMPDIR"
        SEND_EMAIL "ERROR: During processing of the file : $FILENAME.$FILENUM" "Please check the attached log file for further details." $LOGDIR/$LOGFILE
    return -1
  else 
    echo "Decompressing of the tar file is completed...Continuing">> $LOGDIR/$LOGFILE
    return 0
  fi
  return
  }

#########################################################################
# Function Name: VALIDATE_FILE
# Description:   Validate the actual file(.csv and .ctl)
########################################################################

VALIDATE_FILE()
{
	echo "Starting the file validation process for Se2 file"
	if [[ ${CALLER} == "SE2VAL" ]]
	then
		echo "Checking the file validity of the se2 file... "

		LASTLINE=$(tail -1 $TEMPDIR/$EXTRACTED_FILENAME | head -1)
		SPLITLINE=($(echo $LASTLINE | tr '~' '\n'))
		SPLITLINECUT=${LASTLINE##*~}
		RECORD_COUNT=$(echo $SPLITLINECUT | xargs)
		RECORD_COUNT=$(echo $RECORD_COUNT | sed 's/[^0-9]*//g')
		LINE_COUNT=$(cat $TEMPDIR/$EXTRACTED_FILENAME | wc -l)

		if [[ $RECORD_COUNT = $LINE_COUNT ]]
		then
			echo "File passed: $EXTRACTED_FILENAME"
			return 0
		fi
		echo "File did not pass verification test: $1"
		exit 1
	fi

#echo "Checking the byte count on the control file and detail file"

#sed -i 's/ *, */,/g' $TEMPDIR/$FILENAME*".ctl"
#ctrl_byte=`cat $TEMPDIR/$FILENAME*".ctl" |grep csv |cut -f3 -d,`
#file_byte=`cat $TEMPDIR/$FILENAME*".csv"|wc -c`

#if [[ $ctrl_byte = $file_byte ]]
# then
#   echo "Byte Count of the detail and control files matched"
#  else
#   echo "Error:Byte count of the control and detail files do not match "
# SEND_ALERT "BYTE COUNT OF THE FILE DO NOT MATCH WITH THE BYTE COUNT ON THE CONTROL FILE"
#  SEND_EMAIL "ERROR: During processing of the file : $FILENAME.$FILENUM" "Please check the attached log file for further details." $LOGDIR/$LOGFILE
#fi

echo "Checking the hash value on the control file and detail file"

sed -i 's/ *, */,/g' $TEMPDIR/$FILENAME*".ctl"
ctrl_hash=`cat $TEMPDIR/$FILENAME*".ctl" |grep csv |cut -f4 -d,`
file_hash=`/usr/bin/openssl dgst -sha256 $TEMPDIR/$FILENAME*".csv"|awk '{print $2}'`

if [[ $ctrl_hash = $file_hash ]]
 then
   echo "Hash value of the detail and control files matched"
  else
   echo "Error:Hash Value of the control and detail files do not match "
   SEND_ALERT "HASH VALUE OF THE FILE DO NOT MATCH WITH THE HASH VALUE ON THE CONTROL FILE"
   SEND_EMAIL "ERROR: During processing of the file : $FILENAME.$FILENUM" "Please check the attached log file for further details." $LOGDIR/$LOGFILE
fi

echo "Checking for the row count on the control and detail file"

 ctl_rc=`cat $TEMPDIR/$FILENAME*".ctl" | awk -F, '(NR==2){print $2}'`
 rc=`cat $TEMPDIR/$FILENAME*".csv" | wc -l`

if [[ $ctl_rc -eq  $rc  ]]
 then
  echo "Row count of the detail and control files matched" 
 else
   echo "Error:Row count of detail and control files do not match" 
   SEND_ALERT "ROW COUNT OF THE DETAIL AND CONTROL FILE DO NOT MATCH"
   SEND_EMAIL "ERROR: During processing of the file : $FILENAME.$FILENUM" "Please check the attached log file for further details." $LOGDIR/$LOGFILE
fi

echo "Checking for the Header and Footer exist in the the file"
  
  headercheck=`head -1 $TEMPDIR/$FILENAME*".csv"| cut -d"," -f1`
  footercheck=`tail -1 $TEMPDIR/$FILENAME*".csv"| cut -d"," -f1`

if [ "$headercheck" -eq 0 ];
 then
    echo "Header Record found in the detail file" >> $LOGDIR/$LOGFILE
  else
    echo "Error:Header Record  in the detail file not found" 
    SEND_ALERT "Error:HEADER RECORD NOT FOUND IN THE DETAIL FILE"
    SEND_EMAIL "ERROR: During processing of the file : $FILENAME.$FILENUM" "Please check the attached log file for further details." $LOGDIR/$LOGFILE
fi

if [ "$footercheck" -eq 9 ];
then
  echo "Footer Record found in $detail file" >> $LOGDIR/$LOGFILE
else
  echo  "Error:Footer Record in the detail file not found"  
  SEND_ALERT "Error:FOOTER RECORD NOT FOUND IN THE DETAIL FILE"
  SEND_EMAIL "ERROR: During processing of the file : $FILENAME.$FILENUM" "Please check the attached log file for further details." $LOGDIR/$LOGFILE
fi

return 0 	

}

#########################################################################
# Function Name: COPY_TO_SRC
# Description:   Move the files from TEMPDIR to SRCDIR and remame to generic naming removing the date in the file names.
#########################################################################

COPY_TO_SRC()
{
	if [[ ${CALLER} == "SE2VAL" ]]
	then
		cp $TEMPDIR/$1 $SRCFILEDIR/${RENAME_TARGET:-$2}
		RC=$?
	elif [[ ${CALLER} == "SE2RECON" ]]
	then
		cp ${TEMPDIR}/${FILENAME}.csv $SRCFILEDIR/$FILENAME.csv
		RC=$?
	#elif [[ ${CALLER} == "PACT" ]]
	#then
	#	cp ${TEMPDIR}/${FILENAME} $SRCFILEDIR/$FILENAME
	#	RC=$?
	elif [[ ${CALLER} == "VPAS" ]]
	then
		cp $TEMPDIR/$FILENAME*.csv $SRCFILEDIR/$FILENAME.csv
                echo ${FILENAME}.csv > $SRCFILEDIR/${SOURCE}_${FILEID}_I.lst
		RC=$?
  	else
		cp $TEMPDIR/$FILENAME*.csv $SRCFILEDIR/$FILENAME.csv
		RC=$?
		#cp  $TEMPDIR/$FILENAME*".ctl" $SRCFILEDIR/$FILENAME.ctl
  	fi

	if  [[ ${RC} -ne 0 ]]
	then
		echo "Error:Source Files did not copied to the SRC DIR - $SRCFILEDIR" >> $LOGDIR/$LOGFILE
		SEND_ALERT "Error:SOURCEFILE DID NOT COPIED TO THE SRCFILE DIR - $SRCFILEDIR"
        	SEND_EMAIL "ERROR: During processing of the file : $FILENAME.$FILENUM" "Please check the attached log file for further details." $LOGDIR/$LOGFILE 
		return -1
	else 
		echo "File Exists in the SrcFile Dir...Continuing">> $LOGDIR/$LOGFILE
		return 0
	fi

#rm -rf $TEMPDIR/*	
}

#########################################################################
# Function Name: BUILD_PARM_FILE
# Description:   Run ETL processing for the specified file
#########################################################################

BUILD_PARM_FILE()
{

  echo "Start build of parameter file for ${FILEID}..."

  if [[ ${CALLER} == "SE2VAL" ]]
  then
	  FILENAME=$1
	  #export ADMIN_PROC_DT=$(date -d "$(date -d "$(date -d "next month" "+%Y%m" )01") - 1 day" "+%Y%m%d")	
          export ADMIN_PROC_DT=$(head -1 ${SRCFILEDIR}/${SE2_BC}.csv | cut -d~ -f5 | sed -e "s/\"//g" -e "s/\///g")
	  export FILE_CRT_DT=$(date '+%Y%m%d')
	  export FILE_CRT_TM=$(date '+%H%M%S')
	  export FILENAME=SE2.ISGHUB.BASICCONTRACT
	  EXT=".csv"
  elif [[ ${CALLER} == "SE2RECON" ]]
  then
	  #export ADMIN_PROC_DT=$(cal |  awk 'NF {DAYS = $NF}; END {print DAYS}')
	  #export ADMIN_PROC_DT=$(date -d "$(date -d "$(date -d "next month" "+%Y%m" )01") - 1 day" "+%Y%m%d")
	  export FILE_CRT_DT=$(date '+%Y%m%d')
	  export FILE_CRT_TM=$(date '+%M%S')
	  EXT=".csv"
  else
  	  export ADMIN_PROC_DT=$(head -1 ${SRCFILEDIR}/${FILENAME}.csv | cut -d, -f4 | sed -e "s/\"//g" -e "s/\///g")
  	  export FILE_CRT_DT=$(head -1 ${SRCFILEDIR}/${FILENAME}.csv | cut -d, -f5 | sed -e "s/\"//g" -e "s/\///g")
  	  export FILE_CRT_TM=$(head -1 ${SRCFILEDIR}/${FILENAME}.csv | cut -d, -f6 |  sed -e "s/\"//g")
	  EXT=".csv"
  fi
  
  cat ${PARAMDIR}/ISGHub_COMMON.parm ${PARAMDIR}/ISGHub_WF_PROCESS_SOURCE_FEED.parmt | \
     sed -e "s/%FEED_ID%/${FILEID}/g" \
         -e "s/%FILE_NUM%/${FILENUM}/g" \
         -e "s/%FILE_CREATE_DT%/${FILE_CRT_DT}/g" \
         -e "s/%FILE_CREATE_TM%/${FILE_CRT_TM}/g" \
         -e "s/%SRC_SYS_CD%/${SOURCE}/g" \
         -e "s/%ADMIN_PROC_DT%/${ADMIN_PROC_DT}/g" \
         -e "s/%SRC_FILE_NAME%/${FILENAME}.csv/g" \
         -e "s/%PROCESS%/${PROCESS}/g" \
		 -e "s/%ERR_THRESHOLD%/${ERR_THRESHOLD}/g" \
      > ${PARAMDIR}/ISGHub_WF_${PROCESS}_${SOURCE}_${FILEID}.parm


  if  [[ ! -f $PARAMDIR/ISGHub_WF_${PROCESS}_${SOURCE}_${FILEID}.parm ]]
  then
    echo "Error:Parameter file did not get created in param dir - $PARAMDIR" >> $LOGDIR/$LOGFILE
	SEND_ALERT "Error:PARAMETER FILE DID NOT GET CREATED IN THE PARAM DIR - $PARAMDIR"
        SEND_EMAIL "ERROR: During processing of the file : $FILENAME.$FILENUM" "Please check the attached log file for further details." $LOGDIR/$LOGFILE
  return -1
  else 
    echo "Parameter file is created ...Continue with ETL Process">> $LOGDIR/$LOGFILE
    return 0
  fi

   return  	

rm -rf $TEMPDIR/*

}


#########################################################################
# Function Name: RUN_ETL
# Description:   Run ETL processing for the specified file
#########################################################################

RUN_ETL()
{

  echo "Start Informatica processing... "

   export WORKFLOW=wf_${PROCESS}_${SOURCE}_${FILEID}
   export PARMFILE=ISGHub_WF_${PROCESS}_${SOURCE}_${FILEID}.parm
   export INFA_PROJ_FOLDER=ANN_TSL_${PROCESS}
 
  echo "Running Informatica - with parm file"
  ${INFA_BIN_ROOT}/pmcmd startworkflow -d ${INFA_DOMAIN} -sv ${INFA_INTG_SRVC} -u ${INFA_PRJ_OPERATOR_ACCOUNT} -pv INFA_PRJ_OPERATOR_ACCOUNT_PASSWORD \
    -f ${INFA_PROJ_FOLDER} -usd ${INFA_SECURITY_DOMAIN} -paramfile ${PARAMDIR}/${PARMFILE} -wait ${WORKFLOW} > \
      ${LOGDIR}/${ME}.${WORKFLOW}.${PID}.log 2>&1

  rc=$?

  if [[ $rc != 0 ]]; then

   echo "Return Code_fail                : " $rc
   echo "Failed in executing the workflow: " ${WORKFLOW}
   echo "Please refer to the Informatica Workflow monitor for more details."
   echo "Informatica Domain              : " ${INFA_DOMAIN}
   echo "Informatica Integration Service : " ${INFA_INTG_SRVC}
   echo "Informatica Operator id         : " ${INFA_PRJ_OPERATOR_ACCOUNT}
   echo "Informatica Folder              : " ${INFA_PROJ_FOLDER}
   echo "Informatica Workflow Name       : " ${WORKFLOW}
   echo "Return Code                     : " $rc
   echo "ETL job failed to run, please check the Informatica session log for detail errror information"
   SEND_ALERT "ETL JOB FAILED TO RUN.PLEASE CHECK THE INFORMATICA SESSION LOG FOR DETAIL ERROR INFORMATION"
   SEND_EMAIL "ERROR: During processing of the file : $FILENAME.$FILENUM" "Please check the attached log file for further details." $LOGDIR/$LOGFILE
   exit 1
  else
   echo "Return Code_succ:$rc"
   echo "Execution of the workflow $WFLW_NAME completed Successfully"
   echo "Informatica Domain              : ${INFA_DOMAIN}"
   echo "Informatica Integration Service : ${INFA_INTG_SRVC}"
   echo "Informatica Operator id         : ${INFA_PRJ_OPERATOR_ACCOUNT}"
   echo "Informatica Folder              : ${INFA_PROJ_FOLDER}"
   echo "Informatica Workflow Name       : ${WORKFLOW}"

   echo "Return Code:$rc"
#####   exit 0
  fi

   return $rc

}


#########################################################################
# CREATE_FILE_LIST
# Description:   Create a file list for the PACT Files
#########################################################################

CREATE_FILE_LIST()
{
	if [[ ${CALLER} == "PACT" ]]
	then
		ls -1tr ${CALLER}*.csv* > ${INBOUNDDIR}"/PACT_DAILYCONTRACTS.lst"    
	fi

  if  [[ ! -f $INBOUNDDIR/PACT_DAILYCONTRACTS.lst ]]
  then
    echo "Error: Pact list file did not get created in the Inbound Dir- $INBOUNDDIR" 
	SEND_ALERT "PACT LIST FILE DID NOT GET CREATED IN THE SRCFILE DIR - $INBOUNDDIR"
    SEND_EMAIL "ERROR: During processing of the file : $FILENAME.$FILENUM" "Please check the attached log file for further details." $LOGDIR/$LOGFILE
  else 
    echo "Pact List File Exists...Continuing">> $LOGDIR/$LOGFILE
    return 0
  fi


}


#########################################################################
# Function Name: GET_ERROR_THRESHOLD
# Description:   Determine length of file
#                Prepare a variable for addition to the parameter file 
#                Set variable to a 5% level 
#                After that level, a notification will be sent via the workflow process
#########################################################################

GET_ERROR_THRESHOLD()
{
echo "Computing Error Threshold" >> $LOGDIR/$LOGFILE

if [[ $# -ne 0 ]]
then
	FILENAME=$1
	EXT=""
	else
	 EXT=".csv"
fi

# set percentage to 5 % of rows
export THRESH_PCT=`echo "scale=2; 5/100" |bc`

#get number of source file rows, it includes header and trailer
export ROWS=`wc -l < $SRCFILEDIR/$FILENAME.csv`

# get the floating point value for the number of rows in the threshold
export ET=`expr "$ROWS * $THRESH_PCT" |bc`

# convert to integer
export ERR_THRESHOLD=${ET%.*}

return

}

#########################################################################
# CLEAR THE TEMP DIR
# Description:   Clear the temp dir
#########################################################################
CLEAR_TEMP()
{
echo "Starting To clear the Temp Dir..."
  if [[ ${CALLER} == "SE2VAL" ]]
  then
	  cd $TEMPDIR
	  rm vsub*.txt
          rm vint*.txt
          rm vprb*.txt
	  rm vbas*.txt
          rm PRU2*.TXT
          rm Se2_avis_valuations*.zip
  else  
	  cd $TEMPDIR
	  rm $FILENAME*
     fi
  return
 
}

#########################################################################
# Function Name: TRANSFER
# Description:  It initiates the transfer
#########################################################################
TRANSFER()
{
	if [ $# != 6 ]; then
        	echo "Incorrect parameter passed to the function TRANSFER" 
		echo "USAGE: TRANSFER <sourcePath> <sourceFile> <targetPath> <targetFile> <targetHost> <targetUser> <targetMode>"
        	exit 4
	fi
	sourcePath=$1
	file=$2
	targetPath=$3
	targetFile=$4
	targetHost=$5
	targetUser=$6
	echo "CFSEND Process .............................................: Started" #>> /tmp/mail
	echo "Source path is .............................................: ${sourcePath}" #>> /tmp/mail
	echo "Source file is .............................................: ${file}" #>> /tmp/mail
	echo "Target path is .............................................: ${targetPath}" #>> /tmp/mail
	echo "Target file is .............................................: ${targetFile}" #>> /tmp/mail
	echo "Target server is ...........................................: ${targetHost}" #>> /tmp/mail
	echo "/CyberFusion/cfsend lf:${sourcePath}/${file} rf:${targetPath}/${targetFile} CR:${targetUser} ip:${targetHost}" #>> /tmp/mail
	/CyberFusion/cfsend lf:${sourcePath}/${file} rf:${targetPath}/${targetFile} CR:${targetUser} ip:${targetHost} #>> /tmp/mail
	if [[ $? != 0 ]]
        then
		echo "CFSEND Status .............................................: Failure" #>> /tmp/mail
		mailx -s "${file} PROBLEM Sending file ${sourcePath} to ${targetPath}" ${MAIL} < ${LOGFILE} #/tmp/mail
		#rm -f /tmp/mail
		return 5
        else
		echo "CFSEND Status .............................................: Success"
		rm -f ${file}
		#rm -f /tmp/mail
	fi
}

#########################################################################
# Function Name :CHECK_HALT_FILE
# Description   :Check if HALT_TRANSFER* flag is available for FILENAME
# Arguments     :FILENAME
#########################################################################
CHECK_HALT_FLAG()
{
	SOURCE=$1
	file=$2
	FEED_ID=$(echo ${SOURCE} | cut -d"." -f3)
	HALT_FLAG=${HALT_TOKEN}_${SOURCE}_${FEED_ID}
	echo -e "Checking if there is HALT flag available for [${file}] - \c"
	if [[ -f "${CNTLDIR}/${HALT_FLAG}" ]]
	then
		echo "[FOUND]"
		echo "Ignoring the transfer of file ${file}"
		return 12
	fi
	echo "[NOT FOUND]"
}

#########################################################################
# Function Name: CONFIG_CHECK
# Description:  This function checks the file in configuration 
# Argument:	FILENAME
#########################################################################
CONFIG_CHECK()
{
	file=$1
	exec < ${CONFIG_FILE} 
	while read line
	do
		patt=$(echo ${line} | cut -d"|" -f2)
		for item in $(ls -1 ${OUTBOUNDDIR}/${patt} 2>/dev/null)
		do
			test="${OUTBOUNDDIR}/${file}"
			if [[ ${item} == ${test} ]]
			then
				source=$(echo ${line} | cut -d"|" -f1)
				detailFile=${item}
				controlFile="${item}.ctl"
				targetPath=$(echo ${line} | cut -d"|" -f3)
				targetFile=$(echo ${line} | cut -d"|" -f4)
				targetHost=$(echo ${line} | cut -d"|" -f5)
				targetUser=$(echo ${line} | cut -d"|" -f6)
				CHECK_HALT_FLAG ${source} ${detailFile}
				TRANSFER ${source} ${detailFile} ${targetPath} ${targetFile} ${targetHost} ${targetUser}
				RC=$?
				if [[ ${RC} -ne 0 ]]
				then
					echo "Transfer Failure - ${detailFile} to ${targetHost}"
					return ${RC} 
				fi
				TRANSFER ${source} ${controlFile} ${targetPath} "${targetFile}.ctl" ${targetHost} ${targetUser}
				RC=$?
				if [[ ${RC} -ne 0 ]]
				then
					echo "Transfer Failure - "${controlFile}" to ${targetHost}"
					return ${RC}
				fi
			fi
		done
	done
	return ${RC}
}

#########################################################################
# Function Name	:FILE_EXISTS_OB
# Description	:Check if the file exists in Outbound Directory
# Arguments	:FILENAME
#########################################################################
FILE_EXISTS_OB()
{
	file=$(find ${OUTBOUNDDIR} -type f -name $1)
	echo -e "Checking File Existance [${OUTBOUNDDIR}/${file}*] - \c"
	if [[ ! -f "${OUTBOUNDDIR}/${file}" ]]
	then
		echo "[Not Found]"
		return 8
	fi
	echo "[SUCCESS]"
	return 0
}

#########################################################################
# Function Name :CREATE_CTL_FILE
# Description   :Create Control file in Outbound Directory
# Arguments     :FILENAME
#########################################################################
CREATE_CTL_FILE()
{
        file=$1
	CONTROLFILE="${OUTBOUNDDIR}/${file}.ctl"
	file=${OUTBOUNDDIR}/${file}
        echo -e "Creating Control File [${CONTROLFILE}] - \c"
	if [[ -f ${file} ]]
	then
		SYSTEM=`echo $file | cut -d"." -f1`
		TRANSACT=`echo $file | cut -d"." -f2`
		CURDT=`echo $file | cut -d"." -f3`
		F_SIZE=`wc -l $file|awk '{print $1}'`
		TR_CNT=0
		TR_CNT=`expr $TR_CNT + 1`
		HSH_TL=`/usr/bin/openssl dgst -sha256 $file|awk '{print $2}'`
		echo "H,$DATETIMESTAMP,$SYSTEM,$TRANSACT,$CURDT," > ${CONTROLFILE}
		echo "$file,$F_SIZE,$HSH_TL," >> ${CONTROLFILE}
		echo "T,$TR_CNT," >> ${CONTROLFILE}
        	if [[ ! -f "${CONTROLFILE}" ]]
        	then
                	echo "[FAILED]"
                	return 9
        	fi
		echo "[SUCCESS]"
		return 0
	fi
	echo "[NOT CREATED]"
	return 0
}

#########################################################################
# Function Name :ARCHIVE_OB
# Description   :Archive file from Outbound Directory to Archive Directory
# Arguments     :FILENAME
#########################################################################
ARCHIVE_OB()
{
        file=$1
        echo -e "Archiving Control File [${OUTBOUNDDIR}/${file}.ctl] - \c"
        cp "${OUTBOUNDDIR}/${file}.ctl" "${ARCHIVEDIR}/${file}.ctl"
        if [[ $? -ne 0 ]]
        then
                echo "[FAILED]"
                return 10
        fi
	echo "[SUCCESS]"
        echo -e "Archiving Detail File [${OUTBOUNDDIR}/${file}] - \c"
        cp "${OUTBOUNDDIR}/${file}" "${ARCHIVEDIR}/${file}"
        if [[ $? -ne 0 ]]
        then
                echo "[FAILED]"
                return 11
        fi
	echo "[SUCCESS]"
	return 0
}

