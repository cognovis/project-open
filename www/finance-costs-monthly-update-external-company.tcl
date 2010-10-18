# /packages/intranet-reporting-finance/www/finance-costs-monthly-update-external-company.tcl
#
# Copyright (C) 2010 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/ for licensing details.

ad_page_contract {
    Report showing the project hierarchy, together with financial information
    and timesheet hours
} {
    external_company_name
    return_url
}

# ------------------------------------------------------------
# Security

set current_user_id [ad_maybe_redirect_for_registration]
set permission_p [im_permission $current_user_id "edit_bundled_expense_items"]
set page_title [lang::message::lookup "" intranet-reporting-finance.Replace_expense_company_name "Replace Expense Company Name"]


if {!$permission_p} {
    ad_return_complaint 1 [lang::message::lookup "" intranet-reporting.You_dont_have_permissions "You don't have the necessary permissions to view this page"]
    ad_script_abort
}

