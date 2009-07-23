#!/usr/bin/perl

use strict;
use warnings;
use lib "lib";

use JSON::Acrobatic;
use JSON::Acrobatic::Root;
use Data::Dumper;
use JSON::Any;

my $jsona = JSON::Acrobatic->new();

my $value = {
    name => "Martin Atkins",
    age => 34,
    other => {
        blah => undef,
    },
    interests => [qw(bananas peaches bananas 34)],
};

$value->{self} = $value;
$value->{interests2} = $value->{interests};
push @{$value->{interests}}, $value;
push @{$value->{interests}}, $value->{interests};

my $buf = $jsona->encode($value);
print $buf, "\n";

my $clone_value = $jsona->decode($buf);
print Data::Dumper::Dumper($clone_value);

$clone_value->{interests3} = $clone_value->{interests};
$clone_value->{other_object} = { ohno => undef };
$clone_value->{alive} = $jsona->true;

print Data::Dumper::Dumper($jsona->true);

my $clone_buf = $jsona->encode($clone_value);
print $clone_buf, "\n";

my $clone_clone_value = $jsona->decode($clone_buf);
print Data::Dumper::Dumper($clone_clone_value);

