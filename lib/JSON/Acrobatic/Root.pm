
package JSON::Acrobatic::Root;

use strict;
use warnings;
use JSON::Acrobatic::Object;
use JSON::Acrobatic::Array;
use Scalar::Util qw(reftype refaddr);
use B;
use Carp;

use constant STRUCT => 0;
use constant MODIFIED => 1;
use constant JSON => 2;
use constant TRUE => 3;
use constant FALSE => 4;
use constant NEXT_ID => 5;
use constant WRAPPED => 6;
use constant REF_IDS => 7;
use constant STRING_IDS => 8;
use constant NUMBER_IDS => 9;

sub from_struct {
    my ($class, $struct, $json) = @_;

    my $self = bless [], $class;

    # Assign the last index first so we grow the array only once.
    $self->[NUMBER_IDS] = {};
    $self->[STRING_IDS] = {};
    $self->[REF_IDS] = {};

    $self->[STRUCT] = $struct;
    $self->[JSON] = $json;
    $self->[TRUE] = $json->true;
    $self->[FALSE] = $json->false;
    $self->[NEXT_ID] = scalar(@$struct);
    $self->[WRAPPED] = {};
    $self->[MODIFIED] = 0;

    return $self;
}

sub new_object {
    my ($class, $json) = @_;

    return $class->for_value({}, $json);
}

sub new_array {
    my ($class, $json) = @_;

    return $class->for_value([], $json);
}

sub for_value {
    my ($class, $value, $json) = @_;

    my $self = $class->from_struct([], $json);
    my $id = $self->_acrobatic_value($value);
    Carp::croak("Something went horribly wrong: the first value didn't get index zero?!") unless $id == 0;

    $self->[MODIFIED] = 0;

    return $self;
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

sub struct_for_serialization {
    my ($self) = @_;

    if (! $self->[MODIFIED]) {
        # Fast path: we can just return our struct verbatim
        return $self->[STRUCT];
    }
    else {
        # Slow path: pass our value into a new root to force
        # it to generate the optimal struct.
        my $optimal_root = __PACKAGE__->new_from_value($self->value);
        return $optimal_root->[STRUCT];
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

sub _acrobatic_value {
    my ($self, $value) = @_;

    # nulls don't get pointerized
    return undef unless defined($value);

    if (ref($value)) {
        # booleans don't get pointerized
        return $value if (refaddr($value) == refaddr($self->[TRUE]) || refaddr($value) == refaddr($self->[FALSE]));

        # if it's actually one of our wrapper objects, we must look inside and use the id it already has.
        # otherwise we'll allocate it a second id since it's a different hashref than we have in the id table.
        my $wrapper;

        if (ref($value) eq 'ARRAY') {
            $wrapper = tied(@$value);
        }
        elsif (ref($value) eq 'HASH') {
            $wrapper = tied(%$value);
        }

        if (UNIVERSAL::isa($wrapper, 'JSON::Acrobatic::Wrapper')) {
            my $root = $wrapper->[JSON::Acrobatic::Wrapper::ROOT];
            if ($root == $self) {
                return $wrapper->[JSON::Acrobatic::Wrapper::INDEX];
            }
        }
    }

    # determine the id for this value
    my $id;
    {
        my $table;
        my $key;

        if (ref($value)) {
            $table = $self->[REF_IDS];
            $key = refaddr($value);
        }
        else {
            my $b_obj = B::svref_2object(\$value);
            my $flags = $b_obj->FLAGS;

            if (($flags & B::SVf_IOK or $flags & B::SVp_IOK or $flags & B::SVf_NOK or $flags & B::SVp_NOK) and !($flags & B::SVf_POK )) {
                $table = $self->[NUMBER_IDS];
                $key = $value;
            }
            else {
                $table = $self->[STRING_IDS];
                $key = $value;
            }
        }
        Carp::croak("I don't know what to do with $value") unless $table;

        if (exists($table->{$key})) {
            $id = $table->{$key};
        }
        else {
            $id = $table->{$key} = $self->[NEXT_ID]++;
        }

    }

    # If we've already inserted this object we can just return its id without doing any further work
    return $id if (defined($self->[STRUCT][$id]));

    # Otherwise, we need to actually build an acrobatic version.
    my $slot = \$self->[STRUCT][$id];
    my $reftype = reftype($value);

    # Put a placeholder value in $slot in case we end up recursing into the same
    # object before we finish building it.
    $$slot = 0xdeadbeef;

    if (! defined($reftype)) {
        $$slot = $value;
    }
    elsif ($reftype eq 'ARRAY') {
        local $_;
        $$slot = [ map { $self->_acrobatic_value($_) } @$value ];
    }
    elsif ($reftype eq 'HASH') {
        local $_;
        my $new_value = {};
        map { $new_value->{$_} = $self->_acrobatic_value($value->{$_}) } keys %$value;
        $$slot = $new_value;
    }
    else {
        Carp::croak("Unsupported reftype $reftype");
    }

    # Mark the object as modified so that we know we need to
    # do an optimization pass before re-serializing.
    $self->[MODIFIED] = 1;

    return $id;
}

1;
