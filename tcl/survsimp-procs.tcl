# /tcl/survey-simple-defs.tcl
ad_library {

  Support procs for simple survey module, most important being
  survsimp_question_display which generates a question widget based
  on data retrieved from database.

  @author philg@mit.edu on
  @author teadams@mit.edu
  @author nstrug@arsdigita.com
  @creation-date   February 9, 2000
  @cvs-id $Id$

}

proc_doc survsimp_question_display { question_id {edit_previous_response_p "f"} } "Returns a string of HTML to display for a question, suitable for embedding in a form. The form variable is of the form \"response_to_question.\$question_id" {
    set element_name "response_to_question.$question_id"

    db_1row survsimp_question_properties "
select
  survey_id,
  sort_key,
  question_text,
  abstract_data_type,
  required_p,
  active_p,
  presentation_type,
  presentation_options,
  presentation_alignment,
  creation_user,
  creation_date
from
  survsimp_questions, acs_objects
where
  object_id = question_id
  and question_id = :question_id"
    
    set html $question_text
    if { $presentation_alignment == "below" } {
	append html "<br>"
    } else {
	append html " "
    }

    set user_value ""

    if {$edit_previous_response_p == "t"} {
 	set user_id [ad_get_user_id]

 	set prev_response_query "select	
	  choice_id,
	  boolean_answer,
	  clob_answer,
	  number_answer,
 	  varchar_answer,
	  date_answer,
          attachment_file_name
   	  from survsimp_question_responses
 	  where question_id = :question_id
             and response_id = (select max(response_id) from survsimp_responses r, survsimp_questions q, acs_objects
   	                       where q.question_id = :question_id
                                 and object_id = r.survey_id
                       	         and creation_user = :user_id
 	                         and q.survey_id = r.survey_id)"

	set count 0
	db_foreach survsimp_response $prev_response_query {
	    incr count
	    
	    if {$presentation_type == "checkbox"} {
		set selected_choices($choice_id) "t"
	    }
	} if_no_rows {
	    set choice_id 0
	    set boolean_answer ""
	    set clob_answer ""
	    set number_answer ""
	    set varchar_answer ""
	    set date_answer ""
            set attachment_file_name ""
	}
    }

    switch -- $presentation_type {
        "upload_file"  {
	    if {$edit_previous_response_p == "t"} {
		set user_value $attachment_file_name
	    }
	    append html "<input type=file name=$element_name $presentation_options>"
	}
	"textbox" {
	    if {$edit_previous_response_p == "t"} {
		if {$abstract_data_type == "number" || $abstract_data_type == "integer"} {
		    set user_value $number_answer
		} else {
		    set user_value $varchar_answer
		}
	    }

	    append html "<input type=text name=$element_name value=\"[philg_quote_double_quotes $user_value]\" [ad_decode $presentation_options "large" "size=70" "medium" "size=40" "size=10"]>"
	}
	"textarea" {
	    if {$edit_previous_response_p == "t"} {
		if {$abstract_data_type == "number" || $abstract_data_type == "integer"} {
		    set user_value $number_answer
		} elseif { $abstract_data_type == "shorttext" } {
		    set user_value $varchar_answer
		} else {
		    set user_value $clob_answer
		}
	    }

	    append html "<textarea name=$element_name $presentation_options>$user_value</textarea>" 
	}
	"date" {
	    if {$edit_previous_response_p == "t"} {
		set user_value $date_answer
	    }

	    append html "[ad_dateentrywidget $element_name $user_value]" 
	}
	"select" {
	    if { $abstract_data_type == "boolean" } {
		if {$edit_previous_response_p == "t"} {
		    set user_value $boolean_answer
		}

		append html "<select name=$element_name>
 <option value=\"\">Select One</option>
 <option value=\"t\" [ad_decode $user_value "t" "selected" ""]>True</option>
 <option value=\"f\" [ad_decode $user_value "f" "selected" ""]>False</option>
</select>
"
	    } else {
		if {$edit_previous_response_p == "t"} {
		    set user_value $choice_id
		}

		append html "<select name=$element_name>
<option value=\"\">Select One</option>\n"
		db_foreach survsimp_question_choices "select choice_id, label
from survsimp_question_choices
where question_id = :question_id
order by sort_order" {
		
		    if { $user_value == $choice_id } {
			append html "<option value=$choice_id selected>$label</option>\n"
		    } else {
			append html "<option value=$choice_id>$label</option>\n"
		    }
		}
		append html "</select>"
	    }
	}
    
	"radio" {
	    if { $abstract_data_type == "boolean" } {
		if {$edit_previous_response_p == "t"} {
		    set user_value $boolean_answer
		}

		set choices [list "<input type=radio name=$element_name value=t [ad_decode $user_value "t" "checked" ""]> True" \
				 "<input type=radio name=$element_name value=f [ad_decode $user_value "f" "checked" ""]> False"]
	    } else {
		if {$edit_previous_response_p == "t"} {
		    set user_value $choice_id
		}
		
		set choices [list]
		db_foreach sursimp_question_choices_2 "select choice_id, label
from survsimp_question_choices
where question_id = :question_id
order by sort_order" {
		    if { $user_value == $choice_id } {
			lappend choices "<input type=radio name=$element_name value=$choice_id checked> $label"
		    } else {
			lappend choices "<input type=radio name=$element_name value=$choice_id> $label"
		    }
		}
	    }  
	    if { $presentation_alignment == "beside" } {
		append html [join $choices " "]
	    } else {
		append html "<blockquote>\n[join $choices "<br>\n"]\n</blockquote>"
	    }
	}

	"checkbox" {
	    set choices [list]
	    db_foreach sursimp_question_choices_3 "select * from survsimp_question_choices
where question_id = :question_id
order by sort_order" {

		if { [info exists selected_choices($choice_id)] } {
		    lappend choices "<input type=checkbox name=$element_name value=$choice_id checked> $label"
		} else {
		    lappend choices "<input type=checkbox name=$element_name value=$choice_id> $label"
		}
	    }
	    if { $presentation_alignment == "beside" } {
		append html [join $choices " "]
	    } else {
		append html "<blockquote>\n[join $choices "<br>\n"]\n</blockquote>"
	    }
	}
    }
    return $html
}

