package TestMarcMapping;

use base qw(Test::Unit::TestCase);

use MarcUtil::MarcMapping;
use MarcUtil::FieldTag;
use MARC::Record;
use MARC::File::XML ( BinaryEncoding => 'utf8', RecordFormat => 'NORMARC' );
use Modern::Perl;
use List::MoreUtils qw(pairwise);
use Data::Dumper;
use utf8;

sub new {
    my $self = shift()->SUPER::new(@_);
    return $self;
}

sub set_up {
    my $self = shift;
    $self->{record} = MARC::Record->new();
    $self->{mm} = MarcUtil::MarcMapping->new(
        control_fields => [MarcUtil::FieldTag->new(tag => '001'), MarcUtil::FieldTag->new(tag => '002')],
        subfields => [
            MarcUtil::FieldTag->new(tag => '100', subtags => ['a', 'b', 'c']),
            MarcUtil::FieldTag->new(tag => '101', subtags => ['d', 'e', 'f'])
        ],
        append_fields => 0
        );
    $self->{mm}->record($self->{record});
}

sub tear_down {
    # clean up after test
}

sub test_get {
    my $self = shift;

    $self->{mm}->set( 'foo' );

    my @res = $self->{mm}->get();

    my @exp = ( 'foo', 'foo', 'foo', 'foo', 'foo', 'foo', 'foo', 'foo' );

    pairwise {
        $self->assert_equals( $a, $b );
    } @exp, @res;

    $self->{mm}->append_fields(1);
    $self->{mm}->reset();

    $self->{mm}->set( 'bar' );

    my $last = $self->{mm}->get();

    @exp = ( 'foo', 'bar', 'foo', 'bar', 'foo', 'bar', 'foo', 'bar', 'foo', 'bar', 'foo', 'bar', 'foo', 'bar', 'foo', 'bar' );
    @res = $self->{mm}->get();

    pairwise {
        $self->assert_equals( $a, $b );
    } @exp, @res;

    $self->assert_equals( 'bar', $last );
}

sub test_set {
    my $self = shift;

    $self->{mm}->set( 'foo' );

    $self->check_control_field( '001', 1, 'foo' );
    $self->check_control_field( '002', 1, 'foo' );

    $self->check_subfield( '100', 'a', 1, 'foo' );
    $self->check_subfield( '100', 'b', 1, 'foo' );
    $self->check_subfield( '100', 'c', 1, 'foo' );
    $self->check_subfield( '101', 'd', 1, 'foo' );
    $self->check_subfield( '101', 'e', 1, 'foo' );
    $self->check_subfield( '101', 'f', 1, 'foo' );

    $self->{mm}->reset();
    $self->{mm}->set( 'bar' );

    $self->check_control_field( '001', 1, 'bar' );
    $self->check_control_field( '002', 1, 'bar' );

    $self->check_subfield( '100', 'a', 1, 'bar' );
    $self->check_subfield( '100', 'b', 1, 'bar' );
    $self->check_subfield( '100', 'c', 1, 'bar' );
    $self->check_subfield( '101', 'd', 1, 'bar' );
    $self->check_subfield( '101', 'e', 1, 'bar' );
    $self->check_subfield( '101', 'f', 1, 'bar' );

}

sub test_set_multi {
    my $self = shift;

    $self->{mm}->set( 'foo', 'bar' );

    $self->check_control_field( '001', 2, 'foo', 'bar' );
    $self->check_control_field( '002', 2, 'foo', 'bar' );

    $self->check_subfield( '100', 'a', 2, 'foo', 'bar' );
    $self->check_subfield( '100', 'b', 2, 'foo', 'bar' );
    $self->check_subfield( '100', 'c', 2, 'foo', 'bar'  );
    $self->check_subfield( '101', 'd', 2, 'foo', 'bar'  );
    $self->check_subfield( '101', 'e', 2, 'foo', 'bar'  );
    $self->check_subfield( '101', 'f', 2, 'foo', 'bar'  );
}

sub test_generator {
    my $self = shift;

    $self->{mm}->set('foo', 'bar');

    $self->{mm}->reset;

    $self->{mm}->set( sub { return shift() ? 'quiz' : 'baz'  } );

    $self->check_control_field( '001', 2, 'baz', 'quiz' );
    $self->check_control_field( '002', 2, 'baz', 'quiz' );

    $self->check_subfield( '100', 'a', 2, 'baz', 'quiz' );
    $self->check_subfield( '100', 'b', 2, 'baz', 'quiz' );
    $self->check_subfield( '100', 'c', 2, 'baz', 'quiz'  );
    $self->check_subfield( '101', 'd', 2, 'baz', 'quiz'  );
    $self->check_subfield( '101', 'e', 2, 'baz', 'quiz'  );
    $self->check_subfield( '101', 'f', 2, 'baz', 'quiz'  );
}

