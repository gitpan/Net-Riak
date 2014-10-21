package Net::Riak::Transport::PBC;
{
  $Net::Riak::Transport::PBC::VERSION = '0.1700';
}

use Moose::Role;

with qw/
  Net::Riak::Role::PBC
  /;

1;

__END__

=pod

=head1 NAME

Net::Riak::Transport::PBC

=head1 VERSION

version 0.1700

=head1 AUTHOR

franck cuny <franck@lumberjaph.net>, robin edwards <robin.ge@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by linkfluence.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
