ad_page_contract {

    Allow the user to modify the text of a question.

    @param   survey_id   survey this question belongs to
    @param   question_id question which text we're changing

    @author  cmceniry@arsdigita.com
    @author  nstrug@arsdigita.com
    @creation-date    Jun 16, 2000
    @cvs-id  $Id$
} {

    question_id:integer
    survey_id:integer

}

ad_require_permission $survey_id survsimp_modify_question

set survey_name [db_string survey_name_from_id "select name from survsimp_surveys where survey_id=:survey_id" ]

set question_text [db_string survsimp_question_text_from_id "select question_text
from survsimp_questions
where question_id = :question_id" ]

set context [list [list "one?[export_url_vars survey_id]" "Administer Survey"] "Modify a Question's Text"]