proc_doc util_show_plain_text { text_to_display } "allows plain text (e.g. text entered through forms) to look good on screen without using tags; preserves newlines, angle brackets, etc." {
    regsub -all "\\&" $text_to_display "\\&amp;" good_text
    regsub -all "\>" $good_text "\\&gt;" good_text
    regsub -all "\<" $good_text "\\&lt;" good_text
    regsub -all "\n" $good_text "<br>\n" good_text
    # get rid of stupid ^M's
    regsub -all "\r" $good_text "" good_text
    return $good_text
}

proc_doc survsimp_answer_summary_display {response_id {html_p 1} {category_id_list ""}} "Returns a string with the questions and answers. If html_p =t, the format will be html. Otherwise, it will be text.  If a list of category_ids is provided, the questions will be limited to that set of categories." {

    set return_string ""
    set question_id_previous ""

    if [empty_string_p $category_id_list] {
	set summary_query "
select
  sq.question_id,
  sq.survey_id,
  sq.sort_key,
  sq.question_text,
  sq.abstract_data_type,
  sq.required_p,
  sq.active_p,
  sq.presentation_type,
  sq.presentation_options,
  sq.presentation_alignment,
  sqr.response_id,
  sqr.question_id,
  sqr.choice_id,
  sqr.boolean_answer,
  sqr.clob_answer,
  sqr.number_answer,
  sqr.varchar_answer,
  sqr.date_answer,
  sqr.attachment_file_name
from
  survsimp_questions sq,
  survsimp_question_responses sqr
where
  sqr.response_id = :response_id
  and sq.question_id = sqr.question_id
  and sq.active_p = 't'
order by sort_key"
    } else {
	set bind_var_list [list]
	set i 0
	foreach cat_id $category_id_list {
	    incr i
	    set category_id_$i $cat_id
	    lappend bind_var_list ":category_id_$i"
	}
	set summary_query "
select
  sq.question_id,
  sq.survey_id,
  sq.sort_key,
  sq.question_text,
  sq.abstract_data_type,
  sq.required_p,
  sq.active_p,
  sq.presentation_type,
  sq.presentation_options,
  sq.presentation_alignment,
  creation_user,
  creation_date,
  sqr.response_id,
  sqr.choice_id,
  sqr.boolean_answer,
  sqr.clob_answer,
  sqr.number_answer,
  sqr.varchar_answer,
  sqr.date_answer,
  sqr.attachment_file_name
from
  survsimp_questions sq,
  survsimp_question_responses sqr,
  acs_objects
where
  sq.question_id = object_id
  sqr.response_id = :response_id
  and sq.question_id = sqr.question_id
  and sq.active_p = 't'
order by sort_key"
    }
    
    db_foreach survsimp_response_display $summary_query {

	if {$question_id == $question_id_previous} {
	    continue
	}
	
	if $html_p {
	    append return_string "<b>$question_text</b> 
	<blockquote>"
	} else {
	    append return_string "$question_text:  "
	}
	append return_string [util_show_plain_text "$clob_answer $number_answer $varchar_answer $date_answer"]
	
	if {![empty_string_p $attachment_file_name]} {
	    append return_string "Uploaded file: <a href=/survsimp/view-attachment?[export_url_vars response_id question_id]>\"$attachment_file_name\"</a>"
	}
	
	if {$choice_id != 0 && ![empty_string_p $choice_id] && $question_id != $question_id_previous} {
	    set label_list [db_list survsimp_label_list "select label
	    from survsimp_question_choices, survsimp_question_responses
	    where survsimp_question_responses.question_id = :question_id
	    and survsimp_question_responses.response_id = :response_id
	    and survsimp_question_choices.choice_id = survsimp_question_responses.choice_id" ]
	    append return_string "[join $label_list ", "]"
	}
	
	if ![empty_string_p $boolean_answer] {
	    append return_string "[ad_decode $boolean_answer "t" "True" "False"]"
	    
	}
	
	if $html_p {
	    append return_string "</blockquote>
	    <P>"
	} else {
	    append return_string "\n\n"
	}
	
	set question_id_previous $question_id 
    }
    
    return "$return_string"
}

proc_doc survsimp_survey_admin_check { user_id survey_id } { Returns 1 if user is allowed to administer a survey or is a site administrator, 0 otherwise. } {
    if { ![ad_permission_p -user_id $user_id $survey_id "admin"] && [db_string survsimp_creator_p "
    select creation_user
    from   survsimp_surveys
    where  survey_id = :survey_id" ] != $user_id } {
	ad_return_error "Permission Denied" "You do not have permission to administer this survey."
	ad_script_abort
    }
}

# For site administrator new stuff page.
proc_doc ad_survsimp_new_stuff { since_when only_from_new_users_p purpose } "Produces a report of the new surveys created for the site administrator." {
    if { $purpose != "site_admin" } {
	return ""
    }
    if { $only_from_new_users_p == "t" } {
	set users_table "users_new"
    } else {
	set users_table "users"
    }
    
    set new_survey_items ""
    
    db_for_each survsimp_responses_new "select survey_id, name, description, u.user_id, first_names || ' ' || last_name as creator_name, creation_date
from survsimp_surveys s, $users_table u
where s.creation_user = u.user_id
and creation_date> :since_when
order by creation_date desc" {
	append new_survey_items "<li><a href=\"/survsimp/admin/one?[export_url_vars survey_id]\">$name</a> ($description) created by <a href=\"/shared/community-member?[export_url_vars user_id]\">$creator_name</a> on $creation_date\n" 
    }
    
    if { ![empty_string_p $new_survey_items] } {
	return "<ul>\n\n$new_survey_items\n</ul>\n"
    } else {
	return ""
    }
}

ns_share ad_new_stuff_module_list

if { ![info exists ad_new_stuff_module_list] || [util_search_list_of_lists $ad_new_stuff_module_list "Surveys" 0] == -1 } {
    lappend ad_new_stuff_module_list [list "Surveys" ad_survsimp_new_stuff]
}

proc_doc survsimp_survey_short_name_to_id  {short_name} "Returns the id of the survey
given the short name" {
        
    set survey_id [db_string survsimp_id_from_shortname "select survey_id from survsimp_surveys where lower(short_name) = lower(:short_name)" -default ""]   
    
    return $survey_id
}

