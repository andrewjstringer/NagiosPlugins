#!/bin/bash
#Written Andrew Stringer, 31/10/2013
#Purpose is to test  power usage on smart power strips
 
#See http://www.oidview.com/mibs/318/PowerNet-MIB.html
 
#OID's of use for multi bank PDU
#.1.3.6.1.4.1.318.1.1.12.2.3.1.1.2.1 <- Multi-Bank Total Load (divide by 10)
#.1.3.6.1.4.1.318.1.1.12.2.3.1.1.2.2 <- Multi-Bank B1 Load (divide by 10)
#.1.3.6.1.4.1.318.1.1.12.2.3.1.1.2.3 <- Multi-Bank B2 Load (divide by 10)
 
#.1.3.6.1.4.1.318.1.1.12.2.4.1.1.2.1 <- Multi-Bank B1 Low Load Warning Threshold
#.1.3.6.1.4.1.318.1.1.12.2.4.1.1.2.2 <- Multi-Bank B2 Low Load Warning Threshold
#.1.3.6.1.4.1.318.1.1.12.2.2.1.1.2.1 <- Multi-Bank Total Low Load Warning Threshold
 
#.1.3.6.1.4.1.318.1.1.12.2.4.1.1.3.1 <- Multi-Bank B1 Near Overload Warning Threshold
#.1.3.6.1.4.1.318.1.1.12.2.4.1.1.3.2 <- Multi-Bank B2 Near Overload Warning Threshold
#.1.3.6.1.4.1.318.1.1.12.2.2.1.1.3.1 <- Multi-Bank Total Near Overload Warning Threshold
 
#.1.3.6.1.4.1.318.1.1.12.2.4.1.1.4.1 <- Multi-Bank B1 Overload Alarm Threshold
#.1.3.6.1.4.1.318.1.1.12.2.4.1.1.4.2 <- Multi-Bank B2 Overload Alarm Threshold
#.1.3.6.1.4.1.318.1.1.12.2.2.1.1.4.1 <- Multi-Bank Total Overload Alarm Threshold 
 
#Single Bank OID
#.1.3.6.1.4.1.318.1.1.12.2.3.1.1.2.1 <- Single-Bank Total Load (divide by 10)
 
#.1.3.6.1.4.1.318.1.1.12.2.2.1.1.2.1 <- Single-Bank Low Load Warning Threshold
#.1.3.6.1.4.1.318.1.1.12.2.2.1.1.3.1 <- Single-Bank Near Overload Warning Threshold
#.1.3.6.1.4.1.318.1.1.12.2.2.1.1.4.1 <- Single-Bank Overload Alarm Threshold
 
#.1.3.6.1.4.1.318.1.1.12.1.5.0 = PDU Model number, dual AP8953, single AP7954
 
#Print out command line options
usage() { echo "Usage:- check_apcpowerstrip.sh <hostname> <communitystring> <bank [B1/B2/T(otal)]> (for multi bank PDU only)" 1>&2; exit 1; }
 
#Check we have some arguments passed
if [ -z "$1" ] ; then
        usage
        exit 4
fi
 
 
HOSTNAME=$1
COMMSTRING=$2
#Only for multibank powerstrip
BANK=$3
 
SNMPGET=/usr/bin/snmpget
 
MODEL=`${SNMPGET} -v1 -c ${COMMSTRING} ${HOSTNAME} SNMPv2-SMI::enterprises.318.1.1.12.1.5.0 | cut -d: -f4 | cut -d" " -f2 | sed 's/^\"\(.*\)\"$/\1/' `
#echo ${MODEL}
 
if [ -z "${MODEL}" ]; then
        echo "UNKNOWN - An error has occurred communicating with the PDU."
        exit 3
