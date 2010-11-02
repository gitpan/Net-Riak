package Net::Riak::Role::REST;
BEGIN {
  $Net::Riak::Role::REST::VERSION = '0.10';
}

# ABSTRACT: role for REST operations

use URI;
use HTTP::Request;
use Moose::Role;

requires 'http_request';
requires 'http_response';
requires 'useragent';

sub _build_path {
    my ($self, $path) = @_;
    $path = join('/', @$path);
}

sub _build_uri {
    my ($self, $path, $params) = @_;

    my $uri = URI->new($self->get_host);
    $uri->path($self->_build_path($path));
    $uri->query_form(%$params);
    $uri;
}

# constructs a HTTP::Request
sub new_request {
    my ($self, $method, $path, $params) = @_;
    my $uri = $self->_build_uri($path, $params);
    return HTTP::Request->new($method => $uri);
}

# makes a HTTP::Request returns and stores a HTTP::Response
sub send_request {
    my ($self, $req) = @_;

    $self->http_request($req);
    my $r = $self->useragent->request($req);
    $self->http_response($r);

    return $r;
}

1;

__END__
=pod

=head1 NAME

Net::Riak::Role::REST - role for REST operations

=head1 VERSION

version 0.10

=head1 AUTHOR

franck cuny <franck@lumberjaph.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by linkfluence.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

