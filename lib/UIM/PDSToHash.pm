package AXA::PDSToHash;

use strict;
use warnings;
use 5.014;

use Nimbus::API;
use Nimbus::PDS;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(asHash);

use constant {
    PDS_ERR_NONE => 0,
    PDS_PPCH => 8,
    PDS_PPI => 3
};

our @EXPORT_OK = ('PDS_ERR_NONE','PDS_PPCH','PDS_PPI');

sub asHash {
     my $self = shift;
     my $hptr = shift || {};
     my $pds  = shift || $self->{pds};
     my $lev  = shift || 1;

     my ($rc, $key, $type, $size, $value);
     my $line = "-" x $lev;
     while($rc == 0) {
          ($rc, $key, $type, $size, $value) = pdsGetNext($pds);
          #print "PDS Type => $type, key => $key, value => $value, size => $size\n";
          next if $rc != PDS_ERR_NONE;
          if ($type == PDS_PDS) {
               if (!defined($hptr->{$key})) {
                    nimLog(3,"PDS::asHash $line>Adding PDS: $key") if defined($INT_debug) && $INT_debug > 0;
                    $hptr->{$key} = {};
               }
               asHash($self, $hptr->{$key}, $value, $lev + 1);
               pdsDelete($value);
          }
          elsif ($type == PDS_PPCH || $type == PDS_PPI) {
               nimLog(3,"PDS::asHash $line>Adding Array: $key") if defined($INT_debug) && $INT_debug > 0;
               my $tableIndex = 0;
               my @tableValues = ();
               my ($rc_table, $rd);
               WPDS_PCH: while($rc_table == 0) {
                    ($rc_table, $rd) = pdsGetTable($pds, PDS_PCH, $key, $tableIndex);
                    last WPDS_PCH if $rc_table != PDS_ERR_NONE;
                    push(@tableValues, $rd);
                    $tableIndex++;
               };
               $hptr->{$key} = \@tableValues;
          }
          else {
               nimLog(3, "PDS::asHash $line>Adding key/value: $key = $value") if defined($INT_debug) && $INT_debug > 0;
               $hptr->{$key} = $value;
          }
     };
     return $hptr;
}