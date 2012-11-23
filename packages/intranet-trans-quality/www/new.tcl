# /packages/intranet-trans-quality/www/new.tcl

# ---------------------------------------------------------------
# Page Contract
# ---------------------------------------------------------------

ad_page_contract { 
    @author Guillermo Belcic Bardaji
    @author Frank Bergmann (frank.bergmann@project-open.com)
} {
    { task_id:integer 0 }
    { report_id:integer 0 }
    { project_id:integer 0 }
    { form_mode "display" }
    { return_url "" }
}

# ---------------------------------------------------------------
# Defaults & Security
# ---------------------------------------------------------------

set user_id [ad_maybe_redirect_for_registration]
set todays_date [lindex [split [ns_localsqltimestamp] " "] 0]
set page_title "One Quality Report"
set context_bar [im_context_bar $page_title]
set view_user_url "/intranet/users/view"
set current_url [im_url_with_query]

set bgcolor(0) " class=roweven"
set bgcolor(1) " class=rowodd"

if {![im_permission $user_id view_trans_quality]} {
    ad_return_complaint 1 "<li>[_ intranet-core.lt_You_have_insufficient_6]"
    return
}

# Get write permission
set add_trans_quality_p [im_permission $user_id add_trans_quality]


if {0 == $task_id && 0 == $report_id && 0 != $project_id} {
    # A project has been specified, but no task
    # => redirect to a page to select a translation task
    # for this projects and return.
    set return_url $current_url
    set url "project-task-select?[export_url_vars project_id return_url]"
    ad_returnredirect $url
}

if {0 == $task_id && 0 == $report_id} {
    ad_return_complaint 1 "<li>You must specify either task_id, report_id or project_id"
    return
}

# ---------------------------------------------------------------
# Get everything about the task, its project etc.
# ---------------------------------------------------------------

# Check if there is already a q-report for the specified task 
if {0 != $task_id} {
    # There is max 1 report per task, enforced by
    # a unique criterium on task_id in im_trans_quality_reports
    #
    set report_id [db_string get_report_i "select report_id from im_trans_quality_reports where task_id = :task_id" -default 0]
}

# Get the task_id if the report was specified
if {0 == $task_id && 0 != $report_id} {
    set task_id [db_string get_task_from_report "select task_id from im_trans_quality_reports where report_id=:report_id" -default 0]
}

# Set the forum_mode to "edit" if the report doesn't exist yet
if {0 == $report_id} {
    set form_mode "edit"
}


# This information always needs to be present,
# because we can't file a q-report without the
# translation task and hence the translation 
# project.
#
if [catch {
	db_1row task_evaluation {
	select
		t.*,
		t.task_units as words,
	        im_category_from_id(t.task_type_id) as task_type,
		im_category_from_id(t.task_status_id) as task_status,
		im_name_from_user_id(t.trans_id) as translator_name,
		im_name_from_user_id(t.edit_id) as editor_name,
		im_name_from_user_id(t.proof_id) as proofer_name,
		im_name_from_user_id(t.other_id) as other_name,
		p.project_name,
		p.project_nr,
		p.expected_quality_id,
		im_category_from_id(p.expected_quality_id) as expected_quality,
		c.company_id,
		c.company_name,
		im_name_from_user_id(p.project_lead_id) as manager_name,
		im_category_from_id (t.source_language_id) as source_language,
		im_category_from_id (t.target_language_id) as target_language,
		im_name_from_user_id(:user_id) as current_user_name
	from
		im_trans_tasks t,
		im_projects p,
		im_companies c
	where
		t.task_id = :task_id
		and t.project_id = p.project_id
		and p.company_id = c.company_id
	}
} errmsg] {
    ad_return_complaint 1 "<li>Error while getting information about translation task '$task_id':<br><pre>$errmsg</pre>"
    return
}

# ---------------------------------------------------------------
# Get everything about the report, if there is one.
# There can be atmost one report per task...
# ---------------------------------------------------------------

