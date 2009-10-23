# /packages/intranet-filestorage/action.tcl
#
# Copyright (C) 2003 - 2009 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

ad_page_contract {
    Single point of entry for all FS related actions.
    We need this, because we are using form buttons
    instead of JavaScript, so that there is only a
    single target for the form.

    @param submit (up-folder, new-folder, upload, new-doc, del, zip)

    @author pvilarmau@hotmail.com
    @author santitrenchs@santitrenchs.com
    @author frank.bergmann@project-open.com
} {
    actions
    file_id:array,optional
    dir_id:array,optional
    id_path:array,optional
    bread_crum_path
    object_id:notnull
    folder_type
    return_url:notnull
}

# User id already verified by filters
set user_id [ad_maybe_redirect_for_registration]
set base_path [im_filestorage_base_path $folder_type $object_id]
set context_bar ""
set page_title ""
set page_content ""

set url_base_list [split $return_url "?"]
set url_base [lindex $url_base_list 0]
set bgcolor(0) " class=roweven "
set bgcolor(1) " class=rowodd "

# Remove those variables that we've extracted in the
# page contract. Why?
set bind_vars [ns_conn form]
ns_set delkey $bind_vars bread_crum_path
ns_set delkey $bind_vars actions
ns_set delkey $bind_vars return_url

# X and Y come from image buttons and can just
# be removed
ns_set delkey $bind_vars x
ns_set delkey $bind_vars y


# Get the list of all relevant roles and profiles for permissions
set roles [im_filestorage_roles $user_id $object_id]
set profiles [im_filestorage_profiles $user_id $object_id]

# Get the group membership of the current (viewing) user
set user_memberships [im_filestorage_user_memberships $user_id $object_id]

# Get the list of all (known) permission of all folders of the FS
# of the current object
set perm_hash_array [im_filestorage_get_perm_hash $user_id $object_id $user_memberships]
array set perm_hash $perm_hash_array



foreach var [ad_ns_set_keys $bind_vars] {
    set value [ns_set get $bind_vars $var]
    if {[regexp {first_line_flag} $var]} {
	ns_set delkey $bind_vars $var
    }
}

set vars ""

