#!/usr/bin/perl

use MojaMoja qw/render/;
use Path::Class qw/file dir/;
use Plack::Runner;
use Plack::Request;
use Text::VimColor;
use Pod::Simple::XHTML;
use HTML::TreeBuilder::XPath;
use Git::Class::Cmd;

my $git_root = dir('.git')->stringify;
my $git_cmd = Git::Class::Cmd->new( die_on_error => 1 , git_dir => $git_root );

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
        my ($children, $git_logs) = get_dir($current);
        return make_response( render('dir.mt') );
    }

    if( -B $current ) {
        my $body = file($current)->slurp;
        return [200,[ 'Content-Length' => length $body ],[ $body ]];
    }

    if( -f $current ) {
        $current = file($current);
        my ($content, $git_logs) = get_file($current);
        return make_response( render('file.mt') );
    }
    return [404,[],['404 Document Not Found']];
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
    my @children = $path->children;
    if( wantarray ){
        my $git_logs = '<pre class="git">' . highlight( git_show(), 'diff' ) . '</pre>';
        return (\@children, $git_logs);
    }else{
        return \@children;
    }
}

sub get_file {
    my $path = shift;
    my $text = $path->slurp;
    my $html;
    my ($ext) = $path->basename =~ /\.([^\.]+)$/;
    if( $ext =~ /(?:pm|pl|psgi|pod|t)/i ){
        $html .= pod( $text );
        $html .= '<pre class="code">' . highlight( $text ) . '</pre>';
    }else{
        $html = '<pre>' . highlight( $text ) . '</pre>';
    }
    if(wantarray){
        my $git_logs;
        push @$git_logs, '<pre class="git">' . highlight( git_diff( $path ),'diff' ) . '</pre>';
        push @$git_logs, '<pre class="git">' . git_log( $path ) . '</pre>';
        return ( $html, $git_logs );
    }else{
        return $html;
    }
}

sub highlight {
    my ( $text, $type ) = @_;
    $type ||= 'perl';
    my $syntax = Text::VimColor->new(
        string   => $text,
        filetype => $type,
    );
    return $syntax->html;
}

sub pod {
    my $text = shift;
    my $parser = Pod::Simple::XHTML->new();
    my $html;
    $parser->output_string( \$html );
    $parser->html_header('');
    $parser->html_footer('');
    $parser->html_h_level(3);
    $parser->parse_string_document( $text );
    $html = highlight_pod($html);
    $html = '<div class="pod">' . $html . '</div>';
    return $html;
}

sub highlight_pod {
    my $html = shift;
    my $tree = HTML::TreeBuilder::XPath->new;
    $tree->parse($html);
    for my $code ( $tree->findnodes('//pre') ) {
        my $hilight_code = highlight( $code->as_text );
        my $code_html    = $code->as_HTML;
        $html =~ s/\Q$code_html\E/<pre>$hilight_code<\/pre>/m;
    }
    return $html;
}

sub git_show {
    my $log =
      $git_cmd->git( 'show' );
    return $log;
}

sub git_log {
    my $path = shift;
    my $log = $git_cmd->git( 'log', $path );
    return $log;
}

sub git_diff {
    my $path = shift;
    my $log = $git_cmd->git( 'diff', $path );
    return $log;
}

=head1 NAME

podder-lite - Yet another document viewer support perl and pod using "many" CPAN modules.

=head1 SYNOPSIS

Run on your directory to want to see.

  $ plackup podder-lite.psgi

=head1 HOW TO GET

  $ git clone git://gist.github.com/336278.git gist-336278

=head1 AUTHOR

Yusuke Wada

=cut

__DATA__

@@ dir.mt
<link rel="stylesheet" href="http://gist.github.com/raw/336278/f542e3051457773bfa4503e283a1a182b0ce7b12/screen.css" type="text/css" media="screen, projection">
<link rel="stylesheet" href="http://gist.github.com/raw/336278/e8e7b9aa8fffb554b74953c66d7c581b3c4ea903/site.css" type="text/css" media="screen, projection">
<link rel="stylesheet" href="http://gist.github.com/raw/336278/fdb82208e9920c801638671f92a8fd0b62902464/print.css" type="text/css" media="print">
<!--[if lt IE 8]><link rel="stylesheet" href="http://gist.github.com/raw/336278/3dddda9451f84f20b5b0b27307f0eac4f1a535fe/ie.css" type="text/css" media="screen, projection"><![endif]-->
<body>
<div class="container">
<hr class="space" />
<h1><?= $current ?></h1>
<hr />
<ul>
? for my $obj ( @$children ) {
<li><a href="<?= $base ?><?= $obj ?>"><?= $obj ?></a></li>
? }
</ul>
<h2>git info</h2>
?= Text::MicroTemplate::encoded_string $git_logs
</div>
</body>

@@ file.mt
<link rel="stylesheet" href="http://gist.github.com/raw/336278/f542e3051457773bfa4503e283a1a182b0ce7b12/screen.css" type="text/css" media="screen, projection">
<link rel="stylesheet" href="http://gist.github.com/raw/336278/e8e7b9aa8fffb554b74953c66d7c581b3c4ea903/site.css" type="text/css" media="screen, projection">
<link rel="stylesheet" href="ttp://gist.github.com/raw/336278/fdb82208e9920c801638671f92a8fd0b62902464/print.css" type="text/css" media="print">
<!--[if lt IE 8]><link rel="stylesheet" href="http://gist.github.com/raw/336278/3dddda9451f84f20b5b0b27307f0eac4f1a535fe/ie.css" type="text/css" media="screen, projection"><![endif]-->
<body>
<div class="container">
<hr class="space" />
<h1><?= $current ?></h1>
<hr />
?= Text::MicroTemplate::encoded_string $content
? for my $log ( @$git_logs ) {
?= Text::MicroTemplate::encoded_string $log
? }
</div>
</body>