sub test_append {
    my $self = shift;

    $self->{mm}->append_fields(1);

    $self->{mm}->set( 'foo' );

    $self->check_control_field( '001', 1, 'foo' );
    $self->check_control_field( '002', 1, 'foo' );

    $self->check_subfield( '100', 'a', 1, 'foo' );
    $self->check_subfield( '100', 'b', 1, 'foo' );
    $self->check_subfield( '100', 'c', 1, 'foo' );
    $self->check_subfield( '101', 'd', 1, 'foo' );
    $self->check_subfield( '101', 'e', 1, 'foo' );
    $self->check_subfield( '101', 'f', 1, 'foo' );

    $self->{mm}->reset();
    $self->{mm}->set( 'bar' );

    $self->check_control_field( '001', 2, 'foo', 'bar' );
    $self->check_control_field( '002', 2, 'foo', 'bar' );

    $self->check_subfield( '100', 'a', 2, 'foo', 'bar' );
    $self->check_subfield( '100', 'b', 2, 'foo', 'bar' );
    $self->check_subfield( '100', 'c', 2, 'foo', 'bar' );
    $self->check_subfield( '101', 'd', 2, 'foo', 'bar' );
    $self->check_subfield( '101', 'e', 2, 'foo', 'bar' );
    $self->check_subfield( '101', 'f', 2, 'foo', 'bar' );

}

