use Giita;

my $giita =
  Giita->new( name => 'root', repos => [qw!./ /home/yusuke/work/noe/Noe!] );
$giita->app;
