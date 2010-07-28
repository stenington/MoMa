#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'App::Moma' );
}

diag( "Testing App::Moma $App::Moma::VERSION, Perl $], $^X" );
