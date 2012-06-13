# /www/survsimp/admin/survey-create-choice.tcl
ad_page_contract {

    Ask the user what kind of survey they wish to create.

    @author nstrug@arsdigita.com
    @creation-date September 13, 2000
    @cvs-id $Id$

} {



}

set package_id [ad_conn package_id]
ad_require_permission $package_id survsimp_create_survey

set whole_page "[ad_header "Choose Survey Type"]

<h2>Choose a Survey Type</h2>

[ad_context_bar "Choose Type"]

<hr>

<dl>
<dt><a href=\"survey-create?type=scored\">Scored Survey</a>
<dd>This is a multiple choice survey where each answer can be scored on one
or more variables. This survey also allows you to execute arbitrary
code (e.g. for redirects) conditional on the user's score at the end
of the survey.</dd>
<dt><a href=\"survey-create?type=general\">General Survey</a>
<dd>This survey allows you to specify the type of response
required. Use this survey if you want to allow users to enter their
own answers rather than choose from a list. You should also use this
survey if you wish to mix question types, e.g. have multiple choice
and free text answer questions in the same survey.</dd>
</dl>

[ad_footer]
"

doc_return 200 text/html $whole_page
