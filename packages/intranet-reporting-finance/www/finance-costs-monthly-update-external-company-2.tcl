# /packages/intranet-reporting-finance/www/finance-costs-monthly-update-external-company-2.tcl
#
# Copyright (C) 2010 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/ for licensing details.

ad_page_contract {
    Report showing the project hierarchy, together with financial information
    and timesheet hours
} {
    old_external_company_name
    new_external_company_name
    return_url
}

# ------------------------------------------------------------
# Security

set current_user_id [ad_maybe_redirect_for_registration]
set permission_p [im_permission $current_user_id "edit_bundled_expense_items"]

if {!$permission_p} {
    ad_return_complaint 1 [lang::message::lookup "" intranet-reporting.You_dont_have_permissions "You don't have the necessary permissions to view this page"]
    ad_script_abort
}

db_dml update_expenses "
	update	im_expenses
	set 	external_company_name = trim(:new_external_company_name)
	where	trim(lower(external_company_name)) = trim(lower(:old_external_company_name))
"

ad_returnredirect $return_url
