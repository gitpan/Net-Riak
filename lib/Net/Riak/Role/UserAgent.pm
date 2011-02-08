package Net::Riak::Role::UserAgent;
BEGIN {
  $Net::Riak::Role::UserAgent::VERSION = '0.13';
}

# ABSTRACT: useragent for Net::Riak

use Moose::Role;
use LWP::UserAgent;
use LWP::ConnCache;

our $CONN_CACHE;

sub connection_cache { $CONN_CACHE ||= LWP::ConnCache->new }

has useragent => (
    is      => 'rw',
    isa     => 'LWP::UserAgent',
    lazy    => 1,
    default => sub {
        my $self = shift;

        # The Links header Riak returns (esp. for buckets) can get really long,
        # so here increase the MaxLineLength LWP will accept (default = 8192)
        my %opts = @LWP::Protocol::http::EXTRA_SOCK_OPTS;
        $opts{MaxLineLength} = 65_536;
        @LWP::Protocol::http::EXTRA_SOCK_OPTS = %opts;

        my $ua = LWP::UserAgent->new(
            timeout => $self->ua_timeout
        );

        $ua->conn_cache(__PACKAGE__->connection_cache);

        $ua;
    }
);

1;

__END__
=pod

=head1 NAME

Net::Riak::Role::UserAgent - useragent for Net::Riak

=head1 VERSION

version 0.13

=head1 AUTHOR

franck cuny <franck@lumberjaph.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by linkfluence.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

