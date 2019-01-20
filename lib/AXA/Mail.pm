package AXA::Mail;

use strict;
use warnings;
use 5.014;

use MIME::Lite;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw( Email_Send MAIL_OK MAIL_KO );

use constant {
    MAIL_KO => 1,
    MAIL_OK => 0
};

sub Return_Code {
    my ($code) = @_;
    my %message = (
        '0' => 'Email send with success.',
        '100' => 'You must to provide a host address !',
        '101' => 'You must to provide a user id for the authentication on the host !',
        '102' => 'You must to provide the password of the user id for the authentication on the host !',
        '103' => 'A <from> email address is required !',
        '104' => 'A <reply-to> email address is required !',
        '105' => 'An email type is required to define the HTML template of the body.',
        '106' => 'You must to provide a <To> mail address !'
    );
    if ($code == MAIL_OK) {
        return ($code,$message{$code},MAIL_OK);
    }
    return ($code,$message{$code},MAIL_KO);
}

sub Email_Send {
    my $CFG = shift;
    my $ARG = shift;

    ### Simplification of the way to the template settings
    my $config     = $CFG->{"templates"}->{"mail"};

    ### The default template is set to 'default'
    my $template   = $ARG->{"template"} || "default";

    ### Items impossible to be passed by the JSON file :
    my $smtp_host  = $config->{$template}->{"host"} || $config->{"default"}->{"host"} || return Return_Code(100);
    my $smtp_user  = $config->{$template}->{"user"} || $config->{"default"}->{"user"} || return Return_Code(101);
    my $smtp_pass  = $config->{$template}->{"pass"} || $config->{"default"}->{"pass"} || return Return_Code(102);
    my $smtp_from  = $config->{$template}->{"from"} || $config->{"default"}->{"from"} || return Return_Code(103);

    ### Items which can be passed, in this order, by : JSON file, custom template or default template
    my $smtp_reply = $ARG->{"reply"} || $config->{$template}->{"reply"} || $config->{"default"}->{"reply"} || return Return_Code(104);
    my $mail_type  = $ARG->{"type"}  || $config->{$template}->{"type"}  || $config->{"default"}->{"type"}  || return Return_Code(105);

    ### Item which can be passed only in the JSON
    my %variables  = %{ $ARG->{"variables"} };

    ### Specific items translated in array references
    my @empty = ();
    my $empty = \@empty;

    my @to  = split(',',$config->{$template}->{"to"});
    my @cc  = split(',',$config->{$template}->{"cc"});
    my @bcc = split(',',$config->{$template}->{"bcc"});
    
    my $to  = $ARG->{"to"}  || \@to  || return Return_Code(106);
    my $cc  = $ARG->{"cc"}  || \@cc  || $empty;
    my $bcc = $ARG->{"bcc"} || \@bcc || $empty;

    my %mail = (
        'From'    => $smtp_from,
        'Reply-To'=> $smtp_reply,
        'To'      => $to,
        'Subject' => '[AXA-IM][Monitoring][RTA] Test mail HTML with Nimsoft Template',
        'Type'    => 'multipart/related'
    );
    if ( scalar(@$cc )  != '0' ) { $mail{'Cc'}  = $cc;  }
    if ( scalar(@$bcc ) != '0' ) { $mail{'Bcc'} = $bcc; }

    my $msg = MIME::Lite->new(%mail);

    my %color = (
        '0' => ['clear'      ,'#00FF00'],
        '1' => ['information','#00FFFF'],
        '2' => ['warning'    ,'#0000FF'],
        '3' => ['minor'      ,'#FFFF00'],
        '4' => ['major'      ,'#FF8000'],
        '5' => ['critical'   ,'#FF0000']
    );

    ### Define HTML body template based on mail type
    given($mail_type) {
        when("alarm") {
            $msg->attach(
                'Type' => 'text/html',
                'Data' => qq{
                    <body>
                    <table cellspacing="0" cellpadding="0" width="100%" border="1" bgcolor="#330066">
                    <tbody>
                        <tr>
                        <td width="100%" bgcolor="#330066" valign="middle" align="left">
                            <table width="100%" border="0" bgcolor="#330066" cellspacing="0" cellpadding="0">
                            <tbody>
                                <tr>
                                <td width="4%" height="2" align="left">
                                    <table width="100%" border="0" height="19">
                                    <tbody>
                                        <tr>
                                        <td width="100%" bgcolor="$color{$variables{level}}[1]" bordercolorlight="#FFFFFF" bordercolordark="#C0C0C0">&nbsp;</td>
                                        </tr>
                                    </tbody>
                                    </table>
                                </td>
                                <td width="10%" valign="middle" align="left"><b><font color="#FFFFFF">$color{$variables{level}}[0]</font></b></td>
                                <td width="86%" valign="top" align="left">
                                    <table width="100%" border="0">
                                    <tbody>
                                        <tr>
                                        <td width="25%"><b><font color="#FFFFFF">$variables{source} - $variables{robot}</font></b></td>
                                        <td width="25%"><b><font color="#FFFFFF">Robot</font></b></td>
                                        <td width="25%"><b><font color="#FFFFFF">Robot: $variables{robot}</font></b></td>
                                        <td width="25%"><b><font color="#FFFFFF">Sonde: --sonde--</font></b></td>
                                        </tr>
                                    </tbody>
                                    </table>
                                </td>
                                </tr>
                            </tbody>
                            </table>
                        </td>
                        </tr>
                        <tr>
                        <td width="100%" bgcolor="#FFFFFF"><b>Message:</b>&nbsp;<i>$variables{message}</i></td>
                        </tr>
                        <tr>
                        <td width="100%" bgcolor="#FFFFFF"><b>Consignes:</b>&nbsp;<i>https://spportal.axa-im.intraxa/sites/is-operations/Orders/6490&middot;mht</i></td>
                        </tr>
                        <tr>
                        <td width="100%" bgcolor="#FFFFFF"><b>Example of field name:</b>&nbsp;<i>Example of field value</i></td>
                        </tr>
                    </tbody>
                    </table>
                    <br>
                    <img src="cid:axa.jpg">
                    </body>
                }
            );
        }
        default {
            return Return_Code(105);
        }
    }

    $msg->attach(
        'Type' => 'image/jpg',
        'Id'   => 'axa.jpg',
        'Path' => './templates/mail/axa.jpg',
    );

    $msg->send('smtp', $smtp_host, 'Timeout'=>'30', 'AuthUser'=>$smtp_user, 'AuthPass'=>$smtp_pass);
    
    return Return_Code(0);
}