fi
 
 
if [ ${MODEL} == "AP7951" ] || [ ${MODEL} == "AP7954" ]
then
        TYPE='SINGLEBANK'
        TOTALLOADRAW=`${SNMPGET} -v1 -c ${COMMSTRING} ${HOSTNAME} SNMPv2-SMI::enterprises.318.1.1.12.2.3.1.1.2.1 | cut -d: -f4 | cut -d" " -f2 `
        TOTALLOAD=`echo "scale = 2; $TOTALLOADRAW / 10" | bc -l`
        WARNINGTHRESHOLD=`${SNMPGET} -v1 -c ${COMMSTRING} ${HOSTNAME} SNMPv2-SMI::enterprises.318.1.1.12.2.2.1.1.3.1 | cut -d: -f4 | cut -d" " -f2 `
        CRITICALTHRESHOLD=`${SNMPGET} -v1 -c ${COMMSTRING} ${HOSTNAME} SNMPv2-SMI::enterprises.318.1.1.12.2.2.1.1.4.1 | cut -d: -f4 | cut -d" " -f2 `
        #echo "TLr=${TOTALLOADRAW}, TL=${TOTALLOAD},  w=${WARNINGTHRESHOLD}, c=${CRITICALTHRESHOLD} "
 
        if [[ "$TOTALLOADRAW" -lt $(($WARNINGTHRESHOLD * 10)) ]]; then
                echo "OK - ${MODEL}, Total Load is ${TOTALLOAD}A."
                exit 0
        elif [[ "$TOTALLOADRAW" -le $(($CRITICALTHRESHOLD * 10 )) ]]; then
                echo "WARNING - ${MODEL}, Total Load is ${TOTALLOAD}A, warning is ${WARNINGTHRESHOLD}A."
                exit 1
        elif [[ "$TOTALLOADRAW" -ge $(($CRITICALTHRESHOLD * 10 )) ]]; then
                echo "CRITICAL - ${MODEL}, Total Load is ${TOTALLOAD}A, critical is ${CRITICALTHRESHOLD}A."
                exit 2
        else
                echo "UNKNOWN - Total Load is not known."
                exit 3
        fi
 
