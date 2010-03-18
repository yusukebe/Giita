#!/usr/bin/env perl
use MojaMoja qw/render/;
use Path::Class qw/file dir/;
use Plack::Runner;
use Plack::Request;
use Text::VimColor;

#XXX
my $runner = Plack::Runner->new;
$runner->parse_options(@ARGV);
$runner->run( sub { app(@_) } );

sub app {
    my $env = shift;
    my $req = Plack::Request->new( $env );
    my $current = $req->path_info;
    $current =~ s!^/!./!;
    my $base = $req->base;
    if ( -d $current ) {
        $current = dir($current);
        my @children = get_dir($current);
        make_response( render('dir.mt') );
    }
    else {
        $current = file($current);
        my $html = get_file($current);
        make_response( render('file.mt') );
    }
}

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
    my $text = $path->slurp;
    my $html = highlight( $text );
    return $html;
}

sub highlight {
    my $text = shift;
    my $syntax = Text::VimColor->new(
        string   => $text,
        filetype => 'perl',
    );
    return $syntax->html;
}

zigorou; #XXX

__DATA__

@@ dir.mt
<h1><?= $current ?></h1>
<ul>
? for my $obj ( @children ) {
<li><a href="<?= $base ?><?= $obj ?>"><?= $obj ?></a></li>
? }
</ul>

@@ file.mt
<style type="text/css">
.synComment    { color: #0000FF }
.synConstant   { color: #FF00FF }
.synIdentifier { color: #008B8B }
.synStatement  { color: #A52A2A ; font-weight: bold }
.synPreProc    { color: #A020F0 }
.synType       { color: #2E8B57 ; font-weight: bold }
.synSpecial    { color: #6A5ACD }
.synUnderlined { color: #000000 ; text-decoration: underline }
.synError      { color: #FFFFFF ; background: #FF0000 none }
.synTodo       { color: #0000FF ; background: #FFFF00 none }
</style>
<h1><?= $current ?></h1>
<pre>
?= Text::MicroTemplate::encoded_string $html
</pre>
