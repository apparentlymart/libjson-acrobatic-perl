
package JSON::Acrobatic::Object;

use strict;
use warnings;
use JSON::Acrobatic::Wrapper;
use base qw(JSON::Acrobatic::Wrapper);
use JSON::Acrobatic::Array;

sub TIEHASH {
    my ($class, $root, $idx) = @_;
    return $class->new($root, $idx);
}

sub FETCH {
    my ($self, $key) = @_;

    my $idx = $self->[JSON::Acrobatic::Wrapper::REF()]->{$key};
    return undef unless defined($idx);

    my $root = $self->[JSON::Acrobatic::Wrapper::ROOT()];

    my $value = $root->[JSON::Acrobatic::Wrapper::ROOT_STRUCT()]->[$idx];

    return $value unless defined($value);
    return $value if ref($value) && ($value == $root->[JSON::Acrobatic::Wrapper::ROOT_TRUE()] || $value == $root->[JSON::Acrobatic::Wrapper::ROOT_FALSE()]);

    if (ref($value)) {
        return $root->_wrapped_ref($idx);
    }
    else {
        return $value;
    }
}

sub STORE {
    my ($self, $key, $value) = @_;

    my $id = $self->[JSON::Acrobatic::Wrapper::ROOT()]->_acrobatic_value($value);
    $self->[JSON::Acrobatic::Wrapper::REF()]->{$key} = $id;
}

sub FIRSTKEY {
    my ($self) = @_;
    keys %{$self->[JSON::Acrobatic::Wrapper::REF()]}; # reset each() pointer
    return $self->NEXTKEY();
}

sub NEXTKEY {
    my ($self) = @_;
    return each %{$self->[JSON::Acrobatic::Wrapper::REF()]};
}

1;
