use v6;
use lib 'lib';
use JSON::Fast;
use Test;
use URI;
use WebService::SOP::Auth::V1_1;

subtest {

    subtest {
        dies-ok {
            WebService::SOP::Auth::V1_1.new(
                app-secret => 'hogefuga',
            );
        }, 'Fails without app-id';

        dies-ok {
            WebService::SOP::Auth::V1_1.new(
                app-id     => 'hogefuga',
                app-secret => 'hogefuga',
            );
        }, 'Fails with wrong type';

    }, 'Test app-id';

    subtest {
        dies-ok {
            WebService::SOP::Auth::V1_1.new(
                app-id => 123,
            );
        }, 'Fails without app-secret';

        dies-ok {
            WebService::SOP::Auth::V1_1.new(
                app-id     => 123,
                app-secret => 12345,
            );
        }, 'Fails with wrong type';

    }, 'Test app-secret';

    subtest {
        my WebService::SOP::Auth::V1_1 $auth
            .= new(app-id => 123, app-secret => 'hogefuga');

        ok $auth;

    }, 'Succeeds with valid params';

}, 'Test instance';

subtest {
    my WebService::SOP::Auth::V1_1 $auth
        .= new(app-id => 123, app-secret => 'hogehoge');

    subtest {
        my HTTP::Request $req = $auth.get(
            'http://hoge/fuga?bbb=bbb', { aaa => 'aaa' },
        );

        is $req.method,     'GET';
        is $req.uri.scheme, 'http';
        is $req.uri.host,   'hoge';
        is $req.uri.path,   '/fuga';

        my %query = $req.uri.query-form;

        is %query<app_id>,  123;
        is %query<aaa>,     'aaa';
        is %query<bbb>,     'bbb';
        like %query<time>,  rx{ ^^ <[0..9]>+ $$ };
        like %query<sig>,   rx{ ^^ <[a..f 0..9]> ** 64 $$ };

    }, 'Creating a GET request';

    subtest {
        my HTTP::Request $req = $auth.post(
            'http://hoge/fuga?bbb=bbb', { aaa => 'aaa' },
        );

        is $req.method,     'POST';
        is $req.uri.scheme, 'http';
        is $req.uri.host,   'hoge';
        is $req.uri.path,   '/fuga';
        is-deeply $req.uri.query-form, {};

        my %query = URI::split-query(~$req.content);

        is %query<app_id>,  123;
        is %query<aaa>,     'aaa';
        is %query<bbb>,     'bbb';
        like %query<time>,  rx{ ^^ <[0..9]>+ $$ };
        like %query<sig>,   rx{ ^^ <[a..f 0..9]> ** 64 $$ };

    }, 'Creating a POST request';

    subtest {
        my HTTP::Request $req = $auth.post-json(
            'http://hoge/fuga?bbb=bbb', { aaa => 'aaa' },
        );

        is $req.method,     'POST';
        is $req.uri.scheme, 'http';
        is $req.uri.host,   'hoge';
        is $req.uri.path,   '/fuga';
        is-deeply $req.uri.query-form, {};

        like ~$req.header.field('X-Sop-Sig'), rx{ ^^ <[a..f 0..9]> ** 64 $$ };

        my %query = from-json(~$req.content);

        is %query<app_id>,  123;
        is %query<aaa>,     'aaa';
        is %query<bbb>,     'bbb';
        like ~%query<time>,  rx{ ^^ <[0..9]>+ $$ };

    }, 'Creating a POST request with JSON body';

}, 'Test create-request';

done-testing;