proc_doc survsimp_survey_get_response_id {survey_id user_id} "Returns the id of the user's most recent response to a survey" {
    
    set response_id [ db_string get_response_id {
        select response_id
        from acs_objects, survsimp_responses
        where object_id = response_id
        and creation_user = :user_id
        and survey_id = :survey_id
        and creation_date = (select max(creation_date)
                             from survsimp_responses, acs_objects
                             where object_id = response_id
                             and creation_user = :user_id
                             and survey_id = :survey_id)                          
    } -default 0]
    
    return $response_id
}

proc_doc survsimp_survey_get_score {survey_id user_id} "Returns the score of the user's most recent response to a survey" {
    
    set response_id [ survsimp_survey_get_response_id $survey_id $user_id ]
    
    if { $response_id != 0 } {
        set score [db_string get_score {
            select 
            sum(score) 
            from survsimp_choice_scores,
            survsimp_question_responses, survsimp_variables
            where
            survsimp_choice_scores.choice_id = survsimp_question_responses.choice_id
            and survsimp_choice_scores.variable_id = survsimp_variables.variable_id
            and survsimp_question_responses.response_id = :response_id } -default 0]
    } else {
        set score {}
    }
    
    return $score
}

proc_doc survsimp_get_response_date {survey_id user_id} "Returns the date of the user's most recent response to a survey" {
    
    set response_id [ survsimp_survey_get_response_id $survey_id $user_id ]

    if { $response_id != 0 } {
        set date [db_string get_date {
            select to_char(creation_date, 'DD/MM/YYYY')
            from acs_objects
            where object_id = :response_id
        } -default 0]
    } else {
        set date {}
    }

    return $date
}

