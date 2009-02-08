#    @author Matthew Geddert openacs@geddert.com
#    @creation-date 2005-07-09
#    @cvs-id $Id$

if { [string is false [contact::exists_p -party_id $party_id]] } {
    error "[_ intranet-contacts.lt_The_party_id_specifie]"
}
set package_id [ad_conn package_id]
multirow create public_searches title url
if { [site_node::get_package_url -package_key "tasks"] != "" } {
    set tasks_enabled_p 1
    db_foreach dbqd.contacts.www.index.public_searches {} {
	if { [contact::search::party_p_not_cached -search_id $search_id -party_id $party_id -package_id $package_id] && $title != "All People" && $title != "All Organizations" } {
	    multirow append public_searches $title [export_vars -base "../" -url {search_id}] 
	}
    }
} else {
    set tasks_enabled_p 0
}
