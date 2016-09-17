#!/usr/bin/env perl
use strict;
use warnings;
use feature qw/say/;
use JSON::PP qw/decode_json encode_json/;

my $command_prefix = 'azure';
my $command_postfix = '--json';
my $dry_run = 0;

main(@ARGV);

sub main {
    my ($resource_group, $vnet_name, $src_name, $needs_dry_run) = @_;
    if ($needs_dry_run) {
        $dry_run = 1;
    }
    construct_executed_json("network vnet create $resource_group isucon6q -l japaneast");
}

sub construct_executed_json {
    my ($command, $is_danger) = @_;
    my $call = $command_prefix . ' ' . $command . ' ' . $command_postfix;
    say "[exec] $call";
    my $ret = ($dry_run && $is_danger) ? '[]' : `$call`;
    my $json = eval { decode_json $ret };
    if (my $e = $@) {
        say $e;
        $json = {};
    }
    return $json;
}
