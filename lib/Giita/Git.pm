package Giita::Git;
use strict;
use warnings;
use Git::Class::Cmd;

sub new {
    my ( $class, %opt ) = @_;
    my $self = bless {
        git_dir => $opt{git_dir},
        cmd => Git::Class::Cmd->new(
#            die_on_error => 1,
        ),
    }, $class;
    $self->{root_dir} = $self->{git_dir};
    $self->{root_dir} =~ s/\.git$//;
    $self->{root_dir} =~ s/\/$//;
    $self;
}

sub cmd {
    return shift->{cmd};
}

sub log {
    my ( $self, $abs ) = @_;
    my $path = $abs->absolute;
    $path =~ s/$self->{root_dir}//;
    $path = ".$path";
    my $log = $self->cmd->git( { git_dir => $self->{git_dir} },'log', $path );
    $log = $self->escape($log);
    my $html;
    for my $l ( split '\n', $log ) {
        $l =~ s!commit\s([0-9a-z]{40})!commit <a href="/?commit=$1">$1</a>!;
        $html .= $l . "\n";
    }
    return $html;
}

sub show {
    my ( $self, $sha ) = @_;
    my $log = $self->cmd->git( 'show', $sha );
    $log = $self->highlight( $log, 'diff' ) if $log;
    return $log;
}

sub escape {
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
