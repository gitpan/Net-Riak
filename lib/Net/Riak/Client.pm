package Net::Riak::Client;
BEGIN {
  $Net::Riak::Client::VERSION = '0.02';
}

use Moose;
use MIME::Base64;

with qw/Net::Riak::Role::REST Net::Riak::Role::UserAgent/;

has host => (
    is      => 'rw',
    isa     => 'Str',
    default => 'http://127.0.0.1:8098'
);
has prefix => (
    is      => 'rw',
    isa     => 'Str',
    default => 'riak'
);
has mapred_prefix => (
    is      => 'rw',
    isa     => 'Str',
    default => 'mapred'
);
has r => (
    is      => 'rw',
    isa     => 'Int',
    default => 2
);
has w => (
    is      => 'rw',
    isa     => 'Int',
    default => 2
);
has dw => (
    is      => 'rw',
    isa     => 'Int',
    default => 2
);
has client_id => (
    is         => 'rw',
    isa        => 'Str',
    lazy_build => 1,
);

sub _build_client_id {
    "perl_net_riak" . encode_base64(int(rand(10737411824)), '');
}

1;

__END__
=pod

=head1 NAME

Net::Riak::Client

=head1 VERSION

version 0.02

=head1 AUTHOR

  franck cuny <franck@lumberjaph.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by linkfluence.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

