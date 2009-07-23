
use strict;
use warnings;
use lib "lib";
use JSON::Acrobatic;
use Compress::Zlib;
use JSON::Any;
use Time::HiRes;

my $jw = JSON::Acrobatic->new();
my $ja = JSON::Any->new();

my $user = {
    displayName => "Martin Atkins",
    interests => [
        "json",
        "api",
        "cheese",
        "beer",
    ],
    id => "blahblahblah",
    links => [
        {
            rel => "alternate",
            type => "text/html",
            href => "http://profile.typepad.com/mart",
        },
        {
            rel => "favorites",
            href => "favorites.json",
            count => 12,
        },
    ],
    active => $jw->true,
    blog => undef,
    dead => $jw->false,
};

my $asset_id = 1;

my $make_event = sub {
    return {
        object => {
            author => $user,
            id => $asset_id++,
        },
        actor => $user,
    },
};

my $events = [ map { $make_event->() } 1..50 ];

my $list = {
    total => 100,
    entries => $events,
};

compare($list);

sub measure_time(&) {

    my $start = Time::HiRes::time;
    my $ret = $_[0]->();
    my $end = Time::HiRes::time;
    return ($ret, $end - $start);

}

sub compare {
    my ($struct) = @_;


    my ($normal_json, $normal_json_time) = measure_time { $ja->encode($struct) };
    my ($acrobatic_json, $acrobatic_json_time) = measure_time { $jw->encode($struct) };

    my ($gzip_normal_json, $gzip_normal_json_time) = measure_time { Compress::Zlib::memGzip($normal_json) };
    my ($gzip_acrobatic_json, $gzip_acrobatic_json_time) = measure_time { Compress::Zlib::memGzip($acrobatic_json) };

    my $baseline_length = length($normal_json);
    my $baseline_time = $normal_json_time;

    my $print_result = sub {
        my ($caption, $string, $new_time) = @_;

        my $new_length = length($string);
        my $length_percent = ($new_length / $baseline_length) * 100;
        my $time_percent = ($new_time / $baseline_time) * 100;

        printf("%19s: %5i (%3i%%) %1.4fs (%3i%%)\n", $caption, $new_length, $length_percent, $new_time, $time_percent);
    };

    $print_result->("Normal JSON" => $normal_json, $normal_json_time);
    $print_result->("Acrobatic JSON" => $acrobatic_json, $acrobatic_json_time);
    $print_result->("Normal JSON Gzip" => $gzip_normal_json, $normal_json_time + $gzip_normal_json_time);
    $print_result->("Acrobatic JSON Gzip" => $gzip_acrobatic_json, $acrobatic_json_time + $gzip_acrobatic_json_time);

}


