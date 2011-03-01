
# --------------------------------------------------------
package KeyTypeValue;
# --------------------------------------------------------

=begin WSDL
    _ATTR key $string The name of the variable
    _ATTR type $string The type of the value. 
    One of {null, string, integer, numeric, date, timestamptz, varbit}
    _ATTR value $string Value, encoded according to the specified PostgreSQL type
=end WSDL

sub new {
    bless {
	key => '',
	type => 'null',
	value => ''
    }, $_[0];
}

1;

