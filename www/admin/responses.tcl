ad_page_contract {

    View summary of all responses to one survey.

    @param   survey_id       survey for which we're building list of responses
    @param   unique_users_p  whether we will display only latest response for each user

    @author  jsc@arsdigita.com
    @author  nstrug@arsdigita.com
    @creation-date    February 11, 2000
    @cvs-id  $Id$
} {

    survey_id:integer
    {unique_users_p "f"}

}

ad_require_permission $survey_id survsimp_admin_survey

set user_id [ad_get_user_id]

# nstrug - 12/9/2000
# Summarise scored responses for all users

set type [db_string survey_name "select type
  from survsimp_surveys
  where survey_id = :survey_id"]

proc survey_specific_html { type } {
    switch $type {

	"general" {
	    set return_html ""
	}

	"scored" {
	    
	    upvar survey_id local_survey_id
	    set return_html "<h3>Scored Survey Statistics</h3>
<table border=0 align=center>
<tr><th>Variable</th><th>Mean</th><th>Min</th><th>Max</th><th>Sample SD</th><th>Count</th></tr>
"
	    db_foreach get_survey_scores_summary "select variable_name, to_char(avg(sum_score), '9999.9') as mean_score,
                                          min(sum_score) as min_score,
                                          max(sum_score) as max_score,
                                          count(sum_score) as count_score,
                                          nvl(to_char(stddev_samp(sum_score), '9999.9'), '0.0') as sd_score                                           
                                          from
                                          (select variable_name, sum(score) as sum_score
	                                    from survsimp_choice_scores, survsimp_question_responses, survsimp_variables,
                                            survsimp_responses
                                            where survsimp_choice_scores.choice_id = survsimp_question_responses.choice_id
                                            and survsimp_choice_scores.variable_id = survsimp_variables.variable_id
                                            and survsimp_responses.response_id = survsimp_question_responses.response_id
                                            and survey_id = :local_survey_id
                                            group by survsimp_responses.response_id, variable_name)
                                          group by variable_name" {
					      append return_html "<tr><th>$variable_name</th><td align=center>$mean_score</td><td align=center>$min_score</td><td align=center>$max_score</td><td align=center>$sd_score</td><td>$count_score</td></tr>\n"
					  }

	    append return_html "</table>\n"
	}

	default {
	    set return_html ""
	}
    }

    return $return_html
}


# mbryzek - 3/27/2000
# We need a way to limit the summary page to 1 response from 
# each user. We use views to select out only the latest response
# from any given user

if { [string compare $unique_users_p "t"] == 0 } {
    set responses_table "survsimp_responses_unique"
    set question_responses_table "survsimp_question_responses_un"
    set unique_users_toggle " <a href=responses?[export_ns_set_vars url [list unique_users_p]]>View all responses</a> | <b>View responses from distinct users</b> "
} else {
    set responses_table "survsimp_responses"
    set question_responses_table "survsimp_question_responses"
    set unique_users_toggle " <b>View all responses</b> | <a href=responses?unique_users_p=t&[export_ns_set_vars url [list unique_users_p]]>View responses from distinct users</a> "
}

set results ""

db_foreach survsimp_survey_question_list "select question_id, question_text, abstract_data_type
from survsimp_questions
where survey_id = :survey_id
order by sort_key" {
    append results "<li>$question_text
<blockquote>
"
    switch -- $abstract_data_type {
	"date" -
	"text" -
	"shorttext" {
	    append results "<a href=\"view-text-responses?question_id=$question_id\">View responses</a>\n"
	}
	
	"boolean" {

	    db_foreach survsimp_boolean_summary "select count(*) as n_responses, decode(boolean_answer, 't', 'True', 'f', 'False') as boolean_answer
from $question_responses_table
where question_id = :question_id
group by boolean_answer
order by boolean_answer desc" { 
		append results "$boolean_answer: $n_responses<br>\n"
	    }
	}
	"integer" {}
	"number" {
	    db_foreach survsimp_number_summary "select count(*) as n_responses, number_answer
from $question_responses_table
where question_id = :question_id
group by number_answer
order by number_answer" {
		append results "$number_answer: $n_responses<br>\n"
            }
	    db_1row survsimp_number_average "select avg(number_answer) as mean, stddev(number_answer) as standard_deviation
from $question_responses_table
where question_id = :question_id" {
         append results "<p>Mean: $mean<br>Standard Dev: $standard_deviation<br>\n"
            }
	}
	"choice" {
	    db_foreach survsimp_survey_question_choices "select count(*) as n_responses, label, qc.choice_id
from $question_responses_table qr, survsimp_question_choices qc
where qr.choice_id = qc.choice_id
  and qr.question_id = :question_id
group by label, sort_order, qc.choice_id
order by sort_order" {
             append results "$label: <a href=\"response-drill-down?[export_url_vars question_id choice_id]\">$n_responses</a><br>\n"
             }
	 }
    }
    append results "</blockquote>\n"
}
 
set survey_name [db_string survey_name "select name as survey_name
from survsimp_surveys
where survey_id = :survey_id"]

set n_responses [db_string survsimp_number_responses "select count(*)
from $responses_table
where survey_id = :survey_id" ]

if { $n_responses == 1 } {
    set response_sentence "There has been 1 response."
} else {
    if { [string compare $unique_users_p "t"] == 0 } {
	set response_sentence "$n_responses distinct users have responded."
    } else {
	set response_sentence "There have been $n_responses responses."
    }
}

set context [list [list "one?survey_id=$survey_id" "Administer Survey"] \
     "Responses"]

