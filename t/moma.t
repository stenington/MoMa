#!/usr/coderyte/bin/perl
#
use strict;
use warnings;

use Test::More 'no_plan';
use App::Moma;

my $app = App::Moma->new();
isa_ok($app, 'App::Moma', "new");

ok( !$app->parse_args("123"), "bad args fail" );
$app->load_rc("t/.moma"); # without this, no identifiers would be valid
ok( $app->parse_args("+lr"), "good args don't" );
ok( $app->parse_args("+lrx"), "mixed good and bad fails" );
is( 1, $app->parse_args("+r"), "returns arg count" );
is( 2, $app->parse_args("+r-l"), "returns arg count; doesn't accumulate" );
is( 3, $app->parse_args("+ri-l"), "returns arg count" );
$app->load_rc("t/.moma2"); # different set of identifiers
ok( $app->parse_args("+abc"), "new identifiers loaded" );
ok( !$app->parse_args("+lri"), "old identifiers removed" );

### Converted procedural tests

my ($on, $off) = App::Moma::_parse("+lri");
is( $on, "lri", "all on" );
is( $off, "", "off empty");

($on, $off) = App::Moma::_parse("-lri");
is( $on, "", "on empty");
is( $off, "lri", "all off" );

($on, $off) = App::Moma::_parse("+lr-i");
is( $on, "lr", "some on" );
is( $off, "i", "some off");

($on, $off) = App::Moma::_parse("+a+b-x-y");
is( $on, "ab", "extraneous +'s parse" );
is( $off, "xy", "extraneous -'s parse" );

# no modes specified
is( App::Moma::_build_cmd(["a"], undef, {}), "xrandr --output a --auto ", "one on (undef)" );
is( App::Moma::_build_cmd(["a"], [], {}), "xrandr --output a --auto ", "one on" );
is( App::Moma::_build_cmd([], ["a"], {}), "xrandr --output a --off ", "one off" );
is( App::Moma::_build_cmd(["a"], ["b"], {}), "xrandr --output a --auto --output b --off ", "one on, one off" );
like( App::Moma::_build_cmd(["a", "b"], ["c", "d"], undef), qr/--output a --auto --output b --auto.*--output c --off --output d --off/, "two on, two off" );

is( App::Moma::_build_cmd(["a", "b"], [], undef), "xrandr --output a --auto --output b --auto --right-of a ", "two on, b right of a" );

# modes
is( App::Moma::_build_cmd(["a"], undef, {a => "1280x1024"}), "xrandr --output a --mode 1280x1024 ", "screen mode specified" );

