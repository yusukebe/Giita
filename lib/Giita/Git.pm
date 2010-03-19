package Giita::Git;
use strict;
use warnings;
use Git::Class::Cmd;

sub new {
    my ( $class, %opt ) = @_;
    my $self = bless {}, $class;
    $self;
}

sub git_cmd {
}

sub log {
    my ( $self, $path ) = @_;
    my $log = $self->git_cmd->git( 'log', $path );
    $log = escape($log);
    my $html;
    for my $l ( split '\n', $log ) {
        $l =~ s!commit\s([0-9a-z]{40})!commit <a href="/?commit=$1">$1</a>!;
        $html .= $l . "\n";
    }
    return $html;
}

sub show {
    my ( $self, $sha ) = @_;
    my $log = $self->git_cmd->git( 'show', $sha );
    $log = highlight( $log, 'diff' ) if $log;
    return $log;
}

sub _escape {
    my ($self, $html)  = @_;
    my %_escape_table = (
        '&'  => '&amp;',
        '>'  => '&gt;',
        '<'  => '&lt;',
        '"'  => '&quot;',
        '\'' => '&#39;'
    );
    $html =~ s/([&><\"\'])/$_escape_table{$1}/gme;
    return $html;
}

1;
