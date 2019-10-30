# Intro
Uses 'sacli' to get licensed connections, licence usage and checks for licence expiry. 
  (LicUsage, VPNSummary or LICexpire) This check needs to be run locally via the check_by_ssh plugin. 
  
As a result, you will need to have ssh keys setup. 
This runs as user nagios on the OpenVPN AS server, but as sacli requires root to run, 
two lines are required in sudo to allow this:-

nagios ALL=(ALL) NOPASSWD: /usr/local/openvpn_as/scripts/sacli
nagios ALL=(ALL) NOPASSWD: /bin/grep


This check provides performance data to enable graph generation. It is written in bash.

