package AXA::Schedule;

use strict;
use warnings;
use 5.014;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw( Schedule SCHEDULE_IN_RANGE SCHEDULE_NI_RANGE SCHEDULE_RC_OK SCHEDULE_RC_KO );

use constant {
    SCHEDULE_IN_RANGE => 1,
    SCHEDULE_NI_RANGE => 0,
    SCHEDULE_RC_OK => 0,
    SCHEDULE_RC_KO => 1
};

sub Schedule {
    my ($STR_schedule) = @_;
    my @return;

    ### Global syntax verification
    my $regex1 = qr/S=[0-9h:-]*;M=[0-9h:-]*;T=[0-9h:-]*;W=[0-9h:-]*;T=[0-9h:-]*;F=[0-9h:-]*;S=[0-9h:-]*/;
    unless ($STR_schedule =~ /$regex1/) {
        return (SCHEDULE_RC_KO,"Wrong Schedule syntax !");
    }

    ### Convert datetime to 0->1400 minutes
    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime();
    my $INT_now = $hour * 60 + $min;

    ### Hash to convert localtime() week day to splitted schedule day.
    my %w = ('1'=>'1','2'=>'2','3'=>'3','4'=>'4','5'=>'5','6'=>'6','7'=>'0');

    ### Split Schedule per day
    my @ARR_schedule_per_day = split(';',$STR_schedule);
    if ($#ARR_schedule_per_day != '6') { return (SCHEDULE_RC_KO,"Bad number of day returned by the splitted schedule !",""); }

    ### Extract the Schedule of day
    my $STR_schedule_of_day = (split('=',$ARR_schedule_per_day[$w{$wday}]))[1];

    ### Schedule of day syntax verification
    my $regex2 = qr/[0-9h:-]*/;
    unless ($STR_schedule_of_day =~ /$regex2/) {
        return (SCHEDULE_RC_KO,"Wrong Schedule of day syntax !","");
    }

    ### Loop on time range
    my @ARR_day_range = split('-',$STR_schedule_of_day);
    my $INT_range     = '1';
    foreach my $STR_range (@ARR_day_range)
    {
        ### Time range synthax verification
        my $regex3= qr/[0-2][0-9]h[0-5][0-9]:[0-2][0-9]h[0-5][0-9]/;
        unless ($STR_range =~ /$regex3/) {
            return (SCHEDULE_RC_KO,"Wrong Time range syntax !","");
        }

        ### Evaluate if your are in one of the time ranges
        my ($STR_top     , $STR_end)      = split(':',$STR_range);
        my ($INT_top_hour, $INT_top_mins) = split('h',$STR_top);
        my ($INT_end_hour, $INT_end_mins) = split('h',$STR_end);
        my $INT_top = $INT_top_hour * 60 + $INT_top_mins;
        my $INT_end = $INT_end_hour * 60 + $INT_end_mins;
        if ( $INT_now >= $INT_top and $INT_now <= $INT_end ){
            return (SCHEDULE_RC_OK,"Now you are in a time range",SCHEDULE_IN_RANGE);
        } 
        $INT_range++;
    } 
    return (SCHEDULE_RC_OK,"Now you're not in a time range",SCHEDULE_NI_RANGE);
}