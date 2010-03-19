use Giita;

my $giita = Giita->new(
    name  => 'root',
    repos => [qw( ./ )]
);
$giita->app;
