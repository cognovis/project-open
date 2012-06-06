# /www/survsimp/admin/question-delete.tcl
ad_page_contract {

  Delete a question from a survey, along with all responses.

  @param  question_id     question we're deleting
  @author jsc@arsdigita.com
  @creation-date   March 13, 2000
  @cvs-id $Id$
} {

    question_id:integer

}

ad_require_permission $question_id survsimp_delete_question

set user_id [ad_get_user_id]

set survey_id [db_string survsimp_survey_id_from_question_id "select survey_id from survsimp_questions where question_id = :question_id" ]
survsimp_survey_admin_check $user_id $survey_id

db_transaction {
    db_dml survsimp_question_responses_delete "delete from survsimp_question_responses where question_id = :question_id" 

db_dml survsimp_question_choices_score_delete "delete from survsimp_choice_scores where choice_id in (select choice_id from survsimp_question_choices
          where question_id = :question_id)"

    db_dml survsimp_question_choices_delete "delete from survsimp_question_choices where question_id = :question_id" 

    db_dml survsimp_questions_delete "delete from survsimp_questions where question_id = :question_id" 

} on_error {
    ad_return_error "Database Error" "There was an error while trying to delete the question:
        <pre>
        $errmsg
        </pre>
        <p> Please go back to the <a href=\"one?survey_id=$survey_id\">survey</a>.
        "
ad_script_abort
}

db_release_unused_handles
ad_returnredirect "one?survey_id=$survey_id"

