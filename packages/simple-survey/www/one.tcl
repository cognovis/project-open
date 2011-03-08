
# Is this page called as part of a workflow panel?
if {![info exists task]} {

    # Skip if this page is called as part of a Workflow panel
    ad_page_contract {

	Display a questionnaire for one survey.
	
	@param  survey_id   id of displayed survey
	
	@author philg@mit.edu
	@author nstrug@arsdigita.com
	@creation-date   28th September 2000
	@cvs-id $Id: one.tcl,v 1.4 2010/06/04 15:46:51 po34demo Exp $
	
    } {
	survey_id:integer,notnull
	{ related_object_id:integer "" }
	{ related_context_id:integer "" }
	return_url:optional
	{ message "" }
	{ project_id 0 }
	
    } -validate {
	survey_exists -requires {survey_id} {
	    if ![db_0or1row survey_exists {
		select 1 from survsimp_surveys where survey_id = :survey_id
	    }] {
		ad_complain "Survey $survey_id does not exist"
	    }
	}
    } -properties {
	name:onerow
	survey_id:onerow
	button_label:onerow
	questions:onerow
	description:onerow
	modification_allowed_p:onerow
	return_url:onerow
    }

    # Enable the normal ]po[ master template.
    # Queried in the one.adp page
    set enable_master_p 1
    
} else {

    # Yes, we are running as part of a WF
    set task_id $task(task_id)
    set case_id $task(case_id)
    set workflow_key $task(workflow_key)
    set transition_key $task(transition_key)

    # Determine the business object of the WF
    # This is usally a im_project, but could be different.
    set related_object_id [db_string pid "select object_id from wf_cases where case_id = :case_id" -default ""]
    # The "related context" is not used. It could be another business object.
    set related_context_id ""
    # Deprecated
    set project_id 0
    if {![info exists return_url]} { set return_url [im_url_with_query] }
    set message ""

    # Determine the simple-survey from the "Header" of the panel.
    # This is not the intended use of the "Header", but comes in very handy.
    set wf_panel_header [db_string panel_header "
	select	header
	from	wf_context_task_panels
	where	workflow_key = :workflow_key and
		transition_key = :transition_key
    " -default ""]
    # Check for a survey with the given name:
    set survey_id [db_string survey "
	select	survey_id
	from	survsimp_surveys
	where	name = :wf_panel_header
    " -default 0]
    if {0 == $survey_id} {
	ad_return_complaint 1 "<b>Didn't find survey '$wf_panel_header'</b>:
	<br>&nbsp;<br>
	This page uses the 'Panel Header' of a workflow panel to identify the
	simple survey to present to the user.<br>
	Please edit your workflow's Panel definition and choose as the header
	for this transition the name of an existing Simple Survey.<br>
	You can setup new Simple Surveys in Admin -&gt; Simple Survey.<br>"
	ad_script_abort
    }

    # Disable the normal ]po[ master template
    # Queried in the one.adp page
    set enable_master_p 0

}


ad_require_permission $survey_id survsimp_take_survey

set user_id [ad_maybe_redirect_for_registration]

set package_url "/simple-survey"

db_1row survey_info "select name, description, single_response_p, single_editable_p, display_type
    from survsimp_surveys where survey_id = :survey_id"

set context [list [list "./" "Surveys"] "$name"]

set num_responses [db_string responses_count {
    select count(response_id)
    from survsimp_responses, acs_objects
    where response_id = object_id
    and creation_user = :user_id
    and survey_id = :survey_id
}]

if {$single_response_p == "t"} {
    if {$num_responses == "0"} {
	set button_label "Submit response"
	set edit_previous_response_p "f"
    } else {
	set button_label "Modify submited response"
	set edit_previous_response_p "t"
    }
    set previous_responses_link ""
} else {
    set button_label "Submit response"
    set edit_previous_response_p "f"
    if {$num_responses == "0"} {
        set previous_response_p "f"
    } else {
	set previous_response_p "t"
    }
}

if {$single_response_p == "t" && $single_editable_p == "f"} {
    set modification_allowed_p "f"
} else {
    set modification_allowed_p "t"
}

# build a list containing the HTML (generated with survsimp_question_display) for each question
set rownum 0

set questions [list]

db_foreach question_ids_select {
    select question_id
    from survsimp_questions  
    where survey_id = :survey_id
    and active_p = 't'
    order by sort_key
} {
    lappend questions [survsimp_question_display $question_id $edit_previous_response_p]
}

# return_url is used for infoshare - if it is set
# the survey will return to it rather than
# executing the survey associated with the logic
# after the survey is completed
#
if ![info exists return_url] {
    set return_url {}
}

set project_menu ""

if {0 != $project_id} {
    set menu_label "project_summary"
    set bind_vars [ns_set create]
    ns_set put $bind_vars project_id $project_id
    set parent_menu_id [db_string parent_menu "select menu_id from im_menus where label='project'" -default 0]
    set project_menu [im_sub_navbar $parent_menu_id $bind_vars "" "pagedesriptionbar" $menu_label]
}

