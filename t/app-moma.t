#!/usr/coderyte/bin/perl
#
use strict;
use warnings;

use Test::More 'no_plan';
use Test::Exception;
use App::Moma;

{
  my $app = App::Moma->new();
  isa_ok($app, 'App::Moma', "new");

  ok( $app->load_rc("t/.moma"), "true on good config");
  dies_ok( sub{ $app->load_rc("FAKEFAKE"); }, "dies on no config");
  dies_ok( sub{ $app->load_rc("t/.badmoma"); }, "dies on bad config");
}

# config 
{
  my $app = App::Moma->new();
  $app->load_rc("t/.empty"); 
  ok( !$app->verbosity(), "no verbosity set, default 0" );
  $app->load_rc("t/.verbose"); 
  ok( $app->verbosity(), "verbosity non-zero" );
}

# parse_args
{
  my $app = App::Moma->new();

  dies_ok( sub{ $app->parse_args("+abc"); }, "bad args dies" );
  $app->load_rc("t/.moma"); # without this, no identifiers would be valid
  ok( $app->parse_args("+lr"), "good args don't" );
  dies_ok( sub{ $app->parse_args("+lrx"); }, "mixed good and bad dies" );

  is( $app->parse_args("+r"), 1, "returns arg count" );
  is( $app->parse_args("+r-l"), 2, "returns arg count; doesn't accumulate" );
  is( $app->parse_args("+ri-l"), 3, "returns arg count" );

  $app->load_rc("t/.moma2"); # different set of identifiers
  ok( $app->parse_args("+abc"), "new identifiers loaded" );
  dies_ok( sub{ $app->parse_args("+lri"); }, "old identifiers removed" );

  ok( $app->parse_args("+a+b+c"), "repeated +'s ok" );
  ok( $app->parse_args("-a-b-c"), "repeated -'s ok" );

  dies_ok( sub{ $app->parse_args("--abc"); }, "bad arg format (good ids) dies" );
  dies_ok( sub{ $app->parse_args("+-abc"); }, "bad arg format (good ids) dies" );
  dies_ok( sub{ $app->parse_args("+ab/c"); }, "bad arg format (good ids) dies" );
  dies_ok( sub{ $app->parse_args("+ab--c"); }, "bad arg format (good ids) dies" );
}

### Converted procedural tests
# on/off
{
  my $app = App::Moma->new();

  my ($on, $off) = $app->_parse("+lri");
  is( $on, "lri", "all on" );
  is( $off, "", "off empty");

  ($on, $off) = $app->_parse("-lri");
  is( $on, "", "on empty");
  is( $off, "lri", "all off" );

  ($on, $off) = $app->_parse("+lr-i");
  is( $on, "lr", "some on" );
  is( $off, "i", "some off");

  ($on, $off) = $app->_parse("+a+b-x-y");
  is( $on, "ab", "extraneous +'s parse" );
  is( $off, "xy", "extraneous -'s parse" );
}

# build_cmd
{
  # no modes specified
  is( App::Moma::_build_cmd(["a"], undef, {}), "xrandr --output a --auto ", "one on (undef)" );
  is( App::Moma::_build_cmd(["a"], [], {}), "xrandr --output a --auto ", "one on" );
  is( App::Moma::_build_cmd([], ["a"], {}), "xrandr --output a --off ", "one off" );
  is( App::Moma::_build_cmd(["a"], ["b"], {}), "xrandr --output a --auto --output b --off ", "one on, one off" );
  like( App::Moma::_build_cmd(["a", "b"], ["c", "d"], undef), qr/--output a --auto --output b --auto.*--output c --off --output d --off/, "two on, two off" );
  is( App::Moma::_build_cmd(["a", "b"], [], undef), "xrandr --output a --auto --output b --auto --right-of a ", "two on, b right of a" );

  # modes
  is( App::Moma::_build_cmd(["a"], undef, {a => "1280x1024"}), "xrandr --output a --mode 1280x1024 ", "screen mode specified" );
}
