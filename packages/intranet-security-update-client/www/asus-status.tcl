# /packages/intranet-security-update-client/www/asus-status.tcl
#
# Copyright (C) 2003 - 2009 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.
#

ad_page_contract {
    Show the status of the user's ASUS account
    @author frank.bergmann@project-open.com
} {
}

# ---------------------------------------------------------------
#
# ---------------------------------------------------------------

set page_title [lang::message::lookup "" intranet-security-update-client.Account_Status "Account Status"]

set po_server "http://www.project-open.org"
set po "&#93;project-open&#91;"

set current_url [ns_conn url]
set system_id [im_system_id]

set current_user_id [ad_maybe_redirect_for_registration]
db_0or1row user_info "
	select	*
	from	cc_users
	where	user_id = :current_user_id
"

db_0or1row company_info "
	select	company_id,
		company_name
	from	im_companies
	where	company_path = 'internal'
"

set contract_end_date ""

set user_account_status "unknown"
set user_account_status "exists"


set system_status "unknown"
set company_status "unknown"
set contract_status "unknown"


set create_account_url [export_vars -base "$po_server/register/user-new" {{return_url $current_url}}]
set create_system_url [export_vars -base "$po_server/" {}]
set login_url [export_vars -base "$po_server/register/login" {}]
