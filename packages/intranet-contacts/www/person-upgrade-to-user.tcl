ad_page_contract {

    @author Matthew Geddert openacs@geddert.com
    @creation-date 2005-07-06
    @cvs-id $Id$


} {
    {person_id:integer}
}
contact::require_visiblity -party_id $person_id

permission::require_permission -object_id [ad_conn package_id] -privilege "admin"

contact::person_upgrade_to_user -person_id $person_id
set contact_link [contact::link -party_id $person_id]

# If we are autoadding users into .LRN we should do so here as well.
if {[parameter::get_from_package_key -package_key "dotlrn" -parameter "AutoAddUsersP" -default 0]} {
    dotlrn::user_add -user_id $person_id -can_browse
}        
util_user_message -message "[_ intranet-contacts.lt_-contact_link-_was_upgraded_to_a_user]"
ad_returnredirect [contact::url -party_id $person_id]
ad_script_abort
