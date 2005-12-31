ad_page_contract {

    Display the user's previous responses.

    @param   survey_id   id of survey for which responses are displayed
    @param   return_url  if provided, generate a 'return' link to that URL
    @param   group_id    if specified, display all the responses for all
                         users of that group

    @author  philg@mit.edu
    @author  nstrug@arsdigita.com
    @creation-date    28th September 2000
    @cvs-id  $Id$
} {

    survey_id:integer
    {return_url ""}
    {group_id:integer ""}

} -validate {
        survey_exists -requires {survey_id} {
	    if ![db_0or1row survey_exists {
		select 1 from survsimp_surveys where survey_id = :survey_id
	    }] {
		ad_complain "Survey $survey_id does not exist"
	    }
	}
} -properties {
    survey_name:onerow
    description:onerow
    responses:multirow
}

# If group_id is specified, we return all the responses for that group by any user

set user_id [ad_verify_and_get_user_id]

db_1row survey_info { select name, description
    from survsimp_surveys
    where survey_id = :survey_id
} -column_array survey

set survey_name $survey(name)
set description $survey(description)
set context [list [list "index" "Surveys"] [list "one?[export_url_vars survey_id]" "One survey"] "Responses"]

if { ![empty_string_p $group_id] } {
    set limit_to_sql "group_id = :group_id"
} else {
    set limit_to_sql "user_id = :user_id"
}

#
# why not a db_multirow? Well, we need to use the survsimp_answer_summary_display proc to generate HTML
# db_multirow doesn't have a side-effect block, so we have to build up the multirow by hand
# the template::multirow seems broken...

### incr rownum added to support postgresql
set rownum 1
db_foreach response_ids_select {} {
    set submission_date_ansi [lc_time_system_to_conn $submission_date_ansi]
    set pretty_submission_date [lc_time_fmt $submission_date_ansi "%x %X"]

    set array_val responses:$rownum
    set [set array_val](submission_date) $creation_date
    set [set array_val](pretty_submission_date) $pretty_submission_date
    set [set array_val](answer_summary) [survsimp_answer_summary_display $response_id 1] 
    set [set array_val](rownum) $rownum
    incr rownum
}
set responses:rowcount [expr { $rownum - 1 }]
db_release_unused_handles
ad_return_template
