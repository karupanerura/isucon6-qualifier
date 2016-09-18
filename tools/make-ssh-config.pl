#!/usr/bin/env perl
use strict;
use warnings;
use feature qw/say/;

use JSON::PP;

chomp(my $out = `azure vm list-ip-address -g isucon6q-team155 --json`);
my $payloads = JSON::PP->new->utf8->decode($out);
for my $payload (@$payloads) {
    for my $network_interface (@{ $payload->{networkProfile}->{networkInterfaces} }) {
        for my $ip_configuration (@{ $network_interface->{expanded}->{ipConfigurations} }) {
            say <<"...";
Host $payload->{name}.isucon6q
    HostName              $ip_configuration->{publicIPAddress}->{expanded}->{ipAddress}
    User                  $ENV{USER}
    UserKnownHostsFile    /dev/null
    IdentitiesOnly        yes
    CheckHostIP           no
    StrictHostKeyChecking no
...
        }
    }
}

