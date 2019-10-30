# Background
This plugin checks the status of mail volumes sent through the Mandrill mail server. 
It checks for a minimum number of messages sent and alerts if the number is less than the warning/critical thresholds. 
If it is expected that mail is sent on a regular basis, if less than the expected amount 
is sent it may indicate a problem on Mandrill, most likely billing or reputation related. 
You should be checking the mail host which sends to the Mandrill API to check that it is working in addition.

Also, this checks for a backlog on Mandrill which represents queued mail which has been sent from the 
API but not delivered. Values from the API which give messages opened and rejected are also presented, 
but as they are not certain to be correct, they are not alerted on.

Status info is provided which allows pretty graphs to be drawn

# To Do
The shell out to curl and saving files in /tmp is probably not the best way to write perl, this should be replaced.

# Finally....
And before you ask, this was not written to facilitate sending spam email, it was done to monitor a 
legitimate mail sending application.
