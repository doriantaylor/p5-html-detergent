use inc::Module::Install;

name     'HTML-Detergent';
all_from 'lib/HTML/Detergent.pm';
author   q{Dorian Taylor <dorian@cpan.org>};
license  'apache';

build_requires 'Test::More';

auto_install;

WriteAll;

