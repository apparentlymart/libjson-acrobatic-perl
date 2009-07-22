#!/usr/bin/perl

use strict;
use warnings;
use lib "lib";

use JSON::Acrobatic::Reader;

my $struct = [
    {
        name => 1,
        age => 2,
        other => 3,
        interests => 4,
    },
    "Martin Atkins",
    26,
    {
        name => 1,
        age => 2,
        first => 0,
        self => 3,
    },
    [
        5,
        6,
        1,
    ],
    "Bananas",
    "Peaches",
];

my $jr = JSON::Acrobatic::Reader->new();
my $object = $jr->wrap_struct($struct);

use Data::Dumper;

print Data::Dumper::Dumper($object);

1;
