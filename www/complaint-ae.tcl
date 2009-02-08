ad_page_contract {

    @author Matthew Geddert openacs@geddert.com
    @creation-date 2005-07-09
    @cvs-id $Id$


} {
    {supplier_id:integer}
    {customer_id ""}
    {project_id ""}
    {object_id ""}
} -validate {
    contact_exists -requires {party_id} {
	if { ![contact::exists_p -party_id $party_id] } {
	    ad_complain "[_ intranet-contacts.lt_The_contact_specified]"
	}
    }
}

if {![empty_string_p $project_id]} {
    if {[empty_string_p $customer_id]} {
        set customer_id [db_string get_customer_id "select p.customer_id from pm_projectsx p, cr_items i where p.item_id = :project_id and i.live_revision = p.revision_id"]
    }
    set object_id $project_id
}

ad_return_template
