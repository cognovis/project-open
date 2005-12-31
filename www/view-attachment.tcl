ad_page_contract {

  View the attachment contents of a given response.

  @param  response_id  id of complete survey response submitted by user
  @param  question_id  id of question for which this file was submitted as an answer

  @author jbank@arsdigita.com
  @author nstrug@arsdigita.com
  @creation-date   28th September 2000
  @cvs-id $Id$
} {

  response_id:integer,notnull
  question_id:integer,notnull

} -validate {
    attachment_exists -requires {response_id question_id} {
	set file_type  [db_string get_file_type {select attachment_file_type
	    from survsimp_question_responses
	    where response_id = :response_id and question_id = :question_id} -default ""]

	if { [empty_string_p $file_type] } {
	    ad_complain "Couldn't find attachment. Couldn't find an attachment matching the response_id $response_id, question_id $question_id given."
	}
    }
}

ReturnHeaders $file_type

#  This has not been converted to bind variables yet, but for the
#  moment we're still using tcl variable substitution because we
#  are certain that these are integers

# DRB: should be rewritten to use the content repository ...

db_write_blob return_attachment {select attachment_answer  
    from survsimp_question_responses
    where response_id = $response_id and question_id = $question_id
}

db_release_unused_handles
