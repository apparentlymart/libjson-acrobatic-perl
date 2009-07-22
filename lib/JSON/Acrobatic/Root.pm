
package JSON::Acrobatic::Root;

use strict;
use warnings;
use JSON::Acrobatic::Object;
use JSON::Acrobatic::Array;

use constant STRUCT => 0;
use constant MODIFIED => 1;
use constant JSON => 2;
use constant TRUE => 3;
use constant FALSE => 4;
use constant NEXT_IDX => 5;
use constant WRAPPED => 6;

sub from_struct {
    my ($class, $struct, $json) = @_;

    my $self = bless [undef,undef,undef,undef,undef,undef,undef], $class;

    $self->[STRUCT] = $struct;
    $self->[MODIFIED] = 0;
    $self->[JSON] = $json;
    $self->[TRUE] = $json->true;
    $self->[FALSE] = $json->false;
    $self->[NEXT_IDX] = $json->false;
    $self->[WRAPPED] = {};

    return $self;
}

sub new_object {
    my ($class, $json) = @_;

    return $class->new_from_struct([{}]);
}

sub new_array {
    my ($class, $json) = @_;

    return $class->new_from_struct([[]]);
}

sub value {
    my ($self) = @_;

    my $value = $self->[STRUCT][0];

    return $value unless defined($value);
    return $value if ref($value) && ($value == $self->[TRUE] || $value == $self->[FALSE]);

    if (ref($value)) {
        return $self->_wrapped_ref(0);
    }
    else {
        return $value;
    }
}

sub _wrapped_ref {
    my ($self, $idx) = @_;

    return $self->[WRAPPED]{$idx} if $self->[WRAPPED]{$idx};

    my $value = $self->[STRUCT][$idx];

    if (ref($value) eq 'ARRAY') {
        my @ret;
        tie @ret, 'JSON::Acrobatic::Array', $self, $idx;
        return $self->[WRAPPED]{$idx} = \@ret;
    }
    elsif (ref($value) eq 'HASH') {
        my %ret;
        tie %ret, 'JSON::Acrobatic::Object', $self, $idx;
        return $self->[WRAPPED]{$idx} = \%ret;
    }
    else {
        Carp::croak("I don't know how to wrap $value");
    }
}

1;
