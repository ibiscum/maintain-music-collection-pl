#!/usr/bin/env perl
use strict;
use warnings;
use Data::Dumper;
use Config::Tiny;
use LWP::UserAgent ();
use DBI;
use URI ();
use HTTP::Request;
use JSON;

my $ua = LWP::UserAgent->new(timeout => 10);
my $json =JSON->new;

my $req = HTTP::Request->new;
$req->method( 'GET' );

my $uri = URI->new( 'https://api.discogs.com/database/search' );
 
my $config = Config::Tiny->read('discogs_collection.conf');

my $token = $config->{_}->{token};
my $dbfile = $config->{_}->{dbfile};

$req->header('Authorization' => 'Discogs token=' . $token);

my $dbh = DBI->connect("dbi:SQLite:dbname=$dbfile","","");
my $sql_select = "SELECT DISTINCT ALBUM, ALBUMARTIST FROM ITEM i WHERE DISCOGS_RELEASE_ID IS NULL ORDER BY ALBUMARTIST ASC";
my $sth_select = $dbh->prepare($sql_select);
$sth_select->execute();

my $sql_update = 'UPDATE ITEM SET DISCOGS_RELEASE_ID = ? WHERE ALBUM = ? AND ALBUMARTIST = ?';
my $sth_update = $dbh->prepare($sql_update);

my $cnt = 0;

MASTER: while (my @row = $sth_select->fetchrow_array) {

  my $album = $row[0];
  my $albumartist = $row[1];
    
  $uri->query_form(type => 'release', release_title => $album, artist => $albumartist, format => 'CD');
  
  $req->uri( $uri );

  print "\n---------------------------------------\n";
  print "Request #" . $cnt++ . "\n";
  print "$uri\n";
  print "----------------------------------------\n";

  my $resp = $ua->request($req);
   
  if ($resp->is_success) {
    print "Headers response: ", join(", ", $resp->header_field_names);
    print "  $_: ", $resp->header($_) . "\n" for  $resp->header_field_names;

    my $msg = $resp->decoded_content;
    my $msg_decoded_json = $json->decode($msg);

    RELEASE: foreach (@{ $msg_decoded_json->{results} }) {
      if ($_->{user_data}->{in_collection}) {
        my $rel = $_->{id};
        print "Release ID: $rel\n";
        $sth_update->execute($rel, $album, $albumartist);
        next MASTER; 
      }
    }

    print Dumper($msg_decoded_json) . "\n";
    
    if ($resp->header('X-Discogs-Ratelimit-Remaining') <= 10) {
      sleep 30;
    }
  }
  else {
    print "HTTP GET error code: ", $resp->code, "\n";
    print "HTTP GET error message: ", $resp->message, "\n";

    if ($resp->code == 429) {
      sleep 30;
    }
  }
}
