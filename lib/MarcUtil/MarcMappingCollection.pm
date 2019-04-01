package MarcUtil::MarcMappingCollection;

use namespace::autoclean;
use Modern::Perl;
use Moose;
use MooseX::StrictConstructor;
use MarcUtil::MarcMapping;
use MarcUtil::FieldTag;
use Carp;

has mappings => (
    is => 'ro',
    isa => 'HashRef[MarcUtil::MarcMapping]',
    default => sub { return {} }
    );

has record => (
    is => 'rw',
    isa => 'Maybe[MARC::Record]',
    trigger => sub {
        my $self = shift;
        my $record = shift;
        for my $m (keys %{$self->mappings}) {
            $self->mappings->{$m}->record($record);
            $self->mappings->{$m}->reset();
        }
        $self->reset();
    }
    );


sub BUILD {
    my $self = shift;

    $self->{fhs} = {};
}

sub marc_mappings {
    return __PACKAGE__->_marc_mappings(@_);
}

sub _marc_mappings {
    my $class = shift;
    my %params = @_;

    my $c = $class->new();

    for my $name (keys %params) {
        my @cfs = ();
        my @subfields = ();
        if (defined($params{$name}->{map})) {
            my %fs = ();
            for my $mv ($params{$name}->{map}) {
                if (UNIVERSAL::isa($mv, 'HASH')) {
                    for my $sf (keys %$mv) {
                        if (UNIVERSAL::isa($mv->{$sf}, 'ARRAY')) {
                            $fs{$sf} = $mv->{$sf};
                        } else {
                            $fs{$sf} = [ $mv->{$sf} ];
                        }
                    }
                } else {
                    push @cfs, $mv;
                }
            }
            push @subfields, (map {
                my $f = $_;
                MarcUtil::FieldTag->new(tag => $f, subtags => $fs{$f});
            } keys %fs);
        }
        if (defined($params{$name}->{fieldtags})) {
            push @subfields, @{$params{$name}->{fieldtags}};
        }
	my $params = {};
	for my $p (keys %{$params{$name}}) {
	    if ($p ne 'map') {
		$params->{$p} = $params{$name}->{$p};
	    }
	}
        my $mm = MarcUtil::MarcMapping->new(
            control_fields => [map { UNIVERSAL::isa($_, 'MarcUtil::FieldTag') ? $_ : MarcUtil::FieldTag->new(tag => $_) } @cfs],
            subfields => \@subfields,
            collection => $c,
	    params => $params
            );
        if ($params{$name}->{append}) {
            $mm->append_fields(1);
        }
        $c->mappings->{$name} = $mm;
    }
    return $c;
}

sub set {
    my $self = shift;
    my $name = shift;

    croak "No mapping named $name!" unless defined $self->mappings->{$name};

    $self->mappings->{$name}->set(@_);
}

sub get {
    my $self = shift;
    my $name = shift;

    croak "No mapping named $name!" unless defined $self->mappings->{$name};

    return $self->mappings->{$name}->get();
}

sub delete {
    my $self = shift;
    my $name = shift;

    croak "No mapping named $name!" unless defined $self->mappings->{$name};

    $self->mappings->{$name}->delete();
}

sub _appended_fields {
    my ($self, $fieldtag, $n) = @_;

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
            ind1 => MarcUtil::MarcMapping::_ind_val($fieldtag->ind1),
            ind2 => MarcUtil::MarcMapping::_ind_val($fieldtag->ind2)
        );
        push @$fhs, $fh;
    }

    return $fhs;
}

sub reset {
    my $self = shift;
    my $name  = shift;

    if (defined($name)) {
        my $mapping = $self->{mappings}->{$name};
        croak "No mapping named $name!" unless defined $mapping;
        for my $cf (@{$mapping->control_fields}) {
            my $tag = $cf->tag .
                (defined($cf->ind1) ? $cf->ind1 : '') .
                (defined($cf->ind2) ? $cf->ind2 : '');

            delete($self->{fhs}->{$tag});
        }
        for my $f (@{$mapping->subfields}) {
            my $tag = $f->tag .
                (defined($f->ind1) ? $f->ind1 : '') .
                (defined($f->ind2) ? $f->ind2 : '');
            delete($self->{fhs}->{$tag});
        }
    } else {
        $self->{fhs} = {};
    }
}

__PACKAGE__->meta->make_immutable;

1;
=head1 NAME

MarcUtil::MarcMappingCollection - Utility package for creating a mapping to fields in a marc record.

=head1 SYNOPSIS

  use MarcUtil::MarcMappingCollection;

  $mm = marc_mappings (
     name1 => {
        map => ['001', {'999', 'a'}]
     },
     name2 => {
        map => ['852', 'c'],
        append => 1
     },
     ...
  );

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
