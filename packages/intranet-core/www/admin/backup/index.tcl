# /packages/intranet-core/www/admin/menus/index.tcl
#
# Copyright (C) 2004 ]project-open[
# The code is based on ArsDigita ACS 3.4
#
# This program is free software. You can redistribute it
# and/or modify it under the terms of the GNU General
# Public License as published by the Free Software Foundation;
# either version 2 of the License, or (at your option)
# any later version. This program is distributed in the
# hope that it will be useful, but WITHOUT ANY WARRANTY;
# without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.
# See the GNU General Public License for more details.

ad_page_contract {
    Show the permissions for all menus in the system

    @author frank.bergmann@project-open.com
} {
    { return_url "/intranet/admin/backup/index" }

    item_remove:optional
    filename:multiple,optional
}

# ------------------------------------------------------
# Defaults & Security
# ------------------------------------------------------

set user_id [ad_maybe_redirect_for_registration]
set user_is_admin_p [im_is_user_site_wide_or_intranet_admin $user_id]

if {!$user_is_admin_p} {
    ad_return_complaint 1 "You have insufficient privileges to use this page"
    return
}

set page_title "Backup & Restore"
set context_bar [im_context_bar $page_title]
set context ""
set find_cmd [parameter::get -package_id [im_package_core_id] -parameter "FindCmd" -default "/bin/find"]

set menu_url "/intranet/admin/menus/new"
set toggle_url "/intranet/admin/toggle"
set group_url "/admin/groups/one"

set bgcolor(0) " class=rowodd"
set bgcolor(1) " class=roweven"

# ------------------------------------------------------
# Get the list of backup sets for restore
# ------------------------------------------------------

# Get the list of all backup sets under backup_path
set backup_path [im_backup_path]
set backup_path_exists_p [file exists $backup_path]
set not_backup_path_exists_p [expr !$backup_path_exists_p]
set file_body ""

multirow create backup_files filename file_body extension date size restore_p

foreach file [lsort [glob -nocomplain -type f -directory $backup_path "pg_dump.*.{sql,pgdmp,gz,bz2}"]]  {
    set trim [string range $file [string length $backup_path] end]

    if {[regexp {(\d\d\d\d)(\d\d)(\d\d)\.(\d\d)(\d\d)\d\d\.([0-9a-z\.]+)$} $trim match file_year file_month file_day file_hour file_second file_extension]} {

	# Get rid of the leading "/" of $match
	if {[regexp {^\/(.*)} $trim match body]} { set file_body $body }
	if { ""==$file_body } { set file_body $file }

	# File needs to end in "*.sql" in order to be restorable
	set restore_p [regexp {\.sql$} $file_body]

	multirow append backup_files \
	    $file \
	    $file_body \
	    $file_extension \
	    "$file_day.$file_month.$file_year $file_hour:$file_second" \
	    [file size $file] \
	    $restore_p
    }
}

set actions [list \
		 [lang::message::lookup "" intranet-core.New_Backup "New Backup"] \
		 [export_vars -base pg_dump] \
		 [lang::message::lookup "" intranet-core.Create_new_backup_dump "Create a new backup dump"] \
		 [lang::message::lookup "" intranet-core.Upload_backup_dump "Upload Backup"] \
		 [export_vars -base upload-pgdump] \
		 [lang::message::lookup "" intranet-core.Upload_an_existing_backup "Upload an existing backup dump from your filesystem into this backup list"] \
]

set bulk_actions [list \
		      [lang::message::lookup "" intranet-core.Backup_Delete "Delete"] \
		      "delete-pgdump" \
		      [lang::message::lookup "" intranet-core.Backup_Delete_checked_backup_dumps "Remove checked backup dumps"] \
		      [lang::message::lookup "" intranet-core.Backup_Bzip "Bzip"] \
		      "bzip-pgdump" \
		      [lang::message::lookup "" intranet-core.Backup_Compress_the_backup_dump "Compress the backup dump using bzip2"] \
		      [lang::message::lookup "" intranet-core.Backup_Un_Bzip "Un-Bzip"] \
		      "unbzip-pgdump" \
		      [lang::message::lookup "" intranet-core.Backup_Uncompress_backup_dump "Uncompress backup dump"] \
]


template::list::create \
    -name backup_files \
    -key filename \
    -elements [list \
		   filename [list \
		       label [lang::message::lookup "" intranet-core.Backup_File_Name "File Name"] \
		       link_url_eval "/intranet/admin/backup/download/$file_body" \
		   ] \
		   extension [list \
				  label [lang::message::lookup "" intranet-core.Backup_Type "Type"] \
		   ] \
		   date [list \
			     label [lang::message::lookup "" intranet-core.Backup_Date "Date"] \
		   ] \
		   size [list \
			     label [lang::message::lookup "" intranet-core.Backup_Size "Size"] \
		       html { align right } \
		   ] \
		   restore [list \
			       display_template {
				   <if @backup_files.restore_p@>
				   <a class=button href="restore-pgdmp?filename=@backup_files.filename@&return_url=$return_url">[lang::message::lookup "" intranet-core.Backup_restore "Restore"]</a>
				   </if>
			       } \
		   ] \
    ] \
    -bulk_actions $bulk_actions \
    -bulk_action_method post \
    -bulk_action_export_vars { return_url } \
    -actions $actions






# ---------------------------------------------------------------
# Left-Navbar
# ---------------------------------------------------------------

set admin_html "
<br><ul>
<li><a href=\"[export_vars -base reinstall-tsearch2]\">[lang::message::lookup "" intranet-core.Reinstall_TSearch2  "Reinstall TSearch2 Search Engine"]</a>
</ul><br>
"

set left_navbar_html "
            <div class=\"filter-block\">
                <div class=\"filter-title\">
                    [lang::message::lookup "" intranet-helpdesk.Admin_Actions "Admin Actions"]
                </div>
                $admin_html
            </div>
            <hr/>
"
