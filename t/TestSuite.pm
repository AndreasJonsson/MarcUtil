package TestSuite;

use base qw(Test::Unit::TestCase);

sub suite {
    my $class = shift;

    my $suite = Test::Unit::TestSuite->empty_new("MarcMapping etc.");

    $suite->add_test('TestMarcFieldHolder');
    $suite->add_test('TestMarcMapping');
    $suite->add_test('TestMarcMappingCollection');

    return $suite;
}

1;
