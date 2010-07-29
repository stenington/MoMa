use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'App::Moma',
    AUTHOR              => q{Mike Larsson <mlarsson@coderyte.com>},
    VERSION_FROM        => 'lib/App/Moma.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Config::Tiny' => 0,
        'Moose' => 0,
    },
    EXE_FILES           => ['bin/moma'],
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'App-Moma-*' },
);
