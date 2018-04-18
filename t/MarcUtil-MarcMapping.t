# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl MarcUtil-MarcMapping.t'

#########################

use strict;
use warnings;

push @INC, "./t";

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

use Test::Unit::HarnessUnit;
#use Test::Unit::Debug qw(debug_to_file debug_pkgs);

#debug_pkgs(
#    'Test::Unit::TestSuite',
#    'Test::Unit::TestCase',
#    'Test::Unit::Test',
#    'Test::Unit::Assert',
#    'Test::Unit');


my $testrunner = Test::Unit::HarnessUnit->new();

$testrunner->start('TestSuite');
