package Giita;
use strict;
use warnings;
use Path::Class qw/file dir/;
use Plack::Request;
use Giita::Filter;
use Giita::Git;
use Text::MicroTemplate ();
use Data::Section::Simple ();

our $VERSION = '0.01';

my %CACHE;
our $KEY;
our $DATA_SECTION_LEVEL = 0;

sub new {
    my ( $class, %opt ) = @_;
    my $self = bless { name => $opt{name} || 'Repos' }, $class;
    my $repos = $self->_init( $opt{repos} );
    $self->{repos} = $repos;
    $self->{filter} = Giita::Filter->new;
    $self;
}

sub _init {
    my ( $self, $r ) = @_;
    my $repos;
    for ( @$r ) {
        my $dir = dir( $_ );
        next unless -d $dir->subdir('.git')->absolute;
        my $git = Giita::Git->new( git_dir => $dir->subdir('.git')->absolute );
        my @paths = split '/', $dir->absolute;
        my $name = pop @paths;
        push @$repos, { dir => $dir, name => $name, git => $git };
    }
    return $repos;
}

sub app {
    my $self = shift;
    sub {
        my $env     = shift;
        my $req     = Plack::Request->new($env);
        my $base = $req->base;

        if ( $req->path_info eq '/' ){
            my @repos = @{ $self->{repos} };
            return $self->make_response( $self->render( 'index.mt') );
        }

        my $current = $req->path_info;
        my ($name) = $current =~ /^\/([^\/]+)/;
        my $repo = $self->get_repo( $name ) or $self->handle_404;
        $self->dispatch( $req, $repo );
    };
}

sub handle_404 {
    return [ 404, [], ['404 Document Not Found'] ];
}

sub dispatch {
    my ( $self, $req, $repo ) = @_;
    my $base = $req->base;

    if ( my $sha = $req->param('commit') ) {
        my $git_commit = $repo->{git}->show($sha);
        $git_commit = $self->{filter}->highlight($git_commit, 'diff');
        return $self->make_response( $self->render('commit.mt') );
    }

    warn $req->path_info;
    my $path_info = $req->path_info || '';
    $path_info =~ s!^/!!;
    my $path_name = $path_info || '';
    $path_name =~ s/$repo->{name}//;
    my $current = $repo->{dir}->absolute . $path_name;
    if ( -d $current ) {
        $current = dir($current);
        my ( $children, $git_logs ) = (
            $self->get_dir( $current ),
            $repo->{git}->log( $current, $repo )
        );
        my $links = $self->get_links($path_info);
        return $self->make_response( $self->render('dir.mt') );
    }
    if ( -B $current ) {
        my $body = file($current)->slurp;
        return [ 200, [ 'Content-Length' => length $body ], [$body] ];
    }
    if ( -f $current ) {
        $current = file($current);
        my ( $content, $git_logs ) =
            ( $self->get_file($current), $repo->{git}->log($current, $repo) );
        my $links = $self->get_links($path_info);
        return $self->make_response( $self->render('file.mt') );
    }
    return $self->handle_404;
}

sub get_links {
    my ( $self, $path_info ) = @_;
    my @path = split '/', $path_info;
    my (@l, $links);
    for ( @path ){
        push @l, $_;
        my $href = join '/', @l;
        push @$links, { href => $href , name => $_ }
    }
    return $links;
}

sub make_response {
    my ( $self, $body ) = @_;
    my $head = $self->render('head.mt');
    my $foot = $self->render('foot.mt');
    $body = $head . $body . $foot;
    return [200,[ 'Content-Length' => length $body, 'Content-Type' => 'text/html'], [$body] ];
}

sub get_repo {
    my ( $self, $name ) = @_;
    map { return $_ if $_->{name} eq $name } @{ $self->{repos} };
    return;
}

sub get_dir {
    my ( $self, $path ) = @_;
    $path ||= dir('./');
    my @children = $path->children;
    return \@children;
}

sub get_file {
    my ( $self, $path ) = @_;
    my $text = $path->slurp;
    my $html;
    my ($ext) = $path->basename =~ /\.([^\.]+)$/;
    if ( $ext =~ /(?:pm|pl|psgi|pod|t)/i ) {
        $html .= $self->{filter}->pod($text);
        $html .= '<pre class="code">' . $self->{filter}->highlight($text) . '</pre>';
    }
    elsif ( $ext =~ /(?:md|mkdn)/i ) {
        $html .= $self->{filter}->markdown($text);
        $html .= '<pre>' . $self->{filter}->highlight($text) . '</pre>';
    }
    else {
        $html = '<pre>' . $self->{filter}->highlight($text) . '</pre>';
    }
    return $html;
}

