#!/bin/bash

#################################################################################################################
######    Script which automates the task of Pre Health check for rpd deployment - OBIEE                        
#Name           :       hc_generic.sh                                                                             
#Usage          :       script can be called internally though server or using ATOM 2.0
#
#
#Author         :       Anuj Kumar Singh
#Modified       :       24-12-2018
#Created        :       16-08-2018
#Descrition     :  This script automate Pre Health check task , it can be used as independent script or can
#                  be clubbed in ATOM 2.0 workflow as set of tasks.
#                  NOTE: Any front end health check is not included in script please perform it manaully.
#
#    *** DO NOT MAKE ANY CHANGES IN SCRIPT WITHOUT APPROVAL OF AUTHOR  ***
#################################################################################################################

send_mail ()
{
if [ $exit_Code -eq 0 ]
then
  echo
  echo "Health Check Success"| mail -s "Health Check Completed successfully: $instance" $email
else
  echo
  echo "Health Check Failed"| mail -s "Health Check Failed !!: $instance" $email
fi
}

exit_Function ()
{
#rm -f /$instance/oraclebi/rpd_deployment_lock.lck
send_mail
exit $exit_Code  #THERE IS ONLY TWO EXIT CODE 1 AND 0
}

checkuser ()
{
user=`whoami`
if [ "$user" = "sb$instance" ]
then
        sleep 3
        echo "===================================================="|tee -a $LOG_FILE
        echo "[INFO]:[`date +%T`]:SB USER DETECTED SUCCESSFULLY"|tee -a $LOG_FILE
        echo "===================================================="|tee -a $LOG_FILE
else
        echo "[WARNING]:[`date +%T`]:Run Script using sb user"|tee -a $LOG_FILE
        exit 1 #FAILURE EXIT
fi
}

usage ()
{
echo 'Usage : '
echo 'To Start RPD Automation: ./RPD_WRAPPER_HC.sh <INSTANCE_SID>'
echo "==============================================="|tee -a $LOG_FILE
echo "SCRIPT EXECUTION FAILED DUE TO BAD USER INPUT"|tee -a $LOG_FILE
echo "==============================================="|tee -a $LOG_FILE
echo "[WARNING][`date +%T`]: ABBORTING EXECUTION"
count=0
while [ $count -le 10 ]
do
    echo -ne ". "
    sleep 1
    ((count++))
    #count=$((count+1))
done
exit_Code=1
exit_Function
}

housekeeping ()
{
if [ ! -d "/tmp/RPD_deployment_logs" ]
then
        mkdir "/tmp/RPD_deployment_logs"
        chmod 777 "/tmp/RPD_deployment_logs"
fi
export time_Stamp=`date +%d-%b-%Y`
chmod 777 "/tmp/RPD_deployment_logs"
touch /tmp/RPD_deployment_logs/pre_Health_check_$time_Stamp.log
LOG_FILE=/tmp/RPD_deployment_logs/pre_Health_check_$time_Stamp.log
echo -n > $LOG_FILE
echo "==============================================================================="
echo "Log Files Location : $LOG_FILE"
echo "==============================================================================="
echo
}


