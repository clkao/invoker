package invoker;

use strict;
use 5.010_001;

use B::Hooks::OP::Check;
use B::Hooks::EndOfScope;

our $VERSION = "0.29_002";

require XSLoader;
XSLoader::load(__PACKAGE__, $VERSION);

sub import {
    my ($class) = @_;
    my $caller = caller;

    my $hook = $class->setup;

    on_scope_end {
        $class->teardown($hook);
    };

    return;
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
encouraged to use it in conjunction with L<self>,
<Method::Signatures::Simple>, or other similar modules.

The following syntax works:

=over

=item $->foo( .. args ...)

=item $->foo

=item $->$method_name

=back

The following syntax does not work:

=over

=item $->$method_name( .. args ...)

=back

=head1 CAVEATS

WARNINGS WARNINGS WARNINGS

This is alpha code.  Do not use in production.

Internally, the module installs a check on the C<< > >> (gt) op.  if
the left operand is C< $- > (some format-related perlvar you probably
shouldn't be using), it then replaces the optree with an appropriate
entersub with method_named.

=head1 TODO

=over

=item make sure context are correct

=item custom invoker name with "use invoker '$this'"

=back

=head1 AUTHOR

Chia-liang Kao E<lt>clkao@clkao.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut

__END__


