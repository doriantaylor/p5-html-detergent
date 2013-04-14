#!perl

use strict;
use warnings FATAL => 'all';

use Test::More tests => 4;

use_ok('HTML::Detergent::Config');

my %links = (
    'dct:author' => 'John Q. Winning',
    'dct:subject' => [qw(puppies kitties unicorns)],
);

my $cfg = HTML::Detergent::Config->new(
    match => [qw(/foo /bar), [qw(/bitz /stuff.xsl)]],
    link  => \%links,
);

is($cfg->stylesheet('/bitz'), '/stuff.xsl', 'map coercion works');

is_deeply([$cfg->match_sequence], [qw(/foo /bar /bitz)],
          'match_sequence matches');

#require Data::Dumper;
#diag(Data::Dumper::Dumper($cfg->links));

is_deeply($cfg->links,
          { %links, 'dct:author' => ['John Q. Winning'] }, 'links match');
