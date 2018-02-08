package MarcUtil::MarcMapping;

our $VERSION = '0.03';

use namespace::autoclean;
use Modern::Perl;
use Moose;
use MooseX::StrictConstructor;
use Carp;
use MARC::Field;
use MarcUtil::MarcFieldHolder;
use Data::Dumper;

has record => (
    is => 'rw',
    isa => 'Maybe[MARC::Record]',
    trigger => sub { shift->reset; }
    );

has collection => (
    is => 'ro',
    isa => 'Maybe[MarcUtil::MarcMappingCollection]'
    );

has control_fields => (
    is => 'rw',
    isa => 'ArrayRef[Str]',
    default => sub { [] }
    );

has subfields => (
    is => 'rw',
    isa => 'HashRef[ArrayRef[Str]]',
    default => sub { {} }
    );

has append_fields => (
    is => 'rw',
    isa => 'Bool',
    default => '1'
    );

sub BUILD {
    my $self = shift;

    $self->{fhs} = {};
}

sub mm_sf {
    my ($field, $sub) = @_;
    return MarcMapping->new(subfields => { $field => [ $sub ] });
}


sub _get_fhs {
    my $self = shift;
    my $tag = shift;
    my $n = shift;

    my $fhs;
    if ($self->append_fields) {
        $fhs = $self->_appended_fields( $tag, $n );
    } else {
        my @existing_fields = $self->record->field( $tag );
        $fhs = [];
        my $i = 0;
        for (; $i < scalar(@existing_fields); $i++) {
            push @$fhs, MarcUtil::MarcFieldHolder->new( record => $self->record, tag => $tag, field => $existing_fields[$i] );
        }
        push @$fhs, @{$self->_appended_fields( $tag, defined($n) ? $n - $i : undef )};
    }

    return $fhs;
}

sub set {
    my $self = shift;
    my $n = scalar(@_);

    my @data = @_;

    my ($g, $stop);
    if ($n == 1 && UNIVERSAL::isa($_[0], 'CODE')) {
        $g = $data[0];
        $stop = sub { return 0 };
        undef($n);
    } else {
        $g = sub {
            my $i = shift;
            return $data[$i];
        };
        $stop = sub { return shift >= $n };
    }

    croak "No record bound!" unless $self->record;

    for my $cf (@{$self->control_fields}) {
        my $cfn = 0;
        my $fhs = $self->_get_fhs( $cf, $n );

        for my $fh (@$fhs) {
            last if $stop->($cfn);
            $fh->set_controlfield($g->($cfn));
            $cfn++;
        }
    }

    for my $f (keys %{$self->subfields}) {
        my $nf = 0;
        my $fhs = $self->_get_fhs( $f, $n );

        for my $fh (@$fhs) {
            last if $stop->($nf);
            for my $subfields ($self->subfields->{$f}) {
                $fh->set_subfield( $_, $g->($nf) ) for @$subfields;
            }
            $nf++;
        }
    }
}

sub setLast {
    my $self = shift;
    my $v = shift;

    for my $cf (@{$self->control_fields}) {
        my $cfn = 0;
        my $fhs = $self->_get_fhs( $cf );

	$fhs->[$#{$fhs}]->set_controlfield($v);
    }    

    for my $f (keys %{$self->subfields}) {
        my $nf = 0;
        my $fhs = $self->_get_fhs( $f );

	my $last_fh = $fhs->[$#{$fhs}];
	for my $subfields ($self->subfields->{$f}) {
	    $last_fh->set_subfield( $_, $v ) for @$subfields;
	}
    }
}

sub get {
    my $self = shift;

    croak "No record bound!" unless $self->record;

    my @ret = ();

    for my $cf (@{$self->control_fields}) {
        my @fields = $self->record->field( $cf );
        for (my $i = 0; $i < @fields; $i++) {
            $ret[@ret] = $fields[$i]->data();
        }
    }

    for my $f (keys %{$self->subfields}) {
        for my $sf (@{$self->subfields->{$f}}) {
            my @fields = $self->record->field($f);
            for (my $i = 0; $i < @fields; $i++) {
                $ret[@ret] = scalar($fields[$i]->subfield( $sf ));
            }
        }
    }

    return @ret if wantarray;
    return $ret[$#ret];
}

sub delete {
    my $self = shift;

    croak "No record bound!" unless $self->record;

    for my $cf (@{$self->control_fields}) {
        $self->record->delete_fields( $self->record->field( $cf ) );
    }

    for my $f (keys %{$self->subfields}) {
        map {
            $_->delete_subfield( code => $self->subfields->{$f} );
            if (0 + $_->subfields == 0) {
                $self->record->delete_fields( $_ );
            }
        } $self->record->field( $f );
    }
}

sub _appended_fields {
    my ($self, $tag, $n) = @_;

    if (defined($self->collection)) {
        return $self->collection->_appended_fields( $tag, $n );
    }

    my $fhs = [];

    if (defined($self->{fhs}->{$tag})) {
        $fhs = $self->{fhs}->{$tag};
    } else {
        $self->{fhs}->{$tag} = $fhs;
    }

    for (my $i = 0 + @$fhs; defined($n) && $i < $n; $i++) {
        my $fh = MarcUtil::MarcFieldHolder->new( record => $self->record, tag => $tag );
        push @$fhs, $fh;
    }

    return $fhs;
}

sub reset {
    my $self = shift;

    $self->{fhs} = {};
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
