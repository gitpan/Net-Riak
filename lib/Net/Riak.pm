package Net::Riak;
BEGIN {
  $Net::Riak::VERSION = '0.02';
}

# ABSTRACT: Interface to Riak

use Moose;

use Net::Riak::Client;
use Net::Riak::Bucket;

with 'Net::Riak::Role::MapReduce';

has client => (
    is       => 'rw',
    isa      => 'Net::Riak::Client',
    required => 1,
    handles  => [qw/request useragent/]
);

sub BUILDARGS {
    my ($class, %args) = @_;
    my $client = Net::Riak::Client->new(%args);
    $args{client} = $client;
    \%args;
}

sub bucket {
    my ($self, $name) = @_;
    my $bucket = Net::Riak::Bucket->new(name => $name, client => $self->client);
    $bucket;
}

sub is_alive {
    my $self     = shift;
    my $request  = $self->request('GET', ['ping']);
    my $response = $self->useragent->request($request);
    $response->is_success ? return 1 : return 0;
}

1;


__END__
=pod

=head1 NAME

Net::Riak - Interface to Riak

=head1 VERSION

version 0.02

=head1 SYNOPSIS

    my $client = Net::Riak->new(host => 'http://10.0.0.40:8098');
    my $bucket = $client->bucket('blog');
    my $obj    = $bucket->new_object('new_post', {title => 'foo', content => 'bar'});
    $obj->store;

    my $obj = $bucket->get('new_post');

=head1 DESCRIPTION

=head2 ATTRIBUTES

=over 4

=item B<host>

Hostname or IP address (default 'http://127.0.0.1:8098')

=item B<prefix>

Interface prefix (default 'riak')

=item B<mapred_prefix>

MapReduce prefix (default 'mapred')

=item B<r>

R value setting for this client (default 2)

=item B<w>

W value setting for this client (default 2)

=item B<dw>

DW value setting for this client (default 2)

=item B<client_id>

client_id for this client

=back

=head2 METHODS

=head1 METHODS

=head2 bucket

    my $bucket = $client->bucket($name);

Get the bucket by the specified name. Since buckets always exist, this will always return a L<Net::Riak::Bucket>

=head2 is_alive

    if (!$client->is_alive) {
        ...
    }

Check if the Riak server for this client is alive

=head2 add

    my $map_reduce = $client->add('bucket_name', 'key');

Start assembling a Map/Reduce operation

=head2 link

    my $map_reduce = $client->link();

Start assembling a Map/Reduce operation

=head2 map

    my $map_reduce = $client->add('bucket_name', 'key')->map("function ...");

Start assembling a Map/Reduce operation

=head2 reduce

    my $map_reduce = $client->add(..)->map(..)->reduce("function ...");

Start assembling a Map/Reduce operation

=head1 AUTHOR

  franck cuny <franck@lumberjaph.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by linkfluence.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

