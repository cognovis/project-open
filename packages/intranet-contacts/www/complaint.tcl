ad_page_contract {

    @author Matthew Geddert openacs@geddert.com
    @creation-date 2005-07-09
    @cvs-id $Id$


} {
    {party_id:integer}
    {page "Complaints"}
    {customer_id ""}
} -validate {
    contact_exists -requires {party_id} {
	if { ![contact::exists_p -party_id $party_id] } {
	    ad_complain "[_ intranet-contacts.lt_The_contact_specified]"
	}
    }
}
contact::require_visiblity -party_id $party_id

set supplier_id $party_id

ad_return_template
