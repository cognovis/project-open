ad_page_contract {

    @author Miguel Marin (miguelmarin@viaro.net)
    @author Viaro Networks www.viaro.net
    @creation-date 2005-09-12
} {
    {party_id:integer}
    {revision_id:integer "" }
} -validate {
    contact_exists -requires {party_id} {
	if { ![contact::exists_p -party_id $party_id] } {
	    ad_complain "[_ intranet-contacts.lt_The_contact_specified]"
	}
    }
}
contact::require_visiblity -party_id $party_id

ad_return_template
