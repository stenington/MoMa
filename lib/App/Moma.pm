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

  $cfgfile = $ENV{HOME} . "/.moma" unless $cfgfile;
  return unless -f $cfgfile;

  my $cfg = Config::Tiny->read( $cfgfile ) or die "Unable to load $cfgfile: " . Config::Tiny::errstr;
  $self->portnames($cfg->{identifiers}) if $cfg->{identifiers};
  $self->modes($cfg->{modes}) if $cfg->{modes};
}

sub parse_args {
  my ($self, $str) = @_;
  my ($on, $off) = _parse($str);
  my $ports_on = [];
  my $ports_off = [];
  foreach my $mon (split(//, $on)) {
    push @$ports_on, $self->portnames->{$mon} if $self->portnames->{$mon};
  }
  foreach my $mon (split(//, $off)) {
    push @$ports_off, $self->portnames->{$mon} if $self->portnames->{$mon};
  }
  $self->ports_on( $ports_on );
  $self->ports_off( $ports_off );
  return @{$self->ports_on} + @{$self->ports_off};
}

sub _parse {
  my ($str) = @_; 
  my $on = "";
  my $off = "";
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
