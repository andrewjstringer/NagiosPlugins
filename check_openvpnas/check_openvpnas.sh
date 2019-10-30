#!/bin/bash
# Written Andrew Stringer, 04/09/2014 contact me on:- nagios atsymbol rainsbrook dot co dot uk
#Name check_openvpnas.sh
 
# Purpose is to check OpenVPN Access Server status.
#Checks Licence status, number of connections and licence expiry dates.
 
#Print out command line options
usage() { echo "Usage:- check_openvpnas.sh <check-to-perform> (LicUsage, VPNSummary or LICexpire)" 1>&2; exit 4; }
 
#Check we have some arguments passed
if [ -z "$1" ] ; then
        usage
        exit 4
fi
 
#This requires an addition to the sudoers file:-
#nagios ALL=(ALL) NOPASSWD: /usr/local/openvpn_as/scripts/sacli
#nagios ALL=(ALL) NOPASSWD: /bin/grep
 
#sacli needs to be run as root because it can run auth type commands against openVPN
SACLI="sudo /usr/local/openvpn_as/scripts/sacli"
 
 
 
case $1 in                                                                                                                                                                                           
        LicUsage | licusage )                                                                                                                                                                        
                #LicUsage         -> show active connections compared to license limit (usage, limit)                                                                                                
                LIC=`${SACLI} LicUsage`                                                                                                                                                              
                #[ 30, 30 ]                                                                                                                                                                          
 
                LIC1=${LIC/[/}                                                                                                                                                                       
                #30, 30 ]                                                                                                                                                                            
 
                LIC2=${LIC1/]/}                                                                                                                                                                      
                #30, 30                                                                                                                                                                              
 
                LICINUSE=$(echo ${LIC2} | cut -f1 -d, )
                #echo "LICINUSE = ${LICINUSE}"
 
                TOTLIC=$(echo ${LIC2} | cut -f2 -d, )
                #echo "TOTLIC = ${TOTLIC}"
 
                LICFREE=$(( $TOTLIC-$LICINUSE ))
                #echo "LICFREE = ${LICFREE}"
 
 
                if  [[ "$LICFREE" -gt 4  ]]; then
                        STATUS=0
                        TEXT="OK. ${LICFREE} licences available.  | AvailableLicences=${LICFREE};4;2;"
                elif [[ "$LICFREE" -le 2  ]]; then
                        STATUS=2
                        TEXT="CRITICAL - ${TOTLIC} total, ${LICINUSE} in use, ${LICFREE} client licences available. | AvailableLicences=${LICFREE};4;2;"
                elif [[ "$LICFREE" -le 4 ]]; then
                        STATUS=1
                        TEXT="Warning - ${TOTLIC} total, ${LICINUSE} in use, ${LICFREE} client licences avilable. | AvailableLicences=${LICFREE};4;2;"
                else
                        STATUS=3
                        TEXT="Licence state unknown."
                fi      ;;
 
 
        VPNSummary | vpnsummary )
                VPNSUMMARY=`${SACLI} VPNSummary`
                #{  "n_clients": 26 }
                #echo "$VPNSUMMARY"
 
                VPNSUMMARY1=`echo $VPNSUMMARY | cut -f2 -d:`
                #echo "$VPNSUMMARY1"
                # 26 }
 
                VPNSUMMARY2=${VPNSUMMARY1/\}/}
                #echo "$VPNSUMMARY2"
                #> 26 <
                STATUS=0
                TEXT="${VPNSUMMARY2} VPN clients connected.  | VPN Clients Connected=${VPNSUMMARY2}" ;;
 
        LICexpire | licexpire )
 
                MINLICDAYS=1000000
                MINLICNAME=''
                STATUS=''
 
                #Get today in seconds
                TODAY=`date +%s`
 
                LICLOC='/usr/local/openvpn_as/etc/licenses'
                #LICLOC='/tmp/licence/'
 
                for LIC in `ls -1 ${LICLOC}`
                do
                        LICNAME=${LIC}
 
                        LICEXPIRETMP=`sudo grep 'expiry_date=' ${LICLOC}/${LICNAME}`
 
                        #Expires expiry_date=20150821
                        LICEXPIRE=`echo $LICEXPIRETMP | cut -d= -f2`
 
                        if [[ $LICEXPIRE == '' ]]; then
                                EX=none
                                #echo "No expiry in ${LICNAME}"
                        else
                                #echo "${LICNAME} expires ${LICEXPIRE}"
                                #Work out the difference in seconds between expiry date and now
                                EXP1=$(( `date -d ${LICEXPIRE} +%s` - ${TODAY} ))
 
                                #Convert to days - 60x60x24
                                EXP2=$(( ${EXP1} / 86400 ))
 
                                if [[ $EXP2 -lt 0 ]]; then
                                        STATUSTXT='Warning!! Check for expired licence files.'
 
                                elif [[ $EXP2 -lt $MINLICDAYS ]]; then
                                        MINLICDAYS=$EXP2
                                        MINLICNAME=$LICNAME
 
 
                                fi
                        fi
 
                done
 
                #echo "Next licence >$MINLICNAME< expires in >$MINLICDAYS< days. ${STATUSTXT}"
 
                if  [[ "$MINLICDAYS" -gt 31  ]]; then
                        STATUS=0
                        TEXT="OK. No licence expiry in next 31 days. ${STATUSTXT} | ${MINLICNAME} Expires in = ${MINLICDAYS}Days;31;4;"
                elif [[ "$MINLICDAYS" -le 31  ]]; then
                        STATUS=1
                        TEXT="WARNING - Next licence >$MINLICNAME< expires in >$MINLICDAYS< days. ${STATUSTXT} | ${MINLICNAME} Expires in = ${MINLICDAYS}Days;31;4;"
                elif [[ "MINLICDAYS" -le 7 ]]; then
                        STATUS=2
                        TEXT="CRITICAL - Less than 1 week before >$MINLICNAME< expires! ${STATUSTXT} | ${MINLICNAME} Expires in = ${MINLICDAYS}Days;31;4;"
                else
                        STATUS=3
                        TEXT="Licence expiry state unknown."
                fi      ;;
 
 
 
 
        *)
                echo "Please specify LicUsage, VPNSummary or LICexpire" ;;
 
esac
 
 
 
 
 
if [[ $STATUS -eq 0 ]]; then
        echo "${TEXT}"
        exit 0
elif [[ $STATUS -eq 1 ]]; then
        echo "${TEXT}"
        exit 1
elif [[ $STATUS -eq 2 ]]; then
        echo "${TEXT}"
        exit 2
else
        echo "${TEXT}"
        exit 3
fi
 
exit 0
