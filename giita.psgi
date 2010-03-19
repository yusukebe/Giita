use Giita;

my $giita = Giita->new(
    name  => 'root',
    repos => [
        qw!./ /export/home/yusuke/work/noe/Noe/ /home/yusuke/work/kailas/Kailas-API!
    ]
);
$giita->app;
