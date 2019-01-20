package AXA::Alarm;

use strict;
use warnings;
use 5.014;

### CA UIM Packages
use Nimbus::API;
use Nimbus::Session;
use Nimbus::CFG;
use Nimbus::PDS;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw( Email_Send ALARM_KO ALARM_OK );

use constant {
    ALARM_KO => 1,
    ALARM_OK => 0
};

sub Return_Code {
    my $code = shift;
    my $arg1 = shift || "";
    my $arg2 = shift || "";
    my %message = (
        '0' => 'Nimsoft alarm send with success.'
    );
    if ($code == ALARM_OK) {
        return ($code,$message{$code},ALARM_OK);
    }
    return ($code,$message{$code},ALARM_KO);
}

sub Alarm_Send {
    my $CFG = shift;
    my $ARG = shift;

    ### Simplification of the way to the template settings
    my $config     = $CFG->{"templates"}->{"alarm"};

    ### The default template is set to 'default'
    my $template   = $ARG->{"template"} || "default";

    return Return_Code(0);
}