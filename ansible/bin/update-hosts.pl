#!/usr/bin/env perl
use strict;
use warnings;
use feature qw/say/;

use JSON::PP;

chomp(my $out = `azure vm list-ip-address --json`);
my $payloads = JSON::PP->new->utf8->decode($out);
for my $payload (@$payloads) {
    for my $network_interface (@{ $payload->{networkProfile}->{networkInterfaces} }) {
        for my $ip_configuration (@{ $network_interface->{expanded}->{ipConfigurations} }) {
            say $ip_configuration->{publicIPAddress}->{expanded}->{ipAddress}, ' # ', $payload->{name};
        }
    }
}

