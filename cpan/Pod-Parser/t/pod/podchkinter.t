use warnings;
use strict;
use 5.14.0;

use Pod::Checker;
use Data::Dumper;
use Test::More;
BEGIN { plan tests => 74 };

my $pods = [
    {in   => "=head2 easy warning\n\nX<random>",
     node => ["easy warning"],
     idx  => ["random"],
     warn => 1,
    },
    {in   => "=head1 h1\n\n=head2 h2\n\n=over\n\n=item i1\n\n=item i2\n\n=back",
     node => [qw/h1 h2 i1 i2/],
    },
    {in   => "=head1 NAME\n\ncactus - blah\n\nL<l1>L<l2>L<l3L<l4>>",
     node => [qw/NAME/],
     name => "cactus",
     hlnk => [qw/l1 l2 l3l4 l4/],
     warn => 1,
    },
    {in   => 'no pod here',
     errs => -1,
    },
    {in   => "=over\n\n=item *\n\nno closing back!",
     errs => 1,
    },
    {in   => "=head2\n\n=head1 h1X<i1>\n\nU<unrecognized> X<i2> X<i3>\n\n>",
     idx  => [qw/i1 i2 i3/],
     errs => 2,
     warn => 2,
    },
];

while (my ($i, $pod) = each @$pods) {
    # expected results
    my ($in, $name, $node, $idx, $hlnk, $errs, $warn) = 
        @{$pod}{qw/in name node idx hlnk errs warn/};
    $node //= [];
    $idx  //= [];
    $hlnk //= [];
    $errs //= 0;
    $warn //= 0;

    my ($infile, $outfile) = ("tempin.tmp", "tempout.tmp"); 

    # populate the infile
    open(my $infh, '>', $infile) or die $!;
    print $infh $in;
    close $infh;

    # parse from file with scalars as in/output
    my $pc = Pod::Checker->new();
    $pc->parse_from_file($infile, $outfile);

    # got results
    my @got_node = $pc->node();
    my @got_idx  = $pc->idx();
    my @got_hlnk = $pc->hyperlink();
    my $got_errs = $pc->num_errors();
    my $got_warn = $pc->num_warnings();

    # some tests
    is($pc->name(), $name, "name - iter.$i");

    is(length @got_node, length @$node, "length node - iter.$i");
    is($got_node[$_], $$node[$_], "node $_ - iter.$i") for 0..$#$node;

    is(length @got_idx, length @$idx, "length idx - iter.$i");
    is($got_idx[$_], $$idx[$_], "idx $_ - iter.$i") for 0..$#$idx;

    is(length @got_hlnk, length @$hlnk, "length hlnk - iter.$i");
    is($got_hlnk[$_][1]->text(), $$hlnk[$_], "hlnk $_ - iter.$i")
        for 0..$#$hlnk;

    is($got_errs, $errs, "num errors - iter.$i");
    is($got_warn, $warn, "num warnings - iter.$i");

    # remember parse_from_file's output
    undef $pc; # for GC
    open(my $outfh, '<', $outfile);
    my $pff_output1 = <$outfh>;
    close $outfh;
    unlink $outfile;

    # podchecker with scalars as in/output
    is(podchecker($infile, $outfile), $errs,
       "return value of podchecker - iter.$i");

    # take note of podcheckers's output
    open($outfh, '<', $outfile);
    my $pc_output1 = <$outfh>;
    close $outfh;
    unlink $outfile;

    # parse_from_file and podchecker with fh as in/output
    open($infh,  '<', $infile);
    open($outfh, '>', $outfile);
    $pc = Pod::Checker->new();
    $pc->parse_from_file($infh, $outfh);
    close $outfh;
    open($outfh, '<', $outfile);
    my $pff_output2 = <$outfh>;
    $pff_output2 =~ s/GLOB\(\w+\)$/$infile/g if $pff_output2;
      # normalize file name
    close $outfh;
    close $infh;
    unlink $outfile;

    open($infh,  '<', $infile);
    open($outfh, '>', $outfile);
    podchecker($infh, $outfh);
    close $outfh;
    open($outfh, '<', $outfile);
    my $pc_output2 = <$outfh>;
    $pc_output2 =~ s/GLOB\(\w+\)$/$infile/g if $pc_output2;
    close $infh;
    close $outfh;

    # all parsings result in the same output, right?
    is($pff_output1, $pff_output2, "pff scalar vs pff fh - iter.$i");
    is($pc_output1,  $pc_output2,  "pc scalar vs pc fh - iter.$i");
    is($pff_output1, $pc_output1,  "pff scalar vs pc scalar - iter.$i");

    unlink($infile, $outfile);

}

# check -warnings off/on
# check -quiet off/on
# check poderror() usage (use to issue fake warnings for above)

# DONE
# check filepath vs open filehandle
# check podchecker() vs new Pod::Checker->parse_from_file
# check return value (-1 vs #errors)
# check num_errors
# check num_warnings
# name
# node
# idx
# hyperlink
