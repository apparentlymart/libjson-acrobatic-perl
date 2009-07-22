
package JSON::Acrobatic::Wrapper;

use strict;
use warnings;

use constant ROOT => 0;
use constant INDEX => 1;
use constant REF => 2;

use JSON::Acrobatic::Root;
use constant ROOT_STRUCT => 0;
use constant ROOT_TRUE => 3;
use constant ROOT_FALSE => 4;

sub new {
    my ($class, $root, $idx) = @_;

    my $self = bless [undef,undef,undef], $class;

    $self->[INDEX] = $idx;
    $self->[ROOT] = $root;
    $self->[REF] = $root->[ROOT_STRUCT]->[$idx];

    return $self;
}

1;
