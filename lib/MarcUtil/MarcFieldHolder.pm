package MarcUtil::MarcFieldHolder;

use namespace::autoclean;
use Modern::Perl;
use Moose;
use MooseX::StrictConstructor;
use Carp;
use MARC::Field;

has record => (
    is => 'ro',
    isa => 'MARC::Record',
    required => 1
    );

has tag => (
    is => 'ro',
    isa => 'Str',
    required => 1
    );

has ind1 => (
    is => 'ro',
    isa => 'Str',
    default => ' '
    );

has ind2 => (
    is => 'ro',
    isa => 'Str',
    default => ' '
    );

has field => (
    is => 'rw',
    isa => 'MARC::Field'
    );

sub BUILD {
    my $self = shift;

    $self->{appended_field} = undef;
}

sub insert_field {
    my ($record, $field) = @_;
    for my $f ($record->fields) {
        if (int($f->tag) > int($field->tag)) {
            $record->insert_fields_before($f, $field);
            return;
        }
    }
    $record->append_fields($field);
}

sub set_subfield {
    my ($self, $subtag, $val) = @_;

    unless (defined $val) {
	carp 'Value undefined of ' . $self->tag . " $subtag!";
	$val = '';
    }

    if (defined($self->field)) {
        $self->field->update( $subtag => $val );
    } else {
        $self->field( MARC::Field->new( $self->tag, $self->ind1, $self->ind2, $subtag => $val ) );
        insert_field($self->record,  $self->field );
    }
}

sub set_controlfield {
    my ($self, $val) = @_;

    unless (defined $val) {
	carp 'Value undefined of ' . $self->tag;
	$val = '';
    }

    if (defined($self->field)) {
        $self->field->update($val);
    } else {
        $self->field( MARC::Field->new( $self->tag, $val ) );
        insert_field($self->record,  $self->field );
    }
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

MarcUtil::MarcFieldHolder - Hold a reference to a Marc field.

=head1 SYNOPSIS

  use MarcUtil::MarcMapping;

=head1 DESCRIPTION

This package provides an indirection to create marc fields lazily.

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
