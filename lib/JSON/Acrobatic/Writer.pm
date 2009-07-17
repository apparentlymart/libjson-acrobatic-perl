#!/usr/bin/perl

=head1 NAME

JSON::Acrobatic::Writer - Output a data structure as Acrobatic JSON

=head1 SYNOPSIS

    use JSON::Acrobatic::Writer;
    
    my $j = JSON::Acrobatic::Writer->new();
    my $json = $j->encode($value);

=cut

package JSON::Acrobatic::Writer;

use strict;
use warnings;
use JSON::Any;
use Scalar::Util qw(reftype refaddr);
use B;
use Carp;

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

    my $table = $self->build_table($root_value);
    return $self->{json}->encode($table);
}

sub build_table {
    my ($self, $root_value) = @_;

    my @values = ();
    my %ref_ids = ();
    my %string_ids = ();
    my %number_ids = ();
    my $next_id = 0;

    my $id_for = sub {
        my ($value) = @_;

        my $table;
        my $key;

        if (ref($value)) {
            $table = \%ref_ids;
            $key = refaddr($value);
        }
        else {
            my $b_obj = B::svref_2object(\$value);
            my $flags = $b_obj->FLAGS;

            if (($flags & B::SVf_IOK or $flags & B::SVp_IOK or $flags & B::SVf_NOK or $flags & B::SVp_NOK) and !($flags & B::SVf_POK )) {
                $table = \%number_ids;
                $key = $value;
            }
            else {
                $table = \%string_ids;
                $key = $value;
            }
        }
        Carp::croak("I don't know what to do with $value") unless $table;

        if (exists($table->{$key})) {
            return $table->{$key};
        }
        else {
            return $table->{$key} = $next_id++;
        }
    };

    my $build_acrobatic_value;
    $build_acrobatic_value = sub {
        my ($value) = @_;

        # null and booleans don't get pointerized
        return undef unless defined($value);
        return $value if ref($value) && (refaddr($value) == refaddr($self->true) || refaddr($value) == refaddr($self->false));

        my $id = $id_for->($value);

        # Have we been here before?
        return $id if (defined($values[$id]));

        # Otherwise, we need to actually build an acrobatic version.
        my $slot = \$values[$id];
        my $reftype = reftype($value);

        # Put a placeholder value in $slot in case we end up recursing into the same
        # object before we finish building it.
        $$slot = 0xdeadbeef;

        if (! defined($reftype)) {
            $$slot = $value;
        }
        elsif ($reftype eq 'ARRAY') {
            local $_;
            $$slot = [ map { $build_acrobatic_value->($_) } @$value ];
        }
        elsif ($reftype eq 'HASH') {
            local $_;
            my $new_value = {};
            map { $new_value->{$_} = $build_acrobatic_value->($value->{$_}) } keys %$value;
            $$slot = $new_value;
        }
        else {
            Carp::croak("Unsupported reftype $reftype");
        }

        return $id;
    };

    $build_acrobatic_value->($root_value);

    return \@values;
}

sub true {
    return $_[0]->{true};
}

sub false {
    return $_[0]->{false};
}

1;

=head1 METHODS

