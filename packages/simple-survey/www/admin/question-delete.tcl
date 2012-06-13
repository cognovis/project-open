# /www/survsimp/admin/question-delete.tcl
ad_page_contract {

    Delete a question from a survey
    (or ask for confirmation if there are responses).

    @param  question_id  question we're about to delete

    @author jsc@arsdigita.com
    @creation-date   March 13, 2000
    @cvs-id $Id$
} {

    question_id:integer

}

ad_require_permission $question_id survsimp_delete_question

set survey_id [db_string survsimp_id_from_question_id "select survey_id from survsimp_questions where question_id = :question_id" ]

set n_responses [db_string survsimp_number_responses "select count(*)
from survsimp_question_responses
where question_id = :question_id" ]

if { $n_responses == 0 } {
    db_transaction {

	db_dml survsimp_question_choices_score_delete "delete from survsimp_choice_scores where choice_id in (select choice_id from survsimp_question_choices
          where question_id = :question_id)" 

	db_dml survsimp_question_choices_delete "delete from survsimp_question_choices where
         question_id = :question_id"

	db_exec_plsql survsimp_delete_question {
	    begin
        	survsimp_question.delete (:question_id);
	    end;
	}
    } on_error {
    
	ad_return_error "Database Error" "There was an error while trying to delete the question:
	<pre>
	$errmsg
	</pre>
	<p> Please go back using your browser.
	"
        ad_script_abort
    }

    db_release_unused_handles
    ad_returnredirect "one?survey_id=$survey_id"
    ad_script_abort
} else {
    
    doc_return 200 text/html "[ad_header "Confirm Question Deletion"]
<h2>Really Delete?</h2>

[ad_context_bar [list "one?[export_url_vars survey_id]" "Administer Survey"] "Delete Question"]

<hr>

Deleting this question will also delete all $n_responses responses. Really delete?
<p>
<a href=\"question-delete-2?[export_url_vars question_id]\">Yes</a> / 
<a href=\"one?[export_url_vars survey_id]\">No</a>

[ad_footer]
"
}
