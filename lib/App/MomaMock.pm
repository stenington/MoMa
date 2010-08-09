package App::MomaMock;

use strict;
use warnings;

use Moose;

extends 'App::Moma';

has 'cmd' => (
  is => 'ro',
  writer => '_set_cmd',
  isa => 'Str',
);

sub _call {
  my ($self, $cmd) = @_;
  $self->_set_cmd( $cmd );
}

no Moose;

__PACKAGE__->meta->make_immutable;
