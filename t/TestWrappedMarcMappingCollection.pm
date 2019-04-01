package TestWrappedMarcMappingCollection;

use base qw(Test::Unit::TestCase);

use MarcUtil::WrappedMarcMappingCollection;
use Scalar::Util 'blessed';

sub set_up {
    my $self = shift;
    $self->{record} = MARC::Record->new();
    $self->{mc} = MarcUtil::WrappedMarcMappingCollection::marc_mappings(
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

sub test_class {
    my $self = shift;

    $self->assert_equals('MarcUtil::WrappedMarcMappingCollection',  blessed($self->{mc}), 'Right class');

}

1;
