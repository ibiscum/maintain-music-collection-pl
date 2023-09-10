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

my $json = JSON->new;
my $debug_log = "itunes_db_debug.log";

open (IMLFILE, "< $ENV{ITUNES_MUSIC_LIBRARY}") || die "Can't open $ENV{ITUNES_MUSIC_LIBRARY}: $!\n";
open (DEBUGLOG, "> $debug_log")  || die "Can't open $debug_log: $!\n";

#local $SIG{__WARN__} = sub {
#    my $message = shift;
#    die $message;
#};

my $persistent_id;
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
my $volume_adjustment;
my $play_count;
my $play_date;
my $play_date_utc;
my $artwork_count;

my $dbh = DBI->connect('dbi:Pg:dbname=music;host=localhost','postgres','secret', { AutoCommit => 1 });

$dbh->do('CREATE TABLE IF NOT EXISTS itunes_data ( persistent_id varchar(100) PRIMARY KEY, 
track_id integer, name text, artist text, album_artist text, album text, genre varchar(100), 
disc_number smallint, disc_count smallint,track_number smallint, track_count smallint, 
year date, date_modified timestamp, date_added timestamp, volume_adjustment smallint, 
play_count integer, play_date_utc timestamp, artwork_count smallint );');

my $begin_stanza = qr/<key>Track ID<\/key>/i;
my $endof_stanza = qr/<key>Location<\/key>/i;

my %itunes_data = ();

LINE: while ( <IMLFILE> ) {
    chomp $_;
    
    if ( m{$begin_stanza} .. m{$endof_stanza} ) {
        my $dt;
        
        if ($_ =~ /<key>Persistent ID<\/key>/) {
            ($persistent_id) = ($_ =~ /<string>(\w+)<\/string/);
        }
        elsif ($_ =~ /<key>Track ID<\/key>/) {
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
    }  
    
    if ( m{$endof_stanza} ) {
        my @row = ();

        if (!$disc_number)       { $disc_number = 0; }
        if (!$disc_count)        { $disc_count = 0; }
        if (!$track_number)      { $track_number = 0; }
        if (!$track_count)       { $track_count = 0; }
        if (!$year)              { $year = '1970-01-01'; }
        if (!$volume_adjustment) { $volume_adjustment = 0; }
        if (!$play_count)        { $play_count = 0; }
        if (!$artwork_count)     { $artwork_count = 0; }
        if (!$date_added)        { $date_added = '1970-01-01 00:00:00'; }
        if (!$date_modified)     { $date_modified = '1970-01-01 00:00:00'; }
        if (!$play_date_utc)     { $play_date_utc = '1970-01-01 00:00:00'; }

        @row = ( $track_id, $name, $artist, $album_artist, $album, $genre, $disc_number, $disc_count, $track_number, $track_count,
        $year, $date_modified, $date_added, $volume_adjustment, $play_count, $play_date_utc, $artwork_count );

        #print DEBUGLOG Dumper(@row);
        #print DEBUGLOG "\n";

        $itunes_data{$persistent_id} = \@row;
    }

    if ($_ =~ /<key>Playlists<\/key>/) {
        last LINE;
    }
}

my @p_id_file = (keys %itunes_data);

foreach my $p_id (keys %itunes_data) {

    my @values = @{ $itunes_data{$p_id} };

    $track_id      = $values[0];
    $name          = $values[1];
    $artist        = $values[2];
    $album_artist  = $values[3];
    $album         = $values[4];
    $genre         = $values[5];
    $disc_number   = $values[6];
    $disc_count    = $values[7];
    $track_number  = $values[8];
    $track_count   = $values[9];
    $year          = $values[10];
    $date_modified = $values[11];
    $date_added    = $values[12];
    $volume_adjustment = $values[13];
    $play_count    = $values[14];
    $play_date_utc = $values[15];

    $artwork_count = $values[16];

    $dbh->do("INSERT INTO itunes_data ( persistent_id, track_id, name, artist, album_artist, album, genre,
    disc_number, disc_count,track_number, track_count, year, date_modified, date_added, volume_adjustment, 
    play_count, play_date_utc, artwork_count ) 
    VALUES (
    '$p_id', $track_id, '$name', '$artist', '$album_artist', '$album', '$genre', $disc_number, 
    $disc_count, $track_number, $track_count, '$year', '$date_modified', '$date_added', $volume_adjustment, 
    $play_count, '$play_date_utc', $artwork_count ) 
    ON CONFLICT (persistent_id) DO UPDATE SET
    track_id = EXCLUDED.track_id,
    name = EXCLUDED.name,
    artist = EXCLUDED.artist,
    album_artist = EXCLUDED.album_artist,
    album = EXCLUDED.album,
    genre = EXCLUDED.genre,
    disc_number = EXCLUDED.disc_number,
    disc_count = EXCLUDED.disc_count,
    track_number = EXCLUDED.track_number,
    track_count = EXCLUDED.track_count,
    year = EXCLUDED.year,
    date_modified = EXCLUDED.date_modified,
    date_added = EXCLUDED.date_added,
    volume_adjustment = EXCLUDED.volume_adjustment,
    play_count = EXCLUDED.play_count,
    play_date_utc = EXCLUDED.play_date_utc,
    artwork_count = EXCLUDED.artwork_count
    ;");
}

my $p_id_db = $dbh->selectcol_arrayref('SELECT persistent_id FROM itunes_data;');

my %seen = ();    # lookup table
my @db_only = (); # only in database, not in file

# build lookup table
foreach my $item (@p_id_file) {
    $seen{$item} = 1;
}

foreach my $item (@$p_id_db) {
    unless ($seen{$item}) {
        # it is not in %seen, so add to %db_only
        push @db_only, $item;
    }
}

# delete obsolete rows
my $db_only_join = join ",", map{"'$_'"} @db_only;

my $db_only_len = @db_only;

if ($db_only_len) {
    $dbh->do("DELETE FROM itunes_data WHERE persistent_id IN ($db_only_join);");
}

$dbh->disconnect();

close IMLFILE;
close DEBUGLOG;

exit 0;