package Net::Riak::Object;
{
  $Net::Riak::Object::VERSION = '0.1700';
}

# ABSTRACT: holds meta information about a Riak object

use Moose;
use Scalar::Util;
use Net::Riak::Link;

with 'Net::Riak::Role::Replica' => {keys => [qw/r w dw/]};
with 'Net::Riak::Role::Base' => {classes =>
      [{name => 'bucket', required => 1}]};
use Net::Riak::Types Client => {-as => 'Client_T'};
has client => (
    is       => 'rw',
    isa      => Client_T,
    required => 1,
);
has key => (is => 'rw', isa => 'Str', required => 0);
has exists       => (is => 'rw', isa => 'Bool', default => 0,);
has data         => (is => 'rw', isa => 'Any', clearer => '_clear_data');
has vclock       => (is => 'rw', isa => 'Str', predicate => 'has_vclock');
has vtag          => (is => 'rw', isa => 'Str');
has content_type => (is => 'rw', isa => 'Str', default => 'application/json');
has location     => ( is => 'rw', isa => 'Str' );
has _jsonize     => (is => 'rw', isa => 'Bool', lazy => 1, default => 1);
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
        has_links   => 'count',
        all_links   => 'elements',
    },
    clearer => '_clear_links',
);
has siblings => (
    traits     => ['Array'],
    is         => 'rw',
    isa        => 'ArrayRef[Str]',
    auto_deref => 1,
    lazy       => 1,
    default    => sub { [] },
    handles    => {
        get_siblings    => 'elements',
        add_sibling     => 'push',
        count_siblings  => 'count',
        get_sibling     => 'get',
        has_siblings    => 'count',
        has_no_siblings => 'is_empty',
    },
    clearer => '_clear_siblings',
);

after count_links => sub {
    warn "DEPRECATED: count_links method will be removed in the 0.17 release, please use has_links.";
};

sub store {
    my ($self, $w, $dw) = @_;

    $w  ||= $self->w;
    $dw ||= $self->dw;

    $self->client->store_object($w, $dw, $self);
}

sub status {
    my ($self) = @_;
    warn "DEPRECATED: status method will be removed in the 0.17 release, please use ->client->status.";
    $self->client->status;
}   

sub load {
    my $self = shift;

    my $params = {r => $self->r};

    $self->client->load_object($params, $self);
}

sub delete {
    my ($self, $dw) = @_;

    $dw ||= $self->bucket->dw;
    my $params = {dw => $dw};

    $self->client->delete_object($params, $self);
}

sub clear {
    my $self = shift;
    $self->_clear_data;
    $self->_clear_links;
    $self->exists(0);
    $self;
}

sub sibling {
    my ($self, $id, $r) = @_;
    $r ||= $self->bucket->r;

    my $vtag = $self->get_sibling($id);

    return $self->client->retrieve_sibling(
        $self, {r => $r, vtag => $vtag}
    );
}

sub _build_link {
    my ($self,$obj,$tag) = @_;
    blessed $obj && $obj->isa('Net::Riak::Link')
    ? $obj
    : Net::Riak::Link->new(
          bucket => $obj->bucket,
          key    => $obj->key,
          tag    => $tag || $self->bucket->name,
      );
}

around [qw{append_link remove_link add_link}] => sub{
   my $next = shift;
   my $self = shift;
   $self->$next($self->_build_link(@_));
};

sub add_link {
    my ($self, $link) = @_;
    $self->remove_link($link);
    $self->append_link($link);
    $self;
}

sub remove_link {
   my ($self, $link) = @_;
   my @links = grep { $_->key ne $link->key } @{$self->links};
   $self->_clear_links;
   $self->append_link($_) for @links;
   $self;
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

version 0.1700

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

=item B<links>

Get an array of L<Net::Riak::Link> objects

=item B<exists>

Return true if the object exists, false otherwise.

=item B<siblings>

Return an array of Siblings

=back

=head2 METHODS

=over 4

=item all_links

Return the number of links

=item has_links

Return the number of links

=item append_link

Add a new link

=item get_siblings

Return the number of siblings

=item add_sibling

Add a new sibling

=item count_siblings

=item get_sibling

Return a sibling

=item store

    $obj->store($w, $dw);

Store the object in Riak. When this operation completes, the object could contain new metadata and possibly new data if Riak contains a newer version of the object according to the object's vector clock.

=over 2

=item B<w>

W-value, wait for this many partitions to respond before returning to client.

=item B<dw>

DW-value, wait for this many partitions to confirm the write before returning to client.

=back

=item load

    $obj->load($w);

Reload the object from Riak. When this operation completes, the object could contain new metadata and a new value, if the object was updated in Riak since it was last retrieved.

=over 4

=item B<r>

R-Value, wait for this many partitions to respond before returning to client.

=back

=item delete

    $obj->delete($dw);

Delete this object from Riak.

=over 4

=item B<dw>

DW-value. Wait until this many partitions have deleted the object before responding.

=back

=item clear

    $obj->reset;

Reset this object

=item has_siblings

    if ($obj->has_siblings) { ... }

Return true if this object has siblings

=item has_no_siblings

   if ($obj->has_no_siblings) { ... }

Return true if this object has no siblings

=item populate_object

Given the output of RiakUtils.http_request and a list of statuses, populate the object. Only for use by the Riak client library.

=item add_link

    $obj->add_link($obj2, "tag");

Add a link to a L<Net::Riak::Object>

=item remove_link

    $obj->remove_link($obj2, "tag");

Remove a link to a L<Net::Riak::Object>

=item add

Start assembling a Map/Reduce operation

=item link

Start assembling a Map/Reduce operation

=item map

Start assembling a Map/Reduce operation

=item reduce

Start assembling a Map/Reduce operation

=back

=head1 AUTHOR

franck cuny <franck@lumberjaph.net>, robin edwards <robin.ge@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by linkfluence.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
