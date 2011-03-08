# /packages/intranet-expenses/www/bundle-del.tcl
#
# Copyright (C) 2003-2008 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

# ---------------------------------------------------------------
# 1. Page Contract
# ---------------------------------------------------------------
ad_page_contract { 
    Delete expense bundle 
    @param project_id project on expense is going to create
    @author avila@digiteix.com
} {
    bundle_id:multiple
    project_id:integer,optional
    { return_url "/intranet-expenses/"}
}

# ---------------------------------------------------------------
# Defaults & Security
# ---------------------------------------------------------------

set user_id [ad_maybe_redirect_for_registration]
set current_user_id $user_id
set user_admin_p [im_is_user_site_wide_or_intranet_admin $current_user_id]

foreach id $bundle_id {

    # Get the list of expense items.
    set expense_items [db_list expense_items "select expense_id from im_expenses where bundle_id = :id"]

    # delete bundle as a cost
    # 
    db_transaction {

	foreach exp_id $expense_items {
	    db_dml reset_expense_items "
		update im_expenses set 
		       	bundle_id = null 
		where expense_id = :exp_id
	    "

	    # Audit the deletion
	    im_audit -object_type im_expense_bundle -action after_create -object_id $exp_id
	}

	db_dml del_tokens "
	        delete	from wf_tokens
		where	case_id in (
				select	wfc.case_id
				from 	wf_cases wfc
		      		where	wfc.object_id = :id
		)
	"
	db_dml del_workflows "
	        delete from wf_cases
		where object_id = :id
	"

	# Audit the deletion
	im_audit -object_type im_expense_bundle -action after_delete -object_id $id

	db_string del_expense_bundle {}

    }
}

template::forward $return_url

