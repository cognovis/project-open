# /packages/intranet-freelance-rfqs/www/new-rfq.tcl
#
# Copyright (c) 2003-2007 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

# ---------------------------------------------------------------
# 1. Page Contract
# ---------------------------------------------------------------
ad_page_contract { 
    Add / edit freelance-rfqs in project
    @param project_id
} {
    rfq_id:integer,optional
    { rfq_project_id:integer "" }
    return_url
    { form_mode "edit"}
    { rfq_status_id "[im_freelance_rfq_status_open]" }
    { rfq_type_id "[im_freelance_rfq_type_rfa]" }
    { uom_units 324 }
    { rfq_start_date "" }
    { rfq_end_date "" }
}

# ------------------------------------------------------------------
# Default & Security
# ------------------------------------------------------------------

set user_id [ad_maybe_redirect_for_registration]
if {![im_permission $user_id "add_freelance_rfqs"]} {
    ad_return_complaint 1 "[_ intranet-timesheet2-invoices.lt_You_have_insufficient_1]"
    return
}

set page_title [lang::message::lookup "" intranet-freelance-rfqs.New_Freelance_RFQ "New Freelance-RFQs"]
set context_bar [im_context_bar $page_title]
set action_url "/intranet-freelance-rfqs/new-rfq"
set todays_date [lindex [split [ns_localsqltimestamp] " "] 0]
set todays_time [lindex [split [ns_localsqltimestamp] " "] 1]


# ------------------------------------------------------------------
# Form Options
# ------------------------------------------------------------------


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

set freelance_rfq_project_options [im_project_options -exclude_status_id [im_project_status_closed] -project_id $rfq_project_id]

# ------------------------------------------------------------------
# Build the form
# ------------------------------------------------------------------

set form_id "freelance_rfq"
set focus "$form_id\.var_name"

ad_form \
    -name $form_id \
    -cancel_url $return_url \
    -action $action_url \
    -mode $form_mode \
    -export {return_url} \
    -form {
        rfq_id:key
	{rfq_name:text(text) {label "[_ intranet-freelance-rfqs.Name]"} {html {size 40}}}
	{rfq_project_id:text(select) 
	    {label "[_ intranet-core.Project]"}
	    {options $freelance_rfq_project_options} 
	}
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

	{rfq_units:text(text),optional {label "[_ intranet-freelance-rfqs.Units]"} {html {size 6}}}
	{rfq_uom_id:text(select) 
	    {label "[_ intranet-freelance-rfqs.UoM]"}
	    {options $uom_options} 
	}
    }


im_dynfield::append_attributes_to_form \
    -object_type "im_freelance_rfq" \
    -object_subtype_id $rfq_type_id \
    -form_id $form_id \
    -form_display_mode "edit"


ad_form -extend -name $form_id -form {
        {rfq_description:text(textarea),optional {label "[lang::message::lookup {} intranet-freelance-rfqs.Description Description]"} {html {cols 40}}}
        {rfq_note:text(textarea),optional {label "[lang::message::lookup {} intranet-freelance-rfqs.Note Note]"} {html {cols 40}}}
    }


# ------------------------------------------------------------------
# Form Actions
# ------------------------------------------------------------------