#XXX stolen from MojaMoja
sub get_data_section {
    my $pkg  = caller($DATA_SECTION_LEVEL);
    no warnings; #XXX
    my $data = $CACHE{$KEY}->{__data_section} ||=
      Data::Section::Simple->new($pkg)->get_data_section;
    return @_ ? $data->{ $_[0] } : $data;
}

sub render {
    my ( $self, $key, @args ) = @_;
    no warnings; #XXX
    my $code = $CACHE{$KEY}->{$key} ||= do {
        local $DATA_SECTION_LEVEL = $DATA_SECTION_LEVEL + 1;
        my $tmpl = get_data_section($key);
        Carp::croak("unknown template file:$key") unless $tmpl;
        Text::MicroTemplate->new( template => $tmpl, package_name => 'main' )
          ->code();
    };
    package DB;
    local *DB::render = sub {
        my $coderef = ( eval $code );    ## no critic
        die "Cannot compile template '$key': $@" if $@;
        $coderef->(@args);
    };
    goto &DB::render;
}

1;

=head1 NAME

Giita - Yet another document viewer for local directory of git repository.

=head1 DESCRIPTION

Yet another git repository viewer support perl and pod styling using "many" CPAN modules.

But, we are lightweight rock band.

=head1 SYNOPSIS

In your .psgi

  use Giita;

  my $giita = Giita->new(
      name  => 'root',
      repos => [qw( /path/to/repo )]
  );
  $giita->app;

And run with plackup

  $ plackup giita.psgi

=head1 HOW TO GET

  $ git clone git://github.com/yusukebe/Giita.git

=head1 AUTHOR

Yusuke Wada yusuke at kamawada.com

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__DATA__

@@ index.mt
<h1>Repos</h1>
<hr />

? for my $repo ( @repos ) {
<h2><a href="<?= $base ?><?= $repo->{name} ?>"><?= $repo->{name} ?></a></h2>
? }

@@ dir.mt
<h1>
<a href="<?= $base ?>">Repos</a> /
? my $current_link = pop @$links;
? for my $link ( @$links ){
<a href="<?= $base ?><?= $link->{href} ?>"><?= $link->{name} ?></a> /
? }
<?= $current_link->{name} ?>
</h1>
<hr />
<ul>
? for my $child ( @$children ) {
? my @child_path = split '/', $child->absolute;
? my $child_name = pop @child_path;
<li class="<? if ( $child->is_dir ) { ?>dir<? }else { ?>file<? } ?>"><a href="<?= $base ?><?= $path_info ?>/<?= $child_name ?>"><?= $child_name ?></a></li>
? }
</ul>
<pre class="git">
?= Text::MicroTemplate::encoded_string $git_logs
</pre>

@@ file.mt
? my @path = split '/', $path_info;
? my $current_path = pop @path;
? my @links;
<h1>
<a href="<?= $base ?>">Repos</a> /
? my $current_link = pop @$links;
? for my $link ( @$links ){
<a href="<?= $base ?><?= $link->{href} ?>"><?= $link->{name} ?></a> /
? }
<?= $current_link->{name} ?>
</h1>
<hr />
<div class="span-17">
?= Text::MicroTemplate::encoded_string $content
</div>
<div class="span-7 last">
<pre class="git" style="font-size:0.7em;">
?= Text::MicroTemplate::encoded_string $git_logs
</pre>
</div>

@@ commit.mt
<h1><a href="<?= $base ?>">Repos</a> /
<a href="<?= $base ?><?= $repo->{name} ?>"><?= $repo->{name} ?></a><h1>
<h2><?= $sha ?></h2>
<hr />
<pre class="git">
?= Text::MicroTemplate::encoded_string $git_commit
</pre>

@@ head.mt
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html>
</head>
<title></title>
<link rel="stylesheet" href="http://yusukebe.github.com/Giita/static/screen.css" type="text/css" media="screen, projection" />
<link rel="stylesheet" href="http://yusukebe.github.com/Giita/static/site.css" type="text/css" />
<link rel="stylesheet" href="http://yusukebe.github.com/Giita/static/print.css" type="text/css" media="print" />
<!--[if lt IE 8]><link rel="stylesheet" href="http://yusukebe.github.com/Giita/static/ie.css" type="text/css" media="screen, projection" /><![endif]-->
</head>
<body>
<div class="container">
<hr class="space" />

@@ foot.mt
<hr >
<address>giita - lightweigth rock band. <a href="http://github.com/yusukebe/giita">repository on github</a>.</address>
</div>
</body>
</html>
