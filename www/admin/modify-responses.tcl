ad_page_contract {

    Modify question responses and scores

    @param question_id   which question we'll be changing responses of
    @param survey_id     survey providing this question

    @author Nick Strugnell (nstrug@arsdigita.com)
    @creation-date   September 15, 2000
    @cvs-id $Id$
} {

    question_id:integer
    survey_id:integer

}

ad_require_permission $survey_id survsimp_modify_question

set survey_name [db_string survey_name_from_id "select name from survsimp_surveys where survey_id=:survey_id" ]

set question_text [db_string survsimp_question_text_from_id "select question_text
from survsimp_questions
where question_id = :question_id" ]

set table_html "<table border=0>
<tr><th>Response</th>"

set variable_id_list [list]

db_foreach get_variable_names "select variable_name, survsimp_variables.variable_id as variable_id
  from survsimp_variables, survsimp_variables_surveys_map
  where survsimp_variables.variable_id = survsimp_variables_surveys_map.variable_id
  and survey_id = :survey_id
  order by variable_name" {

      lappend variable_id_list $variable_id
      append table_html "<th>$variable_name</th>"
  }

append table_html "</tr>\n"

set choice_id_list [list]

db_foreach get_choices "select choice_id, label from survsimp_question_choices where question_id = :question_id order by choice_id" {
    lappend choice_id_list $choice_id
    append table_html "<tr><td align=center><input name=\"responses\" value=\"$label\" size=80></td>"

    db_foreach get_scores "select score, survsimp_variables.variable_id as variable_id
      from survsimp_choice_scores, survsimp_variables
      where survsimp_choice_scores.choice_id = :choice_id
      and survsimp_choice_scores.variable_id = survsimp_variables.variable_id
      order by variable_name" {

	  append table_html "<td align=center><input name=\"scores.$variable_id\" value=\"$score\" size=2></td>"
      }

    append table_html "</tr>\n"
}

append table_html "</table>\n"

db_release_unused_handles

doc_return 200 text/html "[ad_header "Modify Responses"]
<h2>$survey_name</h2>

[ad_context_bar [list "one?[export_url_vars survey_id]" "Administer Survey"] "Modify Question Responses"]

<hr>

Question: $question_text
<p>
<form action=\"modify-responses-2\" method=get>
[export_form_vars survey_id question_id choice_id_list variable_id_list]
$table_html
<p>
<center>
<input type=submit value=\"Submit\">
</center>

</form>

[ad_footer]
"
