#!/usr/bin/env perl
use strict;
use warnings;
use Data::Dumper;
use open qw/:std :utf8/;
use DBI;
use XML::LibXML;
use Config::Tiny;

my $config = Config::Tiny->read('itunes_db.conf');
my $dbfile = $config->{_}->{dbfile};

my $dbh = DBI->connect("dbi:SQLite:dbname=$dbfile","","");
my $sth = $dbh->prepare('INSERT INTO ITUNES VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)');
 
local $SIG{__WARN__} = sub {
    my $message = shift;
    die $message;
};

my $track_id;

my $xml = XML::LibXML->load_xml(location => $dbfile);
     
#$sth->execute(undef, $talb, $tpe2, $tpe1, $tpos, $trck, $tcon, $tdor, $tit2, $ufid, $tdrc, undef);

exit 0;