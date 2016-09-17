#!/usr/bin/env perl
use strict;
use warnings;
use feature qw/say/;
use JSON::PP qw/decode_json encode_json/;

my @COPY_NAMES = ('app', 'infra');
my $commands = {
};
my $command_prefix = 'azure';
my $command_postfix = '--json';
my $dry_run = 0;

main(@ARGV);

sub main {
    my ($resource_group, $vnet_name, $src_name, $needs_dry_run) = @_;
    if ($needs_dry_run) {
        $dry_run = 1;
    }
    my $vm_list = construct_executed_json("vm list $resource_group");
    if (ref $vm_list ne 'ARRAY') {
        die 'なんかおかしい';
    }
    my ($src) = grep { $_->{name} eq $src_name } @$vm_list;
    deallocate_machine($resource_group, $src);
    my $src_url = $src->{storageProfile}->{osDisk}->{vhd}->{uri} || '';

    my $storage_account = setup_storage_accounts($resource_group);

    for my $name (@COPY_NAMES) {
        my $container_name = "oniyanma-${name}-container";
        copy_image($container_name, $src_url);
        create_networks($resource_group, $vnet_name, $name);

        my $vhd_url = "https://${storage_account}.blob.core.windows.net/${container_name}/${src_name}.vhd";
        construct_executed_json("vm create -n $name -l japaneast -g $resource_group -f $name -z Standard_F2s -d $vhd_url -y Linux", 1);
    }
}

sub deallocate_machine {
    my ($resource_group, $src) = @_;
    my $name = $src->{name};
    if ($src->{powerState} =~ /^VM (?:run|stop)/) {
        construct_executed_json("vm stop $resource_group $name", 1);
        construct_executed_json("vm deallocate $resource_group $name", 1);
    }
}

sub setup_storage_accounts {
    my $resource_group = shift;

    my $storage_accounts = construct_executed_json('storage account list');
    if (ref $storage_accounts ne 'ARRAY') {
        die 'なんかおかしい';
    }
    my ($account) = grep { $_->{resourceGroup} eq $resource_group } @$storage_accounts;
    my $account_name = $account->{name};
    say $account_name;
    $ENV{AZURE_STORAGE_ACCOUNT} = $account_name;

    unless ($account_name) {
        die "storage account の取得に失敗したみたい";
    }
    my $connection = construct_executed_json("storage account connectionstring show -g $resource_group $account_name");
    my $connection_string = $connection->{string};
    say $connection_string;
    $ENV{AZURE_STORAGE_CONNECTION_STRING} = "$connection_string";

    my $keys = construct_executed_json("storage account keys list -g $resource_group $account_name");
    if (ref $storage_accounts ne 'ARRAY') {
        die 'なんかおかしい';
    }
    my $access_key = $keys->[0]->{value};
    say $access_key;
    $ENV{AZURE_STORAGE_ACCESS_KEY} = $access_key;

    return $account_name;
}

sub copy_image {
    my ($container_name, $src_url) = @_;
    my $container = construct_executed_json("storage container create $container_name", 1);
    construct_executed_json("storage blob copy start $src_url $container_name", 1);
}

sub create_networks {
    my ($resource_group, $vnet_name, $name) = @_;
    construct_executed_json("network vnet set $resource_group $vnet_name", 1);
    construct_executed_json("network public-ip create $resource_group $name -l japaneast", 1);
    construct_executed_json("network nic create $resource_group $name -k $vnet_name -m $vnet_name -p $name -l japaneast", 1);
    construct_executed_json("network nic set -o $vnet_name $resource_group $name", 1);
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


__END__

# $ perl create_vm_copies.pl isucon5-qualifier-01 image --dry-run
#
# [exec] azure vm list isucon5-qualifier-01 --json
# [exec] azure vm stop isucon5-qualifier-01 image --json
# [exec] azure vm deallocat isucon5-qualifier-01 image --json
# [exec] azure storage account list --json
# 5lw5pw5vk6qw6storage
# [exec] azure storage account connectionstring show -g isucon5-qualifier-01 5lw5pw5vk6qw6storage --json
# DefaultEndpointsProtocol=https;AccountName=5lw5pw5vk6qw6storage;AccountKey=45AxbA48IIjXl8AAwliZy1isG3JcE3wgPqGjo+NNWlDeQ3XjSXGt2K48199ZpY6wWeRgfC0A0XzIsyK52xkbKw==
# [exec] azure storage account keys list -g isucon5-qualifier-01 5lw5pw5vk6qw6storage --json
# 45AxbA48IIjXl8AAwliZy1isG3JcE3wgPqGjo+NNWlDeQ3XjSXGt2K48199ZpY6wWeRgfC0A0XzIsyK52xkbKw==
# [exec] azure storage container create oniyanma-app-container --json
# [exec] azure storage blob copy start https://5lw5pw5vk6qw6storage.blob.core.windows.net/vhds/image.vhd oniyanma-app-container --json
# [exec] azure network vnet create isucon5-qualifier-01 app -l japaneast --json
# [exec] azure network vnet subnet create isucon5-qualifier-01 app app -l japaneast -a 10.0.0.0/8 --json
# [exec] azure network public-ip create isucon5-qualifier-01 app -l japaneast --json
# [exec] azure network nic create isucon5-qualifier-01 app -k app -m app -p app -l japaneast --json
# [exec] azure vm create -n app -l japanwest -g isucon5-qualifier-01 -f app -z Standard_F2s -d https://5lw5pw5vk6qw6storage.blob.core.windows.net/oniyanma-app-container/image.vhd -y Linux --json
# [exec] azure storage container create oniyanma-infra-container --json
# [exec] azure storage blob copy start https://5lw5pw5vk6qw6storage.blob.core.windows.net/vhds/image.vhd oniyanma-infra-container --json
# [exec] azure network vnet create isucon5-qualifier-01 infra -l japaneast --json
# [exec] azure network vnet subnet create isucon5-qualifier-01 infra infra -l japaneast -a 10.0.0.0/8 --json
# [exec] azure network public-ip create isucon5-qualifier-01 infra -l japaneast --json
# [exec] azure network nic create isucon5-qualifier-01 infra -k infra -m infra -p infra -l japaneast --json
# [exec] azure vm create -n infra -l japanwest -g isucon5-qualifier-01 -f infra -z Standard_F2s -d https://5lw5pw5vk6qw6storage.blob.core.windows.net/oniyanma-infra-container/image.vhd -y Linux --json


