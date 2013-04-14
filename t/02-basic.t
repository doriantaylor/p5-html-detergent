#!perl

use Test::More;

plan tests => 3;

use_ok('HTML::Detergent');

my $scrubber = HTML::Detergent->new(
    match => [
        [q{//html:div[@id='col2']}, 't/data/iai.xsl'],
    ],
);

isa_ok($scrubber, 'HTML::Detergent');

diag(my ($first) = $scrubber->config->match_sequence);

diag($scrubber->config->stylesheet($first));

open my $fh, 't/data/about.html' or die $!;

my $content = do { local $/; <$fh> };

ok(my $doc = $scrubber->process($content), 'scrubber processes document');

#diag('yo');

#ok($doc = $scrubber->process($content), 'scrubber processes document');

#require Benchmark;
#Benchmark::timethis(100, sub { $scrubber->process($content) });

diag($doc->toString(1));
