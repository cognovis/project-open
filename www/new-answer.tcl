# /packages/intranet-freelance-rfqs/www/panels/rfa-panel.tcl
#
# Copyright (c) 2003-2007 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.
#
# Authors:
#	frank.bergmann@project-open.com


ad_page_contract {
    Purpose: form to add a new project or edit an existing one
} {
    rfq_id:integer
    { return_url "/intranet/" }
    { task_page_url "" }
    { default_assignee_fulfill_rfc_id 0 }
}

# ------------------------------------------------------
# 
# ------------------------------------------------------

set current_user_id [ad_maybe_redirect_for_registration]
set current_url [im_url_with_query]
if {![exists_and_not_null return_url]} { set return_url [im_url_with_query] }
set action_url "/intranet-freelance-rfqs/new-answer"

db_1row rfq_info "
	select	r.rfq_type_id,
		im_category_from_id(r.rfq_type_id) as rfq_type,
		project_lead_id,
		im_name_from_user_id(project_lead_id) as project_manager_name,
		im_email_from_user_id(project_lead_id) as project_manager_email
	from
		im_freelance_rfqs r,
		im_projects p
	where
		r.rfq_id = :rfq_id
		and r.rfq_project_id = p.project_id
"

set page_title [lang::message::lookup "" intranet-freelance-rfqs.[lang::util::suggest_key $rfq_type] $rfq_type]
set context_bar [im_context_bar [list /intranet-freelance-rfqs/ "[lang::message::lookup "" intranet-freelance-rfqs.RFQs "RFQs"]"] $page_title]

set rfq_title [lang::message::lookup "" intranet-freelance-rfqs.[lang::util::suggest_key $rfq_type]_Info $rfq_type]
set rfq_answer_title [lang::message::lookup "" intranet-freelance-rfqs.Answer_Info "Please indicate your availability"]

set project_manager_url [export_vars -base "/intranet/users/view" {{user_id $project_lead_id}}]

# ------------------------------------------------------------------
# Options
# ------------------------------------------------------------------

set freelance_rfq_type_options [db_list_of_lists freelance_rfq_type "
	select	freelance_rfq_type, 
		freelance_rfq_type_id 
	from	im_freelance_rfq_type
"]
set freelance_rfq_type_options [linsert $freelance_rfq_type_options 0 [list "" 0]]

set freelance_rfq_status_options [db_list_of_lists freelance_rfq_status "
	select	freelance_rfq_status,
		freelance_rfq_status_id
	from	im_freelance_rfq_status
"]
set freelance_rfq_status_options [linsert $freelance_rfq_status_options 0 [list "" 0]]

set uom_options [im_cost_uom_options]


set general_outcome_options [list \
	[list \
		[lang::message::lookup "" intranet-freelance-rfqs.Yes_can_deliver "Yes, I can deliver the specified work in time."] \
		"t" \
	] \
	[list \
		[lang::message::lookup "" intranet-freelance-rfqs.No_cant_deliver "No, I decline."] \
		"f" \
	]
]

# -----------------------------------------------------------
# Create the Form with RFQ information
# -----------------------------------------------------------

ad_form \
    -name "rfq-form" \
    -mode "display" \
    -has_edit 1 \
    -form {
        rfq_id:key
        {answer_id:text(hidden)}
        {task_id:text(hidden)}
        {rfq_name:text(text) {label "[_ intranet-freelance-rfqs.Name]"} {html {size 40}} }
        {rfq_type_id:text(select)
            {label "[_ intranet-freelance-rfqs.RFQ_Type]"}
            {options $freelance_rfq_type_options}
        }
        {rfq_status_id:text(select)
            {label "[_ intranet-freelance-rfqs.RFQ_Status]"}
            {options $freelance_rfq_status_options}
        }
        {rfq_start_date:date(date) {label "[_ intranet-freelance-rfqs.Start_date]"} }
        {rfq_end_date:date(date) {label "[_ intranet-freelance-rfqs.End_date]"} {format "DD Month YYYY HH24:MI"} }
        {rfq_units:text(text),optional {label "[_ intranet-freelance-rfqs.Units]"} {html {size 6}} }
        {rfq_uom_id:text(select)
            {label "[_ intranet-freelance-rfqs.UoM]"}
            {options $uom_options}
        }
    }

im_dynfield::append_attributes_to_form \
    -object_type "im_freelance_rfq" \
    -object_subtype_id $rfq_type_id \
    -form_id "rfq-form" \
    -form_display_mode "display"

ad_form -extend -name "rfq-form" -form {
    {rfq_description:text(textarea),optional \
	 {label "[lang::message::lookup {} intranet-freelance-rfqs.Description Description]"}
    }
    {rfq_note:text(textarea),optional
	{label "[lang::message::lookup {} intranet-freelance-rfqs.Note Note]" } 
	{html {cols 40} }
    }
}

ad_form -extend -name "rfq-form" -select_query {
	select	*,
		to_char(rfq_start_date, 'YYYY MM DD') as rfq_start_date,
		to_char(rfq_end_date, 'YYYY MM DD HH24 MI') as rfq_end_date
	from	im_freelance_rfqs
	where	rfq_id = :rfq_id

} 



# -----------------------------------------------------------
# Create the Form with RFQ Answer Information
# -----------------------------------------------------------

ad_form \
    -name "rfq-answer-form" \
    -export {return_url} \
    -form {
        answer_id:key
        {rfq_id:text(hidden)}
        {answer_accepted_p:text(radio)
            {label "[_ intranet-freelance-rfqs.General_Outcome]"}
            {options $general_outcome_options}
        }
    }

im_dynfield::append_attributes_to_form \
    -object_type "im_freelance_rfq_answer" \
    -object_subtype_id $rfq_type_id \
    -form_id "rfq-answer-form"


ad_form -extend -name "rfq-answer-form" -form {
    {rfq_note:text(textarea),optional
	{label "[lang::message::lookup {} intranet-freelance-rfqs.Note Note]"}
	{html {cols 40 rows 8} }
    }
}

ad_form -extend -name "rfq-answer-form" -select_query {
	select	*,
	from	im_freelance_rfq_answers
	where	answer_id = :answer_id

} 


