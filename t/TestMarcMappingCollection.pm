package TestMarcMappingCollection;

use base qw(Test::Unit::TestCase);

use MarcUtil::MarcMappingCollection;
use MARC::Record;
use MARC::File::XML ( BinaryEncoding => 'utf8', RecordFormat => 'NORMARC' );
use Modern::Perl;
use List::MoreUtils qw(pairwise);
use Data::Dumper;

sub new {
    my $self = shift()->SUPER::new(@_);
    return $self;
}

sub set_up {
    my $self = shift;
    $self->{record} = MARC::Record->new();
    $self->{mc} = MarcUtil::MarcMappingCollection::marc_mappings(
    'homebranch'                       => { map => { '952' => 'a' } },
    'holdingbranch'                    => { map => { '952' => 'b' } },
    'localshelf'                       => { map => { '952' => 'c' } },
    'date_acquired'                    => { map => { '952' => 'd' } },
    'price'                            => { map => { '952' => [ 'g', 'v' ] } },
    'total_number_of_checkouts'        => { map => { '952' => 'l' } },
    'call_number'                      => { map => { '952' => 'o' } },
    'barcode'                          => { map => { '952' => 'p' } },
    'date_last_seen'                   => { map => { '952' => 'r' } },
    'date_last_checkout'               => { map => { '952' => 's' } },
    'internal_staff_note'              => { map => { '952' => 'x' } },
    'itemtype'                         => { map => { '952' => 'y' } },
    'lost_status'                      => { map => { '952' => '1' } },
    'damaged_status'                   => { map => { '952' => '4' } },
    'subjects'                         => { map => { '653' => 'b' } }
    );
    $self->{mc}->record( $self->{record} );
}


sub tear_down {
    # clean up after test
}

sub test_set_invalid {
    my $self = shift;

    eval { $self->{mc}->set('foo', 0); };

    $self->assert( $@ =~ /^No mapping named foo/ );

}

sub test_set {

    my $self = shift;

    $self->{mc}->set('homebranch', 'foo');

    $self->check_subfield( '952', 'a', 1, 'foo' );

    $self->{mc}->set('homebranch', 'bar');

    $self->check_subfield( '952', 'a', 1, 'bar' );

    $self->{mc}->reset();

    $self->{mc}->set('homebranch', 'foo');

    $self->check_subfield( '952', 'a', 2, 'bar', 'foo' );

}

sub test_get_other {
    my $self = shift;

    $self->{mc}->set( 'holdingbranch', 'foo', 'bar' );

    my @res = $self->{mc}->get( 'homebranch' );

    my @exp = (undef, undef);

    pairwise {
        $self->assert_equals( $a, $b );
    } @exp, @res;

    $self->{mc}->set( 'localshelf', undef, 'baz');

    @res = $self->{mc}->get( 'localshelf' );

    @exp = (undef, 'baz');

    pairwise {
        $self->assert_equals( $a, $b );
    } @exp, @res;
}


sub test_set_multi {
    my $self = shift;

    $self->{mc}->set('subjects', 'foo', 'bar', 'baz');

    $self->check_subfield( '653', 'b', 3, 'foo', 'bar', 'baz' );
}

sub test_reset {
   my $self = shift;

   $self->{mc}->set('price', 'foo1');
   $self->{mc}->set('subjects', 'foo2');

   $self->check_subfield( '952', 'g', 1, 'foo1' );
   $self->check_subfield( '952', 'v', 1, 'foo1' );
   $self->check_subfield( '653', 'b', 1, 'foo2' );

   $self->{mc}->reset('price');

   $self->{mc}->set('price', 'bar1');
   $self->{mc}->set('subjects', 'bar2');

   $self->check_subfield( '952', 'g', 2, 'foo1', 'bar1' );
   $self->check_subfield( '952', 'v', 2, 'foo1', 'bar1' );
   $self->check_subfield( '653', 'b', 1, 'bar2' );
}

sub test_delete {
   my $self = shift;

   $self->{mc}->set('price', 'foo1');
   $self->{mc}->set('subjects', 'foo2');

   $self->check_subfield( '952', 'g', 1, 'foo1' );
   $self->check_subfield( '952', 'v', 1, 'foo1' );
   $self->check_subfield( '653', 'b', 1, 'foo2' );

   $self->{mc}->delete('price');

   $self->check_subfield( '952', 'g', 0);
   $self->check_subfield( '952', 'v', 0);
   $self->check_subfield( '653', 'b', 1, 'foo2' );
}

sub test_get {
    my $self = shift;

    $self->{mc}->set( 'homebranch', 'foo' );

    my @res = $self->{mc}->get( 'homebranch' );
    my @exp = ( 'foo' );

    pairwise {
        $self->assert_equals( $b, $a );
    } @exp, @res;
}

sub check_control_field {
    my $self = shift;
    my $tag = shift;
    my $length = shift;
    my @val = (@_);

    my @fields = $self->{record}->field( $tag );

    $self->assert_equals($length, 0 + @fields);

    pairwise {
        $self->assert( defined($a) );
        $self->assert( defined($b) );
        $self->assert_equals($b->data(), $a);
    } @val, @fields;
}

sub check_subfield {
    my $self = shift;
    my $tag = shift;
    my $subtag = shift;
    my $length = shift;
    my @val = @_;

    my @subfields = ();
    for my $field ($self->{record}->field( $tag )) {
        push @subfields, $field->subfield( $subtag );
    }

    $self->assert_equals( $length, 0 + @subfields );

    pairwise {
        $self->assert_equals( $a, $b );
    } @val, @subfields;
}

1;
