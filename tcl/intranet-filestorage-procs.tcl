# /tcl/intranet-trans-filestorage.tcl

ad_library {
    Translation Industry File Storage Component Library
    @author fraber@fraber.de
    @creation-date  27 June 2003
    
    This file storage type sets the access rights to project
    folders according to some regular expressions, that
    determine the read/write permissions for the project profiles:
    - Admin	r/w all
    - Sales	r all, w sales
    - Member	r/w all except sales
    - Trans	r source trans edit proof, w trans
    - Editor	r source trans edit proof, w edit
    - Proof	r source trans edit proof, w proof
}

ad_register_proc GET /intranet/download/project/* intranet_project_download
ad_register_proc GET /intranet/download/customer/* intranet_customer_download
ad_register_proc GET /intranet/download/user/* intranet_user_download

ad_proc intranet_project_download {} { intranet_download "project" }
ad_proc intranet_customer_download {} { intranet_download "customer" }
ad_proc intranet_user_download {} { intranet_download "user" }

# Serve the abstract URL 
# /intranet/download/<group_id>/...
#
proc intranet_download { folder_type } {
    set url "[ns_conn url]"
    set user_id [ad_maybe_redirect_for_registration]

    ns_log Notice "intranet_download: url=$url"

    # /intranet/download/projects/1934/source_en_US/help.rtf?
    # Using the group_id as selector for various storage types.
    set path_list [split $url {/}]
    set len [expr [llength $path_list] - 1]

    # skip: +0:/ +1:intranet, +2:download, +3:folder_type, +4:<group_id>, +5:...
    set group_id [lindex $path_list 4]
    ns_log Notice "group_id=$group_id"

    # Start retreiving the path starting at:
    set start_index 5

    set file_comps [lrange $path_list $start_index $len]
    set file_name [join $file_comps "/"]
    ns_log Notice "file_name=$file_name"

    switch $folder_type {
	project {set base_path [im_filestorage_project_path $group_id]}
	customer {set base_path [im_filestorage_customer_path $group_id]}
	user {set base_path [im_filestorage_user_path $group_id]}
	default {
	    ad_return_complaint 1 "<LI>Unknown folder_type \"$folder_type\"."
	    return
	}
    }

    set file "$base_path/$file_name"
    ns_log Notice "file=$file"

    if { [catch {
        set file_readable [file readable $file]
    } err_msg] } {
        # Probably some strange filename
        ad_return_complaint 1 "<LI>$err_msg<br>
	This issue is most likely due to strange characters in the 
	file. Please remove any accents etc. and try again."
	return
    }

    if $file_readable {
	rp_serve_concrete_file $file
    } else {
	doc_return 500 text/html "Did not find the specified file"
    }
}


ad_proc im_filestorage_user_role_list {user_id group_id} {
    Return the list of all roles that a user has for the specified project,
    customer or other type of group
} {
    set sql "
select distinct
	rel_type
from
	group_member_map
where
	member_id=:user_id
	and group_id=:group_id
"
    set bind_vars [ns_set create]
    return [db_list user_role_list $sql]
}


ad_proc im_filestorage_folder_perms {folder_path top_folder folder_type user_id group_id} {
    Determines the access permissions of a user to a specific path
    Returns (1-1-1-1 = Read-Write-See-Admin) permission binary number

    "folder_type" is one of {project|customer|user}
} {

    # ---------------- Gather all necessary information -------------------

    set role_list [util_memoize "im_filestorage_user_role_list $user_id $group_id"]

    # Check the user administration permissions
    set user_is_admin_p [util_memoize "im_is_user_site_wide_or_intranet_admin $user_id"]
    set user_is_wheel_p [util_memoize "ad_user_group_member [im_wheel_group_id] $user_id"]
    set user_is_group_admin_p [util_memoize "im_can_user_administer_group $group_id $user_id"]
    set user_admin_p [expr $user_is_admin_p || $user_is_group_admin_p]
    set user_admin_p [expr $user_admin_p || $user_is_wheel_p]

    ns_log Notice "admin=$user_is_admin_p wheel=$user_is_wheel_p group_admin=$user_is_group_admin_p admin=$user_admin_p"


    # ---------------- Now start evaluating permissions -------------------

    # Administrators and "members" can write to the directory.
    if {$user_admin_p} { 
	ns_log Notice "Admin=15 for all folders"
	return 15 
    }

    switch $folder_type {
 
	"project" {
 
	    # "sales" or "presales" folder - requires profile "sales"
	    # for read/write/view access.
	    if {[regexp sales $top_folder]} {
		if {[lsearch -exact $role_list sales] >= 0} {
		    ns_log Notice "Sales person=7 on sales folder"
		    return 7
		}
		ns_log Notice "Non-sales person=0 on sales folder"
		return 0
	    }

	    # "deliv" folder requires profile "member"
	    # for read/write/view access.
	    if {[regexp deliv $top_folder]} {
		if {[lsearch -exact $role_list member] >= 0} {
		    ns_log Notice "Member=7 on deliv folder"
		    return 7
		}
		ns_log Notice "Non-member=0 on deliv folder"
		return 0
	    }

	    # Now we deal with all folders that are not "sales" or "presales":

	    # "Members" can write to all directory (!= sales)
	    if {[lsearch -exact $role_list "member"] >= 0} {
		ns_log Notice "member=7 on other folder"
		return 7
	    }
	}

	"customer" {
	    set read 0
	    set write 0
	    set see 0
	    set admin 0

	    if {[im_permission $user_id view_customer_fs]} { 
		set see 1 
		set read 1 
	    }
	    if {[im_permission $user_id edit_customer_fs]} { 
		set see 1 
		set read 1 
		set write 1
	    }

	    # Returns (1-1-1-1 = Read-Write-See-Admin) permission binary number
	    return [expr $read + 2*$write + 4*$see +8*$admin]
	}

	"user" {
	    set read 0
	    set write 0
	    set see 0
	    set admin 0

	    if {[im_permission $user_id view_user_fs]} { 
		set see 1 
		set read 1 
	    }
	    if {[im_permission $user_id edit_user_fs]} { 
		set see 1
		set read 1 
		set write 1
	    }

	    # Returns (1-1-1-1 = Read-Write-See-Admin) permission binary number
	    return [expr $read + 2*$write + 4*$see +8*$admin]
	}

	default {
	    ns_log Error "im_filestorage_folder_perms: Unknown folder type \"$folder_type\". "
	    return 0
	}

    }


    # By default: allow read and see
    ns_log Notice "Default=5 on other folder"
    return 5
}


ad_proc im_filestorage_home_component { user_id return_url} {
    Filestorage for projects
} {
    set home_path [im_filestorage_home_path]
    set folder_type "home"
    return [im_filestorage_base_component $user_id 0 $home_path "Home" $folder_type $return_url]
}


ad_proc im_filestorage_project_component { user_id project_id project_name return_url} {
    Filestorage for projects
} {
    set project_path [im_filestorage_project_path $project_id]
    set folder_type "project"
    return [im_filestorage_base_component $user_id $project_id $project_path $project_name $folder_type $return_url]
}


ad_proc im_filestorage_customer_component { user_id customer_id customer_name return_url} {
    Filestorage for customers
} {
    set customer_path [im_filestorage_customer_path $customer_id]
    set folder_type "customer"
    return [im_filestorage_base_component $user_id $customer_id $customer_path $customer_name $folder_type $return_url]
}


ad_proc im_filestorage_user_component { user_id user_to_show_id user_name return_url} {
    Filestorage for users
} {
    set result ""    

    set token ""
    set user_is_employee_p [im_user_is_employee_p $user_to_show_id]
    set user_is_freelance_p [im_user_is_freelance_p $user_to_show_id]
    set user_is_customer_p [im_user_is_customer_p $user_to_show_id]

    if {$user_is_customer_p} { set token "view_customer_fs" }
    if {$user_is_freelance_p} { set token "view_freelance_fs" }
    if {$user_is_employee_p} { set token "view_employee_fs" }

    if {"" != $token} {
	if {[im_permission $user_id $token]} {
	    set user_path [im_filestorage_user_path $user_to_show_id]
	    set folder_type "user"
	    set result [im_filestorage_base_component $user_id $user_to_show_id $user_path $user_name $folder_type $return_url]
	}
    }
    return $result
}


ad_proc im_filestorage_base_component { user_id id base_path name folder_type return_url} {
    Creates a table showing the content of the specified directory.
    "id" changes as a function of "folder_type":
    - project
    - customer
    - user
} {
    set folder "/"
    set project_id $id

    set component_body "
<table bgcolor=white cellspacing=0 border=0 cellpadding=0>
<tr> 
  <td class=rowtitle align=center>Name&nbsp;</td>
  <td class=rowtitle align=center>[im_gif help "Upload and download file to and form a directiry"]</td>
<!--  <td class=rowtitle align=center>Man<BR>age&nbsp;</td> -->
<!--  <td class=rowtitle align=center>Refers<BR>to&nbsp;</td> -->
<!--  <td class=rowtitle align=center>Words&nbsp;</td> -->
<!--  <td class=rowtitle align=center>Status&nbsp;</td> -->
  <td class=rowtitle align=center>Size&nbsp;</td>
  <td class=rowtitle align=center>Modified&nbsp;</td>
<!--  <td class=rowtitle align=center>Owner&nbsp;</td> -->
</tr>
"

    # Create a first 'path' with the project name 

    # Check the folder permissions: Set to default permissions
    # and calculate conjunction of the folder pathes
    # "15" = 1-1-1-1 = Read-Write-See-Admin
    set file ""
    set top_folder ""
    set perm [im_filestorage_folder_perms $file $top_folder $folder_type $user_id $id]
    set read_p [expr $perm & 1]
    set write_p [expr ($perm & 2) > 0]
    set see_p [expr ($perm & 4) > 0]
    set admin_p [expr ($perm & 8) > 0]
    ns_log Notice "perm=$perm read=$read_p write=$write_p see=$see_p admin=$admin_p"
    
    append component_body "
<tr> 
  <td>
    <table cellpadding=0 cellspacing=0 border=0>
      <tr>
        <td>\n"

    if {$write_p} {
	append component_body "<A href='/intranet-filestorage/upload?[export_url_vars folder folder_type project_id return_url]'>[im_gif "exp-folder"]</A>"
    } else {
	append component_body [im_giv "exp-folder"]
    }

    append component_body "
        </td>
        <td>&nbsp;$name</td>
      </tr>
    </table>
  </td>
  <td align=middle>\n"

    if {$write_p} {
	append component_body "<A href='/intranet-filestorage/upload?[export_url_vars folder folder_type project_id return_url]'>[im_gif open "Upload a new file"]</A>"
    }

    append component_body "
  </td>
<!--  <td>-</td> -->
<!--  <td></td> -->
  <td></td>
<!--  <td>Source</td> -->
<!--  <td></td> -->
  <td></td>
<!--  <td></td> -->
</tr>
"

    if { [catch {
	ns_log Notice "im_filestorage_component: Checking $base_path"
	exec /bin/mkdir -p $base_path
	set file_list [exec /usr/bin/find $base_path]
    } err_msg] } {
	# Probably some permission errors - return empty string
	ns_log Notice "\nim_filestorage_component:
	'exec /usr/bin/find $base_path' failed with error:
	err_msg=$err_msg\n"
	return "
		<table bgcolor=white cellspacing=2 border=1 cellpadding=2>
		<tr><td class=rowtitle align=center>
		  Error with project folders:
		</td></tr>
		<tr><td>
		  Unable to show folders for \"$name\". 
		  Did somebody rename or remove the folder?
		</td></tr>
		</table>"
    }

    set org_paths [split $base_path "/"]
    set org_paths_len [llength $org_paths]
    set start_index $org_paths_len

    # Get the sorted list of files in the directory
    set files [lsort [split $file_list "\n"]]
    
    foreach file $files {

	# Get the basic information about a file
	ns_log Notice "file=$file"
	set file_paths [split $file "/"]
	set file_paths_len [llength $file_paths]
	set body_index [expr $file_paths_len - 1]
	set file_body [lindex $file_paths $body_index]

	set file_type ""
	set file_size ""
	set file_modified "(bad filename)"
	set file_extension ""
	set file_size ""
	if { [catch {
	    set file_type [file type $file]
	    set file_size [file size $file]
	    set file_modified [ns_fmttime [file mtime $file] "%d/%m/%Y"]
	    set file_extension [file extension $file]
	    set file_size [expr [file size $file] / 1024]
	} err_msg] } {
	    # Error due to accents in filename - ignore
	}

	# The first folder of the project - contains access perms
	set top_folder [lindex $file_paths $start_index]
	ns_log Notice "top_folder=$top_folder"

	# Check if it is the toplevel directory
	if {[string equal $file $base_path]} { 
	    # Skip the path itself
	    continue 
	}

	# check the folder permissions: Set to default permissions
	# and calculate conjunction of the folder pathes
	# "7" = 1-1-1-1 = Read-Write-See-Admin
	set perm [im_filestorage_folder_perms $file $top_folder $folder_type $user_id $id]
	set read_p [expr $perm & 1]
	set write_p [expr ($perm & 2) > 0]
	set see_p [expr ($perm & 4) > 0]
	set admin_p [expr ($perm & 8) > 0]

	ns_log Notice "perm=$perm read=$read_p write=$write_p see=$see_p admin=$admin_p"

	# Determine how many "tabs" the file should be indented
	set spacer ""
	for {set i [expr $start_index + 1]} {$i < $file_paths_len} {incr i} {
	    append spacer [im_gif "exp-line"]
	}
	
	# determine the part of the filename _after_ the base path
	set end_path ""
	for {set i $start_index} {$i < $file_paths_len} {incr i} {
	    append end_path [lindex $file_paths $i]
	    if {$i < [expr $file_paths_len - 1]} { append end_path "/" }
	}
	
	switch [string tolower $file_type] {
	    file {

		# must be readable and viewable:
		if {!$see_p} { continue }
		if {!$read_p} { continue }

		# Choose a suitable icon
		set alt "Click right and choose \"Save target as\" to download the file to a local directory"
		set icon [im_gif "exp-unknown" $alt]
		switch $file_extension {
		    ".xls" { set icon [im_gif exp-excel $alt] }
		    ".doc" { set icon [im_gif exp-word $alt] }
		    ".rtf" { set icon [im_gif exp-word $alt] }
		    ".txt" { set icon [im_gif exp-text $alt] }
		    default {
			ns_log Notice "im_file_component: unknown file_extension: '$file_extension'"
		    }
		}
	    
	    # Build a <tr>..</tr> line for the file
	    set file_name $end_path
	    set line "
<tr> 
  <td>
    <table cellpadding=0 cellspacing=0 border=0><tr>
<td>$spacer[im_gif "exp-line"]<A href='/intranet/download/$folder_type/$project_id/$file_name'>$icon</A></td>
    <td>&nbsp;$file_body&nbsp;</td>
    </tr></table>
  </td>
  <td align=middle><A href='/intranet/download/$folder_type/$project_id/$file_name'>[im_gif save "Click right and choose \"Save target as\" to download the file to a local directory"]</A></td>
<!--  <td>-</td> -->
<!--  <td></td> -->
<!-- <td align=right>1234&nbsp;</td> -->
<!--  <td>Source</td> -->
  <td align=right>$file_size<b></b>k&nbsp;</td>
  <td>$file_modified</td>
<!--  <td>ijimenez</td> -->
</tr>
"	}


	directory {

	    # must be viewable:
	    if {!$see_p} { continue }

	    set folder $end_path

	    set line "
<tr>
  <td valign=top>
    <table cellpadding=0 cellspacing=0 border=0><tr>
    <td>$spacer[im_gif "exp-minus"]"

	    if {$write_p} {
		append line "<A href='/intranet-filestorage/upload?[export_url_vars folder folder_type project_id return_url]'>[im_gif "exp-folder"]</A>"
	    } else {
		append line [im_gif "exp-folder"]
	    }
	    append line "</td>
    <td>&nbsp;$file_body</td>
    </tr></table>
  </td>
  <td align=middle>"
	    if {$write_p} {
		append line "<A href='/intranet-filestorage/upload?[export_url_vars folder folder_type project_id return_url]'>[im_gif open "Upload a new file"]</A>"
	    }
	    append line "</td>
<!--  <td align=center>
    [im_gif open "Mark the folder as &quot;Open&quot;"]
  </td>
-->
<!--  <td></td> -->
  <td align=right><!-- Words--></td>
<!--  <td>Closed</td> -->
  <td></td>
  <td></td>
<!--  <td>ijimenez</td> -->
</tr>
"	}

	default { set line "
<tr>
  <td valign=top>
    <table cellpadding=0 cellspacing=0 border=0>
    <tr>
      <td>
        $spacer[im_gif "exp-minus"]
        [im_gif "exp-unknown"]
      </td>
      <td>&nbsp;$file_body</td>
    </tr>
    </table>
  </td>
  <td align=middle></td>
  <td align=right><!-- Words--></td>
  <td>(bad file)</td>
</tr>"
	}

	}

    append component_body "$line\n"
    }

    append component_body "\n</table>\n"
    return $component_body
}


# ---------------------------------------------------------------------
# Determine pathes for project, customers and users
# ---------------------------------------------------------------------

ad_proc im_filestorage_home_path { } {
    Determine the location where global company files
    are stored on the hard disk 
} {
    set base_path_unix [ad_parameter "ProjectBasePathUnix" intranet "/tmp/"]
    return "$base_path_unix/home"
}


ad_proc im_filestorage_project_path { project_id } {
    Determine the location where the project files
    are stored on the hard disk for this project
} {
    set base_path_unix [ad_parameter "ProjectBasePathUnix" intranet "/tmp/"]

    # Return a demo path for all project, clients etc.
    if {[string equal "true" [ad_parameter "TestDemoDevServer" "" "false"]]} {
	set path [ad_parameter "TestDemoDevPath" intranet "internal/demo"]
	ns_log Notice "im_filestorage_project_path: TestDemoDevServer: $path"
	return "$base_path_unix/$path"
    }

    set query "
select
	p.project_nr,
	p.project_path,
	p.project_name,
	c.customer_path
from
	im_projects p,
	im_customers c
where
	p.project_id=:project_id
	and p.customer_id=c.customer_id(+)
"

    if { ![db_0or1row projects_info_query $query] } {
	ad_return_complaint 1 "Can't find the project with group 
	id of $project_id"
	return
    }

    return "$base_path_unix/$customer_path/$project_path"
}


ad_proc im_filestorage_user_path { user_id } {
    Determine the location where the user files
    are stored on the hard disk
} {
    set base_path_unix [ad_parameter "UserBasePathUnix" intranet "/tmp/"]

    # Return a demo path for all project, clients etc.
    if {[string equal "true" [ad_parameter "TestDemoDevServer" "" "false"]]} {
	set path [ad_parameter "TestDemoDevUserPath" intranet "users"]
	ns_log Notice "im_filestorage_project_path: TestDemoDevServer: $path"
	return "$base_path_unix/$path"
    }
    
    # get the user email and replace all non-alphanum characters by "_"
    set email_raw [db_string get_email "select email from users where user_id=:user_id"]
    regsub {[^A-Za-z0-9.]} $email_raw "_" email

    return "$base_path_unix/$email"
}

ad_proc im_filestorage_customer_path { customer_id } {
    Determine the location where the project files
    are stored on the hard disk
} {
    set base_path_unix [ad_parameter "CustomerBasePathUnix" intranet "/tmp/"]

    # Return a demo path for all project, clients etc.
    if {[string equal "true" [ad_parameter "TestDemoDevServer" "" "false"]]} {
	set path [ad_parameter "TestDemoDevPath" intranet "customers"]
	ns_log Notice "im_filestorage_project_path: TestDemoDevServer: $path"
	return "$base_path_unix/$path"
    }

    set customer_short_name "internal"
    if {[catch {
	set customer_name [db_string get_customer_shortname "select short_name from user_groups where group_id=:customer_id"]
    } errmsg]} {
	ad_return_complaint 1 "<LI>Internal Error: Unable to determine the file path for customer \#$customer_id"
	return
    }

    return "$base_path_unix/$customer_short_name"
}



ad_proc im_filestorage_project_workflow_dirs { project_type_id } {
    Returns a list of directors that have to be created 
    as a function of the project type (workfow)
    # 85: Trans Only
    # 86: Trans + Edit
    # 87: Edit Only
    # 88: Trans + Edit + Proof
    # 89: Linguistic Validation
    # 90: Localization
    # 91: Other
    # 92: Technology
    # 93: Unknown
    # 94: Trans + Internal Edit
} {
    switch $project_type_id {
	85 { return [list deliv trans]}
	86 { return [list deliv trans edit]}
	87 { return [list deliv edit]}
	88 { return [list deliv trans edit proof]}
	89 { return [list deliv trans edit]}
	90 { return [list deliv]}
	91 { return [list deliv]}
	92 { return [list deliv]}
	93 { return [list deliv]}
	94 { return [list deliv trans inted]}
	default {
	    return [list]
	}
    }
}


# ---------------------------------------------------------------------

ad_proc im_filestorage_create_directories { project_id } {

    Create directory structure for a new project
    Returns "" if successful 
    Returns a formatted errors string otherwise.

} {

    if {[string equal "true" [ad_parameter "TestDemoDevServer" "" "false"]]} {
	# We're at a demo server, so don't create any directories!
	return
    }

    set base_path_unix [ad_parameter "ProjectBasePathUnix" intranet "/tmp/"]

    # Get some missing variables about the project and the customer
    set query "
select
	p.project_type_id,
	cg.short_name as customer_short_name,
        pg.short_name as project_short_name,
	im_category_from_id(p.source_language_id) as source_language
from
	im_projects p,
        im_customers c,
	user_groups cg,
        user_groups pg
where 
	p.group_id=:project_id
	and p.customer_id=c.group_id
	and c.group_id=cg.group_id
        and p.group_id=pg.group_id
"
    if { ![db_0or1row projects_info_query $query] } {
	return "Can't find the project with group id of $project_id"
    }

    # Make sure the directories exists:
    #	- Client directy
    #	- Project directory

    # Create a customer directory if it doesn't already exist
    set customer_dir "$base_path_unix/$customer_short_name"
    if { [catch {
	if {![file exists $customer_dir]} { exec /bin/mkdir -p $customer_dir }
    } err_msg] } { return $err_msg }

    # Create the project dir if it doesn't already exist
    set project_dir "$base_path_unix/$customer_short_name/$project_short_name"
    if { [catch { 
	if {![file exists $project_dir]} { exec /bin/mkdir -p $project_dir }
    } err_msg]} { return $err_msg }

    # Create a source language directory
    set source_dir "$project_dir/source_$source_language"
    if {[catch {
	if {![file exists $source_dir]} {exec /bin/mkdir -p $source_dir} 
    } err_msg]} { return $err_msg }
    
    # Create a new target language director for every
    # target language and every stage of the translation
    # workflow
    #
    set target_languages [im_target_languages $project_id im_projects]
    set workflow_dirs [im_filestorage_project_workflow_dirs $project_type_id]

    foreach workflow_dir $workflow_dirs {
	foreach target_language $target_languages {
	    if {[string equal $target_language "none"]} { continue }
	    set dir "$project_dir/${workflow_dir}_$target_language"
	    ns_log Notice "new dir=$dir"
	    if {![file exists $dir]} {
		if {[catch {
		    exec /bin/mkdir -p $dir} err_msg] 
		} { return $err_msg }
	    }
	}
    }

    # Set the permissions go=u because the AOLServer runs as nsadmin/staff,
    # and we want to allow the users with user/users to create new files.
    #
    if { [catch {
	exec /bin/chmod go=u $customer_dir
    } err_msg] } { return $err_msg }
    if { [catch {
	exec /bin/chmod -R go=u $project_dir
    } err_msg] } { return $err_msg }
    
    return ""
}

