ad_page_contract {

    This page is used to edit the logic used by scored surveys to determine actions based on the score.

    @param   survey_id   integer denoting survey to edit

    @author  Nick Strugnell (nstrug@arsdigita.com)
    @creation-date    September 14, 2000
    @cvs-id  $Id$
} {

    survey_id:integer

}

ad_require_permission $survey_id survsimp_modify_survey

set exception_count 0
set exception_text ""

set type [db_string get_survey_type "select type from survsimp_surveys where survey_id = :survey_id"]
if { $type != "scored" } {
    incr exception_count
    append exception_text "<li>Only scored surveys have editable logic.\n"
}

if { $exception_count > 0 } {
    ad_return_complaint $exception_count $exception_text
}

# get the existing logic

set survey_name [db_string set_survey_name "select name from survsimp_surveys where survey_id = :survey_id"]

db_1row get_logic "select logic, survsimp_logic.logic_id from survsimp_logic, survsimp_logic_surveys_map
where survsimp_logic.logic_id = survsimp_logic_surveys_map.logic_id
and survey_id = :survey_id"

db_release_unused_handles

doc_return 200 text/html "[ad_header "Edit Survey Logic"]
<h2>$survey_name</h2>

[ad_context_bar [list "./" "Simple Survey Admin"] [list "one?[export_url_vars survey_id]" "Administer Survey"] "Edit Logic"]
    
<hr>

<form method=post action=\"edit-logic-2\">
[export_form_vars logic_id survey_id]
Logic:
<blockquote>
<textarea name=logic wrap=off rows=20 cols=65>$logic</textarea>
<p>
<center>
<input type=submit value=\"Continue\">
</center>
</form>
[ad_footer]
"

