ad_page_contract {

    Edit the name of the survey

    @param  survey_id  integer denoting survey whose description we're changing

    @author Jin Choi (jsc@arsdigita.com) 
    @author nstrug@arsdigita.com
    @creation-date   February 16, 2000
    @cvs-id $Id$
} {

    survey_id:integer

}

ad_require_permission $survey_id survsimp_modify_survey

db_1row survey_properties "select name as survey_name, description, description_html_p as desc_html
from survsimp_surveys
where survey_id = :survey_id"

set html_p_set [ns_set create]
ns_set put $html_p_set desc_html $desc_html

set context [list [list "one?[export_url_vars survey_id]" "Administer Survey"] "Edit Name"]


ad_return_template


