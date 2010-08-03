package App::Moma;

use strict;
use warnings;

our $VERSION = '0.0.2';

use Config::Tiny;
use Moose;

has 'ports_on' => (
  is => 'rw',
  isa => 'ArrayRef[Str]',
  default => sub{ [] },
);

has 'ports_off' => (
  is => 'rw',
  isa => 'ArrayRef[Str]',
  default => sub{ [] },
);

has 'modes' => (
  is => 'rw',
  isa => 'HashRef[Str]',
  default => sub{ {} },
);

has 'portnames' => (
  is => 'rw',
  isa => 'HashRef[Str]',
  default => sub{ {} },
);

sub load_rc {
  my ($self, $cfgfile) = @_;

  unless( $cfgfile ){
    $cfgfile = $ENV{HOME} . "/.moma";
    return 0 unless -f $cfgfile;
  }

  $cfgfile =~ s/^~/$ENV{HOME}/;
  my $cfg = Config::Tiny->read( $cfgfile ) or die "Unable to load $cfgfile: " . Config::Tiny::errstr;
  $self->portnames($cfg->{identifiers}) if $cfg->{identifiers};
  $self->modes($cfg->{modes}) if $cfg->{modes};
  return 1;
}

sub parse_args {
  my ($self, $str) = @_;
  $DB::single=1;
  my ($on, $off) = $self->_parse($str);
  my $ports_on = $self->_map_to_portnames( $on );
  my $ports_off = $self->_map_to_portnames( $off );
  $self->ports_on( $ports_on );
  $self->ports_off( $ports_off );
  return @{$self->ports_on} + @{$self->ports_off};
}

sub _map_to_portnames {
  my ($self, $ids) = @_;
  my $portnames = [];
  foreach my $mon (split(//, $ids)) {
    die "Unknown identifier: $mon\n" unless $self->portnames->{$mon};
    push @$portnames, $self->portnames->{$mon};
  }
  return $portnames;
}

sub _parse {
  my ($self, $str) = @_; 
  my $on = "";
  my $off = "";
  die "Bad format: $str\n" unless $str =~ /^(?:[+-][a-zA-Z]+)+$/;
  while ($str =~ /[+]([a-zA-Z]+)/g) {
    $on .= $1;
  }
  while ($str =~ /[-]([a-zA-Z]+)/g) {
    $off .= $1;
  }
  return ($on, $off);
}

sub run {
  my ($self) = @_;
  my $cmd = _build_cmd($self->ports_on, $self->ports_off, $self->modes);
  print "I'm gonna call [$cmd]!\n";
  my $err = system $cmd;
  if( $err ){
    print STDERR "That didn't work, sorry.\n";
  }
}

sub _build_cmd {
  my ($on, $off, $modes) = @_;
  my $cmd = "xrandr ";
  my $prev;
  foreach my $mon (@$on) {
    my $mode = $modes->{$mon} ? "--mode " . $modes->{$mon} : "--auto";
    $cmd .= "--output $mon $mode ";
    if( $prev ){
      $cmd .= "--right-of $prev ";
    }
    $prev = $mon
  }
  foreach my $mon (@$off) {
    $cmd .= "--output $mon --off ";
  }
  return $cmd;
}

no Moose;

__PACKAGE__->meta->make_immutable;
