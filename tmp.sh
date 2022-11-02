CREATE_CTL_FILE()
{
HOME=`pwd`
cd $TEMPDIR
echo $1
files=`cat $1`
for file in $files
do
echo "FILE $file"
CONTFILENAME=${file%.*}
CONTROLFILE="$CONTFILENAME".ctl
SYSTEM=`echo $file | cut -d"." -f1`
TRANSACT=`echo $file | cut -d"." -f2`
CURDT=`echo $file | cut -d"." -f3`
F_SIZE=`wc -l $file|awk '{print $1}'`
#F_BYTE=`wc -c < $file`
TR_CNT=0
TR_CNT=`expr $TR_CNT + 1`
HSH_TL=`/usr/bin/openssl dgst -sha256 $file|awk '{print $2}'`
echo "H,$DATETIMESTAMP,$SYSTEM,$TRANSACT,$CURDT," > $CONTROLFILE
#echo "$file,$F_SIZE,$F_BYTE,$HSH_TL," >> $CONTROLFILE
echo "$file,$F_SIZE,$HSH_TL," >> $CONTROLFILE
echo "T,$TR_CNT," >> $CONTROLFILE
if [ $? -ne 0 ]
then
echo "ERROR: Unable to create $CONTROLFILE control file" >> ${LOGDIR}/${LOGFILE}
SEND_ALERT "Unable to create $CONTROLFILE control file"
SEND_EMAIL "ERROR: During creating of the control file." "Please check the attached log file for furthur details." $LOGDIR/${LOGFILE}
else
echo "Successfully created $CONTROLFILE control file" >> ${LOGDIR}/${LOGFILE}
fi
ARCHIVE_FILES $file $CONTROLFILE $CONTFILENAME
COPY_TO_OUTBOUND $file $CONTROLFILE
done		
cd $HOME
}
