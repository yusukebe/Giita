use Plack::Runner;
use MojaMoja;

my $app = do {
    get '/' => sub {
        render('index.mt');
    };
    zigorou;
};

my $runner = Plack::Runner->new;
$runner->parse_options(@ARGV);
$runner->run($app);

__DATA__

@@ index.mt
hello
