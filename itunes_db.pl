#!/usr/bin/env perl
use strict;
use warnings;
use Data::Dumper;
#use open qw/:std :utf8/;
use DBI;
use Config::Tiny;

my $config = Config::Tiny->read('itunes_db.conf');
my $dbfile = $config->{_}->{dbfile};
my $imlfile = $config->{_}->{imlfile};

my $dbh = DBI->connect("dbi:SQLite:dbname=$dbfile","","");
my $sth = $dbh->prepare('INSERT INTO ITUNES VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)');

open (IMLFILE, "<$imlfile")  || die "Can't open $imlfile: $!\n";

local $SIG{__WARN__} = sub {
    my $message = shift;
    die $message;
};

my $track_id;
my $size;
my $total_time;
my $disc_number;
my $disc_count;
my $track_number;
my $track_count;
my $year;
my $date_modified;
my $location;
my @row;

my $begin_stanza = qr/<key>Track ID<\/key>/i;
my $endof_stanza = qr/<key>Location<\/key>/i;

LINE: while ( <IMLFILE> ) {
    chomp $_;
    
    if ( m{$begin_stanza} .. m{$endof_stanza} ) {
        my %row = ();
        
        if ($_ =~ /<key>Track ID<\/key>/) {
            ($track_id) = ($_ =~ /<integer>(\d+)<\/integer>/);
        }
        elsif ($_ =~ /<key>Disc Number<\/key>/) {
            ($disc_number) = ($_ =~ /<integer>(\d+)<\/integer>/);
        }
        elsif ($_ =~ /<key>Disc Count<\/key>/) {
            ($disc_count) = ($_ =~ /<integer>(\d+)<\/integer>/);
        }
        elsif ($_ =~ /<key>Track Number<\/key>/) {
            ($track_number) = ($_ =~ /<integer>(\d+)<\/integer>/);
        }
        elsif ($_ =~ /<key>Track Count<\/key>/) {
            ($track_count) = ($_ =~ /<integer>(\d+)<\/integer>/);
        }
        elsif ($_ =~ /<key>Year<\/key>/) {
            ($year) = ($_ =~ /<integer>(\d+)<\/integer>/);
        }
        elsif ($_ =~ /<key>Date Modified<\/key>/) {
            ($date_modified) = ($_ =~ /<date>(\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z)<\/date>/);
        }
        
        if ( m{$endof_stanza} ) {

            if (!$disc_number) { $disc_number = 0; }
            elsif (!$disc_count) { $disc_count = 0; }
            elsif (!$track_number) { $track_number = 0; }
            elsif (!$track_count) { $track_count = 0; }
            elsif (!$year) { $year = 0; }
            elsif (!$date_modified) { $date_modified = "N/A"; }


            print "$track_id $disc_number/$disc_count $track_number/$track_count $year $date_modified\n";
        }
    }

    if ($_ =~ /<key>Playlists<\/key>/) {
        last LINE;
    }
}

 
#$sth->execute(undef, $talb, $tpe2, $tpe1, $tpos, $trck, $tcon, $tdor, $tit2, $ufid, $tdrc, undef);

close IMLFILE;

exit 0;