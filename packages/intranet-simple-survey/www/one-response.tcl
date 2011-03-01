ad_page_contract {

    Display one filled-out survey.

    @param  response_id		ID of the response to show

    @author jsc@arsdigita.com
    @author nstrug@arsdigita.com
    @author fraber@fraber.de
    @creation-date   February 11, 2000
    @cvs-id $Id: one-response.tcl,v 1.2 2010/06/30 14:04:25 po34demo Exp $
} {
    response_id:integer
} 

set current_user_id [ad_maybe_redirect_for_registration]

# -----------------------------------------------------------------
# Basic survey information and security

set survey_exists_p [db_0or1row response_info "
	select	sr.*,
		ss.name as survey_name,
		ss.description,
		ss.type,
		o.creation_user,
		im_name_from_user_id(o.creation_user) as creation_user_pretty,
		to_char(o.creation_date, 'YYYY-MM-DD') as creation_date_pretty
	from	survsimp_responses sr,
		survsimp_surveys ss,
		acs_objects o
	where	sr.survey_id = ss.survey_id and
		sr.response_id = o.object_id and
		response_id = :response_id
"]

if {!$survey_exists_p} {
    ad_return_error "Not Found" "Could not find survey #$survey_id"
    ad_script_abort
}


# -----------------------------------------------------------------
# Permissions

if {"" == $related_object_id} {

    # This is a survey response not related to a ]po[
    # object, so use the standard SurvSimp permissions:
    ad_require_permission $survey_id survsimp_admin_survey

} else {

    # This survey response is related to a ]po[ objects.
    # Check if the current user can read this object:

    # Default permissions
    set object_view 0
    set object_read 0
    set object_write 0
    set object_admin 0

    catch {
	set object_type [db_string acs_object_type "select object_type from acs_objects where object_id = :related_object_id"]
	set perm_cmd "${object_type}_permissions \$current_user_id \$related_object_id object_view object_read object_write object_admin"
	eval $perm_cmd
    } err_msg

    if {!$object_read} {
	ad_return_complaint 1 "<li>[_ intranet-core.lt_You_have_insufficient_6]"
	ad_script_abort
    }
}


# -----------------------------------------------------------------
# Title & Defaults

set page_title [lang::message::lookup "" intranet-simple-survey.One_Response "One Response"]
set context_bar [ad_context_bar [list "" "Simple Survey Admin"] \
	     [list "one?survey_id=$survey_id" "Administer Survey"] \
	     [list "respondents?survey_id=$survey_id" "Respondents"] \
             "One Respondent"]
set context ""

set sub_navbar ""
set left_navbar_html ""
set show_context_help_p 0
set main_navbar_label "reporting"

set user_url "/intranet/users/view?user_id="

# -----------------------------------------------------------------
# function to format survey type-specific html

proc survey_specific_html { type response_id } {
    switch $type {
	"general" {
	    set return_html ""
	}
	"scored" {
	    set return_html "<table border=0 align=center>\n<tr><th>Variable</th><th>Score</th>\n"
	    db_foreach get_survey_scores "select variable_name, sum(score) as sum_score
	      from survsimp_choice_scores, survsimp_question_responses, survsimp_variables
	      where survsimp_choice_scores.choice_id = survsimp_question_responses.choice_id
	      and survsimp_choice_scores.variable_id = survsimp_variables.variable_id
	      and survsimp_question_responses.response_id = :response_id
	      group by variable_name" {
		  append return_html "<tr><th>$variable_name</th><td align=center>$sum_score</td></tr>\n"
	      }
	    append return_html "</table>\n"
	}
	default {
	    set return_html ""
	}
    }
    return $return_html
}


# -----------------------------------------------------------------
# Format responses

set html "
	<b>Filled out by</b><br>
	<a href='$user_url$creation_user'>$creation_user_pretty</a><br>

	<b>Date</b><br>
	$creation_date_pretty<br>

	[survey_specific_html $type $response_id]

	[survsimp_answer_summary_display $response_id 1]
"
