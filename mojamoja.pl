#!/usr/bin/env perl
use Plack::Runner;
use MojaMoja;
use Path::Class qw/file dir/;

my $app = do {
    get '/' => sub {
        my $current = dir('./');
        my @children = get_dir( $current );
        make_response( render('dir.mt') );
    };

    get "/{current}" => sub {
        my ($req, $args) = @_;
        my $current = $args->{current};
        if( -d $current ) {
            $current = dir( $current );
            my @children = get_dir( $current );
            make_response( render('dir.mt') );
        }else{
            $current = file( $current );
            my $file = get_file( $current );
            make_response( render('file.mt') );
        }
    };

    zigorou;
};

my $runner = Plack::Runner->new;
$runner->parse_options(@ARGV);
$runner->run($app);

sub make_response {
    my $body = shift;
    my $res = res(200);
    $res->body( $body );
    $res->content_type('text/html');
    $res->finalize;
}

sub get_dir {
    my $path = shift;
    $path ||= dir('./');
    return $path->children;
}

sub get_file {
    my $path = shift;
    return $path->slurp;
}

__DATA__

@@ dir.mt
<h1><?= $current ?></h1>
<ul>
? for my $obj ( @children ) {
<li><a href="<?= $obj ?>"><?= $obj ?></a></li>
? }
</ul>

@@ file.mt
<h1><?= $current ?></h1>
<pre>
<?= $file ?>
</pre>
