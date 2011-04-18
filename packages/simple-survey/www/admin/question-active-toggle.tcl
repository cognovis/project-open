# /www/survsimp/admin/question-active-toggle.tcl
ad_page_contract {

    Toggles if a response to required for a given question.

    @param  survey_id    survey we're operating with
    @param  question_id  denotes which question in survey we're updating

    @cvs-id $Id: question-active-toggle.tcl,v 1.1.1.1 2005/12/31 23:52:30 cvs Exp $
} {

    survey_id:integer
    question_id:integer

}

ad_require_permission $survey_id survsimp_admin_survey

db_dml survsimp_question_required_toggle "update survsimp_questions set active_p = util.logical_negation(active_p)
where survey_id = :survey_id
and question_id = :question_id"

db_release_unused_handles
ad_returnredirect "one?[export_url_vars survey_id]"

