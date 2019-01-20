package AXA::SNMP;

use strict;
use warnings;
use 5.014;

use Net::SNMP;
use JSON;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw( Trap_Send TRAP_KO TRAP_OK );

use constant {
    TRAP_KO => 1,
    TRAP_OK => 0
};

sub Return_Code {
    my $code = shift;
    my $arg1 = shift || "";
    my $arg2 = shift || "";
    my %message = (
        '0' => 'SNMP Trap send with success.',
        '100' => 'You must to provide a remote host address !',
        '101' => 'You must provide the number of the remote listener port !',
        '102' => 'A <from> email address is required !',
        '200' => 'You must to provide an OID list !',
        '201' => 'You must to provide a Types list !',
        '202' => 'You must to provide a Values list !',
        '300' => "Error connecting to target ". $arg1 . ": ". $arg2,
        '301' => "An error occurred sending the trap: " . $arg1,
        '400' => "The ". $arg1 ." is not defined in loop number ". $arg2
    );
    if ($code == TRAP_OK) {
        return ($code,$message{$code},TRAP_OK);
    }
    return ($code,$message{$code},TRAP_KO);
}

sub Trap_Send {
    my $CFG = shift;
    my $ARG = shift;

    ### Simplification of the way to the template settings
    my $config     = $CFG->{"templates"}->{"snmp"};

    ### The default template is set to 'default'
    my $template   = $ARG->{"template"} || "default";

    ### Items which can be passed, in this order, by : JSON file, custom template or default template
    my $remote     = $ARG->{"remote"}     || $config->{$template}->{"remote"}     || $config->{"default"}->{"remote"}     || return Return_Code(100);
    my $port       = $ARG->{"port"}       || $config->{$template}->{"port"}       || $config->{"default"}->{"port"}       || return Return_Code(101);
    my $community  = $ARG->{"community"}  || $config->{$template}->{"community"}  || $config->{"default"}->{"community"}  || return Return_Code(102);

    ### Item with fixed values :
    my $version    = "1";
    my $enterprise = "1.3.6.1.4.1.4055.1";
    my $specific   = "2";
    my $generic    = "6";

    if (!defined $ARG->{"oid"}    or !$ARG->{"oid"})    { return Return_Code(200); }
    if (!defined $ARG->{"types"}  or !$ARG->{"types"})  { return Return_Code(201); }
    if (!defined $ARG->{"values"} or !$ARG->{"values"}) { return Return_Code(202); }

    my ($sess, $err) = Net::SNMP->session(
        '-hostname'     => $remote,
        '-port'         => $port,
        '-version'      => $version,
        '-community'    => $community
    );

    if (!defined $sess) { return Return_Code(300,$remote,$err); }

    my %snmp_types = (
        'INTEGER'           => INTEGER,
        'INTEGER32'         => INTEGER32,
        'OCTET_STRING'      => OCTET_STRING,
        'OBJECT_IDENTIFIER' => OBJECT_IDENTIFIER,
        'IPADDRESS'         => IPADDRESS,
        'COUNTER'           => COUNTER,
        'COUNTER32'         => COUNTER32,
        'GAUGE'             => GAUGE,
        'GAUGE32'           => GAUGE32,
        'UNSIGNED32'        => UNSIGNED32,
        'TIMETICKS'         => TIMETICKS,
        'OPAQUE'            => OPAQUE,
        'COUNTER64'         => COUNTER64
    );

    my @vars = qw();
    my $size = (keys $ARG->{"values"}) - 1;
    foreach my $i (0 .. $size) {
        my $oid   = $enterprise.$ARG->{oid}->{$i};
        my $type  = $ARG->{"types"}->{$i};
        my $value = $ARG->{"values"}->{$i};
        if ( !defined $oid )   { return Return_Code(400,"oid"  ,$i+1); }
        if ( !defined $type )  { return Return_Code(400,"type" ,$i+1); }
        if ( !defined $value ) { return Return_Code(400,"value",$i+1); }
        push (@vars, $oid);
        push (@vars, $snmp_types{$type} || $snmp_types{"OCTET_STRING"});
        push (@vars, $value);
    }

    my $result = $sess->trap(
        '-varbindlist'  => \@vars,
        '-enterprise'   => $enterprise,
        '-specifictrap' => $specific,
        '-generictrap'  => $generic
    );

    if ( !$result ) { return Return_Code(300,$sess->error()); }

    return Return_Code(0);
}