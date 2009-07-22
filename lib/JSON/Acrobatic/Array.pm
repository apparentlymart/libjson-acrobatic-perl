
package JSON::Acrobatic::Array;

use strict;
use warnings;
use base qw(JSON::Acrobatic::Wrapper);

sub TIEARRAY {
    my ($class, $root, $idx) = @_;
    return $class->new($root, $idx);
}

sub FETCH {
    my ($self, $key) = @_;

    my $idx = $self->[JSON::Acrobatic::Wrapper::REF()]->[$key];
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

sub FETCHSIZE {
    my ($self) = @_;

    return scalar(@{$self->[JSON::Acrobatic::Wrapper::REF()]});
}

1;