elif [ ${MODEL} == "AP7922" ] || [ ${MODEL} == "AP8953" ]
then
        TYPE='DUALBANK'
 
        case ${BANK} in
        B1|b1)
        #Bank B1 load
        BANK1LOADRAW=`${SNMPGET} -v1 -c ${COMMSTRING} ${HOSTNAME} SNMPv2-SMI::enterprises.318.1.1.12.2.3.1.1.2.2 | cut -d: -f4 | cut -d" " -f2 `
        BANK1LOAD=`echo "scale = 2; $BANK1LOADRAW / 10" | bc -l`
        B1WARNINGTHRESHOLD=`${SNMPGET} -v1 -c ${COMMSTRING} ${HOSTNAME} SNMPv2-SMI::enterprises.318.1.1.12.2.4.1.1.3.1 | cut -d: -f4 | cut -d" " -f2 `
        B1CRITICALTHRESHOLD=`${SNMPGET} -v1 -c ${COMMSTRING} ${HOSTNAME} SNMPv2-SMI::enterprises.318.1.1.12.2.4.1.1.4.1 | cut -d: -f4 | cut -d" " -f2 `
        #echo "TLAr=${BANK1LOADRAW}, TL=${BANK1LOAD},  w=${B1WARNINGTHRESHOLD}, c=${B1CRITICALTHRESHOLD} "
 
        if [[ "$BANK1LOADRAW" -lt $(($B1WARNINGTHRESHOLD * 10)) ]]; then
                echo "OK - ${MODEL}, Bank B1 load is ${BANK1LOAD}A."
                exit 0
        elif [[ "$BANK1LOADRAW" -le $(($B1CRITICALTHRESHOLD * 10 )) ]]; then
                echo "WARNING - ${MODEL}, Bank B1 load is ${BANK1LOAD}A, warning is ${B1WARNINGTHRESHOLD}A."
                exit 1
        elif [[ "$BANK1LOADRAW" -ge $(($B1CRITICALTHRESHOLD * 10 )) ]]; then
                echo "CRITICAL - ${MODEL}, Bank B1 load is ${BANK1LOAD}A, critical is ${B1CRITICALTHRESHOLD}A."
                exit 2
        else
                echo "UNKNOWN - Bank B1 load is not known."
                exit 3
        fi
        #end of bank B1 case
        ;;
 
        B2|b2)
        #Bank B2 load
        BANK2LOADRAW=`${SNMPGET} -v1 -c ${COMMSTRING} ${HOSTNAME} SNMPv2-SMI::enterprises.318.1.1.12.2.3.1.1.2.3 | cut -d: -f4 | cut -d" " -f2 `
        BANK2LOAD=`echo "scale = 2; $BANK2LOADRAW / 10" | bc -l`
        B2WARNINGTHRESHOLD=`${SNMPGET} -v1 -c ${COMMSTRING} ${HOSTNAME} SNMPv2-SMI::enterprises.318.1.1.12.2.4.1.1.3.2 | cut -d: -f4 | cut -d" " -f2 `
        B2CRITICALTHRESHOLD=`${SNMPGET} -v1 -c ${COMMSTRING} ${HOSTNAME} SNMPv2-SMI::enterprises.318.1.1.12.2.4.1.1.4.2 | cut -d: -f4 | cut -d" " -f2 `
        #echo "TLAr=${BANK2LOADRAW}, TL=${BANK2LOAD},  w=${B2WARNINGTHRESHOLD}, c=${B2CRITICALTHRESHOLD} "
 
        if [[ "$BANK2LOADRAW" -lt $(($B2WARNINGTHRESHOLD * 10)) ]]; then
                echo "OK - ${MODEL}, Bank B2 load is ${BANK2LOAD}A."
                exit 0
        elif [[ "$BANK2LOADRAW" -le $(($B2CRITICALTHRESHOLD * 10 )) ]]; then
                echo "WARNING - ${MODEL}, Bank B2 load is ${BANK2LOAD}A, warning is ${B2WARNINGTHRESHOLD}A."
                exit 1
        elif [[ "$BANK2LOADRAW" -ge $(($B2CRITICALTHRESHOLD * 10 )) ]]; then
                echo "CRITICAL - ${MODEL}, Bank B2 load is ${BANK2LOAD}A, critical is ${B2CRITICALTHRESHOLD}A."
                exit 2
        else
                echo "UNKNOWN - Bank B2 load is not known."
                exit 3
        fi
        #end of bank B2 case
        ;;
 
        *)
        #Total A+B load
        TOTALLOADRAW=`${SNMPGET} -v1 -c ${COMMSTRING} ${HOSTNAME} SNMPv2-SMI::enterprises.318.1.1.12.2.3.1.1.2.1 | cut -d: -f4 | cut -d" " -f2 `
        TOTALLOAD=`echo "scale = 2; $TOTALLOADRAW / 10" | bc -l`
        WARNINGTHRESHOLD=`${SNMPGET} -v1 -c ${COMMSTRING} ${HOSTNAME} SNMPv2-SMI::enterprises.318.1.1.12.2.2.1.1.3.1 | cut -d: -f4 | cut -d" " -f2 `
        CRITICALTHRESHOLD=`${SNMPGET} -v1 -c ${COMMSTRING} ${HOSTNAME} SNMPv2-SMI::enterprises.318.1.1.12.2.2.1.1.4.1 | cut -d: -f4 | cut -d" " -f2 `
        #echo "TLr=${TOTALLOADRAW}, TL=${TOTALLOAD},  w=${WARNINGTHRESHOLD}, c=${CRITICALTHRESHOLD} "
 
        if [[ "$TOTALLOADRAW" -lt $(($WARNINGTHRESHOLD * 10)) ]]; then
                echo "OK - ${MODEL}, Total Load is ${TOTALLOAD}A."
                exit 0
        elif [[ "$TOTALLOADRAW" -le $(($CRITICALTHRESHOLD * 10 )) ]]; then
                echo "WARNING - ${MODEL}, Total Load is ${TOTALLOAD}A, warning is ${WARNINGTHRESHOLD}A."
                exit 1
        elif [[ "$TOTALLOADRAW" -ge $(($CRITICALTHRESHOLD * 10 )) ]]; then
                echo "CRITICAL - ${MODEL}, Total Load is ${TOTALLOAD}A, critical is ${CRITICALTHRESHOLD}A."
                exit 2
        else
                echo "UNKNOWN - Total Load is not known."
                exit 3
        fi
        ;;
        #end of case statement
        esac
else
        echo "No Match for PDU found."
        TYPE='UNKNOWN'
        exit 3
fi
 
echo ${TYPE}
 
exit 0
