use inc::Module::Install;
name 'giita';
all_from 'bin/giita';

requires 'MojaMoja';
requires 'Path::Class';
requires 'Plack::Runner';
requires 'Plack::Request';
requires 'Text::VimColor';
requires 'Pod::Simple::XHTML';
requires 'Text::Markdown';
requires 'HTML::TreeBuilder::XPath';
requires 'Git::Class::Cmd';

install_script 'bin/giita';

#tests 't/*.t';
#author_tests 'xt';

#build_requires 'Test::More';
#use_test_base;
auto_include;
WriteAll;
