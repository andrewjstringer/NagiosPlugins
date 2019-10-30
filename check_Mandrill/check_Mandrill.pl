#!/usr/bin/perl
 
#Written Andrew Stringer 13/08/2015 onwards contact me on:- nagios atsymbol rainsbrook dot co dot uk
#Purpose is to check the number of mails sent through Mandrill.
#This uses the Mandrill API to get results as xml and parses them.
 
#History
#v0.1 testing of concept.
#v0.2 first working version, no alerting, just reporting.
#v0.3 Added thresholds and low volume warnings.
#v0.4 Added check for invalid API key.
#v0.5 Added high volume warning threshold.
#v0.6 Added backlog thresholds
 
#This check should output the number of messages sent and rejects in the last day
#and the last week.
 
#output should show performance data, eg:-
#print "OK - Messages sent is xxxx, rejects is yyyy | Sent=$SENT, Rejects=$REJECTS;${LOWWARNINGTHRESHOLD};${LOWCRITICALTHRESHOLD}"
 
#23-09-2015 - Added in code to report incorrect API key used.
#Also, Happy Birthday Father, 91 today!
 
#26-10-2015 - Added to code to handle high threshold warning and backlog warnings
 
#To-Do:-
#pipe xml curl output directly to xml::simple inlut, avoiding /tmp
 
 
#$USER1$/check_mandrill.pl $ARG1$ $ARG2$ $ARG3$ $ARG4$
#$ARG1$ is the Mandrill api key
#$ARG2$ is the low volume warning threshold for 24h
#$ARG3$ is the low volume critical threshold for 24h
#$ARG4$ is the high volume warning threshold for 24h
#$ARG5$ is the high volume critical threshold for 24h
#$ARG6$ is the backlog warning threshold
#$ARG7$ is the backlog critical threshold
 
use strict;
use warnings;
 
use XML::Simple;
use Data::Dumper;
 
MAIN:
#start of body of program
{
 
my $numArgs = $#ARGV + 1;
 
if ($numArgs < 7) {
        print "You supplied $numArgs arguments.\n";
        print "Usage:- check_mandrill.pl <API key> <low-warning> <low-critical> <high-warning> <high-critical> <backlog-warn> <backlog-critical>\n";
        exit 3;
}
 
 
#This is the xml file retreived from Mandrill,
#it should be possible to read this into an array or something rather than
#write it out to the filesystem.
my $resultsfile = '/tmp/mandrill.xml' ;
 
#These need to be read in as a command line variable from Nagios ($ARG1$ etc.)
my $apikey = $ARGV[0];
my $lowwarning = $ARGV[1];
my $lowcritical = $ARGV[2];
my $highwarning = $ARGV[3];
my $highcritical = $ARGV[4];
my $backlogwarning = $ARGV[5];
my $backlogcritical = $ARGV[6];
 
my $mandrillurl = 'https://mandrillapp.com/api/1.0/users/info.xml';
 
#Set default return code to 0
my $rcode = 0;
 
#get xml file
`curl -s -A 'Mandrill-Curl/1.0' -d '{"key":"$apikey"}' $mandrillurl > $resultsfile` ;
 
# create object
my $xml = new XML::Simple;
 
# read XML file
my $data = $xml->XMLin("$resultsfile");
 
 
#Checks to showup any problems
my $message = $data->{message}->{content} ;
if (defined $message) {
        if ($message eq 'Invalid API key'){
                print"Invalid API key.\n";
                exit 3;
        }
}
 
 
#print Dumper($data);
 
my $sent24h = $data->{stats}->{today}->{sent}->{content};
my $open24h = $data->{stats}->{today}->{opens}->{content};
my $reject24h = $data->{stats}->{today}->{rejects}->{content};
my $sent7d = $data->{stats}->{last_7_days}->{sent}->{content};
my $open7d = $data->{stats}->{last_7_days}->{opens}->{content};
my $reject7d = $data->{stats}->{last_7_days}->{rejects}->{content};
 
my $currentbacklog = $data->{backlog}->{content};
 
 
# Print out data and return codes
#OK
if (($sent24h >= $lowwarning) && ($sent24h <= $highwarning) && ($currentbacklog <= $backlogwarning )) {
        print "OK - $sent24h mails in last 24h, $sent7d in last 7d|"; $rcode = 0;
#Critical
} elsif ($sent24h <= $lowcritical) {
        print "CRITICAL - Less than $lowcritical mails sent in last 24h|"; $rcode = 2;
 
} elsif ($sent24h >= $highcritical) {
        print "CRITICAL - Greater than $highcritical mails sent in last 24h|";$rcode = 2;
 
} elsif ($currentbacklog >= $backlogcritical) {
        print "CRITICAL - Backlog on Mandrill greater than $backlogcritical|"; $rcode = 2;
 
#Warnings
} elsif ($sent24h <= $lowwarning) {
        print "WARNING - Less than $lowwarning mails sent in last 24h|"; $rcode = 1;
 
} elsif ($sent24h >= $highwarning) {
        print "WARNING - Greater than $highwarning mails sent in last 24h|"; $rcode = 1;
 
} elsif ($currentbacklog >= $backlogwarning) {
        print "WARNING - Backlog greater than $backlogwarning|"; $rcode = 1;
 
} else {
        print "UNKNOWN - No idea how many mails sent, debugging needed!|"; $rcode = 3;
}
 
print "Sent last 24h=$sent24h;$lowwarning;$lowcritical, Open last 24h=$open24h, Reject last 24h=$reject24h, Backlog on Mandrill=$currentbacklog;$backlogwarning;$backlogcritical";
print "\n";
 
 
 
#Remove xml file from /tmp
unlink $resultsfile ;
 
exit $rcode;
 
#end of main:
}
