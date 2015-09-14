#!/usr/bin/perl -w

use strict;
use warnings;

use MongoDB ();
use Parse::AccessLog;
use Data::Dumper qw(Dumper);
use 5.010;
use autodie 'open';
use POE qw(Wheel::FollowTail);

my $LOGPATH = "./logs/";


# Set up shared mongodb connection
my $client = MongoDB::MongoClient->new(host => 'localhost', port => 27017);
my $db = $client->get_database('parsed_logs');

# Iterate through arguments as filenames if they exist
# OR, iterate through default array
my @logs;
if (@ARGV) {
  @logs = @ARGV;
} else {
  @logs = ('site.access.log', 'site.error.log');
}

# Create a new POE session for each file
for my $file (@logs) {
  say "Creating new session for $file...";
  &create_session($file);
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
        $_[HEAP]{collection} = $db->get_collection($filename);
      },
      got_line => sub {
        my $parsed = parse_line($_[ARG0]);
        insert_into_db($parsed, $_[HEAP]{collection});

      },
      got_log_rollover => sub {
        say "Log rolled over.";
      },
    },
  );

}

# Misc subroutines to do the work
sub insert_into_db {
  my ($data, $collection) = @_;
  $collection->insert($data);
}

sub parse_line {
  my ($user, $loggedat, $method, 
      $path, $status, $bytessent, 
      $referer, $useragent, $ip, 
      $raw) = ( $_[0] =~ q(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\s-\s(.+)\s\[(.+)\]\s\"(\w+)\s(.+)\sHTTP/\d.\d\"\s(\d{3})\s(\d+)\s\"(http.+)\"\s\"(Mozilla.+)\"\s\"(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})\") );
  my %parsed = (
    "user" => $user, 
    "loggedAt" => $loggedat, 
    "method" => $method, 
    "path" => $path, 
    "status" => $status,
    "bytesSent" => $bytessent, 
    "referer" => $referer,
    "userAgent" => $useragent,
    "ip" => $ip, 
  );
  return \%parsed
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