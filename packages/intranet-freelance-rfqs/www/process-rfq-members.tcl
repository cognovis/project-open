# /packages/intranet-freelance-rfqs/www/process-rfq-members
#
# Copyright (c) 2003-2007 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.


ad_page_contract {
    Purpose: Process one or more users to a RFQ

    @param user_id user_id to add
    @param rfq_id RFQ to which to add 
    @param return_url Return URL

    @author frank.bergmann@project-open.com
} {
    { user_ids:multiple "" }
    { notify_asignee 1 }
    rfq_action_id
    rfq_id:integer
    return_url
}


# --------------------------------------------------------
# 
# --------------------------------------------------------

set current_user_id [ad_maybe_redirect_for_registration]

# Fix issues with user_ids - no idea why they come as a list...
if {1 == [llength $user_ids]} { set user_ids [lindex $user_ids 0]}

# No users selected - return to main page
if {0 == [llength $user_ids]} {
    ad_returnredirect $return_url
    ad_script_abort
}

# im_project_permissions $current_user_id $project_id view read write admin
# if {!$write} {
#     ad_return_complaint 1 "You have no rights to add members to this object."
#     return
# }
# ToDo: Permissions

# Get the SystemUrl without trailing "/"
set system_name [ad_system_name]
set system_url [ad_parameter -package_id [ad_acs_kernel_id] SystemURL ""]
set sysurl_len [string length $system_url]
set last_char [string range $system_url [expr $sysurl_len-1] $sysurl_len]
if {[string equal "/" $last_char]} {
    set system_url "[string range $system_url 0 [expr $sysurl_len-2]]"
}

set add_to_project_checked ""
switch $rfq_action_id {
    4472 {
	# Confirm - add to project by default
	set add_to_project_checked "checked"
    }
}


set rfq_action [im_category_from_id $rfq_action_id]
set rfq_action_upper "[string toupper [string range $rfq_action 0 0]][string range $rfq_action 1 end]"
set rfq_action_upper_l10n [lang::message::lookup "" intranet-freelance-rfqs.$rfq_action $rfq_action_upper]

# ---------------------------------------------------------------
# Get everything about the RFQ
# ---------------------------------------------------------------

db_1row rfq_info "
	select	rfq_project_id as project_id,
		im_category_from_id(rfq_type_id) as rfq_type,
		*
	from	im_freelance_rfqs 
	where	rfq_id = :rfq_id
"


set project_name [db_string project_name "select acs_object__name(:project_id)"]

set page_title [lang::message::lookup "" intranet-freelance-rfqs.${rfq_action_upper}_Users "$rfq_action_upper Users"]
set context [list $page_title]


# --------------------------------------------------------
# Variables for email & current user
# --------------------------------------------------------

set export_vars [export_form_vars rfq_id rfq_action_id return_url]
foreach uid $user_ids {
    append export_vars "<input type=hidden name=user_ids value=$uid>\n"
}

set email_vars "
	rfq_type \
	rfq_name \
	rfq_url \
	project_name \
	name \
	first_names \
	last_name \
	email \
	auto_login \
	current_user_name \
	current_user_email \
	current_user_first_names \
	current_user_last_name \
"

set email_header [lang::message::lookup "" intranet-freelance-rfqs.${rfq_action_upper}_for_RFQ_of_Project_Header "intranet-freelance-rfqs.${rfq_action_upper}_for_RFQ_of_Project_Header Undefined" [list] 0]

set email_body [lang::message::lookup "" intranet-freelance-rfqs.${rfq_action_upper}_for_RFQ_of_Project_Body "intranet-freelance-rfqs.${rfq_action_upper}_for_RFQ_of_Project_Body Undefined" [list] 0]


# ---------------------------------------------------------------
# Project Menu
# ---------------------------------------------------------------

# Setup the subnavbar
set bind_vars [ns_set create]
ns_set put $bind_vars project_id $project_id
set project_menu_id [db_string parent_menu "select menu_id from im_menus where label='project'" -default 0]
set project_menu [im_sub_navbar $project_menu_id $bind_vars "" "pagedesriptionbar" "project_freelance_rfqs"]

