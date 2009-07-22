#!/usr/bin/perl

=head1 NAME

JSON::Acrobatic::Reader - Parse an Acrobatic JSON string to a data structure

=head1 SYNOPSIS

    use JSON::Acrobatic::Reader;
    
    my $j = JSON::Acrobatic::Reader->new();
    my $struct = $j->decode($buf);

=cut

package JSON::Acrobatic::Reader;

use strict;
use warnings;
use JSON::Any;
use JSON::Acrobatic::Root;

sub new {
    my ($class) = @_;

    my $self = bless {}, $class;

    # TODO: Allow some options to be passed through.
    my $json = $self->{json} = JSON::Any->new();

    $self->{true} = $json->can('true') ? $json->true : \1;
    $self->{false} = $json->can('false') ? $json->false : \0;

    return $self;
}

sub decode {
    my ($self, $buf) = @_;

    my $struct = $self->{json}->decode($buf);
    return $self->wrap_struct($struct);
}

sub wrap_struct {
    my ($self, $struct) = @_;

    my $root = JSON::Acrobatic::Root->from_struct($struct, $self->{json});
    return $root->value;
}

sub true {
    return $_[0]->{true};
}

sub false {
    return $_[0]->{false};
}


1;


