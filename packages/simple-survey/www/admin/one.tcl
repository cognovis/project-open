ad_page_contract {

    This page allows the admin to administer a single survey.

    @param  survey_id integer denoting survey we're administering

    @author jsc@arsdigita.com
    @author nstrug@arsdigita.com
    @creation-date   February 9, 2000
    @cvs-id $Id: one.tcl,v 1.2 2009/05/15 17:27:00 cvs Exp $
} {

    survey_id:integer

}

ad_require_permission $survey_id survsimp_admin_survey

set package_id [ad_conn package_id]

# Get the survey information.
db_1row survsimp_info "
select
	ss.name as survey_name, 
	ss.short_name, 
	ss.description as survey_description, 
	im_name_from_user_id(o.creation_user) as creator_name, 
	o.creation_user, 
	o.creation_date, 
	(case when enabled_p = 't' then 'Enabled' when enabled_p = 'f' then 'Disabled' end) as survey_status,
	(case when single_response_p = 't' then 'One' when single_response_p = 'f' then 'Multiple' end) as survey_response_limit,
	(case when single_editable_p = 't' then 'Editable' when single_editable_p = 'f' then 'Non-editable' end) as survey_editable_single, 
	ss.enabled_p,
	ss.type, 
	ss.display_type
from
	survsimp_surveys ss, 
	acs_objects o
where
	o.object_id = ss.survey_id
	and ss.survey_id = :survey_id
	and ss.package_id= :package_id
"

if {$survey_response_limit == "One"} {
    set response_limit_toggle "allow Multiple"
    if {$survey_editable_single == "Editable"} {
        set response_editable_link "| Editable: <a href=\"response-editable-toggle?[export_url_vars survey_id]\">make non-editable</a>"
    } else {
	set response_editable_link "| Non-editable: <a href=\"response-editable-toggle?[export_url_vars survey_id]\">make editable</a>"
    }
} else {
    set response_limit_toggle "limit to One"
    set response_editable_link ""
}

# allow site-wide admins to enable/disable surveys directly from here
set target "one?[export_url_vars survey_id]"
set toggle_enabled_link "\[ <a href=\"survey-toggle?[export_url_vars survey_id enabled_p target]\">"
if {$enabled_p == "t"} {
    append toggle_enabled_link "Disable"
} else {
    append toggle_enabled_link "Enable"
}
append toggle_enabled_link "</a> \]"

# Display Type (ben)
set display_type_toggle "\[ "
set d_count 0
foreach one_disp_type [survsimp_display_types] {
    if {$one_disp_type == $display_type} {
        continue
    }

    if {$d_count > 0} {
        append display_type_toggle " | "
    }

    incr d_count

    append display_type_toggle "<a href=survey-display-type-edit?survey_id=$survey_id&display_type=$one_disp_type>$one_disp_type</a>"
}

append display_type_toggle " \]"

set questions_summary "<form><ol>\n"
set count 0


# Questions summary.   

proc survey_specific_question_option_html { type survey_id question_id } {
    
    switch $type {
	"general" {
	    set return_html ""
	}
	"scored" {
	    set return_html "<a href=\"modify-responses?[export_url_vars survey_id question_id]\">modify responses</a>"
	}
	default {
	    set return_html ""
	}

	return $return_html
    }
}

db_foreach sursimp_survey_questions "select question_id, sort_key, active_p, required_p
from survsimp_questions
where survey_id = :survey_id  
order by sort_key" {


    set question_options [list "<a href=\"question-modify-text?[export_url_vars question_id survey_id]\">modify text</a>" "<a href=\"question-delete?question_id=$question_id\">delete</a>" "<a href=\"question-add?[export_url_vars survey_id]&after=$sort_key\">add new question</a>"]

    if { $count > 0 } {
	lappend question_options "<a href=\"question-swap?[export_url_vars survey_id sort_key]\">swap with prev</a>"
    }

    if {$active_p == "t"} {
	lappend question_options "Active: <a href=\"question-active-toggle?[export_url_vars survey_id question_id active_p]\">inactivate</a>"
	if {$required_p == "t"} {
	    lappend question_options "Response Required: <a href=\"question-required-toggle?[export_url_vars survey_id question_id required_p]\">don't require</a>"
	} else {
	    lappend question_options "Response Not Required: <a href=\"question-required-toggle?[export_url_vars survey_id question_id required_p]\">require</a>"
	}
    } else {
	lappend question_options "Inactive: <a href=\"question-active-toggle?[export_url_vars survey_id question_id active_p]\">activate</a>"
    }

    lappend question_options [survey_specific_question_option_html $type $survey_id $question_id]

    append questions_summary "
<li>[survsimp_question_display $question_id]
<br>
<font size=-1>
\[ [join $question_options " | "] \]
</font>

<p>"
    incr count
}  

if {$count == 0} {
    append questions_summary "<p><a href=\"question-add?survey_id=$survey_id\">Add a question</a>\n"
}

append questions_summary "</ol></form>\n"

proc survey_specific_html { type } {

    switch $type {
	"general" {
	    set return_html ""
	}

	"scored" {
	    upvar survey_id local_survey_id
	    set return_html "<li><a href=\"edit-logic?survey_id=$local_survey_id\">Edit survey logic</a>"
	}

	default {
	    set return_html ""
	}

	return $return_html
    }
}


set context [list "Administer Survey"]
set survey_specific_html [survey_specific_html $type]

ad_return_template
