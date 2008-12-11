ad_page_contract {

    Display a questionnaire for one survey.

    @param  survey_id   id of displayed survey

    @author philg@mit.edu
    @author nstrug@arsdigita.com
    @creation-date   28th September 2000
    @cvs-id $Id$

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

ad_require_permission $survey_id survsimp_take_survey

set user_id [ad_maybe_redirect_for_registration]

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

