ad_page_contract {

  Displays confirmation page for new survey creation or, if we
  just arrived from it, actually creates new survey.

  @param  survey_id    id of survey to be created
  @param  name         new survey title
  @param  short_name   new survey short tag
  @param  description  new survey description
  @param  desc_html    whether the description is provided in HTML or not
  @param  checked_p    t if we arrived from confirmation page

  @author philg@mit.edu
  @creation-date   February 9, 2000
  @cvs-id $Id$

} {

  survey_id:integer,optional
  name
  description:html
  desc_html
  {checked_p "f"}
  type:notnull
  {display_type "list"}
  {variable_names ""}
  {logic:allhtml ""}

}

set package_id [ad_conn package_id]

# bounce the user if they don't have permission to admin surveys
ad_require_permission $package_id survsimp_create_survey

set user_id [ad_get_user_id]

set exception_count 0
set exception_text ""

if { [empty_string_p $name] } {
    incr exception_count
    append exception_text "<li>You didn't enter a name for this survey.\n"
}

if { [empty_string_p $description] } {
    incr exception_count
    append exception_text "<li>You didn't enter a description for this survey.\n"
}

if { $type != "general" && $type != "scored" } {
    incr exception_count
    append exception_text "<li>Surveys of type $type are not currently available.\n"
}

if { $type == "scored" && [empty_string_p $variable_names] } {
    incr exception_count
    append exception_text "<li>You didn't specify any variable names.\n"
}

if {$exception_count > 0} {
    ad_return_complaint $exception_count $exception_text
    ad_script_abort
}

if {$checked_p == "f"} {
    set survey_id [db_nextval acs_object_id_seq]
    set context [list "Confirm New Survey Description"]
    
    switch $desc_html {
	"html" {
	    # nothing, the description is the description
	}
	
	"pre" {
	    regsub "\[ \012\015\]+\$" $description {} description
	    set description "<pre>[ns_quotehtml $description]</pre>"
	}

	default {
	    set description "[util_convert_plaintext_to_html $description]"
	}
    }
    
    ad_return_template survey-create-confirm
    return
} else {
    
    # make sure the short_name is unique

    if {[string compare $desc_html "plain"] == 0} {
	set description_html_p "f"
    } else {
	set description_html_p "t"
    }
    
    db_transaction {
        db_exec_plsql create_survey {
	    begin
	        :1 := survsimp_survey.new (
                    survey_id => :survey_id,
                    name => :name,
                    short_name => :name,
                    description => :description,
                    description_html_p => :description_html_p,
                    type => :type,
                    display_type => :display_type,
                    package_id => :package_id,
                    context_id => :package_id,
		    creation_user => :user_id
                );
            end;
        }
    
	# survey type-specific inserts

	if { $type == "scored" } {

	    foreach variable_name [split $variable_names ","] {
	    
		set variable_id [db_string next_variable_id "select survsimp_variable_id_sequence.nextval from dual"]

		db_dml add_variable_name "insert into survsimp_variables
                  (variable_id, variable_name)
                  values
                  (:variable_id, :variable_name)"

		db_dml map_variable_name "insert into survsimp_variables_surveys_map
                  (variable_id, survey_id)
                  values
                  (:variable_id, :survey_id)"
	    }

	    set logic_id [db_string next_logic_id "select survsimp_logic_id_sequence.nextval from dual"]
	
	    ### added to support postgresql
	    ### oracle query also edited
	    db_dml add_logic "insert into survsimp_logic
              (logic_id, logic)
              values
              (:logic_id, empty_clob()) returning logic into :1" -clobs [list $logic]

	    db_dml map_logic "insert into survsimp_logic_surveys_map
              (logic_id, survey_id)
              values
              (:logic_id, :survey_id)"	
	}
    }
    
    db_release_unused_handles

    ad_returnredirect "question-add?survey_id=$survey_id"
    ad_script_abort
}
