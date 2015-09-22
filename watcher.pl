#!/usr/bin/perl -w

use strict;
use warnings;

use YAML::XS qw(LoadFile);
use Data::Dumper qw(Dumper);
use 5.010;
use autodie 'open';
use POE qw(Wheel::FollowTail);

use MongoDB ();
use Search::Elasticsearch;

my $LOGPATH = "./logs/";
my $DATAPATH = "./data/";


# Set up shared mongodb connection
my $client = MongoDB::MongoClient->new(host => 'localhost', port => 27017);
my $db = $client->get_database('parsed_logs');

# Set up connection to local Elasticsearch cluster
my $e = Search::Elasticsearch->new();

# Iterate through arguments as filenames if they exist
# OR, iterate through default array
my $logs;
if (@ARGV) {
  $logs = @ARGV;
} else {
  my $codex = LoadFile('./data/codex.yml');
  $logs = ($codex->{domains});
}

# Create a new POE session for each file
for (@{$logs}) {
  say "Creating new session for $_...";
  &create_session($_);
}

# Run the POE kernel
$poe_kernel->run();

# The basic POE session creation engine
sub create_session {
  my $filename = $_[0];
  POE::Session->create(
    inline_states => {
      _start => sub {
        # Open the file for tailing
        $_[HEAP]{wheel} = POE::Wheel::FollowTail->new(
          Filename   => $LOGPATH . $filename,
          InputEvent => 'got_line',
          ResetEvent => "got_log_rollover",
          SeekBack   => 8192,
        );
        # Open the collection the mongo collection
        $_[HEAP]{collection} = open_collection($filename);
        # Create ES index
        $_[HEAP]{es_index} = open_index($filename);
      },
      got_line => sub {
        my $parsed = parse_line($_[ARG0]);
        # Insert document into MongoDB
        insert_into_db($parsed, $_[HEAP]{collection});
        # Insert index into ES
        insert_into_es($parsed, $_[HEAP]{es_index});
      },
      got_log_rollover => sub {
        say "Log rolled over.";
      },
    },
  );

}

# Misc subroutines to do the work

sub open_collection {
  my $collection = $db->get_collection($_[0]);
  return $collection;
}

sub open_index {
  my $filename = $_[0];
  my $response;
  if ( ($e->indices->exists(index => $filename)) == 1 ) {
    $response = $e->indices->get( index => $filename );
  } else {
    $response = $e->indices->create( index => $filename );
  }
  return $response;
}

sub insert_into_db {
  my ($data, $collection) = @_;
  $collection->insert($data);
}

sub insert_into_es {
  my ($data, $index) = @_;
  my $name = (keys $index)[0];
  $e->index(
   index   => $name,
   type    => 'logline',
   body    => { 'data' => $data },
  );
}

sub parse_line {
  my ($remote_addr, $remote_user, $logged_at, 
      $method, $path, $http, $status, $bytes_sent, 
      $referer, $user_agent, $user_ip) =
      ($_[0] =~    /^ (\S+)        # remote_addr
                   \ \-\ (\S+)     # remote_user
                   \ \[([^\]]+)\]  # time_local
                   \ \"(\S+)       # method
                   \ (\S+)         # path 
                   \ (\S+)\"       # http 
                   \ (\d+)         # status
                   \ (\-|(?:\d+))  # bytes_sent
                   \ "(\S+)"       # referer
                   \ "(.*?)"       # user_agent
                   \ "(.*?)"       # user_ip
                   $ /x ); # /x for freespacing

  my %parsed = (
    "remoteUser" => $remote_user, 
    "loggedAt" => $logged_at, 
    "method" => $method, 
    "path" => $path, 
    "status" => $status,
    "bytesSent" => $bytes_sent, 
    "referer" => $referer,
    "userAgent" => $user_agent,
    "ip" => $user_ip, 
  );
  return \%parsed;
}



# Initial proof-of-concent version
#use File::Tail;
#my $db = $client->get_database('parsed_logs');
#my $logcoll = $db->get_collection('loglines');
#my $file = File::Tail->new("requests.log");
#while (defined(my $line= $file->read)) {
#  my $rec = Parse::AccessLog->parse($line);
#  print Dumper $rec;
#  $logcoll->insert($rec);
#}#