# set default values in case we start a new report
#
set report_date $todays_date
set sample_size ""
set reviewer_id ""
set allowed_error_percentage [im_transq_error_percentage $expected_quality_id]
set comments ""
set new_report 0

if {0 != $task_id} {
    # task_id specified - either a new or an existing report

    if [catch {
	db_1row get_report {
	select
		r.*
	from
		im_trans_quality_reports r
	where
		r.task_id = :task_id
	}

    } errmsg] {

	# Error getting the report. So let's setup a new one:
	set report_id [db_nextval quality_report_id]
	set new_report 1
    }

} else {

    # report_id specified - get the report
    if [catch {
	db_1row get_report {
	select
		r.*
	from
		im_trans_quality_reports e,
	where
		r.report_id = :report_id
	}
    } errmsg] {
    }
}


# ---------------------------------------------------------------
# Prepare the mask for filling in errors
# ---------------------------------------------------------------

set total_header ""
if {[string equal "display" $form_mode]} { 
    set total_header "<td align=center class=rowtitle>Sum</td>"
}

set errors_html "
        <table border=0 cellspacing=1 cellpadding=1>
        <tr class=rowtitle>
          <td align=center class=rowtitle>Category</td>
          <td align=center class=rowtitle>Minor</td>
          <td align=center class=rowtitle>Major</td>
          <td align=center class=rowtitle>Critical</td>
	  $total_header
        </tr>\n"

set size 5
set ctr 0
set error_sum 0
db_foreach error_list "" {

    set minor "<input type=text name=minor_errors.$category_id size=$size value=\"$minor_errors\">"
    set major "<input type=text name=major_errors.$category_id size=$size value=\"$major_errors\">"
    set critical "<input type=text name=critical_errors.$category_id size=$size value=\"$critical_errors\">"
    set total_col ""

    if {[string equal "display" $form_mode]} { 
	set minor $minor_errors
	set major $major_errors
	set critical $critical_errors

	set total_errors [im_transq_total_errors $minor_errors $major_errors $critical_errors]
	set total_col "<td align=right>$total_errors</td>\n"
	set error_sum [expr $error_sum + $total_errors]
    }

    append errors_html "
        <tr $bgcolor([expr $ctr % 2])>
          <td>$quality_category</td>
          <td align=right>$minor</td>
          <td align=right>$major</td>
          <td align=right>$critical</td>
	  $total_col
        </tr>\n"

    incr ctr
}


# ---------------------------------------------------------------
# Show a summary with allowed against real errors
# ---------------------------------------------------------------

if {[string equal "display" $form_mode]} {

    if {"" == $sample_size} {
	set allowed_errors ""
    } else {
	set allowed_errors [expr $sample_size * $allowed_error_percentage / 100]
    }

    append errors_html "
	<tr $bgcolor([expr $ctr % 2])>
	  <td colspan=4 align=right>Allowed Errors</td>
	  <td align=right><strong>$allowed_errors</strong></td>
	</tr>\n"

    incr ctr

    append errors_html "
	<tr $bgcolor([expr $ctr % 2])>
	  <td colspan=4 align=right>Total Errors</td>
	  <td align=right><strong>$error_sum</strong></td>
	</tr>\n"

    incr ctr
}


if {[string equal "display" $form_mode]} {

    # Show the comments only if not empty
    #
    if {"" != $comments} {
	append errors_html "
        <tr $bgcolor([expr $ctr % 2])>
          <td>Comments</td>
          <td colspan=4>$comments</td>
        </tr>\n"

	incr ctr
    }

}

append errors_html "</table>\n"


if {![string equal "display" $form_mode]} {

    append errors_html "
	<br>
	<table border=0 cellspacing=1 cellpadding=1>
        <tr class=rowtitle>
          <td align=center class=rowtitle>Comments</td>
        </tr>
        <tr $bgcolor([expr $ctr % 2])>
          <td>
	    <textarea name=comments cols=30 rows=5>$comments</textarea>
	  </td>
        </tr>
	</table>
    "
}