ad_proc -public survsimp_display_types {
} {
    return {list table paragraph}
}

# added by Ben (far later than the code below, bt_mergepice, OMG)
ad_proc -public survsimp_display_type_select {
    {-name "display_type"}
    {-value "list"}
} {
    set return_html "<SELECT name=$name>\n"
    foreach val [survsimp_display_types] {
        append return_html "<OPTION> $val\n"
    }
    append return_html "</SELECT>"

    return $return_html
}
            
proc_doc survsimp_bt_mergepiece {htmlpiece values} {
    HTMLPIECE is a form usually; VALUES is an ns_set

    NEW VERSION DONE BY BEN ADIDA (ben@mit.edu)
    Last modification (ben@mit.edu) on Jan ?? 1998
    added support for dates in the date_entry_widget.
   
    modification (ben@mit.edu) on Jan 12th, 1998
    when the val of an option tag is "", things screwed up
    FIXED.
    
    This used to count the number of vars already introduced
    in the form (see remaining num_vars statements), so as 
    to end early. However, for some unknown reason, this cut off a number 
    of forms. So now, this processes every tag in the HTML form.
} {

    set newhtml ""
    
    set html_piece_ben $htmlpiece

    set num_vars 0

    for {set i 0} {$i<[ns_set size $values]} {incr i} {
	if {[ns_set key $values $i] != ""} {
	    set database_values([ns_set key $values $i]) [philg_quote_double_quotes [ns_set value $values $i]]
	    incr num_vars
	} 
    }

    set vv {[Vv][Aa][Ll][Uu][Ee]}     ; # Sorta obvious
    set nn {[Nn][Aa][Mm][Ee]}         ; # This is too
    set qq {"([^"]*)"}                ; # Matches what's in quotes
    set pp {([^ ]*)}                  ; # Matches a word (mind yer pp and qq)

    set slist {}
    
    set count 0

    while {1} {

	incr count
	set start_point [string first < $html_piece_ben]
	if {$start_point==-1} {
	    append newhtml $html_piece_ben
	    break;
	}
	if {$start_point>0} {
	    append newhtml [string range $html_piece_ben 0 [expr $start_point - 1]]
	}
	set end_point [string first > $html_piece_ben]
	if {$end_point==-1} break
	incr start_point
	incr end_point -1
	set tag [string range $html_piece_ben $start_point $end_point]
	incr end_point 2
	set html_piece_ben [string range $html_piece_ben $end_point end]
	set CAPTAG [string toupper $tag]

	set first_white [string first " " $CAPTAG]
	set first_word [string range $CAPTAG 0 [expr $first_white - 1]]
	
	switch -regexp $CAPTAG {
	    
	    {^INPUT} {
		if {[regexp {TYPE[ ]*=[ ]*("IMAGE"|"SUBMIT"|"RESET"|IMAGE|SUBMIT|RESET)} $CAPTAG]} {
		    
		    ###
		    #   Ignore these
		    ###
		    
		    append newhtml <$tag>
		    
		} elseif {[regexp {TYPE[ ]*=[ ]*("CHECKBOX"|CHECKBOX)} $CAPTAG]} {
		    # philg and jesse added optional whitespace 8/9/97
		    ## If it's a CHECKBOX, we cycle through
		    #  all the possible ns_set pair to see if it should
		    ## end up CHECKED or not.
		    
		    if {[regexp "$nn=$qq" $tag m nam]} {}\
			    elseif {[regexp "$nn=$pp" $tag m nam]} {}\
			    else {set nam ""}
		    
		    if {[regexp "$vv=$qq" $tag m val]} {}\
			    elseif {[regexp "$vv=$pp" $tag m val]} {}\
			    else {set val ""}
		    
		    regsub -all {[Cc][Hh][Ee][Cc][Kk][Ee][Dd]} $tag {} tag
		    
		    # support for multiple check boxes provided by michael cleverly
		    if {[info exists database_values($nam)]} {
			if {[ns_set unique $values $nam]} {
			    if {$database_values($nam) == $val} {
				append tag " checked"
				incr num_vars -1
			    }
			} else {
			    for {set i [ns_set find $values $nam]} {$i < [ns_set size $values]} {incr i} {
				if {[ns_set key $values $i] == $nam && [philg_quote_double_quotes [ns_set value $values $i]] == $val} {
				    append tag " checked"
				    incr num_vars -1
				    break
				}
			    }
			}
		    }

		    append newhtml <$tag>
		    
		} elseif {[regexp {TYPE[ ]*=[ ]*("RADIO"|RADIO)} $CAPTAG]} {
		    
		    ## If it's a RADIO, we remove all the other
		    #  choices beyond the first to keep from having
		    ## more than one CHECKED
		    
		    if {[regexp "$nn=$qq" $tag m nam]} {}\
			    elseif {[regexp "$nn=$pp" $tag m nam]} {}\
			    else {set nam ""}
		    
		    if {[regexp "$vv=$qq" $tag m val]} {}\
			    elseif {[regexp "$vv=$pp" $tag m val]} {}\
			    else {set val ""}
		    
		    #Modified by Ben Adida (ben@mit.edu) so that
		    # the checked tags are eliminated only if something
		    # is in the database. 
		    
		    if {[info exists database_values($nam)]} {
			regsub -all {[Cc][Hh][Ee][Cc][Kk][Ee][Dd]} $tag {} tag
			if {$database_values($nam)==$val} {
			    append tag " checked"
			    incr num_vars -1
			}
		    }
		    
		    append newhtml <$tag>
		    
		} else {
		    
		    ## If it's an INPUT TYPE that hasn't been covered
		    #  (text, password, hidden, other (defaults to text))
		    ## then we add/replace the VALUE tag
		    
		    if {[regexp "$nn=$qq" $tag m nam]} {}\
			    elseif {[regexp "$nn=$pp" $tag m nam]} {}\
			    else {set nam ""}

		    set nam [ns_urldecode $nam]

		    if {[info exists database_values($nam)]} {
			regsub -all "$vv=$qq" $tag {} tag
			regsub -all "$vv=$pp" $tag {} tag
			append tag " value=\"$database_values($nam)\""
			incr num_vars -1
		    } else {
			if {[regexp {ColValue.([^.]*).([^ ]*)} $tag all nam type]} {
			    set nam [ns_urldecode $nam]
			    set typ ""
			    if {[string match $type "day"]} {
				set typ "day"
			    }
			    if {[string match $type "year"]} {
				set typ "year"
			    }
			    if {$typ != ""} {
				if {[info exists database_values($nam)]} {
				    regsub -all "$vv=$qq" $tag {} tag
				    regsub -all "$vv=$pp" $tag {} tag
				    append tag " value=\"[ns_parsesqldate $typ $database_values($nam)]\""
				}
			    }
			    #append tag "><nam=$nam type=$type typ=$typ" 
			}
		    }
		    append newhtml <$tag>
		}
	    }
	    
	    {^TEXTAREA} {
		
		###
		#   Fill in the middle of this tag
		###
		
		if {[regexp "$nn=$qq" $tag m nam]} {}\
			elseif {[regexp "$nn=$pp" $tag m nam]} {}\
			else {set nam ""}
		
		if {[info exists database_values($nam)]} {
		    while {![regexp {^<( *)/[Tt][Ee][Xx][Tt][Aa][Rr][Ee][Aa]} $html_piece_ben]} {
			regexp {^.[^<]*(.*)} $html_piece_ben m html_piece_ben
		    }
		    append newhtml <$tag>$database_values($nam)
		    incr num_vars -1
		} else {
		    append newhtml <$tag>
		}
	    }
	    
	    {^SELECT} {
		
		###
		#   Set the snam flag, and perhaps smul, too
		###
		
		set smul [regexp "MULTIPLE" $CAPTAG]
		
		set sflg 1
		
		set select_date 0
		
		if {[regexp "$nn=$qq" $tag m snam]} {}\
			elseif {[regexp "$nn=$pp" $tag m snam]} {}\
			else {set snam ""}

		set snam [ns_urldecode $snam]

		# In case it's a date
		if {[regexp {ColValue.([^.]*).month} $snam all real_snam]} {
		    if {[info exists database_values($real_snam)]} {
			set snam $real_snam
			set select_date 1
		    }
		}
		
		lappend slist $snam
		
		append newhtml <$tag>
	    }
	    
	    {^OPTION} {
		
		###
		#   Find the value for this
		###
		
		if {$snam != ""} {
		    
		    if {[lsearch -exact $slist $snam] != -1} {regsub -all {[Ss][Ee][Ll][Ee][Cc][Tt][Ee][Dd]} $tag {} tag}
		    
		    if {[regexp "$vv *= *$qq" $tag m opt]} {}\
			    elseif {[regexp "$vv *= *$pp" $tag m opt]} {}\
			    else {
			if {[info exists opt]} {
			    unset opt
		    }   }
		    # at this point we've figured out what the default from the form was
		    # and put it in $opt (if the default was spec'd inside the OPTION tag
		    # just in case it wasn't, we're going to look for it in the 
		    # human-readable part
		    regexp {^([^<]*)(.*)} $html_piece_ben m txt html_piece_ben
		    if {![info exists opt]} {
			set val [string trim $txt]
		    } else {
			set val $opt
		    }
		    
		    if {[info exists database_values($snam)]} {
			# If we're dealing with a date
			if {$select_date == 1} {
			    set db_val [ns_parsesqldate month $database_values($snam)]
			} else {
			    set db_val $database_values($snam)
			}

			if {
			    ($smul || $sflg) &&
			    [string match $db_val $val]
			} then {
			    append tag " selected"
			    incr num_vars -1
			    set sflg 0
			}
		    }
		}
		append newhtml <$tag>$txt
	    }
	    
	    {^/SELECT} {
		    
		###
		#   Do we need to add to the end?
		###
		
		set txt ""
		
		if {$snam != ""} {
		    if {[info exists database_values($snam)] && $sflg} {
			append txt "<option selected>$database_values($snam)"
			incr num_vars -1
			if {!$smul} {set snam ""}
		    }
		}
		
		append newhtml $txt<$tag>
	    }
	    
	    {default} {
		append newhtml <$tag>
	    }
	}
	
    }
    return $newhtml
}
            
