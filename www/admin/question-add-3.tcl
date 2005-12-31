# /www/survsimp/admin/question-add-3.tcl
ad_page_contract {
    Inserts a new question into the database.

    @param survey_id               integer denoting which survey we're adding question to
    @param question_id             id of new question
    @param after                   optional integer determining position of this question
    @param question_text           text of question
    @param abstract_data_type      string describing datatype we expect as answer
    @param presentation_type       string describing widget for providing answer
    @param presentation_alignment  string determining placement of answer widget relative to question text
    @param valid_responses         string containing possible choices, one per line
    @param textbox_size            width of textbox answer widget
    @param textarea_cols           number of columns for textarea answer widget
    @param textarea_rows           number of rows for textarea answer widget
    @param required_p              flag telling us whether an answer to this question is mandatory
    @param active_p                flag telling us whether this question will show up at all

    @author Jin Choi (jsc@arsdigita.com) 
    @author nstrug@arsdigita.com
    @creation-date February 9, 2000
    @cvs-id $Id$
} {
    survey_id:integer,notnull
    question_id:integer,notnull
    after:integer,optional
    question_text:html
    {abstract_data_type ""}
    presentation_type
    presentation_alignment
    type:notnull
    {valid_responses ""}
    {textbox_size ""} 
    {textarea_cols:naturalnum ""} 
    {textarea_rows:naturalnum ""}
    {required_p t}
    {active_p t}
    {responses:multiple ""}
    {scores:multiple,array,integer ""}
    {n_variables:integer ""}
    {variable_id_list ""}
}

set package_id [ad_conn package_id]
set user_id [ad_get_user_id]
ad_require_permission $package_id survsimp_create_question

set exception_count 0
set exception_text ""

if { [empty_string_p $question_text] } {
    incr exception_count
    append exception_text "<li>You did not enter a question.\n"
}

if { $type != "scored" && $type != "general" } {
    incr exception_count
    append exception_text "<li>Surveys of type $type are not currently available.\n"
}

if { $type == "general" && $abstract_data_type == "choice" && [empty_string_p $valid_responses] } {
    incr exception_count
    append exception_text "<li>You did not enter a list of valid responses/choices.\n"
}

if { $type == "scored" } {
    set i 0
    foreach response $responses {
	set trimmed_response [string trim $response]
	if { [empty_string_p $trimmed_response] } {
	    incr exception_count
	    incr i
	    append exception_text "<li>You did not enter a valid choice for choice number $i.\n"
	}
    }
    if {  $n_variables < 1 } {
	incr exception_count
	append exception_text "<li>You must score on at least one variable.\n"
    }
}

if { $exception_count > 0 } {
    ad_return_complaint $exception_count $exception_text
    ad_script_abort
}

