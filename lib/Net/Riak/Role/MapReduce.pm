package Net::Riak::Role::MapReduce;
BEGIN {
  $Net::Riak::Role::MapReduce::VERSION = '0.07';
}

use Moose::Role;
use Net::Riak::MapReduce;

sub add {
    my ($self, @args) = @_;
    my $mr = Net::Riak::MapReduce->new(client => $self->client);
    $mr->add(@args);
    $mr;
}

sub link {
    my ($self, @args) = @_;
    my $mr = Net::Riak::MapReduce->new(client => $self->client);
    $mr->link(@args);
    $mr;
}

sub map {
    my ($self, @args) = @_;
    my $mr = Net::Riak::MapReduce->new(client => $self->client);
    $mr->mapd(@args);
    $mr;
}

sub reduce {
    my ($self, @args) = @_;
    my $mr = Net::Riak::MapReduce->new(client => $self->client);
    $mr->reduce(@args);
    $mr;
}

1;

__END__
=pod

=head1 NAME

Net::Riak::Role::MapReduce

=head1 VERSION

version 0.07

=head1 AUTHOR

franck cuny <franck@lumberjaph.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by linkfluence.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

