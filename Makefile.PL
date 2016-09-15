use 5.020002;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'MarcUtil::MarcMapping',
    VERSION_FROM      => 'lib/MarcUtil/MarcMapping.pm', # finds $VERSION, requires EU::MM from perl >= 5.5
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ABSTRACT_FROM     => 'lib/MarcUtil/MarcMapping.pm', # retrieve abstract from module
    AUTHOR            => 'Andreas Jonsson <andreas.jonsson@kreablo.se>',
    LICENSE           => 'gpl',
);