# Get OBIEE Instances
get_obi_instances ()
{
index=0
if [ ! -z "$instance" ]
then
        echo "[INFO]:[`date ++%T`]:Determining the OBIEE instances hosted on this server.."|tee -a $LOG_FILE
        obi_Mount=(`df -hP|grep -ow "/.....3/oraclebi"`)
        obi_Mount_Exa=(`df -hP|grep -ow "/.....3/exalytics"`)
        if [ ${#obi_Mount_Exa[@]} -ge 1 ]
        then
                echo "[INFO]:[`date ++%T`]:Exalytics OracleBIMounts detected"|tee -a $LOG_FILE
                obi_Mount=${obi_Mount_Exa[*]}
        elif [ ${#obi_Mount[@]} -ge 1 ]
        then
                echo "[INFO]:[`date ++%T`]:Commodity OracleBIMounts detected"|tee -a $LOG_FILE
        else
                echo "[WARNING]:[`date ++%T`]:No OBIEE Instances detected on this host"|tee -a $LOG_FILE
                message='No OBIEE Instances detected on this host'
                output_status='Defied'
                exit_Code=1
                exit_Function
        fi
        for i in ${obi_Mount[*]}
        do
                instance_Name[$index]=`echo $i|cut -d "/" -f2`
                index=`expr $index + 1`
        done

        if [ ${#instance_Name[@]} -eq 1 ]
        then
         echo "[INFO]:[`date ++%T`]:Only one OBIEE Instance Found,Instance Execution will take place in foreground : ${instance_Name[*]}"|tee -a $LOG_FILE
         instance=${instance_Name[*]}
        else
         echo "[INFO]:[`date ++%T`]:Following OBIEE Instances Found : ${instance_Name[*]}"|tee -a $LOG_FILE
        fi
fi
}

informatica_hc()
{
        export USER_NAME;
        echo
        echo "********************************************************************"| tee -a $LOG_FILE
        echo "OBIEE On Demand Health Check for INFORMATICA & DAC Services"| tee -a $LOG_FILE
        echo "Managed Cloud Services Health Check Template"| tee -a $LOG_FILE
        echo "********************************************************************"| tee -a $LOG_FILE
        echo
        echo "Ensure all urls are as mentioned in OMP with status Yes/No/NA"
        echo "[Yes - Performed Successfully, No - Performed but Not Successful, NA - Not Applicable]"

        echo "INFORMATICA AND DAC STATUS:"| tee -a $LOG_FILE
        echo
        echo "[INFO][`date +%T`]: DAC status:"| tee -a $LOG_FILE
        echo
        ps -ef|grep $USER_NAME|grep -w QServer|grep -v grep | tee -a $LOG_FILE
        echo "Checking DAC Client Status:"
        # Client status logic
        echo "[WARNING][`date +%T`]: Client Status Logic Not Available"
        echo
    echo "[INFO][`date +%T`]: Informatica status:"| tee -a $LOG_FILE
    echo
    ps -ef |grep $USER_NAME|grep infrmatica|grep -v grep | tee -a $LOG_FILE
    exit_Code=0 #True exit code
    exit_Function
}

hc_12c ()
{
    echo "====================================================="| tee -a $LOG_FILE
    echo "[INFO]:[`date +%T`]: Discovery Completed Successfully"| tee -a $LOG_FILE
    echo "====================================================="| tee -a $LOG_FILE
    echo
    if ps -ef|grep $USER_NAME|grep 'AdminServer'|grep -v grep > /dev/null 2>&1
    then
        if ps -ef | grep NodeManager|grep -v grep > /dev/null 2>&1
        then
                hc_12c_flag="true"
        else
            hc_12c_flag="false"
            echo "[INFO][`date +%T`]: Adminserver : Up & Running"
            echo "[WARNING][`date +%T`]: NodeManager on 12c Host is not running"
            echo "[WARNING][`date +%T`]: Health Check Could not be captured"
            echo "================================================="
            echo "[WARNING][`date +%T`] Script terminated Abnormally"
            echo "================================================="
            exit_Code=0
            exit_Function
        fi
     else
        hc_12c_flag="false"
        echo "[WARNING][`date +%T`] AdminServer on 12c Host is not running"
        echo "[WARNING][`date +%T`] Health Check Could not be captured"
        echo "================================================="
        echo "[WARNING][`date +%T`] Script terminated Abnormally"
        echo "================================================="
        exit_Code=0
        exit_Function
     fi

    echo "======================================================"
    echo "[INFO][`date +%T`]: Health Check on 12c Components"
    echo "======================================================"
    echo
    if [ -d "/$instance/admin/user_projects/domains/bi_domain/bitools/bin" ]
    then
     script_location="/$instance/admin/user_projects/domains/bi_domain/bitools/bin"
    elif [ -d "/$instance/admin/wlsadmin/user_projects/domains/bi_domain/bitools/bin" ]
    then
     script_location="/$instance/admin/wlsadmin/user_projects/domains/bi_domain/bitools/bin"
   elif [ -d "/$instance/wlsadmin/user_projects/domains/bi_domain/bitools/bin" ]
    then
       script_location="/$instance/wlsadmin/user_projects/domains/bi_domain/bitools/bin"
    elif [ -d "/$instance/wlsadmin/user_projects/domains/bi_domain/bitools/bin" ]
    then
       script_location="/$instance/wlsadmin/user_projects/domains/bi_domain/bitools/bin"
    else
    echo "[WARNING][`date +%T`]:Could Not detect 12c status script in possible 12c domains home"|tee -a $LOG_FILE
    echo "[WARNING][`date +%T`]:Pre Health Check Failed !"
    exit_Code=1
    exit_Function
    fi
echo
echo "=============================================================================================" | tee -a $LOG_FILE
echo "[INFO]:[`date +%T`]: OBIEE 12C SCRIPT WILL START NOW WITH STATUS MODE on instance: $instance" | tee -a $LOG_FILE
echo "=============================================================================================" | tee -a $LOG_FILE
echo
$script_location/status.sh | tee -a $LOG_FILE
echo
echo "=============================================================================" | tee -a $LOG_FILE
echo "[INFO][`date +%T`]: Health Check on 12c Components Completed successfully" | tee -a $LOG_FILE
echo "=============================================================================" | tee -a $LOG_FILE
exit_Code=0 # 0 is for true
exit_Function
}


discover_services ()
{
 instance=$1
 USER_NAME=sb$1
 if [ -d "/$instance/oraclebi/fmw/122" ]
 then
  echo "[INFO][`date +%T`]: 12C OBIEE HOST DETECTED"|tee -a $LOG_FILE
  flag_12c_host="true"
 fi

 if [ $flag_12c_host == "true" ]
 then
        # 12C Health Check
        hc_12c
 else
        # 11g AdminServer
        if ps -ef|grep $USER_NAME|grep 'AdminServer\|odi_server\|bi_server'|grep -v grep > /dev/null 2>&1
    then
    echo "[INFO][`date +%T`]:WebLogic Domain processes detected on this host..Looking for 12C ."|tee -a $LOG_FILE
    WebLogic_detection_flag="true"
    echo
        if ps -ef|grep $USER_NAME|grep "/$instance/oraclebi/fmw/122/wlserver/server"| grep -v grep > /dev/null
        then
           echo "[INFO]:[`date +%T`]: WebLogic 12C Domain processes detected successfully on the host"|tee -a $LOG_FILE
        else
           echo "[INFO][`date +%T`]: FYI: Non 12c WebLogic Domain has been detected"|tee -a $LOG_FILE
        fi
    else
      echo
      echo "[WARNING][`date +%T`]: AdminServer Status: NA"|tee -a $LOG_FILE
      WebLogic_detection_flag="false"
      echo
    fi

    #Managed Server
    if [ $WebLogic_detection_flag == "true" ] #IF Adminserver is running then only managed server section starts
    then
        bi_managed_server_count=0
        odi_managed_server_count=0
        count=1
        while [[ $count -ne 4 ]]; do
                if ps ux | grep bi_server$count |grep -v grep > /dev/null 2>&1
                then
                        ((count++))
                        ((bi_managed_server_count++))
                else
                        ((count++))
            fi
        done
        echo
        echo "[INFO][`date +%T`]:Number of bi Managed Server detected: $bi_managed_server_count"
    else
        echo
        echo "[INFO][`date +%T`]:BI Managed Server Status Not Available"|tee -a $LOG_FILE
        echo
    fi

    # Node Manager
    if ps ux |grep NodeManager|grep -v grep > /dev/null 2>&1
    then
       echo
       echo "[INFO][`date +%T`]:NodeManager detected on the host successfully"|tee -a $LOG_FILE
       NodeManager_detection_flag="true"
    else
        echo "[WARNING][`date +%T`]:Could Not find any NodeManager Running on the host"|tee -a $LOG_FILE
        echo
        NodeManager_detection_flag="false"
    fi

    #ODI Managed server
    if [ $WebLogic_detection_flag == "true" ]
    then
    count=0
    while [[ $Managed_Server_Status="true" && $count -ne 4 ]]; do
                if ps ux|grep odi_server$count|grep -v grep > /dev/null 2>&1
                then
                        ((count++))
                        ((odi_managed_server_count++))
                else
                        ((count++))
             fi
        done
        echo
        echo "[INFO][`date +%T`]:Number of odi Managed Server detected: $odi_managed_server_count"
    else
        echo "[INFO][`date +%T`]:ODI Managed Server Status Not Available"|tee -a $LOG_FILE
        echo
    fi


    #BI Services
    if ps -ef|grep $USER_NAME|grep bifoundation|grep -v grep > /dev/null 2>&1
    then
        echo
      echo "[INFO][`date +%T`]:BI Services process successfully detected on host."|tee -a $LOG_FILE
      bi_services_detection="true"
      key_to_rpd="unlocked"
    else
      echo
      echo "[WARNING][`date +%T`]:Could Not detect BI Services Running on the host"|tee -a $LOG_FILE
      echo "[INFO][`date +%T`]:BI Services Status: NA"|tee -a $LOG_FILE
      echo
      bi_services_detection="false"
      key_to_rpd="unlocked"
    fi


    # OHS
    ohs_detection_status="true"
    if ps -ef |grep $USER_NAME|grep -w ohs|grep -v grep > /dev/null 2>&1
    then
        echo
        echo "[INFO]:[`date +%T`]:OHS process detected on this host."
        ohs_detection_status="true"
        key_to_rpd="unlocked"
    else
        ohs_detection_status="false"
        key_to_rpd="unlocked"
    fi


    #7.ODI StandAlone Agent
if ps -ef|grep $USER_NAME|grep oracle.odi.Agent|grep -v grep > /dev/null 2>&1
then
        echo
  echo "[INFO]:[`date +%T`]:ODI Standalone Agent process detected on this host"
  odi_agent_detection="true"
else
        echo
        echo "[WARNING][`date +%T`]:Could Not detect any odi agent Running on the host"|tee -a $LOG_FILE
        odi_agent_detection="false"
fi


    # INFORMATICA & DAC
   #Check if Informatica Process already exist
if ps -ef |grep $USER_NAME|grep infrmatica|grep -v grep> /dev/null
then
           echo
        echo "[INFO][`date +%T`]:INFORMATICA process detected on the host" 1>&2
        #ps -ef |grep $USER_NAME|grep infrmatica|grep -v "$pid\|$PPID\|grep" 1>&2
        Informatica_detection_flag="true"
  else
            echo
            echo "[WARNNING][`date +%T`]:Informatica process could not be detected on the host" 1>&2
        Informatica_detection_flag="false"
fi

if ps -ef|grep $USER_NAME|grep -w QServer|grep -v grep > /dev/null
then
            echo
      echo "[INFO][`date +%T`]:DAC process detected on the host" 1>&2
      #ps -ef|grep $USER_NAME|grep -w QServer|grep -v "$pid\|$PPID\|grep" 1>&2
      dac_detection_flag="true"
 else
            echo
      echo "[WARNNING][`date +%T`]:DAC process could not be detected on the host" 1>&2
      dac_detection_flag="false"
fi

#check for standlone server for informatica and dac

if [ $Informatica_detection_flag == "true" ]
then
        if [ $WebLogic_detection_flag == "false" ]
        then
    echo
    echo "[INFO][`date +%T`]: This host only has Informatica & DAC services hosted"
    echo "[INFO][`date +%T`]: Pre Health Check for Informatica & DAC"
    echo "====================================================="| tee -a $LOG_FILE
    echo "[INFO]:[`date +%T`]: Discovery Completed Successfully"| tee -a $LOG_FILE
    echo "====================================================="| tee -a $LOG_FILE
    echo
    informatica_hc
    fi
fi


fi
}


# ------------------------- Main Section -----------------------------------------------------------------------

#Declare variables
server_Name=`hostname -f`
email="anuj.a.singh@oracle.com"
instance=$1
USER_NAME=sb$2
flag_12c_host="false"
WebLogic_detection_flag="true"
bi_managed_server_count=0
odi_managed_server_count=0
NodeManager_detection_flag=0
bi_services_detection=0
ohs_detection_status="true"
odi_agent_detection="true"
Informatica_detection_flag="true"
dac_detection_flag="true"
key_to_rpd="unlocked"


echo "============================================================="
echo "[INFO][`date +%T`]: HEALTH CHECK ON INSTANCE: $1"
echo "============================================================="

echo "HOST: `hostname -f`"
echo "USER: `whoami`"
echo ""

#Validate Executing User
checkuser

sleep 2
echo "[INFO]:[`date +%T`] USER CHECK PASSED SUCCESSFULLY" | tee -a $LOG_FILE


#Check Proper Usage
if [ $# -ne 1 ]
then
        usage
else
        instance=$2
fi

#Check if specified Instance exists
if [ ! -z "$instance" ]
then
        if [ ! -d "/$instance/oraclebi" ] && [ ! -d "/$instance/exalytics" ]
        then
             echo "[WARNING]:/$instance/oraclebi or /$instance/exalytics  not found...check if the instance name is right" | tee -a $LOG_FILE
             echo
             exit_Code=1
             exit_Function
        else
             export INSTANCE=$instance
        fi
fi

#Housekeeping Section
housekeeping

#Logfile Maintenance section

#Determine OBIEE Instances hosted
get_obi_instances
echo
echo "=============================================================="| tee -a $LOG_FILE
echo "[INFO]:[`date +%T`]: Discovering Services hosted on the Server"| tee -a $LOG_FILE
echo "=============================================================="| tee -a $LOG_FILE
sleep 2

#check_db_host

discover_services $1

echo "====================================================="| tee -a $LOG_FILE
echo "[INFO]:[`date +%T`]: Discovery Completed Successfully"| tee -a $LOG_FILE
echo "====================================================="| tee -a $LOG_FILE
echo


echo "********************************************************************"
echo "OBIEE On Demand Health Check on Instance - $1"
echo "Managed Cloud Services Health Check Template"
echo "********************************************************************"
echo
echo "Ensuring all urls are as mentioned in OMP with status Yes/No/NA"
echo "[Yes - Performed Successfully, No - Performed but Not Successful, NA - Not Applicable]"
echo

hostname -f;whoami
echo "================================================"| tee -a $LOG_FILE
echo "[INFO][`date +%T`]: Process running on the host:"| tee -a $LOG_FILE
echo "================================================"| tee -a $LOG_FILE
echo
ps ux | tee -a $LOG_FILE
echo
echo "==============================="
echo "[INFO][`date +%T`]: Adminserver"| tee -a $LOG_FILE
echo "==============================="
echo
ps ux | grep AdminServer| grep -v grep | tee -a $LOG_FILE
if [ $? -ne 0 ]
then
   echo "[INFO][`date +%T`]: Adminserver: Not Available"     
fi
echo
echo "==================================="
echo "[INFO][`date +%T`]: Managed Servers"| tee -a $LOG_FILE
echo "==================================="
echo
count=1
while [[ $bi_managed_server_count -ne 0 ]]; do
        echo
        echo "======================================================="
        echo "[INFO][`date +%T`]: BI Managed Servers: bi_server$count"| tee -a $LOG_FILE
        echo "======================================================="
        echo
        ps ux | grep bi_server$count| grep -v grep | tee -a $LOG_FILE
        if [ $? -ne 0 ]
        then
            echo "[INFO][`date +%T`]: BI Managed Server: Not Available" 
        fi
        ((count++))
        ((bi_managed_server_count--))
done
count=1
while [[ $odi_managed_server_count -ne 0 ]]; do
        echo
        echo "========================================================="
        echo "[INFO][`date +%T`]: ODI Managed Servers: odi_server$count"| tee -a $LOG_FILE
        echo "========================================================="
        echo
        ps ux | grep odi_server$count| grep -v grep | tee -a $LOG_FILE
        if [ $? -ne 0 ]
        then
        echo "[INFO][`date +%T`]: ODI Managed Server: Not Available"
        fi
        ((count++))
        ((odi_managed_server_count--))
done
#NodeManager
echo
echo "================================"
echo "[INFO][`date +%T`]: NodeManager:"
echo "================================"
echo
ps ux | grep NodeManager | grep -v grep | tee -a $LOG_FILE
if [ $? -ne 0 ]
then
   echo "[INFO][`date +%T`]: NodeManager: Not Available"
fi

#OHS
echo "================================"
echo "[INFO][`date +%T`]: OHS STATUS:"
echo "================================"
echo
instance=$1
if [ -d "/$instance/admin/web" ]
then
ohs_status_location="/$instance/admin/web"
$ohs_status_location/bin/opmnctl status
fi

if [ -d "/$instance/admin/web1" ]
then
instance=$1
ohs_status_location="/$instance/admin/web1"
$ohs_status_location/bin/opmnctl status
fi

if [ -d "/$instance/admin/web2" ]
then
instance=$1
 ohs_status_location="/$instance/admin/web2"
$ohs_status_location/bin/opmnctl status
echo
fi

#BI Services
touch /tmp/RPD_deployment_logs/bi_services.txt
chmod 777 /tmp/RPD_deployment_logs/bi_services.txt
echo "====================================="
echo "[INFO][`date +%T`]:BI Services Status"
echo "====================================="
echo
temphost=`hostname`
instance=$1
if [ -d "/$instance/admin/instances/$1_$temphost" ]
then
bi_services_location="/$instance/admin/instances/$1_$temphost"
echo $bi_services_location
$bi_services_location/bin/opmnctl status
echo
elif [[ -d "/$instance/admin/instances/instance1" ]]; then
bi_services_location="/$instance/admin/instances/instance1"
echo $bi_services_location
$bi_services_location/bin/opmnctl status
echo
elif [[ -d "/$instance/admin/instances/instance2" ]]; then
bi_services_location="/$instance/admin/instances/instance2"
echo $bi_services_location
$bi_services_location/bin/opmnctl status
echo
else
        echo "[WARNING][`date +%T`]: Could Not detect location for bi services status"
        echo "[INFO][`date +%T`]: Please Check BI services status Manually"
fi

if ps -ef | grep nqsclustercontroller | grep -v grep > /dev/null 2>&1
then
pid_cluster_ctrl=`ps ux | grep nqsclustercontroller | grep -v grep | awk '{print $2}'`
if echo $pid_cluster_ctrl | egrep -q '^[0-9]+$'; then
echo "[INFO][`date +%T`]: netstat -alp | grep $pid_cluster_ctrl"
echo
netstat -alp | grep $pid_cluster_ctrl 2> /dev/null
echo
key_to_rpd="unlocked"
else
        echo "[WARNING][`date +%T`]: Cluster Controller: DOWN"
        echo
fi
else
        echo "[WARNING][`date +%T`]: Cluster Controller: DOWN"
        echo
fi


if ps -ef | grep nqscheduler | grep -v grep > /dev/null 2>&1
then
pid_schedular=`ps ux | grep nqscheduler | grep -v grep | awk '{print $2}'`
if echo $pid_schedular | egrep -q '^[0-9]+$'; then
    # $var is a number
echo "[INFO][`date +%T`]: netstat -alp | grep $pid_schedular"
echo
netstat -alp | grep $pid_schedular 2> /dev/null
echo
key_to_rpd="unlocked"
else
    # $var is not a number
    echo
    echo "[WARNING][`date +%T`]: BI Schedular : DOWN"
        echo
fi
else
        echo
        echo "[WARNING][`date +%T`]: BI Schedular : DOWN"
        echo
fi


if ps -ef | grep nqsserver | grep -v grep > /dev/null 2>&1
then
pid_nqsserver=`ps ux | grep nqsserver | grep -v grep | awk '{print $2}'`
if echo $pid_nqsserver | egrep -q '^[0-9]+$'; then
echo "[INFO][`date +%T`]: netstat -alp | grep $pid_nqsserver"
echo
netstat -alp | grep $pid_nqsserver 2> /dev/null
echo
key_to_rpd="unlocked"
else
        echo
        echo "[WARNING][`date +%T`]: NQS Server : DOWN"
        key_to_rpd="unlocked"
        echo
fi
else
        echo "[WARNING][`date +%T`]: NQS Server : DOWN"
        key_to_rpd="unlocked"
        echo
fi


if ps -ef | grep sawserver | grep -v grep > /dev/null 2>&1
then
pid_sawserver=`ps ux | grep sawserver | grep -v grep | awk '{print $2}'`
if echo $pid_sawserver | egrep -q '^[0-9]+$'; then
 echo "[INFO][`date +%T`]: netstat -alp | grep $pid_sawserver"
 echo
 netstat -alp | grep $pid_sawserver 2> /dev/null
 echo
 key_to_rpd="unlocked"
else
 echo
 echo "[WARNING][`date +%T`]: SAW server : DOWN"
 key_to_rpd="unlocked"
 echo
fi

else
        echo "[WARNING][`date +%T`]: SAW server : DOWN"
        key_to_rpd="unlocked"
        echo
fi


#Informatica and DAC
#If DAC & INFORMATICA and bi services hosted in the same server
#Informatica
if [ $Informatica_detection_flag == "true" ]
then
        if [ $dac_detection_flag == "true" ]
        then
         echo "============================================="
         echo "[INFO][`date +%T`]: Informatica & DAC status"
         echo "============================================="
         echo
         ps -ef|grep $USER_NAME|grep infrmatica|grep -v "$pid\|$PPID\|grep"
         echo
         echo
         ps -ef|grep $USER_NAME|grep -w QServer|grep -v "$pid\|$PPID\|grep"
         echo
        fi
fi

echo
echo "[INFO][NOTE]: Please check all the logs updated by ATOM before you start any further activity"
echo
echo "========================================================"
echo "[INFO][`date +%T`]: HEALTH CHECK COMPLETED SUCCESSFULLY"
echo "========================================================"


#NOTE: IGNORE ALL LINES WHERE KEY_TO_RPD IS MENTIONED.

#END OF SCRIPT
#HEALTH CHECK END HERE
