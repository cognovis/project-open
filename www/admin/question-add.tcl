ad_page_contract {
    Present form to begin adding a question to a survey.
    Lets user enter the question and select a presentation type.

    @param survey_id    integer designating survey we're adding question to
    @param after        optinal integer denoting position of question within survey

    @author  jsc@arsdigita.com
    @author  nstrug@arsdigita.com
    @creation-date    February 9, 2000
    @cvs-id $Id$
} {
    survey_id:integer
    {after:integer ""}
}

set package_id [ad_conn package_id]
set user_id [ad_get_user_id]
ad_require_permission $package_id survsimp_create_question

db_1row simpsurv_survey_properties "select name, description, type
from survsimp_surveys
where survey_id = :survey_id" 

# function to insert survey type-specific form html

proc survey_specific_html { type } {
    switch $type {

	"general" {
	    set return_html "
Response Presentation:
<select name=\"presentation_type\">
<option value=\"textbox\">One Line Answer (Text Field)</option>
<option value=\"textarea\">Essay Answer (Text Area)</option>
<option value=\"select\">Multiple Choice (Drop Down)</option>
<option value=\"radio\">Multiple Choice (Radio Buttons)</option>
<option value=\"checkbox\">Multiple Choice (Checkbox)</option>
<option value=\"date\">Date</option>
<!-- Removed by gwong@orchardlabs.com because this option was not supported
in the original code.
<option value=\"upload_file\">File Attachment</option>
-->
</select>
<p>"
	}
	
	"scored" {

# scored surveys always use radio buttons (for the time being) - we just need to know the number of desired responses
	    
	    set return_html "
Response Presentation:
<select name=\"presentation_type\">
<option value=\"radio\">Radio Buttons (single choice only)</option>
<option value=\"checkbox\">Checkbox (multiple choices allowed)</option>
</select>
<p>
Number of possible responses? <input type=text name=\"n_responses\" value=2 size=2>
"
	}

	default {
	    set return_html ""
	}
    }
    return $return_html
}

set context [list [list "one?[export_url_vars survey_id]" "Administer Survey"] "Add A Question"]
