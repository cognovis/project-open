# /www/survsimp/admin/question-add-2.tcl
ad_page_contract {

    Based on the presentation type selected in previous form,
    gives the user various options on how to lay out the question.

    @param survey_id          integer determining survey we're dealing with
    @param after              optional integer determining placement of question
    @param question_text      text comprising this question
    @param presentation_type  string denoting widget used to provide answer
    @param required_p         flag indicating whether this question is mandatory
    @param active_p           flag indicating whether this question is active
    @param category_id        optional integer describing category of this question (within survey)

    @author Jin Choi (jsc@arsdigita.com)
    @author nstrug@arsdigita.com
    @creation-date   February 9, 2000
    @cvs-id $Id$
} {

    survey_id:integer
    question_text:html,notnull
    presentation_type
    {after:integer ""}
    {required_p t}
    {active_p t}
    {n_responses ""}

}

set package_id [ad_conn package_id]
set user_id [ad_get_user_id]
ad_require_permission $package_id survsimp_create_question

set question_id [db_nextval acs_object_id_seq]

db_1row survsimp_survey_properties {select name, description, type
    from survsimp_surveys
    where survey_id = :survey_id}

set exception_count 0
set exception_text ""

if { $type != "general" && $type != "scored" } {
    incr exception_count
    append exception_text "<li>Surveys of type $type are not currently available\n"
}

if { $presentation_type == "upload_file" } {
    incr exception_count
    append exception_text "<li>The presentation type: upload file is not supported at this time."
}

if { $exception_count > 0 } {
    ad_return_complaint $exception_count $exception_text
    return
}

# Survey-type specific question settings

if { $type == "scored" } {

    db_1row count_variable_names {select count(variable_name) as n_variables
	from survsimp_variables, survsimp_variables_surveys_map
        where survsimp_variables.variable_id = survsimp_variables_surveys_map.variable_id
        and survey_id = :survey_id}
    
    set response_fields "<table border=0>
<tr><th>Answer Text</th><th colspan=$n_variables>Score</th></tr>
<tr><td></td>"

    set sql_query "select variable_name, survsimp_variables.variable_id as variable_id
               from survsimp_variables, survsimp_variables_surveys_map
               where survsimp_variables.variable_id = survsimp_variables_surveys_map.variable_id
               and survey_id = :survey_id order by survsimp_variables.variable_id"

    set variable_id_list [list]
    db_foreach select_variable_names $sql_query {
	lappend variable_id_list $variable_id
	append response_fields "<th>$variable_name</th>"
    }

    append response_fields "</tr>\n"

    for {set response 0} {$response < $n_responses} {incr response} {
	append response_fields "<tr><td align=center><input type=text name=\"responses\" size=80></td>"
	for {set variable 0} {$variable < $n_variables} {incr variable} {
	    append response_fields "<td align=center><input type=text name=\"scores.$variable\" size=2></td>"
	}
	append response_fields "</tr>\n"
    }

    append response_fields "</table>\n"
    set response_type_html "<input type=hidden name=abstract_data_type value=\"choice\">"
    set presentation_options_html ""
    set form_var_list [export_form_vars survey_id question_id question_text presentation_type after required_p active_p type n_variables variable_id_list]

} elseif { $type == "general" } {

# Display presentation options for sizing text input fields and textareas.
    set presentation_options ""

    switch -- $presentation_type {
	"textbox" { 
	    set presentation_options "<select name=textbox_size>
<option value=small>Small</option>
<option value=medium>Medium</option>
<option value=large>Large</option>
</select>"
	}
	"textarea" {
	    set presentation_options "Rows: <input name=textarea_rows size=3>  Columns: <input name=textarea_cols size=3>"
	}
    }

    set presentation_options_html ""
    if { ![empty_string_p $presentation_options] } {
	set presentation_options_html "Presentation Options: $presentation_options\n"
    }

# Let user enter valid responses for selections, radio buttons, and check boxes.

    set response_fields ""

    switch -- $presentation_type {
	"radio" -
	"select" {
	    set response_fields "Select one of the following:<p>

<table border=0 width=80% align=center>
<tr valign=top<td valign=middle align=center>
<td>
<input type=radio name=abstract_data_type value=\"boolean\"> True or False
<td valign=middle>
<b>OR</b>
<td>
 <input type=radio name=abstract_data_type value=\"choice\" checked> Multiple choice (enter one per line):
<blockquote>
<textarea name=valid_responses rows=10 cols=50></textarea>
</blockquote>

</table>
"
	    set response_type_html ""
	}

	"checkbox" {
	    set response_fields "Valid Responses (enter one per line):
<blockquote>
<textarea name=valid_responses rows=10 cols=80></textarea>
</blockquote>
"
	    set response_type_html "<input type=hidden name=abstract_data_type value=\"choice\">"
	}
	"textbox" -
	"textarea" {
	    # Fields where users enter free text responses require an abstract type.
	    set response_type_html "<p>
Type of Response:
<select name=\"abstract_data_type\">
 <option value=\"shorttext\">Short Text (< 4000 characters)</option>
 <option value=\"text\">Text</option>
 <option value=\"boolean\">Boolean</option>
 <option value=\"number\">Number</option>
 <option value=\"integer\">Integer</option>
</select>
"
	} 
	"date" {
	    
	    set response_type_html "<input type=hidden name=abstract_data_type value=date>"
	}
	"upload_file" {
	    set response_type_html "<input type=hidden name=abstract_data_type value=blob>"
	}
    }

set form_var_list [export_form_vars survey_id question_id question_text presentation_type after required_p active_p type]

}

set context [list [list "one?[export_url_vars survey_id]" "Administer Survey"] "Add A Question"]

ad_return_template
