use strict;
use warnings;
use utf8;
use feature qw/state/;

use Parallel::Prefork;
use Redis::Fast;
use DBIx::Sunny;
use Cache::Memcached::Fast::Safe;
use Data::MessagePack;
use Compress::LZ4;

my $CACHE_KEY_KEYWORDS = 'keywords';
my $CACHE_KEY_HTML     = 'html';

sub config {
    state $conf = {
        dsn           => $ENV{ISUDA_DSN}         // 'dbi:mysql:db=isuda',
        db_user       => $ENV{ISUDA_DB_USER}     // 'root',
        db_password   => $ENV{ISUDA_DB_PASSWORD} // '',
        isutar_origin => $ENV{ISUTAR_ORIGIN}     // 'http://localhost:5001',
        isupam_origin => $ENV{ISUPAM_ORIGIN}     // 'http://localhost:5050',
    };
    my $key = shift;
    my $v = $conf->{$key};
    unless (defined $v) {
        die "config value of $key undefined";
    }
    return $v;
}

sub dbh {
    state $cache;
    return $cache //= DBIx::Sunny->connect(config('dsn'), config('db_user'), config('db_password'), {
        Callbacks => {
            connected => sub {
                my $dbh = shift;
                $dbh->do(q[SET SESSION sql_mode='TRADITIONAL,NO_AUTO_VALUE_ON_ZERO,ONLY_FULL_GROUP_BY']);
                $dbh->do('SET NAMES utf8mb4');
                return;
            },
        },
    });
}

{
    my %redis;
    sub redis {
        $redis{$$} //= Redis::Fast->new(server => '127.0.0.1:6379');
    }
    __PACKAGE__->redis;
}

{
    my $msgpack = Data::MessagePack->new->utf8;
    sub _message_pack   { $msgpack->pack(@_)   }
    sub _message_unpack { $msgpack->unpack(@_) }
    sub _compress_lz4   { ${$_[1]} = Compress::LZ4::compress(${$_[0]})   }
    sub _uncompress_lz4 { ${$_[1]} = Compress::LZ4::decompress(${$_[0]}) }
}

my $cache = Cache::Memcached::Fast::Safe->new({
    servers => ['127.0.0.1:11211'],
    namespace          => 'isucon6q:isuda:',
    utf8               => 1,
    serialize_methods  => [\&_message_pack, \&_message_unpack],
    ketama_points      => 150,
    hash_namespace     => 0,
    compress_threshold => 5_000,
    compress_methods   => [\&_compress_lz4, \&_uncompress_lz4],
});

my $pm = Parallel::Prefork->new({
    max_workers  => 4,
    trap_signals => {
        TERM => 'TERM',
        HUP  => 'TERM',
        USR1 => undef,
    }
});

while ($pm->signal_received ne 'TERM') {
    $pm->start(sub {
        my $msg = redis()->rpop('queue');
        if ($msg) {
            my $payload = _message_unpack($msg);
            if (my $code = __PACKAGE__->can("job_$payload->{func}")) {
                $code->(@{ $payload->{args} });
            }
        });
    });
}
$pm->wait_all_children();

sub job_delete_releated_caches {
    my ($keyword) = @_;
    my $entries = dbh()->select_all(q[SELECT keyword FROM entry WHERE description LIKE ?], "%$keyword%");

    my @keys = map { $CACHE_KEY_HTML . ":$_->{keyword}" } @$entries;
    $cache->delete_multi(\@keys);
}
