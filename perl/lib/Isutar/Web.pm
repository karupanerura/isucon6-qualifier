package Isutar::Web;
use strict;
use warnings;
use Kossy;
use DBIx::Sunny;
use Furl;
use URI::Escape qw/uri_escape_utf8/;
use Cache::Memcached::Fast::Safe;
use Data::MessagePack;
use Compress::LZ4;
use Redis::Fast;

{
    my $msgpack = Data::MessagePack->new->utf8;
    sub _message_pack   { $msgpack->pack(@_)   }
    sub _message_unpack { $msgpack->unpack(@_) }
    sub _compress_lz4   { ${$_[1]} = Compress::LZ4::compress(${$_[0]})   }
    sub _uncompress_lz4 { ${$_[1]} = Compress::LZ4::decompress(${$_[0]}) }
}

my $cache = Cache::Memcached::Fast::Safe->new({
    servers => ['127.0.0.1:11211'],
    namespace          => 'isucon6q:isutar:',
    utf8               => 1,
    serialize_methods  => [\&_message_pack, \&_message_unpack],
    ketama_points      => 150,
    hash_namespace     => 0,
    compress_threshold => 5_000,
    compress_methods   => [\&_compress_lz4, \&_uncompress_lz4],
});

{
    my %redis;
    sub redis {
        $redis{$$} //= Redis::Fast->new(server => '127.0.0.1:6379');
    }
    __PACKAGE__->redis;
}

sub dbh {
    my ($self) = @_;
    return $self->{dbh} //= DBIx::Sunny->connect(
        $ENV{ISUTAR_DSN} // 'dbi:mysql:db=isutar', $ENV{ISUTAR_DB_USER} // 'root', $ENV{ISUTAR_DB_PASSWORD} // '', {
            Callbacks => {
                connected => sub {
                    my $dbh = shift;
                    $dbh->do(q[SET SESSION sql_mode='TRADITIONAL,NO_AUTO_VALUE_ON_ZERO,ONLY_FULL_GROUP_BY']);
                    $dbh->do('SET NAMES utf8mb4');
                    return;
                },
            },
        },
    );
}

get '/initialize' => sub {
    my ($self, $c) = @_;
    $self->dbh->query('TRUNCATE star');
    $c->render_json({
        result => 'ok',
    });
};

get '/stars' => sub {
    my ($self, $c) = @_;

    my @keywords = $c->req->parameters->get_all('keyword');
    my $stars = $self->select_stars_multi(\@keywords);

    $c->render_json({
        stars => @keywords == 1 ? $stars->{$keywords[0]} : $stars,
    });
};

sub select_stars_multi {
    my ($self, $keywords) = @_;
    my ($sql, @bind) = $self->dbh->fill_arrayref(q[
      SELECT
        keyword, user_name
      FROM
        star
      WHERE
        keyword IN (?)
    ], $keywords);

    my $sth = $self->dbh->prepare($sql);
    $sth->execute(@bind);

    my %stars;
    $sth->bind_columns(\my $keyword, \my $user_name);
    push @{ $stars{$keyword} ||= [] } => $user_name while $sth->fetch;
    $sth->finish;

    return \%stars;
}

# post '/stars' => sub {
#     my ($self, $c) = @_;
#     my $keyword = $c->req->parameters->{keyword};
#  
#     my $origin = $ENV{ISUDA_ORIGIN} // 'http://localhost:5000';
#     my $url = "$origin/keyword/" . uri_escape_utf8($keyword);
#     my $res = Furl->new->get($url);
#     unless ($res->is_success) {
#         $c->halt(404);
#     }
#  
#     $self->dbh->query(q[
#         INSERT INTO star (keyword, user_name, created_at)
#         VALUES (?, ?, NOW())
#     ], $keyword, $c->req->parameters->{user});
#  
#     $c->render_json({
#         result => 'ok',
#     });
# };

1;
