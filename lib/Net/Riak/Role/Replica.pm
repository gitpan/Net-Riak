package Net::Riak::Role::Replica;
BEGIN {
  $Net::Riak::Role::Replica::VERSION = '0.11';
}

use MooseX::Role::Parameterized;

parameter keys => (
    isa      => 'ArrayRef',
    required => 1,
);

role {
    my $p = shift;

    my $keys = $p->keys;

    foreach my $k (@$keys) {
        has $k => (
            is      => 'rw',
            isa     => 'Int',
            lazy    => 1,
            default => sub { (shift)->client->$k }
        );
    }
};

1;

__END__
=pod

=head1 NAME

Net::Riak::Role::Replica

=head1 VERSION

version 0.11

=head1 AUTHOR

franck cuny <franck@lumberjaph.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by linkfluence.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

