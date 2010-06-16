package Net::Riak::Role::UserAgent;
BEGIN {
  $Net::Riak::Role::UserAgent::VERSION = '0.04';
}

# ABSTRACT: useragent for Net::Riak

use Moose::Role;
use LWP::UserAgent;

has useragent => (
    is => 'rw',
    isa => 'LWP::UserAgent',
    lazy => 1,
    default => sub {
        my $self = shift;
        my $ua = LWP::UserAgent->new;
        $ua->timeout(3);
        $ua;
    }
);

1;

__END__
=pod

=head1 NAME

Net::Riak::Role::UserAgent - useragent for Net::Riak

=head1 VERSION

version 0.04

=head1 AUTHOR

  franck cuny <franck@lumberjaph.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by linkfluence.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

