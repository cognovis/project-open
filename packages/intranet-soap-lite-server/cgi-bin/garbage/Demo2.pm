package Demo2;

use XML::Generator::DBI;
use XML::Handler::YAWriter;
use DBI;

=begin WSDL
    
    _IN hi $string A foo
    _DOC This is a test soap web service that prints a list of the current DBAs
    _RETURN $string Returns a string containing the current DBAs
    
=end WSDL
    
sub hi {
    my $out_xml = "hi";
    my $ya = XML::Handler::YAWriter->new();
    
    #  Stuff
    
    return $out_xml;
}

1;

