package MarcUtil::FieldTag;

use namespace::autoclean;
use Modern::Perl;
use Moose;
use MooseX::StrictConstructor;

has tag => (
    is => 'ro',
    isa => 'Str'
);

has ind1 => (
    is => 'ro',
    isa => 'Maybe[Str]',
    default => sub { return undef }
);

has ind2 => (
    is => 'ro',
    isa => 'Maybe[Str]',
    default => sub { return undef }
);

has subtags => (
    is => 'ro',
    isa => 'Maybe[ArrayRef[Str]]',
    default => sub { return undef }
);

sub BUILD {
    my $self = shift;
}

sub is_controlfield {
    my $self = shift;
    return !defined($self->subtags);
}

__PACKAGE__->meta->make_immutable;

1;
__END__

=head1 NAME

MarcUtil::MarcMapping - Utility package for creating a mapping to fields in a marc record.

=head1 SYNOPSIS

  use MarcUtil::MarcMapping;


=head1 DESCRIPTION


=head1 AUTHOR

Andreas Jonsson, E<lt>andreas.jonsson@kreablo.seE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2016 by Andreas Jonsson

it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

=cut
