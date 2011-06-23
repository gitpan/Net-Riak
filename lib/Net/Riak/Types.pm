package Net::Riak::Types;
BEGIN {
  $Net::Riak::Types::VERSION = '0.1502';
}

use MooseX::Types::Moose qw/Str ArrayRef HashRef/;
use MooseX::Types::Structured qw(Tuple Optional Dict);
use MooseX::Types -declare =>
  [qw(Socket Client HTTPResponse HTTPRequest RiakHost)];

class_type Socket,       { class => 'IO::Socket::INET' };
class_type Client,       { class => 'Net::Riak::Client' };
class_type HTTPRequest,  { class => 'HTTP::Request' };
class_type HTTPResponse, { class => 'HTTP::Response' };

subtype RiakHost, as ArrayRef [HashRef];

coerce RiakHost, from Str, via {
    [ { node => $_, weight => 1 } ];
};

coerce RiakHost, from ArrayRef, via {
    warn "DEPRECATED: Support for multiple hosts will be removed in the 0.17 release.";
    my $backends = $_;
    my $weight   = 1 / @$backends;
    [ map { { node => $_, weight => $weight } } @$backends ];
};

coerce RiakHost, from HashRef, via {
    warn "DEPRECATED: Support for multiple hosts will be removed in the 0.17 release.";
    my $backends = $_;
    my $total    = 0;
    $total += $_ for values %$backends;
    [
        map { { node => $_, weight => $backends->{$_} / $total } }
          keys %$backends
    ];
};

1;


__END__
=pod

=head1 NAME

Net::Riak::Types

=head1 VERSION

version 0.1502

=head1 AUTHOR

franck cuny <franck@lumberjaph.net>, robin edwards <robin.ge@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by linkfluence.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

