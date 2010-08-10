package Net::Riak::Role::Hosts;
BEGIN {
  $Net::Riak::Role::Hosts::VERSION = '0.07';
}

use Moose::Role;
use Moose::Util::TypeConstraints;

subtype 'RiakHost' => as 'ArrayRef[HashRef]';

coerce 'RiakHost' => from 'Str' => via {
    [{node => $_, weight => 1}];
};
coerce 'RiakHost' => from 'ArrayRef' => via {
    my $backends = $_;
    my $weight   = 1 / @$backends;
    [map { {node => $_, weight => $weight} } @$backends];
};
coerce 'RiakHost' => from 'HashRef' => via {
    my $backends = $_;
    my $total    = 0;
    $total += $_ for values %$backends;
    [map { {node => $_, weight => $backends->{$_} / $total} }
          keys %$backends];
};

has host => (
    is      => 'rw',
    isa     => 'RiakHost',
    coerce  => 1,
    default => 'http://127.0.0.1:8098',
);

sub get_host {
    my $self = shift;

    my $choice;
    my $rand = rand;

    for (@{$self->host}) {
        $choice = $_->{node};
        ($rand -= $_->{weight}) <= 0 and last;
    }
    $choice;
}

1;

__END__
=pod

=head1 NAME

Net::Riak::Role::Hosts

=head1 VERSION

version 0.07

=head1 AUTHOR

franck cuny <franck@lumberjaph.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by linkfluence.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

