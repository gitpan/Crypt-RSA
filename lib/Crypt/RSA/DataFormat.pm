#!/usr/bin/perl -s
##
## Crypt::RSA::DataFormat -- Functions for converting, shaping and 
##                           creating and reporting data formats.
##
## Copyright (c) 2001, Vipul Ved Prakash.  All rights reserved.
## This code is free software; you can redistribute it and/or modify
## it under the same terms as Perl itself.
##
## $Id: DataFormat.pm,v 1.9 2001/03/12 16:17:32 vipul Exp $

use lib "/home/vipul/PERL/crypto/primes/lib";
package Crypt::RSA::DataFormat; 
use vars qw(@ISA);
use Math::Pari qw(PARI pari2pv floor pari2num);
use Crypt::Random qw(makerandom);
use Digest::SHA1 qw(sha1);
use Carp;
require Exporter;
@ISA = qw(Exporter);

@EXPORT_OK = qw(i2osp os2ip octet_xor generate_random_octet bitsize mgf1 steak);


sub i2osp {
    my $num = PARI(shift); 
    my $l = shift || 0;
    my $base = PARI(256); my $result = '';
    if ($l) { return if $num > $base ** $l }
    DECOMP: {
        my $r = $num % $base; 
        my $d = PARI($num-$r) / $base;
        $result = chr($r) . $result;
        if ($d >= $base) {
            $num = $d; redo DECOMP;
        } elsif ($d != 0) {
            $result = chr($d) . $result
        }
    }
    if (length($result) < $l) { 
        $result = chr(0)x($l-length($result)) . $result;
    }
    return $result;
}


sub os2ip {
    my $string = shift;
    my $base = PARI(256);
    my $result = PARI(0);
    my $l = length($string); 
    for (0 .. $l-1) {
        my ($c) = unpack "x$_ a", $string;
        my $a = int(ord($c));
        my $val = int($l-$_-1); 
        my $b = PARI($base) ** $val;
        $result += PARI($a) * $b;
    }
    return $result;
}


sub generate_random_octet {
    my ( $l, $str ) = @_;
    my $r = makerandom ( Size => int($l*8), Strength => $str );
    return i2osp ($r, $l);
}


sub bitsize ($) {
    return pari2num(floor(Math::Pari::log(shift)/Math::Pari::log(2)) + 1);
}


sub octet_xor { 
    my ($a, $b) = @_; my @xor;
    my @ba = split //, unpack "B*", $a; 
    my @bb = split //, unpack "B*", $b; 
    if (@ba != @bb) {
        if (@ba < @bb) { 
            for (1..@bb-@ba) { unshift @ba, '0' }
        } else { 
            for (1..@ba-@bb) { unshift @bb, '0' }
        }
    } 
    for (0..$#ba) { 
        $xor[$_] = ($ba[$_] xor $bb[$_]) || 0; 
    }
    return pack "B*", join '',@xor; 
}


sub mgf1 {
    my ($seed, $l) = @_;
    my $hlen = 20;  my ($T, $i) = ("",0);
    while ($i <= $l) { 
        my $C = i2osp (int($i), 4);
        $T .= sha1("$seed$C");
        $i += $hlen;
    }
    my ($output) = unpack "a$l", $T;
    return $output;
}


sub steak { 
    my ($text, $blocksize) = @_; 
    my $textsize = length($text);
    my $chunkcount = $textsize % $blocksize 
        ? int($textsize/$blocksize) + 1 : $textsize/$blocksize;
    my @segments = unpack "a$blocksize"x$chunkcount, $text;
    return @segments;
}

1;

=head1 NAME

Crypt::RSA::DataFormat - Data creation, conversion and reporting primitives.

=head1 DESCRIPTION

This module implements several data creation, conversion and reporting
primitives used throughout the Crypt::RSA implementation. Primitives are
available as exportable functions.

=head1 FUNCTIONS

=over 4

=item B<i2osp> Integer, Length

Integer To Octet String Primitive. Converts an integer into its equivalent
octet string representative of length B<Length>. If necessary, the
resulting string is prefixed with nulls.

=item B<os2ip> String

Octet String to Integer Primitive. Converts an octet string into its
equivalent integer representative.

=item B<generate_random_octet> Length, Strength

Generates a random octet string of length B<Length>. B<Strength> specifies
the degree of randomness. See Crypt::Random(3) for an explanation of the
B<Strength> parameter.

=item B<bitsize> Integer

Returns the length of the B<Integer> in bits.

=item B<octet_xor> String1, String2

Returns the result of B<String1> XOR B<String2>.

=item B<steak> String, Length 

Returns an array of segments of length B<Length> from B<String>.  The final 
segment can be smaller than B<Length>.

=back

=head1 AUTHOR

Vipul Ved Prakash, E<lt>mail@vipul.netE<gt>

=cut

