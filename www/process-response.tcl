ad_page_contract {

    Insert user response into database.
    This page receives an input for each question named
    response_to_question.$question_id 

    @param   survey_id             survey user is responding to
    @param   return_url            optional redirect address
    @param   group_id              
    @param   response_to_question  since form variables are now named as response_to_question.$question_id, this is actually array holding user responses to all survey questions.
    
    @author  jsc@arsdigita.com
    @author  nstrug@arsdigita.com
    @creation-date    28th September 2000
    @cvs-id $Id$
} {

  survey_id:integer,notnull
  return_url:optional
  response_to_question:array,optional,multiple,html

} -validate {
	
    survey_exists -requires { survey_id } {
	if ![db_0or1row survey_exists {
	    select 1 from survsimp_surveys where survey_id = :survey_id
	}] {
	    ad_complain "Survey $survey_id does not exist"
	}
    }

    check_questions -requires { survey_id:integer } {

	set question_info_list [db_list_of_lists survsimp_question_info_list {
	    select question_id, question_text, abstract_data_type, presentation_type, required_p
	    from survsimp_questions
	    where survey_id = :survey_id
	    and active_p = 't'
	    order by sort_key
	}]
	    
	## Validate input.
	
	set questions_with_missing_responses [list]
	
	foreach question $question_info_list { 
	    set question_id [lindex $question 0]
	    set question_text [lindex $question 1]
	    set abstract_data_type [lindex $question 2]
	    set required_p [lindex $question 4]
	    
	    #  Need to clean-up after mess with :array,multiple flags
	    #  in ad_page_contract.  Because :multiple flag will sorround empty
	    #  strings and all multiword values with one level of curly braces {}
	    #  we need to get rid of them for almost any abstract_data_type
	    #  except 'choice', where this is intended behaviour.  Why bother
	    #  with :multiple flag at all?  Because otherwise we would lost all
	    #  but first value for 'choice' abstract_data_type - see ad_page_contract
	    #  doc and code for more info.
	    #
	    if { [exists_and_not_null response_to_question($question_id)] } {
		if {$abstract_data_type != "choice"} {
		    set response_to_question($question_id) [join $response_to_question($question_id)]
		}
	    }
	    
	    
	    if { $abstract_data_type == "date" } {
		if [catch  { set response_to_question($question_id) [validate_ad_dateentrywidget "" response_to_question.$question_id [ns_getform]]} errmsg] {
		    ad_complain "$errmsg: Please make sure your dates are valid."
		}
	    }
	    
	    if { [exists_and_not_null response_to_question($question_id)] } {
		set response_value [string trim $response_to_question($question_id)]
	    } elseif {$required_p == "t"} {
		lappend questions_with_missing_responses $question_text
		continue
	    } else {
		set response_to_question($question_id) ""
		set response_value ""
	    }
	    
	    if {![empty_string_p $response_value]} {
		if { $abstract_data_type == "number" } {
		    if { ![regexp {^(-?[0-9]+\.)?[0-9]+$} $response_value] } {
			
			ad_complain "The response to \"$question_text\" must be a number. Your answer was \"$response_value\"."
			continue
		    }
		} elseif { $abstract_data_type == "integer" } {
		    if { ![regexp {^[0-9]+$} $response_value] } {
			
			ad_complain "The response to \"$question_text\" must be an integer. Your answer was \"$response_value\"."
			continue
		}
		}
	    }
	    
	    if { $abstract_data_type == "blob" } {
                set tmp_filename $response_to_question($question_id.tmpfile)
		set n_bytes [file size $tmp_filename]
		if { $n_bytes == 0 && $required_p == "t" } {
		    
		    ad_complain "Your file is zero-length. Either you attempted to upload a zero length file, a file which does not exist, or something went wrong during the transfer."
		}
	    }
	    
	}
	
	if { [llength $questions_with_missing_responses] > 0 } {
	    ad_complain "You didn't respond to all required sections. You skipped:"
	    foreach skipped_question $questions_with_missing_responses {
		ad_complain $skipped_question
	    }
	    return 0
	} else {
	    return 1
	}
    }
} -properties {

    survey_name:onerow
}

