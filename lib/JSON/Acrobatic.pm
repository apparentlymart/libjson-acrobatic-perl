=head1 NAME

JSON::Acrobatic - Encode and decode data structures with Acrobatic JSON

=head1 SYNOPSIS

    use JSON::Acrobatic;
    
    my $j = JSON::Acrobatic->new();
    my $json = $j->encode($value);
    my $clone_value = $j->decode($json);

=cut

package JSON::Acrobatic;

use strict;
use warnings;
use JSON::Any;
use Scalar::Util qw(reftype refaddr);
use B;
use Carp;
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

sub encode {
    my ($self, $root_value) = @_;

    my $root = JSON::Acrobatic::Root->for_value($root_value, $self->{json});
    my $struct = $root->struct_for_serialization();
    return $self->{json}->encode($struct);
}

sub decode {
    my ($self, $buf) = @_;

    my $struct = $self->{json}->decode($buf);
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

=head1 METHODS

=head2 $jsona = JSON::Acrobatic->new()

Create a new JSON::Acrobatic instance.

=head2 $buf = $jsona->encode($value)

Get a string containing the given value encoded as Acrobatic JSON.

The supplied value must be a HASH or ARRAY ref in order for the result to be valid Acrobatic JSON.

=head2 $value = $jsona->decode($buf)

Given a string containing valid Acrobatic JSON, returns the encoded data structure.

The result is either a HASH or ARRAY ref.

