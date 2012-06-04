# /www/survsimp/admin/description-edit-2.tcl
ad_page_contract {
    Updates database with the new name
    information and return user to the main survey page.

    @param survey_id       survey which description we're updating
    @param desc_html       is the description html or plain text
    @param description     text of survey description
    @param checked_p       confirmation flag

    @author jsc@arsdigita.com
    @author nstrug@arsdigita.com
    @creation-date   February 16, 2000
    @cvs-id $Id$
} {
    survey_id:integer
    name:trim,notnull
}

ad_require_permission $survey_id survsimp_modify_survey

set exception_count 0
set exception_text ""

db_dml survsimp_update_name "update survsimp_surveys 
set name= :name, short_name= :name
where survey_id = :survey_id"

ad_returnredirect "one?[export_url_vars survey_id]"


