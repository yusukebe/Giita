#!/usr/bin/env perl
use MojaMoja qw/render/;
use Path::Class qw/file dir/;
use Plack::Runner;
use Plack::Request;
use Text::VimColor;
use Pod::Simple::XHTML;
use HTML::TreeBuilder::XPath;

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
    my $html;
    my ($ext) = $path->basename =~ /\.([^\.]+)$/;
    if( $ext =~ /(?:pm|pl|psgi|pod|t)/i ){
        $html .= pod( $text );
        $html .= '<pre class="code">' . highlight( $text ) . '</pre>';
    }else{
        $html = highlight( $text );
    }
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

zigorou; #XXX

=head1 NAME

mojamoja(kari) - Yet another document viewer support perl and pod.

=head1 SYNOPSIS

Run your directory to want to see.

  $ ./mojamoja.pl

=head1 AUTHOR

Yusuke Wada

=cut

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
pre, pre code { font-family: 'Monaco', monospace; font-size:0.8em; }
pre { border: 1px solid #ccc; background-color: #eee; border: 1px solid #888; padding: 1em; overflow:auto;}
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
?= Text::MicroTemplate::encoded_string $html
