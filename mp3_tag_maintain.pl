#!/usr/bin/env perl
use strict;
use warnings;
use Path::Iterator::Rule;
use MP3::Tag;
use Data::Dumper;
use Data::UUID;
use open qw/:std :utf8/;

 
my $ug = Data::UUID->new;

local $SIG{__WARN__} = sub {
    my $message = shift;
    die $message;
};

my $key = 0;
my $trck;
my $tpos;
my $tcon;
my $tcmp;
my $tdrc;
my $tenc;
my $tsse;
my $tden;
my $talb;
my $tit2;
my $tpe1;
my $tpe2;
my $tkey;
my $tsrc;
my $tsoa;
my $tso2;
my $tsop;
my $tbpm;
my $comm;
my $tcom;
my $tdor;
my $ufid;

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
    # if ($id3v2->frame_have('TSOA') == 0) {
    #     $tsoa = "TSOA N/A";
    # } else {
    #     (my $name, my @info) = $id3v2->get_frames('TSOA');
    #     $tsoa = $info[0];
    # }

    # ALBUMARTIST
    if ($id3v2->frame_have('TPE2') == 0) {
        print "TPE2 missing: " . $file . "\n";
        exit 1;
    } else {
        (my $name, my @info) = $id3v2->get_frames('TPE2');
        $tpe2 = $info[0];
    }

    # ALBUMARTISTSORT
    # if ($id3v2->frame_have('TSO2') == 0) {
    #     $tso2 = "TSO2 N/A";
    # } else {
    #     (my $name, my @info) = $id3v2->get_frames('TSO2');
    #     $tso2 = $info[0];
    # }

    # ARTIST
    if ($id3v2->frame_have('TPE1') == 0) {
        print "TPE1 missing: " . $file . "\n";
        exit 1;
    } else {
        (my $name, my @info) = $id3v2->get_frames('TPE1');
        $tpe1 = $info[0];
    }

    # ARTISTSORT
    # if ($id3v2->frame_have('TSOP') == 0) {
    #     $tsop = "TSOP N/A";
    # } else {
    #     (my $name, my @info) = $id3v2->get_frames('TSOP');
    #     $tsop = $info[0];
    # }

    # BPM
    if ($id3v2->frame_have('TBPM') == 0) {
        $tbpm = "TBPM N/A";
    } else {
        (my $name, my @info) = $id3v2->get_frames('TBPM');
        $tbpm = $info[0];
    }

    # COMMENT
    if ($id3v2->frame_have('COMM') == 0) {
        $comm = "COMM N/A";
    } else {
        (my $name, my @info) = $id3v2->get_frames('COMM');
        $comm = $info[0];
    }

    # COMPILATION
    if ($id3v2->frame_have('TCMP') == 0) {
        $tcmp = 0;
    } else {
        (my $name, my @info) = $id3v2->get_frames('TCMP');
        $tcmp = $info[0];
    }

    # COMPOSER
    if ($id3v2->frame_have('TCOM') == 0) {
        $tcom = "TCOM N/A";
    } else {
        (my $name, my @info) = $id3v2->get_frames('TCOM');
        $comm = $info[0];
    }

    if ($id3v2->frame_have('TRCK') == 0) {
        print "TRCK missing: " . $file . "\n";
        exit 1;
    } else {
        (my $name, my @info) = $id3v2->get_frames('TRCK');
        $trck = $info[0];
    }

    # DISCNUMBER
    if ($id3v2->frame_have('TPOS') == 0) {
        print "TPOS missing: " . $file . "\n";
        exit 1;
    } else {
        (my $name, my @info) = $id3v2->get_frames('TPOS');
        $tpos = $info[0];
    }

    # ENCODEDBY
    if ($id3v2->frame_have('TENC') == 0) {
        $tenc = "N/A";
    } else {
        (my $name, my @info) = $id3v2->get_frames('TENC');
        $tenc = $info[0];
    }

    # ENCODERSETTINGS
    if ($id3v2->frame_have('TSSE') == 0) {
        $tsse = "N/A";
    } else {
        (my $name, my @info) = $id3v2->get_frames('TSSE');
        $tsse = $info[0];
    }

    # ENCODINGTIME
    if ($id3v2->frame_have('TDEN') == 0) {
        $tden = "N/A";
    } else {
        (my $name, my @info) = $id3v2->get_frames('TDEN');
        $tden = $info[0];
    }

    # 
    if ($id3v2->frame_have('TCON') == 0) {
        print "TCON missing: " . $file . "\n";
        exit 1;
    } else {
        (my $name, my @info) = $id3v2->get_frames('TCON');
        $tcon = $info[0];
    }

    if ($id3v2->frame_have('TIT2') == 0) {
        print "TIT2 missing: " . $file . "\n";
        exit 1;
    } else {
        (my $name, my $info) = $id3v2->get_frames('TIT2');
        print $name . "\n";
        $tit2 = $info;
        print $tit2 . "\n";
    }

    # if ($id3v2->frame_have('TKEY') == 0) {
    #     $tkey = "TKEY N/A"
    # } else {
    #     (my $name, my @info) = $id3v2->get_frames('TKEY');
    #     $tkey = $info[0];
    # }

    if ($id3v2->frame_have('TSRC') == 0) {
        $tsrc = "TSRC N/A"
    } else {
        (my $name, my @info) = $id3v2->get_frames('TSRC');
        $tsrc = $info[0];
        # print Dumper($id3v2->get_frames('TSRC'));
    }

    # UNIQUE FILE IDENTIFIER
    if ($id3v2->frame_have('UFID') == 0) {
        $mp3->config("write_v24" => 1);      # Set object options
        # my $name = "Unique file identifier";
        my $uuid = $ug->create();
        my $uuid_str = lc($ug->to_string( $uuid ));
        my %info = ('Text' => "https://liudman.de", '_Data' => $uuid_str);
        my $info_ref = \%info;
        $id3v2->frame_select_by_descr("UFID", "https://liudman.de", $uuid_str); # Set/Change
        $id3v2->write_tag();
        print Dumper($info_ref);
        $ufid = get_value($info_ref->{'_Data'});
    } else {
        (my $name, my $info) = $id3v2->get_frames('UFID');
        print $name . "\n";
        print get_value($info->{'Text'}) . "\n";
        $ufid = get_value($info->{'_Data'});
        print $ufid . "\n";
        print Dumper($info);
        # exit 2;
    }

    if ($id3v2->frame_have('TDRC') == 0) {
        print "TDRC missing: " . $file . "\n";
        exit 1;
    } else {
        (my $name, my @info) = $id3v2->get_frames('TDRC');
        $tdrc = $info[0];
    }

    # ORIGYEAR
    if ($id3v2->frame_have('TDOR') == 0) {
        $tdor = "TDOR N/A";
    } else {
        (my $name, my @info) = $id3v2->get_frames('TDOR');
        $tdor = $info[0];
    }


    print "$trck\t$tpos\t$tcmp\t$tcon\t$tdor\t$tdrc\t$tsrc\t$ufid\t$tit2   $talb   $tpe1   $tpe2\n"; 
    $key++;
}

sub get_value {
  my ($hash) = @_;
  ($hash) = values %$hash while ref $hash eq 'HASH';
  $hash;
}

exit 0;