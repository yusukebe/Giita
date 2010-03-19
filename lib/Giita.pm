package Giita;
use strict;
use warnings;

our $VERSION = '0.01';
our $rock = 1;

sub new {
    my ( $class, %opt ) = @_;
    my $self = bless {}, $class;
    $self;
}

sub app {
    my $self = shift;
    sub {
        my $env     = shift;
        my $req     = Plack::Request->new($env);
        my $current = $req->path_info;
        $current =~ s!^/!./!;

        my $base = $req->base;

        if ( my $sha = $req->param('commit') ) {
            my $git_commit = git_show($sha);
            return make_response( render('commit.mt') );
        }

        if ( -d $current ) {
            $current = dir($current);
            my ( $children, $git_logs ) = get_dir($current);
            return make_response( render('dir.mt') );
        }

        if ( -B $current ) {
            my $body = file($current)->slurp;
            return [ 200, [ 'Content-Length' => length $body ], [$body] ];
        }

        if ( -f $current ) {
            $current = file($current);
            my ( $content, $git_logs ) = get_file($current);
            return make_response( render('file.mt') );
        }
        return [ 404, [], ['404 Document Not Found'] ];
    };
}

sub make_response {
    my ( $self, $body ) = @_;
    my $head = render('head.mt');
    my $foot = render('foot.mt');
    my $res  = res(200);
    $res->body( $head . $body . $foot );
    $res->content_type('text/html');
    $res->finalize;
}

sub get_dir {
    my ( $self, $path ) = @_;
    $path ||= dir('./');
    my @children = $path->children;
    if (wantarray) {
        return ( \@children, git_log($path) );
    }
    else {
        return \@children;
    }
}

sub get_file {
    my ( $self, $path ) = @_;
    my $text = $path->slurp;
    my $html;
    my ($ext) = $path->basename =~ /\.([^\.]+)$/;
    if ( $ext =~ /(?:pm|pl|psgi|pod|t)/i ) {
        $html .= pod($text);
        $html .= '<pre class="code">' . highlight($text) . '</pre>';
    }
    elsif ( $ext =~ /(?:md|mkdn)/i ) {
        $html .= markdown($text);
        $html .= '<pre>' . highlight($text) . '</pre>';
    }
    else {
        $html = '<pre>' . highlight($text) . '</pre>';
    }
    if (wantarray) {
        return ( $html, git_log($path) );
    }
    else {
        return $html;
    }
}

$Giita::rock;

=head1 NAME

Giita - Lightweight Rock Band.

=head1 DESCRIPTION

Yet another git repository viewer support perl and pod styling using "many" CPAN modules.

=head1 SYNOPSIS

Run on your git directory to want to see.

  $ giita

=head1 HOW TO GET

  $ git clone git://github.com/yusukebe/Giita.git

=head1 AUTHOR

Yusuke Wada yusuke at kamawada.com

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

