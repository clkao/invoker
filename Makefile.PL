sub readme_from {}; sub auto_include_deps {}; sub author_tests {}; sub auto_set_repository {};
use strict;
use ExtUtils::Depends;
use inc::Module::Install;
name 'invoker';
all_from 'lib/invoker.pm';
readme_from 'lib/invoker.pm';
build_requires 'Test::More' => 0.88;
auto_include_deps;
author_tests('xt');
configure_requires 'ExtUtils::Depends';
configure_requires 'B::Hooks::OP::Check';

requires 'B::Hooks::OP::Check';
requires 'B::Hooks::EndOfScope';

my $pkg = ExtUtils::Depends->new('invoker', 'B::Hooks::OP::Check');
makemaker_args($pkg->get_makefile_vars);

ppport;

auto_set_repository;
WriteAll;
