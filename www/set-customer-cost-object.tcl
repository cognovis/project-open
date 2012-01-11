# /packages/intranet-cust-koernigweber/www/set-emp-cust-price.tcl
#
# Copyright (C) 1998-2011 various parties

ad_page_contract {
    Sets or updates allowed project types  
    @author various@arsdigita.com
    @author frank.bergmann@project-open.com
    @author klaus.hofeditz@project-open.com
} {
    company_id:integer
    { project_type_id:multiple,integer "" }
    { return_url "" }
    { submit "" }
}

# -----------------------------------------------------------------
# Security
# -----------------------------------------------------------------

set current_user_id [ad_maybe_redirect_for_registration]

# Determine our permissions for the current object_id.
# We can build the permissions command this ways because
# all ]project-open[ object types define procedures
# im_ObjectType_permissions $user_id $object_id view read write admin.
#
set object_type [db_string acs_object_type "select object_type from acs_objects where object_id=:company_id"]
set perm_cmd "${object_type}_permissions \$current_user_id \$company_id view read write admin"
eval $perm_cmd

if {!$write} {
    ad_return_complaint 1  [lang::message::lookup "" intranet-cust-koernigweber.You_have_insufficient " You have insufficient permissions to make these changes"]
    return 
}

# -----------------------------------------------------------------
# Action
# -----------------------------------------------------------------

# Simply delete the old status ... 
db_dml delete "delete from im_customer_project_type where company_id = :company_id"  

# And create them completely new ... 
set sql "" 
foreach project_type $project_type_id {
	append sql "insert into im_customer_project_type (company_id, project_type_id) values (:company_id, $project_type);"						
}
db_dml insert $sql
ad_returnredirect $return_url



