package Net::Riak::Object;
BEGIN {
  $Net::Riak::Object::VERSION = '0.01';
}

# ABSTRACT: holds meta information about a Riak object

use Carp;
use JSON;
use Moose;
use Scalar::Util;
use Net::Riak::Link;

has key    => (is => 'rw', isa => 'Str',               required => 1);
has client => (is => 'rw', isa => 'Net::Riak',         required => 1);
has bucket => (is => 'rw', isa => 'Net::Riak::Bucket', required => 1);
has data => (is => 'rw', isa => 'Any', clearer => '_clear_data');
has r =>
  (is => 'rw', isa => 'Int', lazy => 1, default => sub { (shift)->client->r });
has w =>
  (is => 'rw', isa => 'Int', lazy => 1, default => sub { (shift)->client->w });
has dw => (
    is      => 'rw',
    isa     => 'Int',
    lazy    => 1,
    default => sub { (shift)->client->dw }
);
has content_type => (is => 'rw', isa => 'Str', default => 'application/json');
has status       => (is => 'rw', isa => 'Int');
has links => (
    traits     => ['Array'],
    is         => 'rw',
    isa        => 'ArrayRef[Net::Riak::Link]',
    auto_deref => 1,
    lazy       => 1,
    default    => sub { [] },
    handles    => {
        count_links => 'elements',
        append_link => 'push',
    },
    clearer => '_clear_links',
);
has exists => (
    is => 'rw',
    isa => 'Bool',
    default => 0,
);
has vclock => (
    is => 'rw',
    isa => 'Str',
    predicate => 'has_vclock',
);
has siblings => (
    traits     => ['Array'],
    is         => 'rw',
    isa        => 'ArrayRef[Str]',
    auto_deref => 1,
    lazy       => 1,
    default    => sub { [] },
    handles    => {
        get_siblings   => 'elements',
        add_sibling    => 'push',
        count_siblings => 'count',
        get_sibling    => 'get',
    },
    clearer => '_clear_links',
);

has _headers => (
    is  => 'rw',
    isa => 'HTTP::Response',
);
has _jsonize => (
    is      => 'rw',
    isa     => 'Bool',
    lazy    => 1,
    default => 1,
);

sub store {
    my ($self, $w, $dw) = @_;

    $w  ||= $self->w;
    $dw ||= $self->dw;

    my $params = {returnbody => 'true', w => $w, dw => $dw};

    my $request =
      $self->client->request('PUT',
        [$self->client->prefix, $self->bucket->name, $self->key], $params);

    $request->header('X-Riak-ClientID' => $self->client->client_id);
    $request->header('Content-Type'    => $self->content_type);

    if ($self->has_vclock) {
        $request->header('X-Riack-Vclock' => $self->vclock);
    }

    my $header_link = '';
    foreach my $l ($self->links) {
        $header_link .= ', ' if ($header_link ne '');
        $header_link .= $l->to_link_header($self->client);
    }
    $request->header('link' => $header_link);

    if ($self->_jsonize) {
        $request->content(JSON::encode_json($self->data));
    }
    else {
        $request->content($self->data);
    }

    my $response = $self->client->useragent->request($request);
    $self->populate($response, [200, 300]);
    $self;
}

sub load {
    my $self = shift;

    my $params = {r => $self->r};

    my $request =
      $self->client->request('GET',
        [$self->client->prefix, $self->bucket->name, $self->key], $params);

    my $response = $self->client->useragent->request($request);
    $self->populate($response, [200, 300, 404]);
    $self;
}

sub delete {
    my ($self, $dw) = @_;

    $dw ||= $self->bucket->dw;
    my $params = {dw => $dw};

    my $request =
      $self->client->request('DELETE',
        [$self->client->prefix, $self->bucket->name, $self->key], $params);

    my $response = $self->client->useragent->request($request);
    $self->populate($response, [204, 404]);
}

sub clear {
    my $self = shift;
    $self->_clear_data;
    $self->_clear_links;
    $self->exists(0);
}

sub has_siblings {
    my $self = shift;
    $self->get_siblings > 0 ? return 1 : return 0;
}

sub populate {
    my ($self, $http_response, $expected) = @_;

    $self->clear;

    return if (!$http_response);

    my $status = $http_response->code;
    $self->_headers($http_response);
    $self->status($status);

    $self->data($http_response->content);

    if (!grep { $status == $_ } @$expected) {
        croak "Expected status "
          . (join(', ', @$expected))
          . ", received $status";
    }

    if ($status == 404) {
        $self->clear;
        return;
    }

    $self->exists(1);

    if ($http_response->header('link')) {
        $self->populate_links($http_response->header('link'));
    }

    if ($status == 300) {
        my @siblings = split("\n", $self->data);
        shift @siblings;
        $self->siblings(\@siblings);
    }

    if ($status == 200 && $self->_jsonize) {
        $self->data(JSON::decode_json($self->data));
    }
}

