package AXA::ServiceNow;

use strict;
use warnings;
use 5.014;

use MIME::Base64;
use JSON;
use REST::Client;
use Encode;
use utf8;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw( Merge_RefHash Create_Incident INCIDENT_KO INCIDENT_OK );

use constant {
    INCIDENT_KO => 1,
    INCIDENT_OK => 0
};

sub Return_Code {
    my $code = shift;
    my $arg1 = shift || "";
    my $arg2 = shift || "";
    my %message = (
        '0' => "ServiceNow Incident opened successfully.",
        '100' => "You must to provide a host url !",
        '101' => "You must to provide the url relative path with the parameters !",
        '102' => "You must to provide the authentication string !",
        '103' => "You must to provide the method of the request !",
        '104' => "You must to provide the datas for the ticket creation: <body>"
    );
    if ($code == INCIDENT_OK) {
        return ($code,$message{$code},INCIDENT_OK);
    }
    return ($code,$message{$code},INCIDENT_KO);
}

sub Merge_RefHash {
    my ($hash1,$hash2) = @_;
    my ($k,$v);
    my %empty = ();
    my $empty = \%empty;
    if ( !keys $hash1 and !keys $hash2 ) {
        return $empty;
    } elsif ( keys $hash1 and !keys $hash2 ) {
        return $hash1;
    } elsif ( !keys $hash1 and keys $hash2 ) {
        return $hash2;
    } else {
        while ( ($k, $v) = each($hash2) ) {
            $hash1->{$k} = $v;
        }
        return $hash1;
    }
    return $empty;
}

sub Create_Incident {
    my $CFG = shift;
    my $ARG = shift;

    ### Simplification of the way to the template settings
    my $config   = $CFG->{"templates"}->{"api"};

    ### The default template is set to 'default'
    my $template = $ARG->{"template"} || "default";

    my %empty = ();
    my $empty = \%empty;

    ### Items which can be passed, in this order, by : JSON file, custom template or default template
    my $host     = $ARG->{"host"}   || $config->{$template}->{"host"}   || $config->{"default"}->{"host"}   || return Return_Code(100);
    my $path     = $ARG->{"path"}   || $config->{$template}->{"path"}   || $config->{"default"}->{"path"}   || return Return_Code(101);
    my $auth     = $ARG->{"auth"}   || $config->{$template}->{"auth"}   || $config->{"default"}->{"auth"}   || return Return_Code(102);
    my $method   = $ARG->{"method"} || $config->{$template}->{"method"} || $config->{"default"}->{"method"} || return Return_Code(103);

    ### Merging of the template first then the JSON values
    my $body1    = $config->{$template}->{"body"}   || $empty;
    my $body2    = $ARG->{"body"}                   || $empty;
    my $header1  = $config->{$template}->{"header"} || $empty;
    my $header2  = $ARG->{"header"}                 || $empty;
    my $body     = Merge_RefHash($body1,$body2);
    my $header   = Merge_RefHash($header1,$header2);

    if ( !keys $body )   { return Return_Code(104); }
    if ( !keys $header ) {
        $header = {
            'Authorization' => "Basic $auth",
            'Content-Type' => 'application/json',
            'Accept' => 'application/json'
        }
    }

    my $json   = encode_utf8(encode_json($body));
    my $client = REST::Client->new(host => $host);
    $client->POST($path,$json,$header);

    # print 'Response: ' . $client->responseContent() . "\n";
    # print 'Response status: ' . $client->responseCode() . "\n";
    # foreach ( $client->responseHeaders() ) {
    #     print 'Header: ' . $_ . '=' . $client->responseHeader($_) . "\n";
    # }

    return Return_Code(0);
}