#!/usr/bin/env perl
use strict;
use warnings;
use feature qw/say/;

use constant +{
    ROTATE_NGINX => 'nginx -s reopen',
    ROTATE_MYSQL => 'mysqladmin -u root refresh',
};

my ($mode, $logfile) = @ARGV;
$mode ||= '';
$logfile ||= '';

if ($mode !~ /^(?:nginx|mysql)$/) {
    warn 'You should specify nginx or mysql';
    die "Usage: $0 <nginx|mysql> <logfile>\n";
}
unless (-f $logfile) {
    warn "$logfile is not exists.";
    die "Usage: $0 <nginx|mysql> <logfile>\n";
}

chomp(my $date = `date +'%Y-%m-%d-%H%M'`);
rename $logfile, "$logfile.$date";

my $run_command = $mode eq 'nginx' ? ROTATE_NGINX
                : $mode eq 'mysql' ? ROTATE_MYSQL
                : die 'No reach here';

if ($ENV{DRY_RUN}) {
    say 'dry-run: ', $run_command;
} else {
    system $run_command;
}

print "$logfile -> $logfile.$date\n";
