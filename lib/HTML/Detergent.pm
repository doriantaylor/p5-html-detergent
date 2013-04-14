package HTML::Detergent;

use 5.010;
use strict;
use warnings FATAL => 'all';

use Moose;
use namespace::autoclean;

use Scalar::Util ();
use XML::LibXML  ();
use XML::LibXSLT ();
use XML::LibXML::LazyBuilder qw(DOM E);

has parser => (
    is      => 'ro',
    isa     => 'HTML::HTML5::Parser',
    default => sub { require HTML::HTML5::Parser; HTML::HTML5::Parser->new },
    lazy    => 1,
);

my $XPC = XML::LibXML::XPathContext->new;
$XPC->registerNs('html' => 'http://www.w3.org/1999/xhtml');

=head1 NAME

HTML::Detergent - Clean the gunk off an HTML document

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

    use HTML::Detergent;

    my $scrubber = HTML::Detergent->new($config);

    # $input can be a string, GLOB reference, or XML::LibXML::Document

    my $doc = $scrubber->process($input, $uri);

=head1 DESCRIPTION

L<HTML::Detergent> is for isolating the main content of an HTML page,
stripping it of navigation, visual design, and other ancillary content.

The main purpose of this module is to aid in the migration of web
content from one content management system to another. It is also
useful for preparing HTML resources for automated content inventories.

The module currently has no heuristics for determining the main
content of a page. It works instead by assuming prior knowledge of the
layout, given in the configuration by an XPath expression that
uniquely isolates the container node. That node is then lifted into a
new document, along with the contents of the C<E<lt>headE<gt>>, and
returned by the L</process> method. To accommodate multiple layouts on
a site, the module can be initialized to match multiple XPath
expressions. If further processing is necessary, an expression can be
associated with an XSLT stylesheet, which is assumed to produce an
entire document, thus overriding the default behaviour.

After the new document is generated and before it is returned by
L</process>, it is possible to inject C<E<lt>linkE<gt>> and
C<E<lt>metaE<gt>> elements into the C<E<lt>headE<gt>>. This enables
the inclusion of metadata and the re-association of the main content
with links that represent aspects of the page which have been removed
(e.g. navigation, copyright statement, etc.). In addition, if the
page's URI is supplied to the L</process> method, the
C<E<lt>baseE<gt>> element is either added or rewritten to reflect it,
and the URI attributes in the body are rewritten relative to the base.
Otherwise they are left alone.

The document returned is an L<XML::LibXML::Document> object using the
XHTML namespace, C<http://www.w3.org/1999/xhtml>, but does not profess
to validate against any particular schema. If DTD declarations
(including the empty C<E<lt>!DOCTYPE htmlE<gt>> recommended in HTML5)
are desired, they can be added on afterward. Likewise, the object can
be converted from XML into HTML using L<XML::LibXML::Document/toStringHTML>.

=head1 METHODS

=head2 new %CONFIG | \%CONFIG | $CONFIG

Initialize the processor, either with a list of configuration
parameters, a HASH reference thereof, or an HTML::Detergent::Config
object. Below are the valid parameters:

=over 4

=item match

This is an ARRAY reference of XPath expressions to try against the
document, in order of preference. Entries optionally may be
two-element ARRAY references themselves, the second element being a
URL where an XSLT stylesheet may be found.

    match => [ '/some/xpath/expression',
               [ '/other/expr', '/url/of/transform.xsl' ],
             ],

=item link

This is a HASH reference where the keys correspond to C<rel>
attributes and the values to C<href> attributes of C<E<lt>linkE<gt>>
elements. If the values are ARRAY references, they will be processed
in document order. C<rel> attributes will be sorted lexically. If a
callback is supplied instead, the caller expects a result of the same
form.

    link => { rel1 => 'href1', rel2 => [ qw(href2 href3) ] },

    # or

    link => \&_link_cb,

=item meta

This is a HASH reference where the keys correspond to C<name>
attributes and the values to C<content> attributes of
C<E<lt>metaE<gt>> elements. If the values are ARRAY references, they
will be processed in document order. C<name> attributes will be sorted
lexically. If a callback is supplied instead, the caller expects a
result of the same form.

    meta => { name1 => 'content1',
              name2 => [ qw(content2 content3) ] },

    # or

    meta => \&_meta_cb,

=item callback

These callbacks will be passed into the internal L<XML::LibXSLT>
processor. See L<XML::LibXML::InputCallback> for details.

    callback => [ \&_match_cb, \&_open_cb, \&_read_cb, \&_close_cb ],

    # or

    callback => $icb, # isa XML::LibXML::InputCallback

=back

=cut

around BUILDARGS => sub {
};

sub BUILD {
    # cache stylesheets
}

=head2 process $INPUT [, $URI, $CONFIG ]

Processes C<$INPUT>, which may be a string, GLOB reference, or
L<XML::LibXML::Document> object. Returns an L<XML::LibXML::Document>
object with the changes mentioned in the L</DESCRIPTION>.

=cut

sub process {
    my ($self, $input, $uri, @rest) = @_;

    if (my $ref = ref $input) {
        if (Scalar::Util::reftype($input) eq 'GLOB') {
            $input = eval { $self->parser->parse_fh($input) };
            Carp::croak("Failed to parse X(HT)ML input: $@") if $@;
        }
        elsif (Scalar::Util::blessed($input)
              and $input->isa('XML::LibXML::Document')) {
            # do nothing
        }
        else {
            Carp::croak("Don't know what to do with reference type $ref");
        }
    }
    else {
        $input = eval { $self->parser->parse_string($input) };
        Carp::croak("Failed to parse X(HT)ML input: $@") if $@;
    }

    my @head = map { $_->cloneNode(1) }
        $XPC->findnodes('/html:html/html:head/*', $input);

    my @body;

    my $doc = DOM E html => { xmlns => 'http://www.w3.org/1999/xhtml' },
        (E head => {}, @head), (E body => {}, @body);
}


=head1 AUTHOR

Dorian Taylor, C<< <dorian at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-html-detergent at
rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=HTML-Detergent>.  I
will be notified, and then you'll automatically be notified of
progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc HTML::Detergent

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=HTML-Detergent>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/HTML-Detergent>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/HTML-Detergent>

=item * Search CPAN

L<http://search.cpan.org/dist/HTML-Detergent/>

=back

=head1 SEE ALSO

=over 4

=item L<XML::LibXML>

=item L<HTML::HTML5::Parser>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2013 Dorian Taylor.

Licensed under the Apache License, Version 2.0 (the "License"); you
may not use this file except in compliance with the License.  You may
obtain a copy of the License at
L<http://www.apache.org/licenses/LICENSE-2.0>

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
implied.  See the License for the specific language governing
permissions and limitations under the License.

=cut

__PACKAGE__->meta->make_immutable;
no Moose;

1; # End of HTML::Detergent
