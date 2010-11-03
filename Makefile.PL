
use strict;
use warnings;



use ExtUtils::MakeMaker 6.31;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'Interface to Riak',
  'AUTHOR' => 'franck cuny <franck@lumberjaph.net>',
  'BUILD_REQUIRES' => {
    'Data::Dumper' => '0',
    'HTTP::Response' => '0',
    'Test::More' => '0',
    'YAML::Syck' => '0'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.31'
  },
  'DISTNAME' => 'Net-Riak',
  'EXE_FILES' => [],
  'LICENSE' => 'perl',
  'NAME' => 'Net::Riak',
  'PREREQ_PM' => {
    'Carp' => '0',
    'HTTP::Request' => '0',
    'JSON' => '0',
    'LWP::UserAgent' => '0',
    'MIME::Base64' => '0',
    'Moose' => '0',
    'Moose::Role' => '0',
    'Moose::Util::TypeConstraints' => '0',
    'MooseX::Role::Parameterized' => '0',
    'Scalar::Util' => '0',
    'URI' => '0'
  },
  'VERSION' => '0.11',
  'test' => {
    'TESTS' => 't/*.t'
  }
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.56) } ) {
  my $br = delete $WriteMakefileArgs{BUILD_REQUIRES};
  my $pp = $WriteMakefileArgs{PREREQ_PM};
  for my $mod ( keys %$br ) {
    if ( exists $pp->{$mod} ) {
      $pp->{$mod} = $br->{$mod} if $br->{$mod} > $pp->{$mod};
    }
    else {
      $pp->{$mod} = $br->{$mod};
    }
  }
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);



