#!/usr/bin/env perl
use strict;
use warnings;

use Data::Dumper;
use DateTime;
use DateTime::Format::ISO8601;
use DBI;
use File::Remove qw(remove);
use JSON;
use Digest::MD5 qw(md5_hex);
use open qw(:std :utf8);

#remove('*.log');

my $dbh = DBI->connect('dbi:Pg:dbname=music;host=localhost','postgres','secret',{AutoCommit=>1,RaiseError=>1,PrintError=>0});

my $json = JSON->new;
my $debug_log = "itunes_db_debug.log";

open (IMLFILE, "< $ENV{ITUNES_MUSIC_LIBRARY}") || die "Can't open $ENV{ITUNES_MUSIC_LIBRARY}: $!\n";
open (DEBUGLOG, ">> $debug_log")  || die "Can't open $debug_log: $!\n";

local $SIG{__WARN__} = sub {
    my $message = shift;
    die $message;
};

my $track_id;
my $name;
my $artist;
my $album_artist;
my $album;
my $genre;
my $disc_number;
my $disc_count;
my $track_number;
my $track_count;
my $year;
my $date_modified;
my $date_added;
my $volume_adjustment = 0;
my $play_count;
my $play_date;
my $play_date_utc;
my $artwork_count;
my $persistent_id;

my @row;

$dbh->do("DROP TABLE IF EXISTS itunes_data");

#my $sth = $dbh->table_info('','', 'itunes_data', 'TABLE');
#my $tab_ref = $sth->fetchall_arrayref;

$dbh->do('CREATE TABLE itunes_data ( persistent_id varchar(100) PRIMARY KEY, 
track_id integer, name text, artist text, album_artist text, album text, genre varchar(100), 
disc_number smallint, disc_count smallint,track_number smallint, track_count smallint, 
year date, date_modified timestamp, date_added timestamp, volume_adjustment smallint, 
play_count integer, play_date_utc timestamp, artwork_count smallint );') || die $dbh->errstr;

my $begin_stanza = qr/<key>Track ID<\/key>/i;
my $endof_stanza = qr/<key>Location<\/key>/i;

LINE: while ( <IMLFILE> ) {
    chomp $_;
    
    if ( m{$begin_stanza} .. m{$endof_stanza} ) {
        my %row = ();
        my $dt;
        
        if ($_ =~ /<key>Track ID<\/key>/) {
            ($track_id) = ($_ =~ /<integer>(\d+)<\/integer>/);
        }
        elsif ($_ =~ /<key>Name<\/key>/) {
            $_ =~ s/^\t+//;
            $name = substr($_, 23, -10);
            $name =~ s/'/''/g;
            $name =~ s/&#38;/&/g;
        }
        elsif ($_ =~ /<key>Artist<\/key>/) {
            $_ =~ s/^\t+//;
            $artist = substr($_, 25, -10);
            $artist =~ s/'/''/g;
            $artist =~ s/&#38;/&/g;
        }
        elsif ($_ =~ /<key>Album Artist<\/key>/) {
            $_ =~ s/^\t+//;
            $album_artist = substr($_, 31, -10);
            $album_artist =~ s/'/''/g;
            $album_artist =~ s/&#38;/&/g;
        }
        elsif ($_ =~ /<key>Album<\/key>/) {
            $_ =~ s/^\t+//;
            $album = substr($_, 24, -10);
            $album =~ s/'/''/g;
            $album =~ s/&#38;/&/g;
        }
        elsif ($_ =~ /<key>Genre<\/key>/) {
            $_ =~ s/^\t+//;
            $genre = substr($_, 24, -10);
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
            $year = $year . "-01-01";
        }
        elsif ($_ =~ /<key>Date Modified<\/key>/) {
            ($dt) = ($_ =~ /<date>(\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z)<\/date>/);
            $dt =~ s/[T,Z]/ /g;
            $date_modified = $dt;
        }
        elsif ($_ =~ /<key>Date Added<\/key>/) {
            ($dt) = ($_ =~ /<date>(\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z)<\/date>/);
            $dt =~ s/[T,Z]/ /g;
            $date_added = $dt;
        }
        elsif ($_ =~ /<key>Volume Adjustment<\/key>/) {
            ($volume_adjustment) = ($_ =~ /<integer>(-?\d+)<\/integer>/);
        }
        elsif ($_ =~ /<key>Play Count<\/key>/) {
            ($play_count) = ($_ =~ /<integer>(\d+)<\/integer>/);
        }
        elsif ($_ =~ /<key>Play Date UTC<\/key>/) {
            ($dt) = ($_ =~ /<date>(\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z)<\/date>/);
            $dt =~ s/[T,Z]/ /g;
            $play_date_utc = $dt;
        }
        elsif ($_ =~ /<key>Artwork Count<\/key>/) {
            ($artwork_count) = ($_ =~ /<integer>(\d+)<\/integer>/);
        }
        elsif ($_ =~ /<key>Persistent ID<\/key>/) {
            ($persistent_id) = ($_ =~ /<string>(\w+)<\/string/);
        }
        
        if ( m{$endof_stanza} ) {

            $dbh->do("INSERT INTO itunes_data ( persistent_id, track_id, name,
            artist, album_artist, album, genre, disc_number, disc_count,track_number,
            track_count, year, date_modified, date_added, volume_adjustment, play_count, 
            play_date_utc, artwork_count ) VALUES ( '$persistent_id', $track_id, '$name',
            '$artist', '$album_artist', '$album', '$genre', $disc_number, $disc_count, $track_number,
            $track_count, '$year', '$date_modified', '$date_added', $volume_adjustment, $play_count, 
            '$play_date_utc', $artwork_count );") || die $dbh->errstr;
            
            $disc_number = 0;
            $disc_count = 0;
            $track_number = 0;
            $track_count = 0;
            $year = 0;
            $date_modified = '1970-01-01 00:00:00';
            $date_added = '1970-01-01 00:00:00';
            $volume_adjustment = 0;
            $play_count = 0;
            $play_date_utc = '1970-01-01 00:00:00';
            $artwork_count = 0;
        }
    }

    if ($_ =~ /<key>Playlists<\/key>/) {
        last LINE;
    }
}

close IMLFILE;
close DEBUGLOG;

exit 0;