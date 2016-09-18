package Isuda::Web;
use 5.014;
use warnings;
use utf8;
use Kossy;
use DBIx::Sunny;
use Encode qw/encode_utf8/;
use POSIX qw/ceil/;
use Furl;
use JSON::XS qw/decode_json encode_json/;
use String::Random qw/random_string/;
use Digest::SHA1 qw/sha1_hex/;
use URI::Escape qw/uri_escape_utf8/;
use HTML::Escape qw/escape_html/;
# use Text::Xslate::Util qw/html_escape/;
use List::Util qw/min max/;
use Cache::Memcached::Fast::Safe;
use Cache::Memory::Simple;
use Data::MessagePack;
use Compress::LZ4;
use Redis::Fast;
use feature qw/state/;

# BEGIN {
#     if (0) {
#         use Devel::KYTProf;
#         Devel::KYTProf->add_prof(__PACKAGE__, '_get_sorted_keywords');
#         Devel::KYTProf->add_prof(__PACKAGE__, 'htmlify');
#         Devel::KYTProf->add_prof(__PACKAGE__, 'is_spam_contents');
#         Devel::KYTProf->add_prof(__PACKAGE__, 'register');
#     }
# }

{
    my $msgpack = Data::MessagePack->new->utf8;
    sub _message_pack   { $msgpack->pack(@_)   }
    sub _message_unpack { $msgpack->unpack(@_) }
    sub _compress_lz4   { ${$_[1]} = Compress::LZ4::compress(${$_[0]})   }
    sub _uncompress_lz4 { ${$_[1]} = Compress::LZ4::decompress(${$_[0]}) }
}

my $cache = Cache::Memory::Simple->new();
# my $cache = Cache::Memcached::Fast::Safe->new({
#     servers => ['127.0.0.1:11211'],
#     namespace          => 'isucon6q:isuda:',
#     utf8               => 1,
#     serialize_methods  => [\&_message_pack, \&_message_unpack],
#     ketama_points      => 150,
#     hash_namespace     => 0,
#     compress_threshold => 5_000,
#     compress_methods   => [\&_compress_lz4, \&_uncompress_lz4],
# });

{
    my %redis;
    sub redis {
        $redis{$$} //= Redis::Fast->new(server => '127.0.0.1:6379');
    }
    __PACKAGE__->redis;
}

my $CACHE_KEY_KEYWORDS = 'keywords';
my $CACHE_KEY_HTML     = 'html';
my $REDIS_KEY_TOTAL_ENTRIES = 'total_entries';

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
    my ($self) = @_;
    return $self->{dbh} //= DBIx::Sunny->connect(config('dsn'), config('db_user'), config('db_password'), {
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

filter 'set_name' => sub {
    my $app = shift;
    sub {
        my ($self, $c) = @_;
        my $user_id = $c->env->{'psgix.session'}->{user_id};
        if ($user_id) {
            $c->stash->{user_id} = $user_id;
            $c->stash->{user_name} = $self->dbh->select_one(q[
                SELECT name FROM user
                WHERE id = ?
            ], $user_id);
            $c->halt(403) unless defined $c->stash->{user_name};
        }
        $app->($self,$c);
    };
};

filter 'authenticate' => sub {
    my $app = shift;
    sub {
        my ($self, $c) = @_;
        $c->halt(403) unless defined $c->stash->{user_id};
        $app->($self,$c);
    };
};

get '/initialize' => sub {
    my ($self, $c)  = @_;
    $self->dbh->query(q[
        DELETE FROM entry WHERE id > 7101
    ]);
    $cache->delete($CACHE_KEY_KEYWORDS);
    $self->dbh->query('TRUNCATE star');
    $self->total_entries; # init / set default 7100

    $c->render_json({
        result => 'ok',
    });
};

