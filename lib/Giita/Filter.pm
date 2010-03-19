package Giita::Filter;
use Giita;
use Text::VimColor;
use Pod::Simple::XHTML;
use Text::Markdown ();
use HTML::TreeBuilder::XPath;

sub new { my $self = bless {}, shift; $self };

sub markdown {
    my ($self, $text) = @_;
    my $html = Text::Markdown::markdown( $text );
    return $html;
}

sub highlight {
    my ( $self, $text, $type ) = @_;
    $type ||= 'perl';
    my $syntax = Text::VimColor->new(
        string   => $text,
        filetype => $type,
    );
    return $syntax->html;
}

sub pod {
    my ($slf, $text)  = @_;
    my $parser = Pod::Simple::XHTML->new();
    my $html;
    $parser->output_string( \$html );
    $parser->html_header('');
    $parser->html_footer('');
    $parser->html_h_level(3);
    $parser->parse_string_document($text);
    $html = highlight_pod($html);
    $html = '<div class="pod">' . $html . '</div>';
    return $html;
}

sub highlight_pod {
    my ($sef, $html) = @_;
    my $tree = HTML::TreeBuilder::XPath->new;
    $tree->parse($html);
    for my $code ( $tree->findnodes('//pre') ) {
        my $hilight_code = highlight( $code->as_text );
        my $code_html    = $code->as_HTML;
        $html =~ s/\Q$code_html\E/<pre>$hilight_code<\/pre>/m;
    }
    return $html;
}

1;