ad_form -extend -name $form_id -on_request {

    # Populate elements from local variables


} -select_query {

	select	*,
		to_char(rfq_start_date, 'YYYY MM DD') as rfq_start_date,
		to_char(rfq_end_date, 'YYYY MM DD HH24 MI') as rfq_end_date
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
		:rfq_project_id,
		:rfq_type_id,
		:rfq_status_id
	)
    "]

    set rfq_end_date [template::util::date get_property sql_timestamp $rfq_end_date]
    set rfq_start_date [template::util::date get_property sql_timestamp $rfq_start_date]

    db_dml update_freelance_rfq "
	update im_freelance_rfqs set
		rfq_name = :rfq_name,
		rfq_project_id = :rfq_project_id,
		rfq_status_id = :rfq_status_id,
		rfq_type_id = :rfq_type_id,
		rfq_start_date = $rfq_start_date,
		rfq_end_date = $rfq_end_date,
		rfq_units = :rfq_units,
		rfq_uom_id = :rfq_uom_id,
		rfq_description = :rfq_description,
		rfq_note = :rfq_note
	where rfq_id = :rfq_id
    "

    im_dynfield::attribute_store \
        -object_type "im_freelance_rfq" \
        -object_id $rfq_id \
        -form_id $form_id


    # Add Source Language
    set source_language_id [db_string slid "select source_language_id from im_projects where project_id = :rfq_project_id" -default ""]
    if {"" != $source_language_id} {
	set exists_p [db_string count "
	        select  count(*)
	        from    im_object_freelance_skill_map
	        where   object_id = :rfq_id
	                and skill_type_id = [im_freelance_skill_type_source_language]
	                and skill_id = :source_language_id
	"]
	if {!$exists_p} {
	    db_dml insert "
	        insert into im_object_freelance_skill_map (
	                object_skill_map_id, 
			object_id, skill_type_id, skill_id,
	                experience_id, skill_weight, skill_required_p
	        ) values (
	                nextval('im_object_freelance_skill_seq'),
	                :rfq_id, [im_freelance_skill_type_source_language], :source_language_id,
	                [im_freelance_experience_level_unconfirmed], 10, 't'
	        )
	    "
	}
    }


    # Add Sugject Area
    set subject_area_id [db_string slid "select subject_area_id from im_projects where project_id = :rfq_project_id" -default ""]
    if {"" != $subject_area_id} {
	set exists_p [db_string count "
	        select  count(*)
	        from    im_object_freelance_skill_map
	        where   object_id = :rfq_id
	                and skill_type_id = [im_freelance_skill_type_subject_area]
	                and skill_id = :subject_area_id
	"]
	if {!$exists_p} {
	    db_dml insert "
	        insert into im_object_freelance_skill_map (
	                object_skill_map_id, 
			object_id, skill_type_id, skill_id,
	                experience_id, skill_weight, skill_required_p
	        ) values (
	                nextval('im_object_freelance_skill_seq'),
	                :rfq_id, [im_freelance_skill_type_subject_area], :subject_area_id,
	                null, 10, 't'
	        )
	    "
	}
    }


    # Add Target Languages
    set target_language_ids [db_list tlid "
	select	language_id 
	from	im_target_languages
	where	project_id = :rfq_project_id
    "]
    foreach target_language_id $target_language_ids {

	set exists_p [db_string count "
	        select  count(*)
	        from    im_object_freelance_skill_map
	        where   object_id = :rfq_id
	                and skill_type_id = [im_freelance_skill_type_target_language]
	                and skill_id = :target_language_id
	"]
	if {!$exists_p} {
	    db_dml insert "
	        insert into im_object_freelance_skill_map (
	                object_skill_map_id, 
			object_id, skill_type_id, skill_id,
	                experience_id, skill_weight, skill_required_p
	        ) values (
	                nextval('im_object_freelance_skill_seq'),
	                :rfq_id, [im_freelance_skill_type_target_language], :target_language_id,
	                null, 10, 't'
	        )
	    "
	}
    }



} -edit_data {

    set rfq_end_date [template::util::date get_property sql_timestamp $rfq_end_date]
    set rfq_start_date [template::util::date get_property sql_timestamp $rfq_start_date]

    db_dml update_freelance_rfq "
	update im_freelance_rfqs set
		rfq_name = :rfq_name,
		rfq_project_id = :rfq_project_id,
		rfq_status_id = :rfq_status_id,
		rfq_type_id = :rfq_type_id,
		rfq_start_date = $rfq_start_date,
		rfq_end_date = $rfq_end_date,
		rfq_units = :rfq_units,
		rfq_uom_id = :rfq_uom_id,
		rfq_description = :rfq_description,
		rfq_note = :rfq_note
	where rfq_id = :rfq_id
    "

    im_dynfield::attribute_store \
        -object_type "im_freelance_rfq" \
        -object_id $rfq_id \
        -form_id $form_id


} -on_submit {
    
    ns_log Notice "on_submit"
    
} -after_submit {

    set next_url [export_vars -base "view-rfq" {return_url rfq_id}]
    ad_returnredirect $next_url
    ad_script_abort
}


# Set default values for start and end date - if form is ""
if {"" == [template::element::get_value $form_id rfq_start_date]} {
    set start_date_list [split $todays_date "-"]
    set start_date_list [concat $start_date_list [split $todays_time ":"]]
    template::element::set_value $form_id rfq_start_date $start_date_list
}

if {"" == [template::element::get_value $form_id rfq_end_date]} {
    set end_date_list [split $todays_date "-"]
    set end_date_list [concat $end_date_list [split $todays_time ":"]]
    template::element::set_value $form_id rfq_end_date $end_date_list
}
    
