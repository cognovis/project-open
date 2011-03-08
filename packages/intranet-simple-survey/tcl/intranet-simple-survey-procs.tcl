# /tcl/intranet-simple-survey-procs.tcl
#
# Copyright (C) 2006-2009 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.


ad_library {
    Associate Simple Surveys with ]po[ business objects 
    and allow to manage their relationship and recurrence.

    @author frank.bergmann@project-open.com
    @creation-date  January 3rd, 2006
}


# -----------------------------------------------------------
# Standard procedures
# -----------------------------------------------------------

ad_proc -public im_package_survsimp_id { } {
} {
    return [util_memoize "im_package_survsimp_id_helper"]
}

ad_proc -private im_package_survsimp_id_helper {} {
    return [db_string im_package_core_id {
        select package_id from apm_packages
        where package_key = 'intranet-simple-survey'
    } -default 0]
}


# -----------------------------------------------------------
# Component showing a) survey to fill out and b) surveys related to this object
# -----------------------------------------------------------

ad_proc im_survsimp_component { object_id } {
    Shows all associated simple surveys for a given project or company
} {
    set bgcolor(0) "class=roweven"
    set bgcolor(1) "class=rowodd"
    set survey_url "/simple-survey/one"
    set max_header_len [parameter::get_from_package_key -package_key "intranet-simple-survey" -parameter "MaxTableHeaderLen" -default 8]
    set max_clob_len 20

    set current_user_id [ad_get_user_id]

    # Get information about object type
    db_1row object_type_info "
	select	aot.*,
		aot.pretty_name as aot_pretty_name,
		im_biz_object__type(:object_id) as object_type_id
	from	acs_object_types aot
	where	object_type = (
			select object_type 
			from acs_objects 
			where object_id = :object_id
		)
    "

    # -----------------------------------------------------------
    # Surveys to fill out

    set survsimp_sql "
	select
		som.*,
		som.name as som_name,
		som.note as som_note,
		ss.*
	from
		im_survsimp_object_map som,
		survsimp_surveys ss
	where
		som.survey_id = ss.survey_id
		and som.acs_object_type = :object_type
		and (
			som.biz_object_type_id is null
			OR som.biz_object_type_id = :object_type_id 
		    )
		and im_object_permission_p(ss.survey_id, :current_user_id, 'survsimp_take_survey') = 't'
    "

    set survsimp_html "
	<table>
	<tr class=rowtitle><td>Survey</td><td>Comment</td></tr>
    "
    set ctr 0
    db_foreach survsimp_map $survsimp_sql {
	set som_gif ""
	if {"" != $som_note} {set som_gif [im_gif help $som_note]}
	append survsimp_html "
	    <tr $bgcolor([expr $ctr % 2])>
		<td><a href=\"$survey_url?survey_id=$survey_id\">$short_name</a></td>
		<td>$som_name $som_gif</td>
	    </tr>
	"
	incr ctr
    }

    append survsimp_html "</table>\n"
    if {0 == $ctr} { set survsimp_html "" }

    # -----------------------------------------------------------
    # Surveys Related to This User

    set survsimp_responses_sql "
	select
		s.survey_id,
		r.response_id,
		o.creation_user as creation_user_id,
		im_name_from_user_id(o.creation_user) as creation_user_name,
		s.name as survey_name,
		r.related_context_id,
		acs_object__name(r.related_context_id) as related_context_name,
		ibou.url as related_context_object_url
	from
		survsimp_responses r
		LEFT OUTER JOIN acs_objects rco ON (r.related_context_id = rco.object_id)
		LEFT OUTER JOIN (
			select	*
			from	im_biz_object_urls
			where	url_type = 'view'
		) ibou ON (rco.object_type = ibou.object_type),
		survsimp_surveys s,
		acs_objects o
	where
		r.survey_id = s.survey_id and
		r.related_object_id = :object_id and
		r.response_id = o.object_id
	order by
		s.survey_id,
		r.response_id DESC
    "
    set responses_list_list [db_list_of_lists responses $survsimp_responses_sql]

    set survsimp_response_html ""
    set old_survey_id 0
    set response_ctr 0
    set colspan 2
    foreach response $responses_list_list {

	set survey_id [lindex $response 0]
	set response_id [lindex $response 1]
	set creation_user_id [lindex $response 2]
	set creation_user_name [lindex $response 3]
	set survey_name [lindex $response 4]
	set related_context_id [lindex $response 5]
	set related_context_name [lindex $response 6]
	set related_context_url [lindex $response 7]

	# Create new headers for new surveys
	if {$survey_id != $old_survey_id} {
	    if {0 != $old_survey_id} {
		# Close the last table
		append survsimp_response_html "</table>\n"
	    }
	
	    set questions_sql "
		select	substring(question_text for $max_header_len) as question_text
		from	survsimp_questions
		where	survey_id = :survey_id
		order by sort_key
	    "
	    set survey_header "<tr class=rowtitle>\n"
	    append survey_header "<td class=rowtitle>[lang::message::lookup "" intranet-simple-survey.Entered_By "Entered By"]</td>\n"
	    append survey_header "<td class=rowtitle>[lang::message::lookup "" intranet-simple-survey.Context "Context"]</td>\n"
	    set colspan 2
	    db_foreach q $questions_sql {
		if {[string length $question_text] == $max_header_len} { append question_text "..." }
		append survey_header "<td class=rowtitle>$question_text</td>\n"
		incr colspan
	    }
	    append survey_header "</tr>\n"
	    append survsimp_response_html "
		<table>
		  <tr class=rowtitle><td class=rowtitle colspan=$colspan align=center>$survey_name</td></tr>
	    "
	    append survsimp_response_html $survey_header

	    set old_survey_id $survey_id
	}

	set questions_sql "
		select	r.response_id,
			r.question_id,
			r.choice_id,
			sqc.label as choice,
			r.boolean_answer,
			substring(r.clob_answer for :max_clob_len) as clob_answer,
			r.number_answer,
			r.varchar_answer,
			r.date_answer
		from	survsimp_questions q,
			survsimp_question_responses r
			LEFT OUTER JOIN survsimp_question_choices sqc ON (r.choice_id = sqc.choice_id)
		where	q.question_id = r.question_id
			and r.response_id = :response_id
		order by sort_key
	"
	append survsimp_response_html "
		<tr $bgcolor([expr $response_ctr % 2])>
		<td $bgcolor([expr $response_ctr % 2])>
			<a href=[export_vars -base "/intranet/users/view" {{user_id $creation_user_id}}]
			>$creation_user_name</a>
		</td>
		<td $bgcolor([expr $response_ctr % 2])>
			<a href=\"$related_context_url$related_context_id\"
			>$related_context_name</a>
		</td>
	"
	db_foreach q $questions_sql {
	    if {[string length $clob_answer] == $max_clob_len} { append clob_answer " ..." }
	    append survsimp_response_html "
		<td $bgcolor([expr $response_ctr % 2])>
		$choice $boolean_answer $clob_answer $number_answer $varchar_answer $date_answer
		</td>
	    "
	}
	append survsimp_response_html "</tr>\n"

	incr response_ctr
    }

    if {0 != $old_survey_id} {
	append survsimp_response_html "</table>\n"
    }
    if {0 == $response_ctr} { set survsimp_response_html "" }

    # -----------------------------------------------------------
    # Return the results

    set take_survy_l10n [lang::message::lookup "" intranet-simple-survey.Take_a_Survey "Take a survey"]
    set return_url [im_url_with_query]
    set take_survey_url [export_vars -base "/simple-survey/" {{related_object_id $object_id} {related_context_id $object_id} return_url}]
    append survsimp_response_html "
	<ul>
	<li><a href=\"$take_survey_url\">$take_survy_l10n</a></li>
	</ul>
    "

    return "${survsimp_html}${survsimp_response_html}"
}

