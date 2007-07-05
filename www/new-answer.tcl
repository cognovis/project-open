# /packages/intranet-freelance-rfqs/www/new-answer.tcl
#
# Copyright (c) 2003-2006 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

# ------------------------------------------------------------------
# Default & Security
# ------------------------------------------------------------------

set user_id [ad_maybe_redirect_for_registration]

# ToDo: Add user permissions

set task_id $task(task_id)
set case_id $task(case_id)
set answer_id [db_string pid "select object_id from wf_cases where case_id = :case_id" -default ""]
set rfq_id [db_string rfq_id "select answer_rfq_id from im_freelance_rfq_answers where answer_id = :answer_id"]


# Get everything about the "Answer" and the RFQ
db_1row answer_info "
	select	a.*,
		r.*
	from	im_freelance_rfq_answers a,
		im_freelance_rfqs r
	where
		a.answer_id = :answer_id
		and a.answer_rfq_id = r.rfq_id
"

set action_url "/intranet-freelance-rfqs/new-rfq"
set form_mode "edit"

set page_title [lang::message::lookup "" intranet-freelance-rfqs.New_RFQ_Answer "New RFQ Answer"]
set context_bar [im_context_bar $page_title]


# ------------------------------------------------------------------
# Form Options
# ------------------------------------------------------------------

set freelance_rfq_overall_status_options [db_list_of_lists freelance_rfq_status "
	select	freelance_rfq_overall_status,
		freelance_rfq_overall_status_id
	from	im_freelance_rfq_overall_status
"]
set freelance_rfq_overall_status_options [linsert $freelance_rfq_overall_status_options 0 [list [lang::message::lookup "" "intranet-freelance-rfqs.--Select--" "-- Please Select --"] 0]]

set currency_options [im_currency_options]


set freelance_rfq_type_options [db_list_of_lists freelance_rfq_type "
	select	freelance_rfq_type, 
		freelance_rfq_type_id 
	from	im_freelance_rfq_type
"]
set freelance_rfq_type_options [linsert $freelance_rfq_type_options 0 [list [lang::message::lookup "" "intranet-freelance-rfqs.--Select--" "-- Please Select --"] 0]]

set freelance_rfq_status_options [db_list_of_lists freelance_rfq_status "
	select	freelance_rfq_status,
		freelance_rfq_status_id
	from	im_freelance_rfq_status
"]
set freelance_rfq_status_options [linsert $freelance_rfq_status_options 0 [list [lang::message::lookup "" "intranet-freelance-rfqs.--Select--" "-- Please Select --"] 0]]

set uom_options [im_cost_uom_options]

set workflow_key_options [db_list_of_lists freelance_rfq_status "
	select	workflow_key || ' - ' || description,
		workflow_key
	from
		wf_workflows
	where
		workflow_key like '%rfq%'
	order by
		workflow_key
"]
set workflow_key_options [linsert $workflow_key_options 0 [list [lang::message::lookup "" "intranet-freelance-rfqs.--Select--" "-- Please Select --"] 0]]


# ------------------------------------------------------------------
# Build the form
# ------------------------------------------------------------------

set form_id "freelance_rfq"
set focus "$form_id\.var_name"

ad_form \
    -name $form_id \
    -cancel_url $return_url \
    -has_edit 1 \
    -mode "display" \
    -export {project_id return_url} \
    -form {
        rfq_id:key
	{rfq_name:text(text) {label "[_ intranet-freelance-rfqs.Name]"} {html {size 40}}}
	{rfq_units:text(text) {label "[_ intranet-freelance-rfqs.Units]"} {html {size 6}}}
	{rfq_uom_id:text(select) 
	    {label "[_ intranet-freelance-rfqs.UoM]"}
	    {options $uom_options} 
	}
        {rfq_description:text(textarea),optional {label "[lang::message::lookup {} intranet-freelance-rfqs.Description Description]"} {html {cols 40}}}
        {rfq_note:text(textarea),optional {label "[lang::message::lookup {} intranet-freelance-rfqs.Note Note]"} {html {cols 40}}}
    }

ad_form -extend -name $form_id -select_query {
	select	*
	from	im_freelance_rfqs
	where	rfq_id = :rfq_id
}


set ttt {
	{workflow_key:text(select) 
	    {label "[_ intranet-freelance-rfqs.Workflow]"}
	    {options $workflow_key_options} 
	}
	{rfq_type_id:text(select) 
	    {label "[_ intranet-freelance-rfqs.RFQ_Type]"}
	    {options $freelance_rfq_type_options} 
	}
	{rfq_status_id:text(select) 
	    {label "[_ intranet-freelance-rfqs.RFQ_Status]"}
	    {options $freelance_rfq_status_options} 
	}
}

# ------------------------------------------------------------------
# Build the form
# ------------------------------------------------------------------

set form_id "freelance_rfq_answer"
set focus "$form_id\.var_name"

ad_form \
    -name $form_id \
    -cancel_url $return_url \
    -action $action_url \
    -mode $form_mode \
    -export {project_id return_url} \
    -form {
        answer_id:key
	{answer_status_id:text(hidden)}
	{answer_type_id:text(hidden)}
	{answer_overall_status_id:text(select)
            {label "[_ intranet-freelance-rfqs.Overall_Status]"}
            {options $freelance_rfq_overall_status_options}
        }

        {answer_amount:text(text) {label "[_ intranet-freelance-rfqs.Amount]"} {html {size 20}} }
        {answer_currency:text(select) {label "[_ intranet-freelance-rfqs.Currency]"} {options $currency_options} }

        {answer_start_date:date(date) {label "[_ intranet-freelance-rfqs.Start_date]"}}
        {answer_end_date:date(date) {label "[_ intranet-freelance-rfqs.End_date]"} {format "DD Month YYYY HH24:MI"} }

        {answer_note:text(textarea),optional {label "[lang::message::lookup {} intranet-freelance-rfqs.Note Note]"} {html {cols 40}}}
    }

# ------------------------------------------------------------------
# Form Actions
# ------------------------------------------------------------------

ad_form -extend -name $form_id -select_query {

	select	*
	from	im_freelance_rfqs
	where	rfq_id = :rfq_id

} -new_data {

    set rfq_id [db_string create_freelance_rfq "
	select im_freelance_rfq__new (
		null,
		'im_freelance_rfq',
		now(),
		:user_id,
		'[ad_conn peeraddr]',
		null,
		:rfq_name,
		:project_id,
		:rfq_type_id,
		:rfq_status_id
	)
    "]

    db_dml update_freelance_rfq "
	update im_freelance_rfqs set
		rfq_name = :rfq_name,
		workflow_key = :workflow_key,
		rfq_project_id = :project_id,
		rfq_status_id = :rfq_status_id,
		rfq_type_id = :rfq_type_id,
		num_units = :num_units,
		uom_units = :uom_units,
		description = :description,
		note = :note
	where rfq_id = :rfq_id
    "

} -edit_data {

    db_dml update_freelance_rfq "
	update im_freelance_rfqs set
		rfq_name = :rfq_name,
		workflow_key = :workflow_key,
		rfq_project_id = :project_id,
		rfq_status_id = :rfq_status_id,
		rfq_type_id = :rfq_type_id,
		num_units = :num_units,
		uom_units = :uom_units,
		description = :description,
		note = :note
	where rfq_id = :rfq_id
    "

} -on_submit {
    
    ns_log Notice "on_submit"
    
} -after_submit {

    ad_returnredirect $return_url
    ad_script_abort
}