get '/' => [qw/set_name/] => sub {
    my ($self, $c)  = @_;

    my $PER_PAGE = 10;
    my $page = $c->req->parameters->{page} || 1;

    my $records = $self->dbh->select_all(qq[
        SELECT id FROM entry
        ORDER BY updated_at DESC
        LIMIT $PER_PAGE
        OFFSET @{[ $PER_PAGE * ($page-1) ]}
    ]);
    my $ids = [map { $_->{id} } @$records];

    my $entries = $self->dbh->select_all(qq[
        SELECT id, keyword, description FROM entry WHERE id in (?)
    ], $ids);
    my @entries;
    for my $id (@$ids) {
        push @entries, grep { $_->{id} == $id } @$entries;
    }
    for my $entry (@entries) {
        $entry->{html}  = $self->htmlify($c, $entry->{keyword}, $entry->{description});
        $entry->{stars} = $self->select_stars($entry->{id});
    }

    my %id2ent = map { $_->{id} => $_ } @$entries;
    my $stars = $self->select_stars_multi([keys %id2ent]);
    for my $id (keys %$stars) {
        my $entry = $id2ent{$id};
        $entry->{stars} = $stars->{$id};
    }

    my $total_entries = $self->total_entries;
    my $last_page = ceil($total_entries / $PER_PAGE);
    my @pages = (max(1, $page-5)..min($last_page, $page+5));

    $c->render('index.tx', { entries => \@entries, page => $page, last_page => $last_page, pages => \@pages });
};

get 'robots.txt' => sub {
    my ($self, $c)  = @_;
    $c->halt(404);
};

post '/keyword' => [qw/set_name authenticate/] => sub {
    my ($self, $c) = @_;
    my $keyword = $c->req->parameters->{keyword};
    unless (length $keyword) {
        $c->halt(400, q('keyword' required));
    }
    my $user_id = $c->stash->{user_id};
    my $description = $c->req->parameters->{description};

    if (is_spam_contents($description.' '.$keyword)) {
        $c->halt(400, 'SPAM!');
    }
    $self->dbh->query(q[
        INSERT INTO entry (author_id, keyword, description, created_at, updated_at)
        VALUES (?, ?, ?, NOW(), NOW())
        ON DUPLICATE KEY UPDATE
        author_id = ?, keyword = ?, description = ?, updated_at = NOW()
    ], ($user_id, $keyword, $description) x 2);

    $cache->delete($CACHE_KEY_HTML . ":$keyword");

    if ($self->dbh->last_insert_id) {
        $self->redis->incr($REDIS_KEY_TOTAL_ENTRIES);
        $cache->delete($CACHE_KEY_KEYWORDS);

        my $entries = $self->dbh->select_all(qq[
            SELECT keyword FROM entry WHERE description LIKE "%$keyword%"
        ]);
        
        my @cache_keys;
        for my $entry (@$entries) {
            push @cache_keys, $CACHE_KEY_HTML . ":$entry->{keyword}";
        }
        $cache->delete_multi(\@cache_keys);
    }
    $c->redirect('/');
};

get '/register' => [qw/set_name/] => sub {
    my ($self, $c)  = @_;
    $c->render('authenticate.tx', {
        action => 'register',
    });
};

post '/register' => sub {
    my ($self, $c) = @_;

    my $name = $c->req->parameters->{name};
    my $pw   = $c->req->parameters->{password};
    $c->halt(400) if $name eq '' || $pw eq '';

    my $user_id = register($self->dbh, $name, $pw);

    $c->env->{'psgix.session'}->{user_id} = $user_id;
    $c->redirect('/');
};

sub register {
    my ($dbh, $user, $pass) = @_;

    my $salt = random_string('....................');
    $dbh->query(q[
        INSERT INTO user (name, salt, password, created_at)
        VALUES (?, ?, ?, NOW())
    ], $user, $salt, sha1_hex($salt . $pass));

    return $dbh->last_insert_id;
}

get '/login' => [qw/set_name/] => sub {
    my ($self, $c)  = @_;
    $c->render('authenticate.tx', {
        action => 'login',
    });
};

post '/login' => sub {
    my ($self, $c) = @_;

    my $name = $c->req->parameters->{name};
    my $row = $self->dbh->select_row(q[
        SELECT * FROM user
        WHERE name = ?
    ], $name);
    if (!$row || $row->{password} ne sha1_hex($row->{salt}.$c->req->parameters->{password})) {
        $c->halt(403)
    }

    $c->env->{'psgix.session'}->{user_id} = $row->{id};
    $c->redirect('/');
};

get '/logout' => sub {
    my ($self, $c)  = @_;
    $c->env->{'psgix.session'} = {};
    $c->redirect('/');
};

