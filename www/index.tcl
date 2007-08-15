# /packages/intranet-freelance-rfqs/www/index.tcl
#
# Copyright (C) 2003-2006 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

# ---------------------------------------------------------------
# Page Contract
# ---------------------------------------------------------------

ad_page_contract { 
    @author frank.bergmann@project-open.com
} {
    { project_id:integer "" }
    { rfq_type_id:integer "" }
    { rfq_status_id:integer "" }
}

# ---------------------------------------------------------------
# Defaults & Security
# ---------------------------------------------------------------

# User id already verified by filters
set user_id [ad_maybe_redirect_for_registration]
set current_user_id $user_id
set page_focus "im_header_form.keywords"
set date_format "YYYY-MM-DD"
set return_url [im_url_with_query]
set current_url [ns_conn url]
set project_nr [db_string project_nr "select project_nr from im_projects where project_id=:project_id" -default ""]
set page_title "$project_nr - [_ intranet-freelance-rfqs.RFQs]"
set context_bar [im_context_bar [list /intranet/projects/ "[_ intranet-core.Projects]"] $page_title]
set org_project_id $project_id

set date_format "YYYY-MM-DD"
set date_time_format "YYYY-MM-DD HH24:MI"


# ---------------------------------------------------------------
# Admin Links
# ---------------------------------------------------------------

set add_rfq_p [im_permission $user_id "add_freelance_rfqs"]
set view_rfq_p [im_permission $user_id "view_freelance_rfqs"]

set admin_links ""
set bulk_actions_list "[list]"

if {$add_rfq_p} {
    lappend bulk_actions_list "[_ intranet-freelance-rfqs.Delete]" "del-rfq" "[_ intranet-freelance-rfqs.Delete_RFQ]"
}


# ------------------------------------------------------------------
# Form Options
# ------------------------------------------------------------------

