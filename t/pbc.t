use Net::Riak;
use strict;
use warnings;

use Test::More;

my $r = Net::Riak->new(
        transport => 'PBC',
        host => '10.0.0.40',
        port => 8080
    );

is $r->client->timeout,30, "timeout defaults to 30";

my $r = Net::Riak->new(
        transport => 'PBC',
        host => '10.0.0.40',
        port => 8080,
        timeout => 2,
    );

is $r->client->timeout, 2, "timeout changed";





done_testing;
