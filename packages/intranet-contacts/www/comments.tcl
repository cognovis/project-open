ad_page_contract {

    @author Matthew Geddert openacs@geddert.com
    @creation-date 2004-07-28
    @cvs-id $Id: comments.tcl,v 1.1 2009/02/08 22:28:17 cvs Exp $


} {
    {party_id:integer}
    {page "comments"}
} -validate {
    contact_exists -requires {party_id} {
	if { ![contact::exists_p -party_id $party_id] } {
	    ad_complain "[_ intranet-contacts.lt_The_contact_specified]"
	}
    }
}
contact::require_visiblity -party_id $party_id

ad_return_template
