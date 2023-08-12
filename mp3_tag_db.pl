#!/usr/bin/env perl
use strict;
use warnings;
use Path::Iterator::Rule;
use MP3::Tag;
use Data::Dumper;
use Data::UUID;
use open qw/:std :utf8/;
use DBI;

my $dbfile = "/mnt/c/Users/Ulf/Music/iTunes/music.db";
my $dbh = DBI->connect("dbi:SQLite:dbname=$dbfile","","");
my $sth = $dbh->prepare('INSERT INTO MP3 VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)');
 
local $SIG{__WARN__} = sub {
    my $message = shift;
    die $message;
};

my $key = 0;

my $talb;
my $trck;
my $tcmp;
my $tcon;
my $tdor;
my $tdrc;
my $tpos;
my $tit2;
my $tsoa;
my $tpe2;
my $tso2;
my $tpe1;
my $ufid;
my $tsop;
     
die "Usage: $0 DIRs" if not @ARGV;
     
my $rule = Path::Iterator::Rule->new;
$rule->name("*.mp3");
     
my $it = $rule->iter( @ARGV );
while ( my $file = $it->() ) {
    my $record = "record_" . $key;  
    my $mp3 = MP3::Tag->new($file);
    $mp3->get_tags();

    my $id3v2 = $mp3->{ID3v2} if exists $mp3->{ID3v2};

    # ALBUM
    if ($id3v2->frame_have('TALB') == 0) {
        print "TALB missing: " . $file . "\n";
        exit 1;
    } else {
        (my $name, my @info) = $id3v2->get_frames('TALB');
        $talb = $info[0];
    }

    # ALBUMSORT
    if ($id3v2->frame_have('TSOA') == 0) {
        $tsoa = "TSOA N/A";
    } else {
        (my $name, my @info) = $id3v2->get_frames('TSOA');
        $tsoa = $info[0];
    }

    # ALBUMARTIST
    if ($id3v2->frame_have('TPE2') == 0) {
        print "TPE2 missing: " . $file . "\n";
        exit 1;
    } else {
        (my $name, my @info) = $id3v2->get_frames('TPE2');
        $tpe2 = $info[0];
    }

    # ALBUMARTISTSORT
    if ($id3v2->frame_have('TSO2') == 0) {
        $tso2 = "TSO2 N/A";
    } else {
        (my $name, my @info) = $id3v2->get_frames('TSO2');
        $tso2 = $info[0];
    }

    # ARTIST
    if ($id3v2->frame_have('TPE1') == 0) {
        print "TPE1 missing: " . $file . "\n";
        exit 1;
    } else {
        (my $name, my @info) = $id3v2->get_frames('TPE1');
        $tpe1 = $info[0];
    }

    # ARTISTSORT
    if ($id3v2->frame_have('TSOP') == 0) {
        $tsop = "TSOP N/A";
    } else {
        (my $name, my @info) = $id3v2->get_frames('TSOP');
        $tsop = $info[0];
    }

    # COMPILATION
    if ($id3v2->frame_have('TCMP') == 0) {
        $tcmp = 0;
    } else {
        (my $name, my @info) = $id3v2->get_frames('TCMP');
        $tcmp = $info[0];
    }

    # DISCNUMBER
    if ($id3v2->frame_have('TPOS') == 0) {
        print "TPOS missing: " . $file . "\n";
        exit 1;
    } else {
        (my $name, my @info) = $id3v2->get_frames('TPOS');
        $tpos = $info[0];
    }

    # CONTENT / GENRE 
    if ($id3v2->frame_have('TCON') == 0) {
        print "TCON missing: " . $file . "\n";
        exit 1;
    } else {
        (my $name, my @info) = $id3v2->get_frames('TCON');
        $tcon = $info[0];
    }

    # ORIGYEAR
    if ($id3v2->frame_have('TDOR') == 0) {
        $tdor = "TDOR N/A";
    } else {
        (my $name, my @info) = $id3v2->get_frames('TDOR');
        $tdor = $info[0];
    }

    # PART OF SET
    if ($id3v2->frame_have('TPOS') == 0) {
        $tdor = "TPOS N/A";
        exit 1;
    } else {
        (my $name, my @info) = $id3v2->get_frames('TPOS');
        $tpos = $info[0];
    }

    # TRACK
    if ($id3v2->frame_have('TRCK') == 0) {
        print "TRCK missing: " . $file . "\n";
        exit 1;
    } else {
        (my $name, my @info) = $id3v2->get_frames('TRCK');
        $trck = $info[0];
    }

    # TITLE
    if ($id3v2->frame_have('TIT2') == 0) {
        print "TIT2 missing: " . $file . "\n";
        exit 1;
    } else {
        (my $name, my $info) = $id3v2->get_frames('TIT2');
        print $name . "\n";
        $tit2 = $info;
        print $tit2 . "\n";
    }

    # UNIQUE FILE IDENTIFIER
    if ($id3v2->frame_have('UFID') == 0) {
        $ufid = "UFID N/A";    
    } else {
        (my $name, my $info) = $id3v2->get_frames('UFID');
        $ufid = get_value($info->{'_Data'});
    }

    if ($id3v2->frame_have('TDRC') == 0) {
        print "TDRC missing: " . $file . "\n";
        exit 1;
    } else {
        (my $name, my @info) = $id3v2->get_frames('TDRC');
        $tdrc = $info[0];
    }

    print "$tpos\t$trck\t$tcmp\t$tcon\t$tdor\t$tit2\t$ufid\t$tdrc   $talb   $tpe2   $tpe1\n";
    $sth->execute(undef, $talb, $tpe2, $tpe1, $tpos, $trck, $tcon, $tdor, $tit2, $ufid, $tdrc, undef);

    $key++;
}

sub get_value {
  my ($hash) = @_;
  ($hash) = values %$hash while ref $hash eq 'HASH';
  $hash;
}

exit 0;