switch $actions {
    "none" {

	# --------------------- None --------------------- 

	ad_returnredirect $return_url
    }

    "add-perms" {

	# --------------------- Add permissions to folders --------------------- 

	set profiles [im_filestorage_profiles $user_id $object_id]
	set roles [im_filestorage_roles $user_id $object_id]
	set tds [im_filestorage_profile_tds $user_id $object_id]
	set num_profiles [expr [llength $roles] + [llength $profiles]]

        set dirs_html ""
	set ctr 0
        foreach id [array names dir_id] {
            set rel_path $id_path($id)
            set abs_path "$base_path/$rel_path"
            set checked "checked"

	    # Check permissions and skip
	    set user_perms [im_filestorage_folder_permissions $user_id $object_id $rel_path $user_memberships $roles $profiles $perm_hash_array]
	    set admin_p [lindex $user_perms 3]
	    if {!$admin_p} { continue }

            incr ctr
            append dirs_html "
<tr $bgcolor([expr $ctr % 2])>
  <td>
    <input type=checkbox name=dir_id.$id $checked>
    <input type=hidden name=id_path.$id value=\"$id_path($id)\">
  </td>
  <td>$id_path($id)</td>
</tr>\n"
        }

	set page_title "[_ intranet-filestorage.Add_Permissions]"
	set page_content "
<H1>$page_title</H1>
<form name=add_perms action=/intranet-filestorage/add-perms-2 method=POST>
[export_form_vars object_id folder_type bread_crum_path return_url]
<table border=0 cellspacing=0 cellpadding=2>
<tr class=rowtitle>
  <td></td>
  $tds
</tr>
<tr class=roweven>
  <td>[_ intranet-filestorage.View]</td>\n"
	foreach role $roles {
	    set role_id [lindex $role 0]
	    append page_content "<td><input type=checkbox name=view_role.$role_id></td>\n"
	}
	foreach profile $profiles {
	    set profile_id [lindex $profile 0]
	    append page_content "<td><input type=checkbox name=view_profile.$profile_id></td>\n"
	}
	append page_content "
</tr>
<tr class=rowodd>
  <td>[_ intranet-filestorage.Read]</td>\n"
	foreach role $roles {
	    set role_id [lindex $role 0]
	    append page_content "<td><input type=checkbox name=read_role.$role_id></td>\n"
	}
	foreach profile $profiles {
	    set profile_id [lindex $profile 0]
	    append page_content "<td><input type=checkbox name=read_profile.$profile_id></td>\n"
	}
	append page_content "
</tr>
<tr class=roweven>
  <td>[_ intranet-filestorage.Write]</td>\n"
	foreach role $roles {
	    set role_id [lindex $role 0]
	    append page_content "<td><input type=checkbox name=write_role.$role_id></td>\n"
	}
	foreach profile $profiles {
	    set profile_id [lindex $profile 0]
	    append page_content "<td><input type=checkbox name=write_profile.$profile_id></td>\n"
	}
	append page_content "
</tr>
<tr class=rowodd>
  <td>[_ intranet-filestorage.Admin]</td>\n"
	foreach role $roles {
	    set role_id [lindex $role 0]
	    append page_content "<td><input type=checkbox name=admin_role.$role_id></td>\n"
	}
	foreach profile $profiles {
	    set profile_id [lindex $profile 0]
	    append page_content "<td><input type=checkbox name=admin_profile.$profile_id></td>\n"
	}
	append page_content "
</tr>
</table>
<P>
<input type=submit name=submit value=\"[_ intranet-filestorage.Add_Permissions]\">
[_ intranet-filestorage.lt_Add_the_permissions_a]</p>

<table border=0 cellspacing=0 cellpadding=1>
<tr class=rowtitle><td colspan=2 class=rowtitle>Directories</td></tr>
$dirs_html
</table>
</form>
<p>\n"

	if {"" == $dirs_html} {
	    set im_gif_plus_9 [im_gif plus_9]
	    set page_content "
<H1>[_ intranet-filestorage.lt_No_Directories_Select]</H1>
[_ intranet-filestorage.lt_You_have_not_selected]<br>
[lang::message::lookup "" intranet-filestorage.Or_no_permissions_for_items "Or you don't have permission to administrate any of the items."]<p>
[_ intranet-filestorage.lt_Please_backup_select_]<p>
"
	}
        ad_return_template
        return

    }

    "del-perms" {

	# --------------------- Del permissions to folders --------------------- 

	set profiles [im_filestorage_profiles $user_id $object_id]
	set roles [im_filestorage_roles $user_id $object_id]
	set tds [im_filestorage_profile_tds $user_id $object_id]
	set num_profiles [expr [llength $roles] + [llength $profiles]]

        set dirs_html ""
	set ctr 0
        foreach id [array names dir_id] {
            set rel_path $id_path($id)
            set abs_path "$base_path/$rel_path"
            set checked "checked"

	    # Check permissions and skip
	    set user_perms [im_filestorage_folder_permissions $user_id $object_id $rel_path $user_memberships $roles $profiles $perm_hash_array]
	    set admin_p [lindex $user_perms 3]
#	    if {!$admin_p} { continue }

            incr ctr
            append dirs_html "
<tr $bgcolor([expr $ctr % 2])>
  <td>
    <input type=checkbox name=dir_id.$id $checked>
    <input type=hidden name=id_path.$id value=\"$id_path($id)\">
  </td>
  <td>$id_path($id)</td>
</tr>\n"
        }

	set page_title "[_ intranet-filestorage.Delete_Permissions]"
	set page_content "
<H1>$page_title</H1>
<form action=/intranet-filestorage/del-perms-2 method=POST>
[export_form_vars object_id folder_type bread_crum_path return_url]
<table border=0 cellspacing=0 cellpadding=2>
<tr class=rowtitle>
  <td></td>
  $tds
</tr>
<tr class=roweven>
  <td>[_ intranet-filestorage.View]</td>\n"
	foreach role $roles {
	    set role_id [lindex $role 0]
	    append page_content "<td><input type=checkbox name=view_role.$role_id></td>\n"
	}
	foreach profile $profiles {
	    set profile_id [lindex $profile 0]
	    append page_content "<td><input type=checkbox name=view_profile.$profile_id></td>\n"
	}
	append page_content "
</tr>
<tr class=rowodd>
  <td>[_ intranet-filestorage.Read]</td>\n"
	foreach role $roles {
	    set role_id [lindex $role 0]
	    append page_content "<td><input type=checkbox name=read_role.$role_id></td>\n"
	}
	foreach profile $profiles {
	    set profile_id [lindex $profile 0]
	    append page_content "<td><input type=checkbox name=read_profile.$profile_id></td>\n"
	}
	append page_content "
</tr>
<tr class=roweven>
  <td>[_ intranet-filestorage.Write]</td>\n"
	foreach role $roles {
	    set role_id [lindex $role 0]
	    append page_content "<td><input type=checkbox name=write_role.$role_id></td>\n"
	}
	foreach profile $profiles {
	    set profile_id [lindex $profile 0]
	    append page_content "<td><input type=checkbox name=write_profile.$profile_id></td>\n"
	}
	append page_content "
</tr>
<tr class=rowodd>
  <td>[_ intranet-filestorage.Admin]</td>\n"
	foreach role $roles {
	    set role_id [lindex $role 0]
	    append page_content "<td><input type=checkbox name=admin_role.$role_id></td>\n"
	}
	foreach profile $profiles {
	    set profile_id [lindex $profile 0]
	    append page_content "<td><input type=checkbox name=admin_profile.$profile_id></td>\n"
	}
	append page_content "
</tr>
</table>
<P>
<input type=submit name=submit value=\"[_ intranet-filestorage.Del_Permissions]\">
[_ intranet-filestorage.lt_Delete_the_permission]</p>

<table border=0 cellspacing=0 cellpadding=1>
<tr class=rowtitle><td colspan=2 class=rowtitle>[_ intranet-filestorage.Directories]</td></tr>
$dirs_html
</table>
</form>
<p>\n"

	if {"" == $dirs_html} {
	    set im_gif_plus_9 [im_gif plus_9]
	    set page_content "
<H1>[_ intranet-filestorage.lt_No_Directories_Select]</H1>
[_ intranet-filestorage.lt_You_have_not_selected]<br>
[lang::message::lookup "" intranet-filestorage.Or_no_permissions_for_items "Or you don't have permission to administrate any of the items."]<p>
[_ intranet-filestorage.lt_Please_backup_select_]<p>
"
	}

        ad_return_template
        return

    }

    "zip" {
		global tcl_platform
		set platform [lindex $tcl_platform(platform) 0]

		# --------------------- Download a ZIP --------------------- 


		# Find out where the current directory starts on the hard disk
		set base_path [im_filestorage_base_path $folder_type $object_id]
		if {"" == $base_path} {
			ad_return_complaint 1 "<LI>[_ intranet-filestorage.lt_Unknown_folder_type_f]"
			return
		}

		# Get the list of all relevant roles and profiles for permissions
		set roles [im_filestorage_roles $user_id $object_id]
		set profiles [im_filestorage_profiles $user_id $object_id]

		# Get the group membership of the current (viewing) user
		# Avoid syntax errors in SQL with empty membership list
		set user_memberships [im_filestorage_user_memberships $user_id $object_id]
		lappend user_memberships 0

		# Get folders with read permission
		set dest_path ""
		set folder_sql "
		select
			f.path as folder_path
		from
			im_fs_folder_perms p,
			im_fs_folders f
		where
			f.object_id = :object_id
			and p.folder_id = f.folder_id
			and p.profile_id in ([join $user_memberships ", "])
			and p.read_p = 1
	"

		db_foreach get_folders $folder_sql {
			append dest_path "$base_path/$folder_path "    
		}    

		# privileged users
		set object_write 0
		if {[im_permission $user_id edit_internal_offices]} { 
			set object_write 1
		}
		# Permissions for all usual projects, companies etc.
		set object_type [db_string acs_object_type "select object_type from acs_objects where object_id=:object_id"]
		set perm_cmd "${object_type}_permissions \$user_id \$object_id object_view object_read object_write object_admin"
		eval $perm_cmd

		if { [empty_string_p $dest_path] || $object_write } {
			set dest_path $base_path/$bread_crum_path
		}

		# Determine a random .tgz file
		set r [ns_rand 10000000]
		set file "zip.$user_id.$r.tgz"
		ns_log Notice "file=$file"
		set path "/tmp/$file"

		#build exec command 
		set tar_command  "/bin/tar czf"
		lappend tar_command $path
		lappend tar_command $dest_path
		ns_log Notice "-----> $tar_command"

		if { [catch {
			eval "exec [join $tar_command]"
		} err_msg] } {
			ns_log Error "------> $err_msg"
			# Nothing. We check if TAR was successfull if the file exists.
		}

	    if { $platform == "windows" } {
		# fraber 091023: Changes from Maurizio
	    	# set path "[acs_root_dir]/../cygwin/$path"
		set path "[acs_root_dir]/$path"
	    }
 
		if { [catch {
			set file_readable [file readable $path]
		} err_msg] } {
			ad_return_complaint 1 "<LI>[_ intranet-filestorage.lt_Unable_to_compress_th]"
			return
		}

		if $file_readable {
			ad_returnredirect "/intranet/download/zip/0/$file"
			return
		} else {
			doc_return 404 text/html "[_ intranet-filestorage.lt_Did_not_find_the_spec]"
			return
		}
    }

    "new-folder" {

	# --------------------- New Folder --------------------- 

	# Check permissions and skip
	set user_perms [im_filestorage_folder_permissions $user_id $object_id $bread_crum_path $user_memberships $roles $profiles $perm_hash_array]
	set admin_p [lindex $user_perms 3]
	if {!$admin_p} {
	    ad_return_complaint 1 "You don't have permission to create a subdirectory in folder '$bread_crum_path'"
	    return
	}

        set page_title "[_ intranet-filestorage.New_Folder]"
        set context_bar [im_context_bar $page_title]
	set page_content "
<h1>New Folder</h1>
<form method='post' action='create-folder-2'>
[export_form_vars folder_type bread_crum_path object_id return_url]
<table><tr><td>[_ intranet-filestorage.lt_Please_enter_the_name]
</td></tr>
<tr><td>
  <input type='text' name='folder_name' value='' style='width: 100%;'>
  <input type='submit' value='[lang::message::lookup "" intranet-filestorage.Create_Folder "Create Folder"]'>
</td></tr>
</table>
</form>\n"
        ad_return_template
	return
    }

    "upload" {

	# --------------------- Upload --------------------- 

	# Check permissions and skip
	set user_perms [im_filestorage_folder_permissions $user_id $object_id $bread_crum_path $user_memberships $roles $profiles $perm_hash_array]
	set write_p [lindex $user_perms 2]
	if {!$write_p} {
	    ad_return_complaint 1 "You don't have permission to write to folder '$bread_crum_path'"
	    return
	}

        set page_title "[_ intranet-filestorage.Upload_File]"
        set context_bar [im_context_bar $page_title]
        set page_content "
<form enctype=multipart/form-data method=POST action=upload-2.tcl>
[export_form_vars bread_crum_path folder_type object_id return_url]

          Upload a file into directory \"/$bread_crum_path\".
          [_ intranet-filestorage.lt_If_you_want_to_upload] <br>
          [_ intranet-filestorage.lt_please_backup_up_and_]

    <table border=0>
      <tr>
	<td align=right>[_ intranet-filestorage.Filename]: </td>
	<td>
	  <input type=file name=upload_file size=30>
[im_gif help "Use the 'Browse...' button to locate your file, then click 'Open'."]
	</td>
      </tr>
      <tr>
	<td></td>
	<td>
	  <input type=submit value=\"[_ intranet-filestorage.Submit_and_Upload]\">
	</td>
      </tr>
    </table>
</form>\n"
        ad_return_template
	return
    }

    "up-folder" {

	# --------------------- Up-Folder --------------------- 

	set bread_crum_list [split $bread_crum_path "/"]
	set bread_crum_list_upfolder [lrange $bread_crum_list 0 [expr [llength $bread_crum_list] -2]]
	set bread_crum_path_upfolder [join $bread_crum_list_upfolder "/"]
	ns_set put $bind_vars bread_crum_path $bread_crum_path_upfolder

	ad_returnredirect "$url_base?[export_url_bind_vars $bind_vars]"
    }
    "del" {

	# --------------------- Delete --------------------- 

	set page_title "Delete Files?"
	set context_bar [im_context_bar $page_title]
	set ctr 0

	set files_html ""
	foreach id [array names file_id] {

	    set file_path $id_path($id)
	    set file_path_list [split $file_path {/}]
	    set len [expr [llength $file_path_list] - 2]
	    set path_list [lrange $file_path_list 0 $len]
	    set path [join $path_list "/"]

	    # Check permissions
	    set user_perms [im_filestorage_folder_permissions $user_id $object_id $path $user_memberships $roles $profiles $perm_hash_array]
	    set admin_p [lindex $user_perms 3]
	    if {!$admin_p} { continue }

	    incr ctr
	    append files_html "<tr $bgcolor([expr $ctr % 2])>
<td>
  <input type=checkbox name=file_id.$id checked>
  <input type=hidden name=id_path.$id value=\"$id_path($id)\">
</td><td>$id_path($id)</td><td></td></tr>\n"
	}

	set dirs_html ""
	foreach id [array names dir_id] {
	    set rel_path $id_path($id)
	    set abs_path "$base_path/$rel_path"
	    set err_msg ""
            set checked "checked"


	    # Check permissions and skip
	    set user_perms [im_filestorage_folder_permissions $user_id $object_id $rel_path $user_memberships $roles $profiles $perm_hash_array]
	    set admin_p [lindex $user_perms 3]
	    if {!$admin_p} { continue }

	    if {![im_filestorage_is_directory_empty $abs_path]} {
		set err_msg "<font color=red>[_ intranet-filestorage.lt_Directory_is_not_empt]</font>\n"
                set checked ""
 	    }
	    incr ctr
	    append dirs_html "<tr $bgcolor([expr $ctr % 2])>
<td>
  <input type=checkbox name=dir_id.$id $checked>
  <input type=hidden name=id_path.$id value=\"$id_path($id)\">
</td><td>$id_path($id)</td><td>$err_msg</td></tr>\n"
	}

	set page_content "
<H1>[_ intranet-filestorage.Delete_Files]</H1>
Are you sure you really want to delete the following files?
<form action=delete method=POST>
[export_form_vars object_id bread_crum_path folder_type return_url]
<input type=submit value='[_ intranet-filestorage.Delete]'><p>
<table border=0 cellpadding=1 cellspacing=1>\n"

	if {"" != $dirs_html} {
	    append page_content "<tr class=rowtitle>
	    <td colspan=3 class=rowtitle align=center>[_ intranet-filestorage.Directories]</td></tr>$dirs_html"
	}

	if {"" != $files_html} {
	    append page_content "<tr class=rowtitle>
	    <td colspan=3 class=rowtitle align=center>Files</td></tr>$files_html\n"
	}
	append page_content "</table>\n</form>\n"


        if {"" == $dirs_html && "" == $files_html} {
            # Both are empty - show empty help string
            set page_content "
<h1>[_ intranet-filestorage.Nothing_Selected]</h1>
[lang::message::lookup "" intranet-filestorage.Or_no_permissions_for_items "Or you don't have permission to administrate any of the items."]<p>
[_ intranet-filestorage.lt_Please_back_up_and_se]<br>
[_ intranet-filestorage.lt_by_marking_the_checkb]
"
        }


	ad_return_template
	return
    }

    default {

	# --------------------- Default --------------------- 

	ad_returnredirect $return_url
    }
}



set ctr 0
foreach var [ad_ns_set_keys $bind_vars] {
    set value [ns_set get $bind_vars $var]
    if {$ctr > 0} { append vars "&" }
    append vars "$var=$value\n"
    incr ctr
}

append vars "url_base=$url_base\n"

db_release_unused_handles

ad_return_complaint 1 "<pre>$vars</pre>"
return

set page_title "[_ intranet-filestorage.lt_Upload_into_my_folder]"