set freelance_rfq_type_options [db_list_of_lists freelance_rfq_type "
	select	freelance_rfq_type, 
		freelance_rfq_type_id 
	from	im_freelance_rfq_type
"]
set freelance_rfq_type_options [linsert $freelance_rfq_type_options 0 [list [lang::message::lookup "" "intranet-freelance-rfqs.All" "All"] ""]]

set freelance_rfq_status_options [db_list_of_lists freelance_rfq_status "
	select	freelance_rfq_status,
		freelance_rfq_status_id
	from	im_freelance_rfq_status
"]
set freelance_rfq_status_options [linsert $freelance_rfq_status_options 0 [list [lang::message::lookup "" "intranet-freelance-rfqs.All" "All"] ""]]


# ------------------------------------------------------------------
# Build the form
# ------------------------------------------------------------------

set form_id "rfq_filters"
set focus "$form_id\.var_name"
set form_mode "edit"
set action_url "index"

ad_form \
    -name $form_id \
    -action $action_url \
    -mode $form_mode \
    -export {project_id return_url} \
    -form {
	{rfq_type_id:text(select),optional
	    {label "[_ intranet-freelance-rfqs.RFQ_Type]"}
	    {options $freelance_rfq_type_options} 
	}
	{rfq_status_id:text(select),optional
	    {label "[_ intranet-freelance-rfqs.RFQ_Status]"}
	    {options $freelance_rfq_status_options} 
	}
    }

# ---------------------------------------------------------------
# List RFQs according to filters
# ---------------------------------------------------------------

# define list object
set list_id "rfqs_list"

set actions_list [list]
set export_var_list [list return_url]

if {$add_rfq_p} {
    set add_rfq_msg [lang::message::lookup "" intranet-freelance-rfqs.Create_New_RFQ "Create a New RFQ"]
    lappend actions_list $add_rfq_msg [export_vars -base "new-rfq" {{rfq_project_id $project_id} return_url}] $add_rfq_msg
}

set elements {}
if {$add_rfq_p} {
    set elements {
	rfq_chk {
	    label "<input type=\"checkbox\" 
                          name=\"_dummy\" 
                          onclick=\"acs_ListCheckAll('rfqs_list', this.checked)\" 
                          title=\"Check/uncheck all rows\">"
	    display_template {
		@rfq_lines.rfq_chk;noquote@
	    }
	}
    }
}

set elements [concat $elements {
	rfq_name {
	    label "[_ intranet-freelance-rfqs.RFQ_Name]"
	    link_url_eval $rfq_view_url
	}
	req_project_id {
	    label "[_ intranet-freelance-rfqs.Project]"
	    display_template { <nobr>@rfq_lines.project_name;noquote@</nobr> }
	    link_url_eval $rfq_project_url
	}
	rfq_type {label "[lang::message::lookup {} intranet-freelance-rfqs.RFQ_Type {RFQ Type}]"}
	rfq_start_date_pretty {
	    label "[lang::message::lookup {} intranet-freelance-rfqs.Start_Date {Starts}]"
	    display_template { <nobr>@rfq_lines.rfq_start_date_pretty;noquote@</nobr> }
	}
	rfq_end_date_pretty {
	    label "[lang::message::lookup {} intranet-freelance-rfqs.End_Date {Ends}]"
	    display_template { <nobr>@rfq_lines.rfq_end_date_pretty;noquote@</nobr> }
	}
	rfq_status {label "[lang::message::lookup {} intranet-freelance-rfqs.RFQ_Status {RFQ Status}]"}
}]
	
if {$view_rfq_p} {
    set elements [concat $elements {
	num_inv {label "[lang::message::lookup {} intranet-freelance-rfqs.Num_Invitations {# Inv}]"}
	num_conf {label "[lang::message::lookup {} intranet-freelance-rfqs.Num_Confirmations {# Conf}]"}
	num_decl {label "[lang::message::lookup {} intranet-freelance-rfqs.Num_Declinations {# Decl}]"}
	num_rem {label "[lang::message::lookup {} intranet-freelance-rfqs.Num_Remaining {# Rem}]"}
    }]
}


template::list::create \
    -name $list_id \
    -multirow rfq_lines \
    -key rfq_id \
    -has_checkboxes \
    -actions $actions_list \
    -bulk_actions $bulk_actions_list \
    -bulk_action_export_vars { return_url } \
    -row_pretty_plural "[_ intranet-freelance-rfqs.RFQs_Items]" \
    -elements $elements



set project_where ""
if {"" != $project_id} { 
    append project_where "\tand r.rfq_project_id = :project_id\n" 
}
if {"" != $rfq_type_id} { 
    append project_where "\tand r.rfq_type_id = :rfq_type_id\n" 
}
if {"" != $rfq_status_id} { 
    append project_where "\tand r.rfq_status_id = :rfq_status_id\n" 
}


# ---------------------------------------------------------------
# Permissions - a bit complex
# Start off that each user can read the RFQs where he participates.
# 
set allowed_rfqs "(
			select distinct answer_rfq_id as rfq_id 
			from im_freelance_rfq_answers 
			where answer_user_id = :current_user_id
		)"

if {[im_permission $current_user_id "view_freelance_rfqs_all"]} {
    set allowed_rfqs "(select rfq_id from im_freelance_rfqs)"
}


db_multirow -extend {rfq_chk rfq_new_url rfq_view_url rfq_project_url num_rem} rfq_lines rfqs_lines "
    select
		*,
		(r.rfq_end_date > now()) as rfq_active_p,
		im_category_from_id(rfq_type_id) as rfq_type,
		im_category_from_id(rfq_status_id) as rfq_status,
		to_char(rfq_start_date, :date_format) as rfq_start_date_pretty,
		to_char(rfq_end_date, :date_time_format) as rfq_end_date_pretty,
		(select count(*) from im_freelance_rfq_answers a where a.answer_rfq_id = r.rfq_id) as num_inv,
		(	select	count(*) 
			from	im_freelance_rfq_answers a
			where	a.answer_rfq_id = r.rfq_id
				and a.answer_status_id = [im_freelance_rfq_answer_status_confirmed]
		) as num_conf,
		(	select	count(*) 
			from	im_freelance_rfq_answers a
			where	a.answer_rfq_id = r.rfq_id
				and a.answer_status_id = [im_freelance_rfq_answer_status_declined]
		) as num_decl
    from
		im_freelance_rfqs r
		LEFT OUTER JOIN im_projects p ON (r.rfq_project_id = p.project_id),
		$allowed_rfqs a
    where
		r.rfq_id = a.rfq_id
		$project_where
    order by
		r.rfq_name
" {
    set rfq_chk "<input type=\"checkbox\" name=\"rfq_id\" value=\"$rfq_id\" id=\"rfqs_list,$rfq_id\">"
    set rfq_new_url [export_vars -base "/intranet-freelance-rfqs/new-rfq" {rfq_id project_id return_url}]
    set rfq_view_url [export_vars -base "/intranet-freelance-rfqs/view-rfq" {rfq_id project_id return_url}]
    set rfq_project_url [export_vars -base "/intranet/projects/view" {project_id return_url}]
    set num_rem [expr $num_inv - $num_conf - $num_decl]
    if {!$view_rfq_p} { set rfq_project_url "" }

    if {"t" != $rfq_active_p} {
	set rfq_end_date_pretty "<font color=red>$rfq_end_date_pretty</font>"
    }
}


# ---------------------------------------------------------------
# Project Menu
# ---------------------------------------------------------------

set project_menu ""
set project_id $org_project_id

if {"" != $project_id} {
    # Setup the subnavbar
    set bind_vars [ns_set create]
    ns_set put $bind_vars project_id $project_id
    set project_menu_id [db_string parent_menu "select menu_id from im_menus where label='project'" -default 0]
    set project_menu [im_sub_navbar $project_menu_id $bind_vars "" "pagedesriptionbar" "project_freelance_rfqs"]
}
