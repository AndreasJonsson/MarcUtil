package MarcUtil::MarcMappingCollection;

use namespace::autoclean;
use Modern::Perl;
use Moose;
use MooseX::StrictConstructor;
use MarcUtil::MarcMapping;
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
    my %params = @_;

    my $c = __PACKAGE__->new();

    for my $name (keys %params) {
        my @cfs = ();
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
        my $mm = MarcUtil::MarcMapping->new( control_fields => \@cfs, subfields => \%fs,  collection => $c);
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
    my ($self, $tag, $n) = @_;

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
    my $name  = shift;

    if (defined($name)) {
        my $mapping = $self->{mappings}->{$name};
        croak "No mapping named $name!" unless defined $mapping;
        for my $cf (@{$mapping->control_fields}) {
            delete($self->{fhs}->{$cf});
        }
        for my $f  (keys %{$mapping->subfields}) {
            delete($self->{fhs}->{$f});
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
