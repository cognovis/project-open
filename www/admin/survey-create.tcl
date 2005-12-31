# /www/survsimp/admin/survey-create.tcl
ad_page_contract {

  Form for creating a survey.

  @param  name         title for new survey
  @param  short_name   tag for new survey
  @param  description  description for new survey

  @author raj@alum.mit.edu
  @author nstrug@arsdigita.com
  @creation-date   February 9, 2000
  @cvs-id $Id$

} {

    {name ""}
    {short_name ""}
    {description:html ""}
    {variable_names ""}
    {type "general"}
}

set package_id [ad_conn package_id]

# bounce the user if they don't have permission to admin surveys
ad_require_permission $package_id survsimp_create_survey

# validate input

set exception_count 0
set exception_text ""

if { $type != "general" && $type != "scored" } {
    incr exception_count
    append exception_text "<li>Surveys of type $type are not currently available.\n"
}

if { $exception_count > 0 } {
    ad_return_complaint $exception_count $exception_text
}

# function to insert survey type-specific form html

proc survey_specific_html { type } {
    switch $type {

        "general" {
	    set return_html ""
        }

	"scored" {
	    upvar variable_names local_variable_names
	    set return_html "

Survey variable names (comma-separated list):
<br>
<input type=text name=variable_names value=\"$local_variable_names\" size=65>
<p>
TCL code for survey logic e.g. to direct users to a particular page based on their score. Total scores
are available in a hash, ad_page_contract, keyed on the survey variable names.
<br>
<textarea name=logic wrap=off rows=20 cols=65></textarea>
"
        }

        default {
           set return_html ""
        }

    }
    return $return_html
}

set context [list "Create Survey"]

ad_return_template

