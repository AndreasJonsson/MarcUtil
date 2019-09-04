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
    my $val = shift;

    croak "No mapping named $name!" unless defined $self->mappings->{$name};

    my $mapping = $self->mappings->{$name};

    if (defined $mapping->params->{itemcol}) {
	my $cols = $mapping->params->{itemcol};
	my @cols = ($cols);
	if (ref $cols eq 'ARRAY') {
	    @cols = @$cols;
	}

	for my $col (@cols) {
	    my $items = $self->{items};
	    my $n = scalar(@$items);
	    my $item = $items->[$n - 1];
	    $item->{defined_columns}->{$col} = {
		val => $val,
		mapping => $mapping
	    };
	}
	
	return;
    }

    $self->SUPER::set($name, $val, @_);
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
