use inc::Module::Install;
name 'Giita';
all_from 'lib/Giita.pm';

requires 'MojaMoja';
requires 'Path::Class';
requires 'Plack::Runner';
requires 'Plack::Request';
requires 'Text::VimColor';
requires 'Pod::Simple::XHTML';
requires 'Text::Markdown';
requires 'HTML::TreeBuilder::XPath';
requires 'Git::Class::Cmd';
requires 'Text::MicroTemplate';
requires 'Data::Section::Simple';

tests 't/*.t';
author_tests 'xt';

build_requires 'Test::More';
use_test_base;
auto_include;
WriteAll;