sub populate_links {
    my ($self, $links) = @_;

    for my $link (split(',', $links)) {
        if ($link
            =~ /\<\/([^\/]+)\/([^\/]+)\/([^\/]+)\>; ?riaktag=\"([^\']+)\"/)
        {
            my $bucket = $2;
            my $key    = $3;
            my $tag    = $4;
            my $l      = Net::Riak::Link->new(
                bucket => Net::Riak::Bucket->new(
                    name   => $bucket,
                    client => $self->client
                ),
                key => $key,
                tag => $tag
            );
            $self->add_link($link);
        }
    }
}

sub sibling {
    my ($self, $id, $r) = @_;
    $r ||= $self->bucket->r;

    my $vtag = $self->get_sibling($id);
    my $params = {r => $r, vtag => $vtag};

    my $request =
      $self->client->request('GET',
        [$self->client->prefix, $self->bucket->name, $self->key], $params);
    my $response = $self->client->useragent->request($request);

    my $obj = Net::Riak::Object->new(
        client => $self->client,
        bucket => $self->bucket,
        key    => $self->key
    );
    $obj->_jsonize($self->_jsonize);
    $obj->populate($response, [200]);
    $obj;
}

sub add_link {
    my ($self, $obj, $tag) = @_;
    my $new_link;
    if (blessed $obj && $obj->isa('Net::Riak::Link')) {
        $new_link = $obj;
    }
    else {
        $new_link = Net::Riak::Link->new(
            bucket => $self->bucket,
            key    => $self->key,
            tag    => $tag || $self->bucket->name,
        );
    }
    $self->remove_link($new_link);
    $self->append_link($new_link);
    $self;
}

sub remove_link {
    my ($self, $obj, $tag) = @_;
    my $new_link;
    if (blessed $obj && $obj->isa('RiakLink')) {
        $new_link = $obj;
    }
    else {
        $new_link = Net::Riak::Link->new(
            bucket => $self->bucket,
            key    => $self->key,
            tag    => $tag || ''
        );
    }

    # XXX purge links!
}

sub add {
    my ($self, @args) = @_;
    my $map_reduce = Net::Riak::MapReduce->new(client => $self->client);
    $map_reduce->add($self->bucket->name, $self->key);
    $map_reduce->add(@args);
    $map_reduce;
}

sub link {
    my ($self, @args) = @_;
    my $map_reduce = Net::Riak::MapReduce->new(client => $self->client);
    $map_reduce->add($self->bucket->name, $self->key);
    $map_reduce->link(@args);
    $map_reduce;
}

sub map {
    my ($self, @args) = @_;
    my $map_reduce = Net::Riak::MapReduce->new(client => $self->client);
    $map_reduce->add($self->bucket->name, $self->key);
    $map_reduce->map(@args);
    $map_reduce;
}

sub reduce {
    my ($self, @args) = @_;
    my $map_reduce = Net::Riak::MapReduce->new(client => $self->client);
    $map_reduce->add($self->bucket->name, $self->key);
    $map_reduce->reduce(@args);
    $map_reduce;
}

1;


__END__
=pod

=head1 NAME

Net::Riak::Object - holds meta information about a Riak object

=head1 VERSION

version 0.01

=head1 SYNOPSIS

    my $obj = $bucket->get('foo');

=head1 DESCRIPTION

The L<Net::Riak::Object> holds meta information about a Riak object, plus the object's data.

=head2 ATTRIBUTES

=over 4

=item B<key>

    my $key = $obj->key;

Get the key of this object

=item B<client>

=item B<bucket>

=item B<data>

Get or set the data stored in this object.

=item B<r>

=item B<w>

=item B<dw>

=item B<content_type>

=item B<status>

Get the HTTP status from the last operation on this object.

=item B<links>

Get an array of L<Net::Riak::Link> objects

=item B<exists>

Return true if the object exists, false otherwise.

=item B<siblings>

Return an array of Siblings

=back

=head2 METHODS

=head1 METHODS

=head2 count_links

Return the number of links

=head2 append_link

Add a new link

=head2 get_siblings

Return the number of siblings

=head2 add_sibling

Add a new sibling

=head2 count_siblings

=head2 get_sibling

Return a sibling

=head2 store

    $obj->store($w, $dw);

Store the object in Riak. When this operation completes, the object could contain new metadata and possibly new data if Riak contains a newer version of the object according to the object's vector clock.

=over 2

=item B<w>

W-value, wait for this many partitions to respond before returning to client.

=item B<dw>

DW-value, wait for this many partitions to confirm the write before returning to client.

=back

=head2 load

    $obj->load($w);

Reload the object from Riak. When this operation completes, the object could contain new metadata and a new value, if the object was updated in Riak since it was last retrieved.

=over 4

=item B<r>

R-Value, wait for this many partitions to respond before returning to client.

=back

=head2 delete

    $obj->delete($dw);

Delete this object from Riak.

=over 4

=item B<dw>

DW-value. Wait until this many partitions have deleted the object before responding.

=back

=head2 clear

    $obj->reset;

Reset this object

=head2 has_siblings

    if ($obj->has_siblings) { ... }

Return true if this object has siblings

=head2 populate

Given the output of RiakUtils.http_request and a list of statuses, populate the object. Only for use by the Riak client library.

=head2 add_link

    $obj->add_link($obj2, "tag");

Add a link to a L<Net::Riak::Object>

=head2 remove_link

    $obj->remove_link($obj2, "tag");

Remove a link to a L<Net::Riak::Object>

=head2 add

Start assembling a Map/Reduce operation

=head2 link

Start assembling a Map/Reduce operation

=head2 map

Start assembling a Map/Reduce operation

=head2 reduce

Start assembling a Map/Reduce operation

=head1 AUTHOR

  franck cuny <franck@lumberjaph.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by linkfluence.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

