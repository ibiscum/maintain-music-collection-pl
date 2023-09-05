#!/usr/bin/env perl
use strict;
use warnings;

use Data::Dumper;
use DBI;
use File::Remove qw(remove);
use JSON;
use DateTime;
use open qw(:std :utf8);

remove('*.log');

my $debug_log = "lastfm_db_debug.log";
open (DEBUGLOG, "> $debug_log")  || die "Can't open $debug_log: $!\n";

my $json_text = do {
    open(my $json_fh, "<:encoding(UTF-8)", $ENV{LFM_SCROBBLES}) or die("Can't open $ENV{LFM_SCROBBLES}: $!\n");
    local $/;
    <$json_fh>
};

my $json = JSON->new;
my $data = $json->decode($json_text);

my $dbh = DBI->connect('dbi:Pg:dbname=music;host=localhost','postgres','secret',{AutoCommit=>1,RaiseError=>1,PrintError=>0});

local $SIG{__WARN__} = sub {
    my $message = shift;
    die $message;
};

my $id;
my $album;
my $artist;
my $date;
my $name;

$dbh->do('DROP TABLE IF EXISTS lastfm_data;');
$dbh->do('CREATE TABLE lastfm_data ( id integer PRIMARY KEY GENERATED ALWAYS AS IDENTITY, 
track text, album text, artist text, play_date_utc timestamp );') || die $dbh->errstr;

foreach my $outer (@{$data}) {
    foreach my $inner (@{$outer}) {

        my $track = $inner->{'name'};
        $track =~ s/'/''/g;
    
        my $album = $inner->{'album'}->{'#text'};
        $album =~ s/'/''/g;

        my $artist = $inner->{'artist'}->{'#text'};
        $artist =~ s/'/''/g;

        my $dt = $inner->{'date'}->{'uts'};
        $dt = DateTime->from_epoch( epoch => $dt );
        my $play_date_utc = $dt->datetime(' ');

        $dbh->do("INSERT INTO lastfm_data ( track, album, artist, play_date_utc ) VALUES ( '$track', '$album', '$artist', '$play_date_utc' );") || die $dbh->errstr;
    }
}

close DEBUGLOG;

exit 0;