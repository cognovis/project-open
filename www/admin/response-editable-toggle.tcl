ad_page_contract {

    Toggles a survey between allowing a user to
    edit to or not.

    @param  survey_id survey we're dealing with

    @author Jin Choi (jsc@arsdigita.com)
    @author nstrug@arsdigita.com
    @cvs-id $Id$
} {

    survey_id:integer

}

ad_require_permission $survey_id survsimp_admin_survey

db_dml survsimp_response_editable_toggle "update survsimp_surveys set single_editable_p = util.logical_negation(single_editable_p)
where survey_id = :survey_id"

db_release_unused_handles
ad_returnredirect "one?[export_url_vars survey_id]"
