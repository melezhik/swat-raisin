#!/usr/bin/perl

use strict;
use warnings;
use List::Util qw{max};
 
use utf8;
 
use Raisin::API;
use Types::Standard qw(Any Int Str);
 
my %USERS = (
    1 => {
        name => 'Darth Wader',
        password => 'deathstar',
        email => 'darth@deathstar.com',
    },
    2 => {
        name => 'Luke Skywalker',
        password => 'qwerty',
        email => 'l.skywalker@jedi.com',
    },
);
 
plugin 'Swagger', enable => 'CORS';
api_format 'json';
 
swagger_setup(
    title => 'A POD synopsis API',
    description => 'An example of API documentation.',
    #terms_of_service => '',
 
    contact => {
        name => 'Artur Khabibullin',
        url => 'http://github.com/khrt',
        email => 'rtkh@cpan.org',
    },
 
    license => {
        name => 'Perl license',
        url => 'http://dev.perl.org/licenses/',
    },
);
 
desc 'Users API';
resource users => sub {
    summary 'List users';
    params(
        optional => { name => 'start', type => Int, default => 0, desc => 'Pager (start)' },
        optional => { name => 'count', type => Int, default => 10, desc => 'Pager (count)' },
    );
    get sub {
        my $params = shift;
 
        my @users
            = map { { id => $_, %{ $USERS{$_} } } }
              sort { $a <=> $b } keys %USERS;
 
        my $max_count = scalar(@users) - 1;
        my $start = $params->{start} > $max_count ? $max_count : $params->{start};
        my $count = $params->{count} > $max_count ? $max_count : $params->{count};
 
        my @slice = @users[$start .. $count];
        { data => \@slice }
    };
 
    summary 'List all users at once';
    get 'all' => sub {
        my @users
            = map { { id => $_, %{ $USERS{$_} } } }
              sort { $a <=> $b } keys %USERS;
        { data => \@users }
    };
 
    summary 'Create new user';
    params(
        requires => { name => 'name', type => Str, desc => 'User name' },
        requires => { name => 'password', type => Str, desc => 'User password' },
        optional => { name => 'email', type => Str, default => undef, regex => qr/.+\@.+/, desc => 'User email' },
    );
    post sub {
        my $params = shift;
 
        my $id = max(keys %USERS) + 1;
        $USERS{$id} = $params;
 
        { success => 1 }
    };
 
    desc 'Actions on the user';
    params requires => { name => 'id', type => Int, desc => 'User ID' };
    route_param 'id' => sub {
        summary 'Show user';
        get sub {
            my $params = shift;
            $USERS{ $params->{id} };
        };
 
        summary 'Delete user';
        del sub {
            my $params = shift;
            { success => delete $USERS{ $params->{id} } };
        };
    };
 
    summary 'NOP';
    get nop => sub { };
};
 
desc 'Echo API endpoint';
resource echo => sub {
    params(optional => { name => 'data0', type => Any, default => "hey!" });
    get sub { shift };
};
 
run;
