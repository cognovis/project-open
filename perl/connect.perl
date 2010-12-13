use Net::LDAP;
use Net::LDAP::Schema;
use Net::LDAP::LDIF;
use Net::LDAP::Util qw(ldap_error_text
                         ldap_error_name
                         ldap_error_desc
			 );


$ldap = Net::LDAP->new('192.168.21.128', port=>389, timeout=>5) or die "$@";

# $mesg = $ldap->bind();

$mesg = $ldap->bind("cn=Manager,dc=project-open,dc=com", password => "secret");
die "Bad bind: ",$mesg->code, "\n" if $mesg->code;


#my $schema = $ldap->schema;
#
# print $schema->dump();
# @schema_classes = $schema->all_objectclasses;
# @atts = $schema->all_attributes;



$mesg = $ldap->search(
                       base   => "o=project-open.com",
                       filter => "uid=fraber"
);

die ldap_error_text($mesg->code) if $mesg->code;

die "Bad search: ",$mesg->code, "\n" if $mesg->code;


while( my $entry = $mesg->shift_entry) {
    print "$entry\n";
}
