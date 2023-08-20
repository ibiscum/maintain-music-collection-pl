#!/usr/bin/env perl
use strict;
use warnings;
use Data::Dumper;
use DBI;
use Config::Tiny;
use DateTime;
use DateTime::Format::ISO8601;
use open qw/:std :utf8/;

my $config = Config::Tiny->read('itunes_db.conf');
my $imlfile = $config->{_}->{imlfile};

open (IMLFILE, "<$imlfile")  || die "Can't open $imlfile: $!\n";

my $dbh = DBI->connect("dbi:Cassandra:host=localhost");
$dbh->do("CREATE KEYSPACE IF NOT EXISTS music WITH REPLICATION = {'class': 'SimpleStrategy', 'replication_factor' : 1 };");

$dbh->do("CREATE TABLE IF NOT EXISTS music.itunes_data (track_id int PRIMARY KEY, name text, artist text, album_artist text,
album text, genre text, disc_number smallint, disc_count smallint, track_number smallint, track_count smallint, year smallint,
date_modified timestamp, date_added timestamp, volume_adjustment float, play_count smallint, play_date_utc timestamp,
artwork_count smallint, persistent_id text);");

my $sth_itunes = $dbh->prepare('INSERT INTO music.itunes_data (track_id, name, artist, album_artist, album, genre, disc_number, 
disc_count, track_number, track_count, year, date_modified, date_added, volume_adjustment, play_count, play_date_utc,
artwork_count, persistent_id) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?);');

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
my $volume_adjustment;
my $play_count;
my $play_date_utc;
my $artwork_count;
my $persistent_id;

my @row;

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
        }
        elsif ($_ =~ /<key>Artist<\/key>/) {
            $_ =~ s/^\t+//;
            $artist = substr($_, 25, -10);
        }
        elsif ($_ =~ /<key>Album Artist<\/key>/) {
            $_ =~ s/^\t+//;
            $album_artist = substr($_, 31, -10);
        }
        elsif ($_ =~ /<key>Album<\/key>/) {
            $_ =~ s/^\t+//;
            $album = substr($_, 24, -10);
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
        }
        elsif ($_ =~ /<key>Date Modified<\/key>/) {
            ($dt) = ($_ =~ /<date>(\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z)<\/date>/);
            $dt = DateTime::Format::ISO8601->parse_datetime($dt);
            $date_modified = $dt->epoch * 1000;


        }
        elsif ($_ =~ /<key>Date Added<\/key>/) {
            ($dt) = ($_ =~ /<date>(\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z)<\/date>/);
            $dt = DateTime::Format::ISO8601->parse_datetime($dt);
            $date_added = $dt->epoch * 1000;

        }
        elsif ($_ =~ /<key>Volume Adjustment<\/key>/) {
            ($volume_adjustment) = ($_ =~ /<integer>(-?\d+)<\/integer>/);
        }
        elsif ($_ =~ /<key>Play Count<\/key>/) {
            ($play_count) = ($_ =~ /<integer>(\d+)<\/integer>/);
        }
        elsif ($_ =~ /<key>Play Date UTC<\/key>/) {
            ($dt) = ($_ =~ /<date>(\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z)<\/date>/);
            $dt = DateTime::Format::ISO8601->parse_datetime($dt);
            $play_date_utc = $dt->epoch * 1000;
        }
        elsif ($_ =~ /<key>Artwork Count<\/key>/) {
            ($artwork_count) = ($_ =~ /<integer>(\d+)<\/integer>/);
        }
        elsif ($_ =~ /<key>Persistent ID<\/key>/) {
            ($persistent_id) = ($_ =~ /<string>(\w+)<\/string/);
        }
        
        if ( m{$endof_stanza} ) {

            if (!$disc_number) { $disc_number = 0; }
            elsif (!$disc_count) { $disc_count = 0; }
            elsif (!$track_number) { $track_number = 0; }
            elsif (!$track_count) { $track_count = 0; }
            elsif (!$year) { $year = 0; }
            elsif (!$date_modified) { $date_modified = 0; }
            elsif (!$date_added) { $date_added = 0; }
            elsif (!$volume_adjustment) { $volume_adjustment = 0; }
            elsif (!$play_count) { $play_count = 0; }
            elsif (!$play_date_utc) { $play_date_utc = 0; }
            elsif (!$artwork_count) { $artwork_count = 0; }

            print "$track_id $name $artist $album_artist $album $genre $disc_number/$disc_count $track_number/$track_count \ 
            $year $date_modified $date_added $volume_adjustment $play_count $play_date_utc $artwork_count $persistent_id\n";

            $sth_itunes->execute($track_id, $name, $artist, $album_artist, $album, $genre, $disc_number, $disc_count, 
            $track_number, $track_count, $year, $date_modified, $date_added, $volume_adjustment, $play_count, $play_date_utc,
            $artwork_count, $persistent_id);
        }
    }

    if ($_ =~ /<key>Playlists<\/key>/) {
        last LINE;
    }
}

close IMLFILE;

$dbh->disconnect;
exit 0;