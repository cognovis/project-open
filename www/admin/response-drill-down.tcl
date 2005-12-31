ad_page_contract {

  Display the list of users who gave a particular answer to a
  particular question.

  @param   question_id  question for which we're drilling down responses
  @param   choice_id    we're seeking respondents who selected this choice
                        as an answer to question

  @author  philg@mit.edu
  @author  jsc@arsdigita.com
  @author  nstrug@arsdigita.com
  @creation-date    February 16, 2000
  @cvs-id  $Id$

} {

  question_id:integer,notnull
  choice_id:integer,notnull
  
}

ad_require_permission $question_id survsimp_admin_survey

# get the prompt text for the question and the ID for survey of 
# which it is part

set question_exists_p [db_0or1row get_question_text "
select survey_id, question_text
from survsimp_questions
where question_id = :question_id"]

if { !$question_exists_p }  {
    db_release_unused_handles
    ad_return_error "Survey Question Not Found" "Could not find a survey question #$question_id"
    return
}

set response_exists_p [db_0or1row get_response_text "
select label as response_text
from survsimp_question_choices
where choice_id = :choice_id"]

if { !$response_exists_p } {
    db_release_unused_handles
    ad_return_error "Response Not Found" "Could not find the response #$choice_id"
    return
}

set user_id [ad_get_user_id]

set survey_name [db_string survey_name "select name from survsimp_surveys where survey_id = :survey_id"]

set results ""

# Get information of users who responded in particular manner to
# choice question.
db_foreach all_users_for_response "
select
  first_names || ' ' || last_name as responder_name,
  person_id,
  creation_date
from
  acs_objects,
  survsimp_responses sr,
  persons u,
  survsimp_question_responses qr
where
  qr.response_id = sr.response_id
  and qr.response_id = object_id
  and creation_user = person_id
  and qr.question_id = :question_id
  and qr.choice_id = :choice_id" {

    append results "<li><a href=\"one-respondent?[export_url_vars user_id survey_id]\">$responder_name</a>\n"
}



doc_return 200 text/html "[ad_header "People who answered \"$response_text\""]

<h2>Responder List</h2>

[ad_context_bar [list "one?survey_id=$survey_id" "Administer Survey"] \
                     [list "responses?survey_id=$survey_id" "Responses"] \
                     "One Response"]

<hr>

$survey_name responders who answered \"$response_text\"
when asked \"$question_text\":

<ul>
$results
</ul>

[ad_footer]
"

