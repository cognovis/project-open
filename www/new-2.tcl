# /packages/intranet-trans-quality/www/new-2

# ---------------------------------------------------------------
# Page Contract
# ---------------------------------------------------------------

ad_page_contract {
    @author Guillermo Belcic Bardaji
    @author Frank Bergmann (frank.bergmann@project-open.com)
    @cvs-id
} {
    report_id:integer
    task_id:integer
    project_id:integer
    expected_quality_id:integer
    minor_errors:array
    major_errors:array
    critical_errors:array
    report_date
    sample_size:integer,notnull
    { comments "" }
    return_url
}

# ---------------------------------------------------------------
# Defaults & Security
# ---------------------------------------------------------------

# User id already verified by filters
set user_id [ad_get_user_id]
set today [lindex [split [ns_localsqltimestamp] " "] 0]
set current_user_id [ad_maybe_redirect_for_registration]
set date_format "YYYY-MM-DD"

set page_title "Quality"
set context_bar [im_context_bar $page_title]


if {![im_permission $user_id add_trans_quality]} {
    ad_return_complaint 1 "<li>[_ intranet-core.lt_You_have_insufficient_6]"
    return
}


# ---------------------------------------------------------------
# Save the main quality report
# ---------------------------------------------------------------

# Get the max amount of errors for the given quality level
#
set allowed_error_percentage [im_transq_error_percentage $expected_quality_id]


set exists [db_string report_entry_exists "
        select  count(*)
        from    im_trans_quality_reports
        where   report_id = :report_id
"]


if {!$exists} {
    db_dml insert_quality_report "
	insert into im_trans_quality_reports (
		report_id
	) values (
		:report_id
	)
    "
}

db_dml update_quality_report "
	update im_trans_quality_reports set
		task_id = :task_id,
		report_date = to_date(:report_date, :date_format),
		reviewer_id = :user_id,
		sample_size = :sample_size,
		allowed_error_percentage = :allowed_error_percentage,
		comments = :comments,
		allowed_errors = $sample_size * $allowed_error_percentage / 100
	where
		report_id = :report_id
    "

# ---------------------------------------------------------------
# Save the individual error lines
# ---------------------------------------------------------------


set err_category_ids [array names minor_errors]

foreach err_category_id $err_category_ids {
    set exists [db_string report_entry_exists "
	select	count(*)
	from	im_trans_quality_entries
	where	report_id = :report_id
		and quality_category_id = :err_category_id
    "]

    # Read the values from the array
    set minors $minor_errors($err_category_id)
    set majors $major_errors($err_category_id)
    set criticals $critical_errors($err_category_id)

    if {!$exists} {
	db_dml insert_quality_entry "
		insert into im_trans_quality_entries (
			report_id,
			quality_category_id
		) values (
			:report_id,
			:err_category_id
		)
	"
    }


    db_dml update_quality_entry "
	update im_trans_quality_entries set
		minor_errors = :minors,
		major_errors = :majors,
		critical_errors = :criticals
	where
		report_id = :report_id
		and quality_category_id = :err_category_id
    "

}



# ---------------------------------------------------------------
# Update the report error summary
# ---------------------------------------------------------------

db_dml update_quality_report_total "
	update im_trans_quality_reports set
		total_errors = (
			select
				SUM(im_transq_weighted_error_sum(
					t.task_id, 
					t.project_id, 
					qe.minor_errors, 
					qe.major_errors, 
					qe.critical_errors
				))
			from	im_trans_tasks t,
				im_trans_quality_reports qr,
				im_trans_quality_entries qe
			where
				qr.report_id = :report_id
				and qr.task_id = t.task_id
				and qr.report_id = qe.report_id
		)
	where
		report_id = :report_id
    "



# ---------------------------------------------------------------
# Return to where we came from
# ---------------------------------------------------------------

if {"" == $return_url} {
    set return_url "/intranet/projects/view?project_id=$project_id"
}

ad_returnredirect $return_url

