package MarcUtil::MarcMapping;

our $VERSION = '0.07';

use namespace::autoclean;
use Modern::Perl;
use Moose;
use MooseX::StrictConstructor;

use Carp;
use MARC::Field;
use MarcUtil::MarcFieldHolder;
use MarcUtil::FieldTag;
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
    isa => 'ArrayRef[MarcUtil::FieldTag]',
    default => sub { [] }
    );

has subfields => (
    is => 'rw',
    isa => 'ArrayRef[MarcUtil::FieldTag]',
    default => sub { {} }
    );

has append_fields => (
    is => 'rw',
    isa => 'Bool',
    default => '1'
    );

has params => (
    is => 'ro',
    isa => 'HashRef',
    default => sub { {} }
);

sub BUILD {
    my $self = shift;

    $self->{fhs} = {};
    $self->{ind1} = ' ';
    $self->{ind2} = ' ';
}

sub mm_sf {
    my ($field, $sub, $ind1, $ind2) = @_;
    return MarcMapping->new(subfields => [ MarcUtil::FieldTag->new(
                                               tag => $field,
                                               subtags => $sub,
                                               ind1 => $ind1,
                                               ind2 => $ind2
                                           ) ]);
}

sub ind1 {
    my ($self, $val) = @_;

    return $self->{ind1} unless defined $val;

    die "Indicator must be one character" unless length($val) == 1;

    $self->{ind1} = $val;
    for my $f (@{$self->control_fields}) {
	$f->ind1($val);
    }
    for my $f (@{$self->subfields}) {
	$f->ind1($val);
    }

    return $val;
}

sub ind2 {
    my ($self, $val) = @_;

    return $self->{ind2} unless defined $val;

    die "Indicator must be one character" unless length($val) == 1;

    $self->{ind2} = $val;
    for my $f (@{$self->control_fields}) {
	$f->ind2($val);
    }
    for my $f (@{$self->subfields}) {
	$f->ind2($val);
    }

    return $val;
}

sub _ind_val {
    my $ind = shift;
    if (!defined($ind) || $ind eq '') {
        return ' ';
    }
    return $ind;
}

sub _get_fhs {
    my ($self, $fieldtag, $n) = @_;

    my $fhs;
    if ($self->append_fields) {
        $fhs = $self->_appended_fields( $fieldtag, $n );
    } else {
        my @existing_fields = match_fields($self->record, $fieldtag);
        $fhs = [];
        my $i = 0;
        for (; $i < scalar(@existing_fields); $i++) {
            push @$fhs, MarcUtil::MarcFieldHolder->new(
                record => $self->record,
                tag => $fieldtag->tag,
                field => $existing_fields[$i],
                ind1 => _ind_val($fieldtag->ind1),
                ind2 => _ind_val($fieldtag->ind2));
        }
        push @$fhs, @{$self->_appended_fields( $fieldtag, defined($n) ? $n - $i : undef )};
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

    for my $f (@{$self->subfields}) {
        my $nf = 0;
        my $fhs = $self->_get_fhs( $f, $n );

        for my $fh (@$fhs) {
            last if $stop->($nf);
            if (defined($f->subtags)) {
                $fh->set_subfield( $_, $g->($nf) ) for @{$f->subtags};
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

    for my $f (@{$self->subfields}) {
        my $nf = 0;
        my $fhs = $self->_get_fhs( $f );

        my $last_fh = $fhs->[$#{$fhs}];

        $last_fh->set_subfield( $_, $v ) for @{$f->subtags};
    }
}

sub match_fields {
    my ( $record, $fieldtag ) = @_;
    my @fields = $record->field( $fieldtag->tag );
    my @ret = ();
    for my $f (@fields) {
        if (defined($fieldtag->ind1) && $fieldtag->ind1 ne '') {
            next if ($f->indicator(1) ne $fieldtag->ind1);
        }
        if (defined($fieldtag->ind2) && $fieldtag->ind2 ne '') {
            next if ($f->indicator(2) ne $fieldtag->ind2);
        }
        push @ret, $f;
    }
    return @ret;
}

sub get {
    my $self = shift;

    croak "No record bound!" unless $self->record;

    my @ret = ();

    for my $cf (@{$self->control_fields}) {
        my @fields = match_fields($self->record, $cf);
        for (my $i = 0; $i < @fields; $i++) {
            $ret[@ret] = $fields[$i]->data();
        }
    }

    for my $f (@{$self->subfields}) {
        for my $sf (@{$f->subtags}) {
            my @fields = match_fields($self->record, $f );
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
        my @fields = match_fields($self->record, $cf);
        $self->record->delete_fields( @fields );
    }

    for my $f (@{$self->subfields}) {
        map {
            $_->delete_subfield( code => $f->subtags );
            if (0 + $_->subfields == 0) {
                $self->record->delete_fields( $_ );
            }
        } match_fields($self->record, $f );
    }
}

sub _appended_fields {
    my ($self, $fieldtag, $n) = @_;

    if (defined($self->collection)) {
        return $self->collection->_appended_fields( $fieldtag, $n );
    }

    my $fhs = [];
    my $tag = $fieldtag->tag .
        (defined($fieldtag->ind1) ? $fieldtag->ind1 : '') .
        (defined($fieldtag->ind2) ? $fieldtag->ind2 : '');

    if (defined($self->{fhs}->{$tag})) {
        $fhs = $self->{fhs}->{$tag};
    } else {
        $self->{fhs}->{$tag} = $fhs;
    }

    for (my $i = 0 + @$fhs; defined($n) && $i < $n; $i++) {
        my $fh = MarcUtil::MarcFieldHolder->new(
            record => $self->record,
            tag => $fieldtag->tag,
            ind1 => _ind_val($fieldtag->ind1),
            ind2 => _ind_val($fieldtag->ind2)
        );
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
