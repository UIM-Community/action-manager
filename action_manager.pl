use strict;
use warnings;
use 5.014;

use lib "../../../perllib";
use lib "./lib";

### CA UIM Packages
use Nimbus::API;
use Nimbus::Session;
use Nimbus::CFG;
use Nimbus::PDS;

# External and Public Packages
use JSON;

# AXA Invest Manager Packages
use AXA::Schedule;
use AXA::Mail;
use AXA::SNMP;
use AXA::ServiceNow;

my $STR_Prgname = 'action_manager';
my $STR_Version = '1.00';
my $STR_Edition = 'Dec 12 2018';

#====================================================
# Configuration File
#====================================================
my $CFG                 = Nimbus::CFG->new($STR_Prgname.".cfg");
# Section : setup
my $INT_Loglevel        = $CFG->{"setup"}->{"loglevel"}    || 0;
my $INT_Logsize         = $CFG->{"setup"}->{"logsize"}     || 100;
my $STR_Logfile         = $CFG->{"setup"}->{"logfile"}     || $STR_Prgname.".log";
my $INT_debug           = $CFG->{"setup"}->{"debug"}       || 0;

#====================================================
# JSON File
#====================================================
my $filename = 'action_manager.json';
my $json_text = do {
    open(my $json_fh, "<:encoding(UTF-8)", $filename);
    local $/;
    <$json_fh>
};
my @json_data = @{ decode_json($json_text) };

#====================================================
# Log File
#====================================================
nimLogSet($STR_Logfile, $STR_Prgname, $INT_Loglevel, 0);
nimLogTruncateSize($INT_Logsize * 1024);
nimLog(0, "****************[ Starting ]****************");
nimLog(0, "Probe $STR_Prgname version $STR_Version");
nimLog(0, "AXA Invest Manager, Copyright @ 2018-2020");

#====================================================
# TEST : Schedule
#====================================================
my $schedule = "S=00h00:24h00;M=00h00:24h00;T=00h00:24h00;W=00h00:24h00;T=00h00:24h00;F=00h00:24h00;S=00h00:24h00";
my ($rc1,$msg1,$res1) = Schedule($schedule);

if ($rc1 == SCHEDULE_RC_OK) {
    print ("====================================================\n");
    print ("Schedule :\n");
    print ("====================================================\n");
    print ("RC :       ".$rc1."\n");
    print ("Message :  ".$msg1."\n");
    print ("Schedule : ".$res1."\n");
    print ("\n");
}

#====================================================
# TEST : Mail
#====================================================
my $ARG1 = $json_data[2]{arguments};
my ($rc2,$msg2,$res2) = Email_Send($CFG,$ARG1);

if ($rc2 == MAIL_OK) {
    print ("====================================================\n");
    print ("Mail :\n");
    print ("====================================================\n");
    print ("RC :       ".$rc2."\n");
    print ("Message :  ".$msg2."\n");
    print ("Schedule : ".$res2."\n");
    print ("\n");
}

#====================================================
# TEST : ServiceNow Incident
#====================================================
my $ARG3 = $json_data[0]{arguments};
my ($rc4,$msg4,$res4) = Create_Incident($CFG,$ARG3);

if ($rc4 == TRAP_OK) {
    print ("====================================================\n");
    print ("ServiceNow Incident :\n");
    print ("====================================================\n");
    print ("RC :       ".$rc4."\n");
    print ("Message :  ".$msg4."\n");
    print ("Schedule : ".$res4."\n");
    print ("\n");
}