sub test_delete {

    my $self = shift;

    $self->{mm}->set( 'foo' );

    $self->check_control_field( '001', 1, 'foo' );
    $self->check_control_field( '002', 1, 'foo' );

    $self->check_subfield( '100', 'a', 1, 'foo' );
    $self->check_subfield( '100', 'b', 1, 'foo' );
    $self->check_subfield( '100', 'c', 1, 'foo' );
    $self->check_subfield( '101', 'd', 1, 'foo' );
    $self->check_subfield( '101', 'e', 1, 'foo' );
    $self->check_subfield( '101', 'f', 1, 'foo' );

    $self->{mm}->delete();

    $self->check_control_field( '001', 0);
    $self->check_control_field( '002', 0);

    $self->check_subfield( '100', 'a', 0);
    $self->check_subfield( '100', 'b', 0);
    $self->check_subfield( '100', 'c', 0);
    $self->check_subfield( '101', 'd', 0);
    $self->check_subfield( '101', 'e', 0);
    $self->check_subfield( '101', 'f', 0);

    my @field100 = $self->{record}->field( '100' );
    my @field101 = $self->{record}->field( '101' );

    $self->assert_equals(0, 0 + @field100);
    $self->assert_equals(0, 0 + @field101);

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


sub check_subfield_with_indicators {
    my $self = shift;
    my $tag = shift;
    my $subtag = shift;
    my $ind1 = shift;
    my $ind2 = shift;
    my $length = shift;
    my @val = @_;

    my @subfields = ();
    for my $field ($self->{record}->field( $tag )) {
        if ($field->indicator(1) eq $ind1 && $field->indicator(2) eq $ind2) {
            push @subfields, $field->subfield( $subtag );
        }
    }

    $self->assert_equals( $length, 0 + @subfields );

    pairwise {
        $self->assert_equals( $a, $b );
    } @val, @subfields;
}

sub test_set_last {
    my $self = shift;

    $self->{mm}->set( 'foo', 'bar' );

    $self->check_control_field( '001', 2, 'foo', 'bar' );
    $self->check_control_field( '002', 2, 'foo', 'bar' );

    $self->check_subfield( '100', 'a', 2, 'foo', 'bar' );
    $self->check_subfield( '100', 'b', 2, 'foo', 'bar' );
    $self->check_subfield( '100', 'c', 2, 'foo', 'bar' );
    $self->check_subfield( '101', 'd', 2, 'foo', 'bar' );
    $self->check_subfield( '101', 'e', 2, 'foo', 'bar' );
    $self->check_subfield( '101', 'f', 2, 'foo', 'bar' );

    $self->{mm}->setLast( 'baz' );

    $self->check_control_field( '001', 2, 'foo', 'baz' );
    $self->check_control_field( '002', 2, 'foo', 'baz' );

    $self->check_subfield( '100', 'a', 2, 'foo', 'baz' );
    $self->check_subfield( '100', 'b', 2, 'foo', 'baz' );
    $self->check_subfield( '100', 'c', 2, 'foo', 'baz' );
    $self->check_subfield( '101', 'd', 2, 'foo', 'baz' );
    $self->check_subfield( '101', 'e', 2, 'foo', 'baz' );
    $self->check_subfield( '101', 'f', 2, 'foo', 'baz' );

}

sub test_get_035_a {
    my $self = shift;
    my $xml = <<'EOXML';
<record>
  <leader>00782nam a2200313   45  </leader>
  <controlfield tag="001">0000099793</controlfield>
  <controlfield tag="003">SE-LIBR</controlfield>
  <controlfield tag="005">20070820000000.0</controlfield>
  <controlfield tag="008">010529s2001    sw |||| ||||||||||||swe||</controlfield>
  <datafield tag="020" ind1=" " ind2=" ">
    <subfield code="a">9147049863</subfield>
  </datafield>
  <datafield tag="035" ind1=" " ind2=" ">
    <subfield code="a">(Libra)0000200437</subfield>
  </datafield>
  <datafield tag="035" ind1=" " ind2=" ">
    <subfield code="a">(LibraSE)99793</subfield>
  </datafield>
  <datafield tag="041" ind1="0" ind2=" ">
    <subfield code="a">swe</subfield>
  </datafield>
  <datafield tag="084" ind1=" " ind2=" ">
    <subfield code="a">Eaa</subfield>
  </datafield>
  <datafield tag="084" ind1=" " ind2=" ">
    <subfield code="a">Dg</subfield>
  </datafield>
  <datafield tag="084" ind1=" " ind2=" ">
    <subfield code="a">Dofaa</subfield>
  </datafield>
  <datafield tag="100" ind1="1" ind2=" ">
    <subfield code="a">Johansson, Eva</subfield>
  </datafield>
  <datafield tag="245" ind1="1" ind2="0">
    <subfield code="a">Små barns etik /</subfield>
    <subfield code="c">Eva Johansson ; [illustrationer: Stina Wirsén]</subfield>
  </datafield>
  <datafield tag="250" ind1=" " ind2=" ">
    <subfield code="a">1. uppl.</subfield>
  </datafield>
  <datafield tag="260" ind1=" " ind2=" ">
    <subfield code="a">Stockholm :</subfield>
    <subfield code="b">Liber,</subfield>
    <subfield code="c">2001</subfield>
    <subfield code="e">(Falköping :</subfield>
    <subfield code="f">Elander Gummesson)</subfield>
  </datafield>
  <datafield tag="300" ind1=" " ind2=" ">
    <subfield code="a">200 s. :</subfield>
    <subfield code="b">ill.</subfield>
  </datafield>
  <datafield tag="653" ind1=" " ind2=" ">
    <subfield code="a">Pedagogisk psykologi</subfield>
  </datafield>
  <datafield tag="653" ind1=" " ind2=" ">
    <subfield code="a">Socialpsykologi</subfield>
  </datafield>
  <datafield tag="653" ind1=" " ind2=" ">
    <subfield code="a">Förskolan</subfield>
  </datafield>
  <datafield tag="653" ind1=" " ind2=" ">
    <subfield code="a">Förskolebarn</subfield>
  </datafield>
  <datafield tag="653" ind1=" " ind2=" ">
    <subfield code="a">Normer</subfield>
  </datafield>
  <datafield tag="852" ind1="8" ind2=" ">
    <subfield code="h">Eaa</subfield>
  </datafield>
</record>
EOXML

    my $record = MARC::Record::new_from_xml($xml, 'UTF-8', 'MARC21');
    my $mm = MarcUtil::MarcMapping->new(
        subfields => [ MarcUtil::FieldTag->new( tag => '035', subtags => [ 'a' ] ) ],
        record => $record
	);
    my @values = $mm->get();

    $self->assert_equals(scalar(@values), 2);

    my $catid_copy;
    for my $catid ($mm->get()) {
        if ($catid =~ /^\(LibraSE\)/) {
            $catid =~ s/\((.*)\)//;
            $catid_copy = $catid;
            last;
        }
    }

    
    $self->assert_equals($catid_copy, 99793);

}

sub test_indicators {
    my $self = shift;

    my $mm1 = MarcUtil::MarcMapping->new(
        subfields => [
            MarcUtil::FieldTag->new( tag => '653', subtags => [ 'a' ], ind1 => '7', ind2 => ' ' ),
        ],
        record => $self->{record}
	);

    my $mm2 = MarcUtil::MarcMapping->new(
        subfields => [
            MarcUtil::FieldTag->new( tag => '653', subtags => [ 'a' ], ind1 => ' ', ind2 => ' ' )
        ],
        record => $self->{record}
	);

    $mm1->set('foo', 'bar');
    $mm2->set('quiz', 'quid');

    $self->check_subfield_with_indicators( '653', 'a', '7', ' ', 2, 'foo', 'bar' );
    $self->check_subfield_with_indicators( '653', 'a', ' ', ' ', 2, 'quiz', 'quid' );

    $mm1->delete();
    $self->check_subfield_with_indicators( '653', 'a', '7', ' ', 0 );
    $self->check_subfield_with_indicators( '653', 'a', ' ', ' ', 2, 'quiz', 'quid' );
}

1;