ad_require_permission $survey_id survsimp_take_survey

set user_id [ad_verify_and_get_user_id]

# Do the inserts.

set response_id [db_nextval acs_object_id_seq]
set creation_ip [ad_conn peeraddr]

db_transaction {

    db_exec_plsql create_response {
	begin
	    :1 := survsimp_response.new (
		response_id => :response_id,
		survey_id => :survey_id,		
		context_id => :survey_id,
		creation_user => :user_id
	    );
	end;
    }

    set question_info_list [db_list_of_lists survsimp_question_info_list {
        select question_id, question_text, abstract_data_type, presentation_type, required_p
	from survsimp_questions
	where survey_id = :survey_id
	and active_p = 't'
	order by sort_key }]


    foreach question $question_info_list { 
	set question_id [lindex $question 0]
	set question_text [lindex $question 1]
	set abstract_data_type [lindex $question 2]
	set presentation_type [lindex $question 3]

	set response_value [string trim $response_to_question($question_id)]

	switch -- $abstract_data_type {
	    "choice" {
		if { $presentation_type == "checkbox" } {
		    # Deal with multiple responses. 
		    set checked_responses $response_to_question($question_id)
		    foreach response_value $checked_responses {
			if { [empty_string_p $response_value] } {
			    set response_value [db_null]
			}

			db_dml survsimp_question_response_checkbox_insert "insert into survsimp_question_responses (response_id, question_id, choice_id)
 values (:response_id, :question_id, :response_value)"
		    }
		}  else {
		    if { [empty_string_p $response_value] } {
			set response_value [db_null]
		    }

		    db_dml survsimp_question_response_choice_insert "insert into survsimp_question_responses (response_id, question_id, choice_id)
 values (:response_id, :question_id, :response_value)"
		}
	    }
	    "shorttext" {
		db_dml survsimp_question_choice_shorttext_insert "insert into survsimp_question_responses (response_id, question_id, varchar_answer)
 values (:response_id, :question_id, :response_value)"
	    }
	    "boolean" {
		if { [empty_string_p $response_value] } {
		    set response_value [db_null]
		}

		db_dml survsimp_question_response_boolean_insert "insert into survsimp_question_responses (response_id, question_id, boolean_answer)
 values (:response_id, :question_id, :response_value)"
	    }
	    "number" {}
	    "integer" {
                if { [empty_string_p $response_value] } {
                    set response_value [db_null]
                } 

		db_dml survsimp_question_response_integer_insert "insert into survsimp_question_responses (response_id, question_id, number_answer)
 values (:response_id, :question_id, :response_value)"
	    }
	    "text" {
                if { [empty_string_p $response_value] } {
                    set response_value [db_null]
                }

		db_dml survsimp_question_response_text_insert "
insert into survsimp_question_responses
(response_id, question_id, clob_answer)
values (:response_id, :question_id, empty_clob())
 returning clob_answer into :1" -clobs [list $response_value]
	    }
	    "date" {
                if { [empty_string_p $response_value] } {
                    set response_value [db_null]
                }

		db_dml survsimp_question_response_date_insert "insert into survsimp_question_responses (response_id, question_id, date_answer)
 values (:response_id, :question_id, :response_value)"
	    }   
            "blob" {
                if { ![empty_string_p $response_value] } {
                    # this stuff only makes sense to do if we know the file exists
		    set tmp_filename $response_to_question($question_id.tmpfile)
                    set file_extension [string tolower [file extension $response_value]]
                    # remove the first . from the file extension
                    regsub {\.} $file_extension "" file_extension
                    set guessed_file_type [ns_guesstype $response_value]

                    set n_bytes [file size $tmp_filename]
                    # strip off the C:\directories... crud and just get the file name
                    if ![regexp {([^/\\]+)$} $response_value match client_filename] {
                        # couldn't find a match
                        set client_filename $response_value
                    }
                    if { $n_bytes == 0 } {
                        error "This should have been checked earlier."
                    } else {

			### add content repository support
			# 1. create new content item
			# 2. create relation between user and content item
			# 3. create a new empty content revision and make live
			# 4. update the cr_revisions table with the blob data
			# 5. update the survey table
			db_transaction {
			    set name "blob-response-$response_id"

			    set item_id [db_exec_plsql create_item "
				begin
				:1 := content_item.new (
				    name => :name,
				    creation_ip => :creation_ip);
				end;"]

			    set rel_id [db_exec_plsql create_rel "
				begin
				:1 := acs_rel.new (
				    rel_type => 'user_blob_response_rel',
				    object_id_one => :user_id,
				    object_id_two => :item_id);
				end;"]

			    set revision_id [db_exec_plsql create_revision "
				begin
				:1 := content_revision.new (
				    title => 'A Blob Response',
				    item_id => :item_id,
				    text => 'not_important',
				    mime_type => :guessed_file_type,
				    creation_date => sysdate,
				    creation_user => :user_id,
				    creation_ip => :creation_ip);

				update cr_items
				set live_revision = :1
				where item_id = :item_id;
				
				end;"]

			    db_dml update_response "
				update cr_revisions
				set content = empty_blob()
				where revision_id = :revision_id
				returning content into :1" -blob_files [list $tmp_filename]

			    set content_length [cr_file_size $tmp_filename]

			    db_dml survsimp_question_response_blob_insert "
				insert into survsimp_question_responses 
				(response_id, question_id, item_id, 
				content_length,
				attachment_file_name, attachment_file_type, 
				attachment_file_extension)
				values 
				(:response_id, :question_id, :item_id, 
				:content_length,
				:response_value, :guessed_file_type, 
				:file_extension)"
			}
		    }
                }
            }
	}
    }
} on_error {
    ad_complain "Database Error. There was an error while trying to process your response: $errmsg"
    return
}

#
# Survey type-specific stuff
#

set type [db_string get_type "select type from survsimp_surveys where survey_id = :survey_id"]

switch $type {
    
    "general" {
	      
	set survey_name [db_string survsimp_name_from_id "select name from survsimp_surveys where survey_id = :survey_id" ]

	db_release_unused_handles

	if {[info exists return_url] && ![empty_string_p $return_url]} {
	    ad_returnredirect "$return_url"
            ad_script_abort
	} else {
            set context [list "Response Submitted"]
	}
    }

    "scored" {

        db_foreach get_score "select variable_name, sum(score) as sum_of_scores
                           from survsimp_choice_scores, survsimp_question_responses, survsimp_variables
                           where survsimp_choice_scores.choice_id = survsimp_question_responses.choice_id
                           and survsimp_choice_scores.variable_id = survsimp_variables.variable_id
                           and survsimp_question_responses.response_id = :response_id
                           group by variable_name" {
			       set sum_score($variable_name) $sum_of_scores
			   }

        set logic [db_string get_logic "select logic from survsimp_logic, survsimp_logic_surveys_map
          where survsimp_logic.logic_id = survsimp_logic_surveys_map.logic_id
          and survey_id = :survey_id"]


	if {[info exists return_url] && ![empty_string_p $return_url]} {
            db_release_unused_handles
	    ad_returnredirect $return_url
        }

        eval $logic

        db_release_unused_handles
        ad_script_abort
    }

    default {
	if {[info exists return_url] && ![empty_string_p $return_url]} {
	    ad_returnredirect "$return_url"
            ad_script_abort
	} else {
            set context {"Response Submitted"}
	}	
    }
}
