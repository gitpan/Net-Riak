package Net::Riak::Client;
BEGIN {
  $Net::Riak::Client::VERSION = '0.04';
}

use Moose;
use MIME::Base64;

with qw/
  Net::Riak::Role::REST
  Net::Riak::Role::UserAgent
  Net::Riak::Role::Hosts
  /;

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
has [qw/r w dw/] => (
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

Net::Riak::Client

=head1 VERSION

version 0.04

=head1 AUTHOR

  franck cuny <franck@lumberjaph.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by linkfluence.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

