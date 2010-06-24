ad_page_contract {

    Display one filled-out survey.

    @param  response_id		ID of the response to show

    @author jsc@arsdigita.com
    @author nstrug@arsdigita.com
    @author fraber@fraber.de
    @creation-date   February 11, 2000
    @cvs-id $Id$
} {
    response_id:integer
} 

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
    return
}

ad_require_permission $survey_id survsimp_admin_survey


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
