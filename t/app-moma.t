#!/usr/coderyte/bin/perl
#
use strict;
use warnings;

use Test::More 'no_plan';
use Test::Exception;
use App::Moma;
use App::MomaMock;

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

# on/off
{
  my $app = App::MomaMock->new();
  $app->load_rc("t/.moma");

  $app->parse_args("+lri");
  $app->run();
  like( $app->cmd, qr/VGA-0.*?DVI-0.*?right-of VGA-0.*?LVDS.*?right-of DVI-0/, "all on, left to right" );
  unlike( $app->cmd, qr/\boff\b/, "none off" );

  $app->parse_args("-lri");
  $app->run();
  like( $app->cmd, qr/VGA-0.*?off.*?DVI-0.*?off.*?LVDS.*?off/, "all off" );
  unlike( $app->cmd, qr/\bauto\b/, "none on" );

  $app->parse_args("+lr-i");
  $app->run();
  like( $app->cmd, qr/VGA-0.*?DVI-0.*?right-of VGA-0/, "two on, side-by-side" );
  like( $app->cmd, qr/LVDS.*?off/, "one off" );

  $app->load_rc("t/.simple");

  $app->parse_args("+a+b-c-d");
  $app->run();
  like( $app->cmd, qr/A.*?auto.*?B.*?auto/, "two on" );
  TODO: {
  local $TODO = "Failing test to motivate changes in this branch";
  unlike( $app->cmd, qr/right-of|left-of/, "no side-by-side" );
  };
  like( $app->cmd, qr/C.*?off.*?D.*?off/, "two off" );

  $app->parse_args("-*+a");
  $app->run();
  like( $app->cmd, qr/A --auto/, "one on" );
  like( $app->cmd, qr/(?:[BCDE] --off.*?){4}/, "rest off" );

  $app->parse_args("+b-*+a");
  $app->run();
  like( $app->cmd, qr/(?:[AB] --auto.*?){2}/, "two on" );
  like( $app->cmd, qr/(?:[CDE] --off.*?){3}/, "rest off" );
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