get '/keyword/:keyword' => [qw/set_name/] => sub {
    my ($self, $c) = @_;
    my $keyword = $c->args->{keyword} // $c->halt(400);

    my $entry = $self->dbh->select_row(qq[
        SELECT * FROM entry
        WHERE keyword = ?
    ], $keyword);
    $c->halt(404) unless $entry;
    $entry->{html} = $self->htmlify($c, $entry->{keyword}, $entry->{description});
    $entry->{stars} = $self->select_stars($entry->{id});

    $c->render('keyword.tx', { entry => $entry });
};

post '/keyword/:keyword' => [qw/set_name authenticate/] => sub {
    my ($self, $c) = @_;
    my $keyword = $c->args->{keyword} or $c->halt(400);
    $c->req->parameters->{delete} or $c->halt(400);

    my $keywords = $self->_get_sorted_keywords;
    unless (grep { $_->{keyword} eq $keyword } @$keywords) {
        $c->halt(404);
    }

    $self->dbh->query(qq[
        DELETE FROM entry
        WHERE keyword = ?
    ], $keyword);
    $cache->delete($CACHE_KEY_KEYWORDS);
    $cache->delete($CACHE_KEY_HTML . ":$keyword");

    $self->redis->decr($REDIS_KEY_TOTAL_ENTRIES);

    $c->redirect('/');
};

post '/stars' => [qw/set_name authenticate/] => sub {
    my ($self, $c) = @_;
    my $keyword = $c->req->parameters->{keyword};

    my $entry = $self->dbh->select_row(qq[
        SELECT id FROM entry
        WHERE keyword = ?
    ], $keyword);
    $c->halt(404) unless $entry;

    $self->dbh->query(q[
        INSERT INTO star (entry_id, user_name)
        VALUES (?, ?)
    ], $entry->{id}, $c->req->parameters->{user});

    $c->render_json({
        result => 'ok',
    });
};

sub htmlify {
    my ($self, $c, $keyword, $content) = @_;
    my $cache_key = $CACHE_KEY_HTML . ":$keyword";
    $cache->get_or_set(
        $cache_key,
        sub { $self->_htmlify($c, $content) }
    );
}

sub _htmlify {
    my ($self, $c, $content) = @_;
    return '' unless defined $content;
    my $keywords = $self->_get_sorted_keywords;
    my %kw2sha;
    my $re = join '|', map { quotemeta $_->{keyword} } @$keywords;
    $content =~ s{($re)}{
        my $kw = $1;
        $kw2sha{$kw} = "isuda_" . sha1_hex(encode_utf8($kw));
    }eg;
    $content = escape_html($content);
    while (my ($kw, $hash) = each %kw2sha) {
        my $url = $c->req->uri_for('/keyword/' . uri_escape_utf8($kw));
        my $link = sprintf '<a href="%s">%s</a>', $url, escape_html($kw);
        $content =~ s/$hash/$link/g;
    }
    $content =~ s{\n}{<br \/>\n}gr;
}

sub _get_sorted_keywords {
    my ($self) = @_;
    return $cache->get_or_set(
        $CACHE_KEY_KEYWORDS,
        sub {
            $self->dbh->select_all(qq[
                SELECT keyword FROM entry ORDER BY CHARACTER_LENGTH(keyword) DESC
            ]);
        }
    );
}

sub is_spam_contents {
    my $content = shift;
    my $ua = Furl->new;
    my $res = $ua->post(config('isupam_origin'), [], [
        content => encode_utf8($content),
    ]);
    my $data = decode_json $res->content;
    !$data->{valid};
}

sub select_stars {
    my ($self, $id) = @_;
    my $entries = $self->select_stars_multi([$id]);
    return $entries->{$id};
};

sub select_stars_multi {
    my ($self, $ids) = @_;

    my ($sql, @bind) = $self->dbh->fill_arrayref(q[
      SELECT
        entry_id, user_name
      FROM
        star
      WHERE
        entry_id IN (?)
    ], $ids);

    my $sth = $self->dbh->prepare($sql);
    $sth->execute(@bind);

    my %stars;
    $sth->bind_columns(\my $entry_id, \my $user_name);
    push @{ $stars{$entry_id} ||= [] } => $user_name while $sth->fetch;
    $sth->finish;

    return \%stars;
}

sub total_entries {
    my ($self) = @_;
    my $count = $self->redis->get($REDIS_KEY_TOTAL_ENTRIES);
    return $count if $count;
    $count = 7100;
    $self->redis->set($REDIS_KEY_TOTAL_ENTRIES, $count);
    return $count;
}

1;
