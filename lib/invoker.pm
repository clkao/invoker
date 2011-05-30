package invoker;

use strict;
use 5.010_001;

use B::Hooks::OP::Check;
use B::Hooks::EndOfScope;

our $VERSION = "0.30";

use Devel::Declare;
require XSLoader;
XSLoader::load(__PACKAGE__, $VERSION);

sub import {
    my ($class) = @_;

    my $parser = Devel::Declare::setup();

    my $linestr = Devel::Declare::get_linestr();
    my $offset  = Devel::Declare::get_linestr_offset();
    substr($linestr, $offset, 0) = 'use B::OPCheck const => check => \&invoker::_check;';
    Devel::Declare::set_linestr($linestr);

    my $hook = $class->setup;

    on_scope_end {
        $class->teardown($hook);
    };

    return;
}

sub _check {
    my $op = shift;
    return unless ref($op->gv) eq 'B::PV';

    my $linestr = Devel::Declare::get_linestr;
    my $offset  = Devel::Declare::get_linestr_offset;

    if (substr($linestr, $offset-2, 3) eq '$->') {
        substr($linestr, $offset-2, 3) = '$-->';
        Devel::Declare::set_linestr($linestr);
    }
}

1;
__END__

=encoding utf-8

=for stopwords

=head1 NAME

invoker - implicit invoker, sort of

=head1 SYNOPSIS

  use invoker;

  sub foo {
    my $self = shift;
    $->bar; # calls $self->bar;
  }

  # use Method::Signatures::Simple
  # method {
  #  $->bar # ditto
  # }

=head1 DESCRIPTION

the invoker pragma enables the C<< $-> >> syntax for invoking methods
on C< $self >, inspired by Perl6's C<< $.method >> invocation.

The module does not inject the C< $self > variable for you.  you are
encouraged to use it in conjunction with L<self>, L<selfvars>,
<Method::Signatures::Simple>, or other similar modules.

The following syntax works:

=over

=item $->foo( .. args ...)

=item $->foo

=item $->$method_name

=item $->$method_name( .. args ...)

=back

=head1 CAVEATS

WARNINGS WARNINGS WARNINGS

This is alpha code.  Do not use in production.

Internally, the module installs a parser hook to replace C<< $-> >>
(C<$-> and the gt operator) with $--> (an invocation on the C< $- >
perlvar.  It also injects an entersub hook to replace C< $- > with
C<$self >.

=head1 BUGS

=over

=back

=head1 TODO

=over

=item custom invoker name with "use invoker '$this'"

=back

=head1 AUTHOR

Chia-liang Kao E<lt>clkao@clkao.orgE<gt>
Audrey Tang E<lt>audreyt@audreyt.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut

__END__


