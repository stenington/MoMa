#!/usr/coderyte/bin/perl
#
use strict;
use warnings;

use Test::More 'no_plan';
use App::Moma qw(parse build_cmd);

my ($on, $off) = parse("+lri");
is( $on, "lri", "all on" );
is( $off, undef, "off undefined");

($on, $off) = parse("-lri");
is( $on, undef, "on undefined");
is( $off, "lri", "all off" );

($on, $off) = parse("+lr-i");
is( $on, "lr", "some on" );
is( $off, "i", "some off");

($on, $off) = parse("+a+b-x-y");
is( $on, "ab", "extraneous +'s parse" );
is( $off, "xy", "extraneous -'s parse" );

# no modes specified
is( build_cmd(["a"], undef, {}), "xrandr --output a --auto ", "one on (undef)" );
is( build_cmd(["a"], [], {}), "xrandr --output a --auto ", "one on" );
is( build_cmd([], ["a"], {}), "xrandr --output a --off ", "one off" );
is( build_cmd(["a"], ["b"], {}), "xrandr --output a --auto --output b --off ", "one on, one off" );
like( build_cmd(["a", "b"], ["c", "d"], undef), qr/--output a --auto --output b --auto.*--output c --off --output d --off/, "two on, two off" );

is( build_cmd(["a", "b"], [], undef), "xrandr --output a --auto --output b --auto --right-of a ", "two on, b right of a" );

# modes
is( build_cmd(["a"], undef, {a => "1280x1024"}), "xrandr --output a --mode 1280x1024 ", "screen mode specified" );