if { $type == "scored" } {

    db_transaction {

	if { [exists_and_not_null after] } {
	    # We're inserting between existing questions; move everybody down.
	    set sort_key [expr { $after + 1 }]
	    db_dml renumber_sort_keys "update survsimp_questions
                                   set sort_key = sort_key + 1
                                   where survey_id = :survey_id
                                   and sort_key > :after"
	} else {
	    set sort_key 1
	}
	
	set question_id [db_exec_plsql create_question {
	    begin
		:1 := survsimp_question.new (
		    question_id => :question_id,
		    survey_id => :survey_id,
                    sort_key => :sort_key,
                    question_text => :question_text,
                    abstract_data_type => :abstract_data_type,
                    presentation_type => :presentation_type,
                    presentation_alignment => :presentation_alignment,
                    active_p => :active_p,
                    required_p => :required_p,
		    context_id => :survey_id,
		    creation_user => :user_id
		);
	    end;
	}]

	db_dml add_question_text {
	    update survsimp_questions
	    set question_text = :question_text
	    where question_id = :question_id
	}

	set count 0
	foreach response $responses {
	    set trimmed_response [string trim $response]
	    set choice_id [db_string get_choice_id "select survsimp_choice_id_sequence.nextval as choice_id from dual"]
	    db_dml insert_survsimp_question_choice "
		insert into survsimp_question_choices
                (choice_id, question_id, label, sort_order)
                values
                (:choice_id, :question_id, :trimmed_response, :count)"

	    for {set i 0} {$i < $n_variables} {incr i} {
		set score_list $scores($i)
		set score [lindex $score_list $count]
		set variable_id [lindex $variable_id_list $i]
		db_dml insert_survsimp_scores "
		    insert into survsimp_choice_scores
                    (choice_id, variable_id, score)
                    values
                    (:choice_id, :variable_id, :score)"
	    }
	    incr count
	}

    } on_error {

	set already_inserted_p [db_string already_inserted_p "select decode(count(*),0,0,1) from survsimp_questions where question_id = :question_id"]

	if { !$already_inserted_p } {
	    db_release_unused_handles
	    ad_return_error "Database Error" "<pre>$errmsg</pre>"
            ad_script_abort
	}
    }

} elseif { $type == "general" } {

# Generate presentation_options.
    set presentation_options ""
    if { $presentation_type == "textarea" } {
	if { [exists_and_not_null textarea_rows] } {
	    append presentation_options " rows=$textarea_rows"
	}
	if { [exists_and_not_null textarea_cols] } {
	    append presentation_options " cols=$textarea_cols"
	}
    } elseif { $presentation_type == "textbox" } {
	if { [exists_and_not_null textbox_size] } {
	    # Will be "small", "medium", or "large".
	    set presentation_options $textbox_size
	}
    }
    
    db_transaction {
	if { [exists_and_not_null after] } {
	    # We're inserting between existing questions; move everybody down.
	    set sort_key [expr { $after + 1 }]
	    db_dml renumber_sort_keys "update survsimp_questions
		set sort_key = sort_key + 1
		where survey_id = :survey_id
		and sort_key > :after"
	} else {
	    set sort_key 1
	}

	db_exec_plsql create_question {
	    begin
		:1 := survsimp_question.new (
		    question_id => :question_id,
		    survey_id => :survey_id,
                    sort_key => :sort_key,
                    question_text => empty_clob(),
                    abstract_data_type => :abstract_data_type,
                    presentation_type => :presentation_type,
                    presentation_options => :presentation_options,
                    presentation_alignment => :presentation_alignment,
                    active_p => :active_p,
                    required_p => :required_p,
                    context_id => :survey_id
		);
	    end;
	}

	db_dml add_question_text {
	    update survsimp_questions
	    set question_text = :question_text
	    where question_id = :question_id
	}


    # For questions where the user is selecting a canned response, insert
    # the canned responses into survsimp_question_choices by parsing the valid_responses
    # field.
            if { $presentation_type == "checkbox" || $presentation_type == "radio" || $presentation_type == "select" } {
                if { $abstract_data_type == "choice" } {
	            set responses [split $valid_responses "\n"]
	            set count 0
	            foreach response $responses {
		        set trimmed_response [string trim $response]
		        if { [empty_string_p $trimmed_response] } {
		        # skip empty lines
		            continue
		        }
		        ### added this next line to 
	    	        set choice_id [db_string get_choice_id "select survsimp_choice_id_sequence.nextval as choice_id from dual"]
		        db_dml insert_survsimp_question_choice "insert into survsimp_question_choices (choice_id, question_id, label, sort_order)
values (survsimp_choice_id_sequence.nextval, :question_id, :trimmed_response, :count)"
		        incr count
	            }
	        }
            }
    } on_error {

        set already_inserted_p [db_string already_inserted_p "select decode(count(*),0,0,1) from survsimp_questions where question_id = :question_id" ]

        if { !$already_inserted_p } {
            db_release_unused_handles
            ad_return_error "Database Error" "<pre>$errmsg</pre>"
ad_script_abort
        }
    }
}

db_release_unused_handles
ad_returnredirect "one?survey_id=$survey_id"
