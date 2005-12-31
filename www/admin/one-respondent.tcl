ad_page_contract {

    Display the filled-out survey for a single user.

    @param  user_id    user whose response we're viewing
    @param  survey_id  survey we're viewing
    @author jsc@arsdigita.com
    @author nstrug@arsdigita.com
    @creation-date   February 11, 2000
    @cvs-id $Id$
} {

    user_id:integer
    survey_id:integer

} 

ad_require_permission $survey_id survsimp_admin_survey

set survey_exists_p [db_0or1row survsimp_survey_properties "select name as survey_name, description, type
from survsimp_surveys
where survey_id = :survey_id" ]

if { !$survey_exists_p } {
    ad_return_error "Not Found" "Could not find survey #$survey_id"
    return
}

# survey_name and description are now set 

set user_exists_p [db_0or1row user_name_from_id "select first_names, last_name from persons where person_id = :user_id" ]

if { !$user_exists_p } {
    ad_return_error "Not Found" "Could not find user #$user_id"
    return
}


set whole_page "[ad_header "Response from $first_names $last_name"]

<h2>Response from $first_names $last_name</h2>

[ad_context_bar [list "" "Simple Survey Admin"] \
     [list "one?survey_id=$survey_id" "Administer Survey"] \
     [list "respondents?survey_id=$survey_id" "Respondents"] \
                     "One Respondent"]

<hr>

Here is what <a href=\"/shared/community-member?[export_url_vars user_id]\">$first_names $last_name</a> had to say in response to $survey_name:

<p>

"

# now we have to query Oracle to find out what the questions are and
# how to present them

set response_id_date_list [db_list_of_lists survsimp_survey_response_dates_for_users "select response_id, creation_date 
from survsimp_responses, acs_objects
where response_id = object_id
and creation_user = :user_id
and survey_id = :survey_id
order by creation_date desc" ]

# function to insert survey type-specific form html

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

if { ![empty_string_p $response_id_date_list] } {

    foreach response_id_date $response_id_date_list {

	append whole_page "<h3>Response on [lindex $response_id_date 1]</h3>\n"

	set response_id [lindex $response_id_date 0]
	append whole_page [survey_specific_html $type $response_id]
	append whole_page "[survsimp_answer_summary_display $response_id 1 ]
<hr width=50%>"
	}
}




doc_return 200 text/html "$whole_page  

[ad_footer]"
