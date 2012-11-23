# contact-delete-replace.tcl

ad_page_contract {
    Delete a contact and replace all reference to the
    contact by another contact_id.

    Example:
    /intranet-sencha-ticket-tracker/contact-delete-replace?contact_id=63675&contact_id_replacement=63670

    @author Frank Bergmann (frank.bergmann@project-open.com)
    @author David Blanco (david.blanco@grupoversia.com)
    @creation-date 28 Jul 2011
    @cvs-id $Id$
} {
    { contact_id:integer ""}
    { contact_id_replacement:integer ""}
}

# -------------------------------------------------------------
# Security
# -------------------------------------------------------------

# Check that contact_id and contact_id_replacement are well defined

set contact_id_exists_p [db_string contact_id_exists_p "select count(*) from persons where person_id = :contact_id"]
set contact_id_replacement_exists_p [db_string contact_id_replacement_exists_p "select count(*) from persons where person_id = :contact_id_replacement"]

if {!$contact_id_exists_p || !$contact_id_replacement_exists_p} {
    doc_return 200 "text/html" "{
		\"success\":	false,
		\"errors\":	\"Failure: contact_id='$contact_id' or contact_id_replacement='$contact_id_replacement' is not a valid contact\"
    }"
    ad_script_abort
}

set current_user_id [auth::require_login]
im_user_permissions $current_user_id $contact_id view read write admin 
if {!$admin} {
    ns_log Notice "contact-delete-replace: failure: User \#$user_id doesn't have write permissions to contact \#$contact_id"
    doc_return 200 "text/html" "{
		\"success\":	false,
		\"errors\":	{\"permission\": \"You do not have permission to write to folder \#$folder_id\"}
    }"
    ad_script_abort
}

# -------------------------------------------------------------
# Delete/Replace the contact
# -------------------------------------------------------------



# Delete the contact completely
db_transaction {

	# Replace any ocurrence of contact_id by contact_id_replacement
	db_dml update_im_ticket "update im_tickets set ticket_customer_contact_id = :contact_id_replacement where ticket_customer_contact_id = :contact_id"
	db_dml update_im_company "update im_companies set primary_contact_id = :contact_id_replacement where primary_contact_id = :contact_id"
	db_dml update_acs_rels	"update acs_rels set object_id_two = :contact_id_replacement where object_id_two = :contact_id and object_id_one not in (select object_id_one from acs_rels where object_id_two= :contact_id_replacement)" 
	db_dml update_acs_acs_objects "update acs_objects set creation_user = :contact_id_replacement where creation_user = :contact_id" 
	

    # Delete the contact from the various tables where it exists
    db_dml delete_acs_rels "delete from im_biz_object_members where rel_id in (select rel_id from acs_rels where object_id_one = :contact_id or object_id_two = :contact_id)"
    db_dml delete_acs_rels "delete from membership_rels where rel_id in (select rel_id from acs_rels where object_id_one = :contact_id or object_id_two = :contact_id)"
    db_dml delete_geidx "delete from group_element_index where rel_id in (select rel_id from acs_rels where object_id_one = :contact_id or object_id_two = :contact_id)"
    db_dml delete_acs_rels "delete from acs_rels where object_id_two = :contact_id" 
    db_dml delete_acs_rels "delete from acs_rels where object_id_one = :contact_id" 
    db_dml delete_im_freelancers "delete from im_freelancers where user_id = :contact_id"
    db_dml delete_users "delete from users where user_id = :contact_id"
    db_dml delete_users_contact "delete from users_contact where user_id = :contact_id"
    db_dml delete_persons "delete from persons where person_id = :contact_id"
    db_dml delete_parties "delete from parties where party_id = :contact_id"
    db_dml delete_acs_perms "delete from acs_permissions where object_id = :contact_id"
    db_dml delete_acs_obj "delete from acs_objects where object_id = :contact_id"

}

ns_log Notice "Contact delete replace: success"
doc_return 200 "text/html" "{
		\"success\":	true,
		\"message\":	\"Contact $contact_id successfully replaced by $contact_id_replacement and deleted\"
}"
ad_script_abort

