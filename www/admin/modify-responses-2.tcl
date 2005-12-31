ad_page_contract {
    Modify question responses

    @param survey_id               integer denoting which survey we're adding question to
    @param question_id             id of new question
    @param responses               list of possible responses
    @param scores                  list of variable scores

    @author Nick Strugnell (nstrug@arsdigita.com)
    @creation-date   September 15, 2000
    @cvs-id $Id$
} {
    survey_id:integer,notnull
    question_id:integer,notnull
    {responses:multiple ""}
    {scores:multiple,array,integer ""}
    {variable_id_list ""}
    {choice_id_list ""}
}

ad_require_permission $survey_id survsimp_modify_question

db_transaction {
    
    set i 0
    foreach choice_id $choice_id_list {
	set trimmed_response [string trim [lindex $responses $i]]
	db_dml update_survsimp_question_choice "update survsimp_question_choices
          set label = :trimmed_response
          where choice_id = :choice_id"

	foreach variable_id $variable_id_list {
	    set score_list $scores($variable_id)
	    set score [lindex $score_list $i]
	    db_dml update_survsimp_scores "update survsimp_choice_scores
                                           set score = :score
                                           where choice_id = :choice_id
                                           and variable_id = :variable_id"
	}

	incr i
    }
}

db_release_unused_handles
ad_returnredirect "one?survey_id=$survey_id"
	
