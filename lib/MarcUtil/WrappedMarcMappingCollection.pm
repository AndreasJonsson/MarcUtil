package MarcUtil::WrappedMarcMappingCollection;


use namespace::autoclean;
use Modern::Perl;
use Moose;
use MooseX::StrictConstructor;
use Carp;
use Data::Dumper;

extends 'MarcUtil::MarcMappingCollection';

has quote => (
    is => 'rw',
    isa => 'CodeRef'
);

sub BUILD {
    my $self = shift;

    $self->{items} = [];
}

sub set {
    my $self = shift;
    my $name = shift;
    my @data = @_;
    my $n = scalar(@_);

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

    croak "No mapping named $name!" unless defined $self->mappings->{$name};

    my $mapping = $self->mappings->{$name};

    if (defined $mapping->params->{itemcol}) {
	my $cols = $mapping->params->{itemcol};
	my @cols = ($cols);
	if (ref $cols eq 'ARRAY') {
	    @cols = @$cols;
	}

        my $nf = 0;
	
	for my $col (@cols) {

            last if $stop->($nf);

	    my $items = $self->{items};
	    my $nitems = scalar(@$items);
	    my $item = $items->[($nitems - $n) + $nf];
	    $item->{defined_columns}->{$col} = {
		val => $g->($nf),
		mapping => $mapping
	    };

            $nf++;
	}
	
	return;
    }

    $self->SUPER::set($name, @data);
}

sub get {
    my $self = shift;
    my $name = shift;
    
    my $mapping = $self->mappings->{$name};

    if (defined $mapping->params->{itemcol}) {
	my @ret = ();
	for my $item (@{$self->{items}}) {
	    if (defined $item->{defined_columns}->{$mapping->params->{itemcol}}) {
		push @ret, $item->{defined_columns}->{$mapping->params->{itemcol}}->{val};
	    }
	}

	return @ret if wantarray;
	return $ret[$#ret];
    }
    
    return $self->SUPER::get($name, @_);
}

sub reset {
    my $self = shift;

    $self->{items} = [];
    
    return $self->SUPER::reset(@_);
}

sub new_item {
    my $self = shift;
    my $original_id = shift;

    my $item = {
	original_id => $original_id,
	defined_columns => {}
    };
    push @{$self->{items}}, $item;
}

sub get_items_set_sql {
    my $self = shift;

    my $items = [];
    for my $item (@{$self->{items}}) {
	my $original_id = $item->{original_id};
	my $defined_columns = [];
	for my $col (keys %{$item->{defined_columns}}) {
	    my $val = $item->{defined_columns}->{$col}->{val};
	    my $mapping = $item->{defined_columns}->{$col}->{mapping};
	    if (defined $mapping->params->{av}) {
		$val = "(SELECT id FROM authorised_values WHERE category = " .
		    $self->quote->($mapping->params->{av}) . " AND authorised_value = " . $self->quote->($val) . ")";
	    } elsif (!(defined $mapping->params->{numeric} and $mapping->params->{numeric})) {
		$val = $self->quote->($val);
	    }
	    push @$defined_columns, "$col=$val" if defined($val);
	}
	if (!defined($original_id) || $original_id eq '') {
	    print STDERR "get_items_set_sql no original id\n";
	    print STDERR Dumper($item);
	}
	push @$items, {
	    original_id => $original_id,
	    defined_columns => $defined_columns
	};
    }

    return $items;
}


sub marc_mappings {
    return __PACKAGE__->_marc_mappings(@_);
}

1;
