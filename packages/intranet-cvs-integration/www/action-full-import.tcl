# packages/intranet-cvs-integration/www/action-full-import.tcl

ad_page_contract {
    Bulk action on CVS repositories to execute a full import.
    @author Frank Bergmann (frank.bergmann@project-open.com)
    @creation-date 2005-01-25
    @cvs-id
} {
    repository_id:multiple,integer,notnull
    { return_url "/intranet-cvs-integration/www/index" }
} -properties {
} -validate {
} -errors {
}

# ******************************************************
# Default & Security
# ******************************************************

set user_id [ad_maybe_redirect_for_registration]
set user_is_admin_p [im_is_user_site_wide_or_intranet_admin $user_id]
if {!$user_is_admin_p} {
    ad_return_complaint 1 "You have insufficient privileges to use this page"
    return
}

set title [lang::message::lookup "" intranet-cvs-integration.Full_Import "Full Import of CVS Logs"]
set context [list [list "$return_url" "CVS Repositories"] $title]


# ******************************************************
# Write HTTP headers and start the page
# ******************************************************

# Write out HTTP header, considering CSV/MS-Excel formatting
im_report_write_http_headers -output_format html

ns_write "
	[im_header]
	[im_navbar]

	<h1>$title</h1>
"

ns_write "<ul>\n"


# -------------------------------------------------
# Check for duplicate CVS users
set duplicate_cvs_users_sql "
	select	cvs_user
	from	(
		select	count(*) as cnt,
			lower(cvs_user) as cvs_user
		from	persons
		group by lower(cvs_user)
		) t
	where
		cnt > 1 and
		lower(cvs_user) not in ('anonymous') and
		cvs_user is not null
"

set dup_cvs_users [list]
db_foreach dup_cvs_users $duplicate_cvs_users_sql {
    ns_write "<li><font color=red>Duplicate CVS user '$cvs_user': Please eliminate.</font>\n"
    lappend dup_cvs_users "'$cvs_user'"
}

if {[llength $dup_cvs_users] > 0} {
    ns_write "</ul>\n"
    ns_write "<ul>\n"
}

lappend dup_cvs_users "'anonymous'"

# -------------------------------------------------
# Map unique CVS user to person_id

set user_map_sql "
	select	person_id,
		lower(cvs_user) as cvs_user
	from	persons
	where	lower(cvs_user) not in ([join $dup_cvs_users ","])
"
db_foreach cvs_user_map $user_map_sql {
    set cvs_user_hash($cvs_user) $person_id
}



foreach repo_id $repository_id {

    db_1row repo_info "
	select	*,
		conf_item_nr as repo_name
	from	im_conf_items
	where	conf_item_id = :repo_id
    "

    set cvs_read [acs_root_dir]/packages/intranet-cvs-integration/perl/cvs_read.pl
    set command [list exec $cvs_read -cvsdir :pserver:${cvs_user}:${cvs_password}@${cvs_hostname}:${cvs_path} -rlog $repo_name]

    ns_write "</ul>\n"
    ns_write "<h3>Importing from $cvs_repository</h3>\n"
    ns_write "<ul>\n"
    ns_write "<li>Import Script: '$cvs_read' (this script comes as part of 
    set csv ""
    if {[catch {
	set csv [eval $command]
    } err_msg]} {
	ns_write "<li><font><pre>$err_msg</pre></font>\n"
    }


    # -------------------------------------------------
    # Go though all lines, check if they exist already and insert

    ns_write "<pre>\n"

    set lines [split $csv "\n"]
   
    foreach line $lines {

	# /home/cvsroot/acs-admin/acs-admin.info acs-admin 1.3 {2007/07/14 18:15:45} cvs Exp 1 0 {\n- updated license information\n}
	# Write out the line
	ns_write "<li>$line\n"

	set values [split $line "\t"]

	set filename [lindex $values 0]
	set project [lindex $values 1]
	set revision [lindex $values 2]
	set date [lindex $values 3]
	set author [lindex $values 4]
	set state [lindex $values 5]
	set lines_add [lindex $values 6]
	set lines_del [lindex $values 7]
	set comment [lindex $values 8]

	set person_id ""
	if {[info exists cvs_user_hash($author)]} { set person_id $cvs_user_hash($author) }

	# Check if the line is already in the DB
	set key "$filename-$date-$revision"
	if {[info exists log_hash($key)]} { continue }

	if {[catch {
	    db_dml cvs_insert "
		insert into im_cvs_logs (
			cvs_line_id,
			cvs_project,
			cvs_filename,
			cvs_revision,
			cvs_date,
			cvs_author,
			cvs_state,
			cvs_lines_add,
			cvs_lines_del,
			cvs_note,
			cvs_user_id,
			cvs_conf_item_id
		) values (
			nextval('im_cvs_logs_seq'),
			:project,
			:filename,
			:revision,
			:date,
			:author,
			:state,
			:lines_add,
			:lines_del,
			:comment,
			:person_id,
			:repo_id
		)
	    "
	} err_msg]} {
	    # error - probably because of duplicate key, ignore
	    ns_write "<li><font color=red>$err_msg</font>\n"
	} else {
	    ns_write "."
#	    ns_write "key=$key, filename=$filename, project=$project, revision=$revision, date=$date, author=$author, state=$state, add=$lines_add, del=$lines_del, comment=$comment\n"
	}

    }

    ns_write "</pre>\n"


}

ns_write "<li>Finished.\n"

ns_write "</ul>\n"

ns_write "
	[im_footer]
"
