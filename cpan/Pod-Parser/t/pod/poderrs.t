BEGIN {
   use File::Basename;
   my $THISDIR = dirname $0;
   unshift @INC, $THISDIR;
   require "testpchk.pl";
   import TestPodChecker;
}

my %options = map { $_ => 1 } @ARGV;  ## convert cmdline to options-hash
my $passed  = testpodchecker \%options, $0;
exit( ($passed == 1) ? 0 : -1 )  unless $ENV{HARNESS_ACTIVE};

### Deliberately throw in some blank but non-empty lines
                                        
### The above line should contain spaces


__END__

=head2 This should cause a warning

=head1 NAME

poderrors.t - test Pod::Checker on some pod syntax errors

    GASP! A verbatim paragraph in NAME

=unknown1 this is an unknown command with two N<unknownA>
and D<unknownB> interior sequences.

This is some paragraph text with some unknown interior sequences,
such as Q<unknown2>,
A<unknown3>,
and Y<unknown4 V<unknown5>>.

Now try some unterminated sequences like
I<hello mudda!
B<hello fadda!

Here I am at C<camp granada!

Camps is very,
entertaining.
And they say we'll have some fun if it stops raining!

Okay, now use a non-empty blank line to terminate a paragraph and make
sure we get a warning.
	                                     	
The above blank line contains tabs and spaces only

F<Many B<fcodes B<inside C<other I<fcodes F<inside I<many S<many C<more X<fcodes. S<This is X<ridiculous.>>>>>>>>>>>>

A L<link|perlvar/$/> to L<perlvar/$E<sol>>

A L<nestedL<link>>

=head1 Additional tests

=head2 item without over

=item oops

=head2 back without over

=back

=head2 over without back

=over 4

=item aaps

=head2 end without begin

=end

=end something

=head2 begin and begin

=begin html

=begin text

=end text

=end html

=head2 begin w/o formatter

=begin

=end

=head2 for w/o formatter

=for

something...

=head2 Nested sequences of the same type

C<code I<italic C<code again!>>>

=head2 Garbled entities

E<alea iacta est>
E<C<auml>>
E<abcI<bla>>
E<0x100>
E<07777>
E<300>
E<unknown_entity>

=head2 Unresolved internal links

L</"begin or begin">
L<"end with begin">
L</OoPs>

=head2 Some links with problems

L<abc
def>
L<>
L<   aha>
L<oho   >
L<  weehee  >
L<"Warnings"> this one is ok
L</unescaped> ok too, this POD has an X of the same name

L<<  lead >>
L<< trail  >>
L<< neither >>
L<<<  both  >>>

L<<<<>>>>

L<<<< >>>>

L<<<<  >>>>

=head2 Warnings

L<passwd(5)>
L<some text with / in it|perlvar/$|> should give warnings as hell

=over 4

=item bla

=back 200

the 200 is evil

X<unescaped>see these unescaped < and > in the text?

=head2 Misc

Z<ddd> should be empty

X<> should not be empty

E<> should not be empty

=over four

This paragrapgh is misplaced - it ought to be an item.

=item four should be numeric!

=item

=item blah

=item previous is all empty!!!

=back

=over

    This verbatim paragraph should not be here
    
=item *

bullet

=item 1

number, uh oh

=back

All empty over/back:

=over 4

=over 2

=back

=back

item w/o name

=cut

=pod bla

bla is evil

=cut blub

blub is evil

=head2 reoccurence

=over 4

=item Misc

we already have a head Misc

=back

=head2 some heading

=head2 another one

previous section is empty!

=head1 LINK TESTS

Due to bug reported by Rafael Garcia-Suarez "rgarciasuarez@free.fr":

The following hyperlinks :
L<"I/O Operators">
L<perlop/"I/O Operators">
trigger a podchecker warning (using bleadperl) :
    node 'I/O Operators' contains non-escaped | or /

=head1

Empty head above and unclosed over/begins below

=over

=begin html

What?

=begin :xml

=cut


