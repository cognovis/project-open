# /www/survsimp/admin/response-limit-toggle.tcl
ad_page_contract {

    Toggles a survey between allowing multiple responses or one response per user.

    @param survey_id survey whose properties we're changing

    @cvs-id $Id$

} {

    survey_id:integer

}

ad_require_permission $survey_id survsimp_admin_survey

db_dml survsimp_reponse_toggle "update survsimp_surveys 
set single_response_p = util.logical_negation(single_response_p)
where survey_id = :survey_id"

db_release_unused_handles
ad_returnredirect "one?[export_url_vars survey_id]"
