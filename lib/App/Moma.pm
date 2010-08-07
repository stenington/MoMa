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

has '_config_file' => (
  is => 'rw',
  isa => 'Str',
);

has '_config' => (
  is => 'ro',
  isa => 'Config::Tiny',
  writer => '_set_config',
);

has 'verbosity' => (
  is => 'rw',
  isa => 'Int',
  default => 0,
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
  $self->verbosity($cfg->{config}->{verbosity}) if $cfg->{config} && $cfg->{config}->{verbosity};

  $self->_set_config( $cfg );
  $self->_config_file( $cfgfile );
  return 1;
}

sub print_config {
  my ($self) = @_;
  _boxify( $self->_config_file );
  print "\n";
  print $self->_config->write_string;
  print "\n";
}

sub _boxify {
  my ($str) = @_;
  my $len = (length $str) + 2;
  print "+" . "-" x $len . "+\n";
  print "| " . $str . " |\n";
  print "+" . "-" x $len . "+\n";
}

sub check_config {
  my ($self) = @_;
  my $xrandr_query = `xrandr -q`;
  my $avail = $self->_parse_available( $xrandr_query );
  print $self->_check_config( $avail );
}

sub _check_config {
  my ($self, $avail) = @_;
  my $msg = "";
  foreach my $id (keys %{$self->portnames}) {
    my $port = $self->portnames->{$id};
    $msg .= "$id=$port: $port not connected\n" unless $avail->{$port};
  }
  foreach my $port (keys %{$self->modes}) {
    my $mode = $self->modes->{$port};
    unless( $avail->{$port}->{$mode} ){
      $msg .= "$port=$mode: $mode not available for $port\n";
      $msg .= "  available modes are ".join(", ", keys %{$avail->{$port}})."\n";
    }
  }
  return $msg || "Looks good!\n";
}

sub _parse_available {
  my ($self, $query) = @_;
  my @lines = split('\n', $query);
  my $avail = {};
  my $current_port = "";
  my $line = shift @lines;
  while( $line ) {
    if( $line =~ /^(\S+) connected/ ){
      $current_port = $1;
      $avail->{$current_port} = {};
    }
    elsif( $line =~ /^\s*(\d+x\d+)/ ){
      $avail->{$current_port}->{$1}++;
    }
    $line = shift @lines;
  }
  return $avail;
}

sub parse_args {
  my ($self, $str) = @_;
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
    die "Unknown identifier $mon" unless $self->portnames->{$mon};
    push @$portnames, $self->portnames->{$mon};
  }
  return $portnames;
}

sub _parse {
  my ($self, $str) = @_; 
  my $on = "";
  my $off = "";
  die "Bad format" unless 
    $str =~ /^(?:[+-][a-zA-Z]+)+$/        # basic case
    || $str =~ /^(?:-\*|[+][a-zA-Z])+$/;  # -* syntax
  while ($str =~ /[+]([a-zA-Z]+)/g) {
    $on .= $1;
  }
  while ($str =~ /[-]([a-zA-Z]+)/g) {
    $off .= $1;
  }
  if( $str =~ /-\*/ ){
    my %all = (map {($_, 1)} keys %{$self->portnames});
    foreach my $id ( split('',$on) ) {
      delete $all{$id};
    }
    $off = join("", keys %all);
  }
  return ($on, $off);
}

sub run {
  my ($self) = @_;
  my $cmd = _build_cmd($self->ports_on, $self->ports_off, $self->modes);
  print "I'm gonna call [$cmd]!\n" if $self->verbosity > 0;
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
    $prev = $mon;
  }
  foreach my $mon (@$off) {
    $cmd .= "--output $mon --off ";
  }
  return $cmd;
}

no Moose;

__PACKAGE__->meta->make_immutable;
