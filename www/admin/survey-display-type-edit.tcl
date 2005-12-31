ad_page_contract {

    Set the display type

    @param survey_id survey whose properties we're changing
    @cvs-id $Id$

} {
    survey_id:integer
    display_type:notnull
}

ad_require_permission $survey_id survsimp_admin_survey

if {[lsearch [survsimp_display_types] $display_type] > -1} {
    db_dml survsimp_display_type_edit "update survsimp_surveys 
set display_type= :display_type
where survey_id = :survey_id"
}

db_release_unused_handles
ad_returnredirect "one?[export_url_vars survey_id]"
