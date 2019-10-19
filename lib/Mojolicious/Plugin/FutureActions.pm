package Mojolicious::Plugin::FutureActions;

use Mojo::Base 'Mojolicious::Plugin';

use Scalar::Util 'blessed';

our $VERSION = '0.01';

sub register {
    my ( $self, $app, $conf ) = @_;
    $app->hook(
        before_action => sub { use DDP; p @_; }
    );
    $app->hook(
        around_action => sub {
            my ( $next, $c, $action, $last ) = @_;
            my $want = wantarray;
            my @args;
            if ($want) { @args    = $next->() }
            else       { $args[0] = $next->() }
            if (blessed($args[0]) && $args[0]->can('on_done')) {
                my $tx = $c->tx;
                $c->render_later if $last;
                $args[0] = $args[0]->retain;
                $args[0]->on_done( sub { ( $last ? undef : sub { $c->continue if $_[0] } ) } )
                        ->on_fail( sub { $c->reply->exception($_[0]) and undef $tx; } );
                return unless $last;
            }
            return $want ? @args : $args[0];
        }
    );
}

1;
