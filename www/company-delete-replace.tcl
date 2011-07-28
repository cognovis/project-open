# company-delete-replace.tcl

ad_page_contract {
    Delete a company and replace all reference to the
    company by another company_id.

    Example:
    /intranet-sencha-ticket-tracker/company-delete-replace?company_id=88285&company_id_replacement=86662

    @author Frank Bergmann (frank.bergmann@project-open.com)
    @author David Blanco (david.blanco@grupoversia.com)
    @creation-date 28 Jul 2011
    @cvs-id $Id$
} {
    { company_id:integer ""}
    { company_id_replacement:integer ""}
}

# -------------------------------------------------------------
# Security
# -------------------------------------------------------------

# Check that company_id and company_id_replacement are well defined

set company_id_exists_p [db_string company_id_exists_p "select count(*) from im_companies where company_id = :company_id"]
set company_id_replacement_exists_p [db_string company_id_replacement_exists_p "select count(*) from im_companies where company_id = :company_id_replacement"]

if {!$company_id_exists_p || !$company_id_replacement_exists_p || $company_id == $company_id_replacement} {
    doc_return 200 "text/html" "{
	\"result\": {
		\"success\":	false,
		\"errors\":	\"Failure: company_id='$company_id' or company_id_replacement='$company_id_replacement' is not a valid company\"
    	}
    }"
    ad_script_abort
}

set user_id [im_rest_cookie_auth_user_id]

im_company_permissions $user_id $company_id view read write admin
if {!$write} {
    ns_log Notice "company-delete-replace: failure: User \#$user_id doesn't have write permissions to company \#$company_id"
    doc_return 200 "text/html" "{
	\"result\": {
		\"success\":	false,
		\"errors\":	{\"permission\": \"You do not have permission to write to folder \#$folder_id\"}
    	}
    }"
    ad_script_abort
}

# -------------------------------------------------------------
# Delete/Replace the company
# -------------------------------------------------------------



# Delete the company completely
# im_company_nuke -current_user_id $user_id $company_id
db_transaction {

    # Replace any ocurrence of company_id by company_id_replacement
    db_dml ticket_customer "update im_projects set company_id = :company_id_replacement where company_id = :company_id"

    # Context index is a hierarchy of objects. Put sub-objects of :company_id below :company_id_replacement
    db_dml context_index "update acs_objects set context_id = :company_id_replacement where context_id = :company_id"

    # context_index is a cached denormalized index which doesn't interest us anymore now.
    db_dml context_index "delete from acs_object_context_index where object_id = :company_id or ancestor_id = :company_id"

    # Move any contacts of company_id to company_id_replacement
    db_dml acs_rels "update acs_rels set object_id_one = :company_id_replacement where object_id_one = :company_id"
    db_dml acs_rels "update acs_rels set object_id_two = :company_id_replacement where object_id_two = :company_id"

    # Delete the company from the various tables where it exists
    db_dml delete_company "delete from im_biz_objects where object_id = :company_id"
    db_dml delete_company "delete from parties where party_id = :company_id"
    db_dml delete_company "delete from im_companies where company_id = :company_id"
    db_dml delete_acs_obj "delete from acs_objects where object_id = :company_id"

}

ns_log Notice "company-delete-replace: success"
doc_return 200 "text/html" "{
	\"result\": {
		\"success\":	true,
		\"message\":	\"Company successfully replaced\",
		\"data\":	\[{
			\"company_id\":	\"$company_id\"
		}\]
    	}
}"
ad_script_abort
