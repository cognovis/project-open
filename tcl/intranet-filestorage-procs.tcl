# /packages/intranet-filestorage/tcl/intranet-filestorage-procs.tcl
#
# Copyright (C) 2003-2004 Project/Open
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

ad_library {
    File Storage Component Library
    
    This file storage type sets the access rights to project
    folders according to some regular expressions, that
    determine the read/write permissions for the project profiles:
    - Admin	r/w all
    - Sales	r all, w sales
    - Member	r/w all except sales
    - Trans	r source trans edit proof, w trans
    - Editor	r source trans edit proof, w edit
    - Proof	r source trans edit proof, w proof

    @author frank.bergmann@project-open.com
}

ad_register_proc GET /intranet/download/project/* intranet_project_download
ad_register_proc GET /intranet/download/customer/* intranet_customer_download
ad_register_proc GET /intranet/download/user/* intranet_user_download
ad_register_proc GET /intranet/download/home/* intranet_home_download

ad_proc intranet_project_download {} { intranet_download "project" }
ad_proc intranet_customer_download {} { intranet_download "customer" }
ad_proc intranet_user_download {} { intranet_download "user" }
ad_proc intranet_home_download {} { intranet_download "home" }

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


ad_proc -public im_filestorage_find_files { project_id } {
    Returns a list of files in a project directory
} {
    set project_path [im_filestorage_project_path $project_id]
    if { [catch {
	ns_log Notice "im_filestorage_find_files: Checking $project_path"

	exec /bin/mkdir -p $project_path
        exec /bin/chmod ug+w $project_path
	set file_list [exec /usr/bin/find $project_path -type f]

    } err_msg] } {
	# Probably some permission errors - return empty string
	ns_log Notice "\nim_task_component:
	'exec /usr/bin/find $project_path' failed with error:
	err_msg=$err_msg\n"
	set file_list ""
    }

    set files [split $file_list "\n"]
    return $files
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

    "folder_type" is one of {home|project|customer|user}
} {
    ns_log Notice "im_filestorage_folder_perms: Checking group memberships"

    # ---------------- Gather all necessary information -------------------

    set role_list [util_memoize "im_filestorage_user_role_list $user_id $group_id"]

    # Check the user administration permissions
    set user_is_admin_p [util_memoize "im_is_user_site_wide_or_intranet_admin $user_id"]
    set user_is_wheel_p [util_memoize "ad_user_group_member [im_wheel_group_id] $user_id"]
    set user_admin_p [expr $user_is_admin_p || $user_is_wheel_p]

    # Get the role of this user in the project/customer/...
    set roles [im_biz_object_roles $user_id $group_id]
    if {[lsearch -exact $roles "Key Acount"] >= 0} { set user_admin_p 1 }
    if {[lsearch -exact $roles "Project Manager"] >= 0} { set user_admin_p 1 }
    ns_log Notice "im_filestorage_folder_perms: roles of $user_id in object\# $group_id: '$roles'"

    # ---------------- Now start evaluating permissions -------------------

    # Administrators and "members" can write to the directory.
    if {$user_admin_p} { 
	ns_log Notice "Admin=15 for all folders"
	return 15 
    }
    ns_log Notice "im_filestorage_folder_perms: Not admin => Check the type of folder"

    switch $folder_type {
 
	"home" {
	    set read 1
	    set write 0
	    set see 1
	    set admin 0
	    
	    # ToDo: Implement...
	    # By default everybody gets read access...

	    # Returns (1-1-1-1 = Read-Write-See-Admin) permission binary number
	    return [expr $read + 2*$write + 4*$see +8*$admin]
	}

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

    #return [im_filestorage_base_component $user_id 0 $home_path "Home" $folder_type $return_url]

    return [im_filestorage_pol_component $user_id 2346 "Home"]
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
    set user_path [im_filestorage_user_path $user_to_show_id]
    set folder_type "user"
    return [im_filestorage_base_component $user_id $user_to_show_id $user_path $user_name $folder_type $return_url]
}


ad_proc im_filestorage_base_component { user_id id base_path name folder_type return_url} {
    Creates a table showing the content of the specified directory.
    "id" changes as a function of "folder_type":
    - project
    - customer
    - user
    - home
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
    ns_log Notice "im_filestorage_base_component: before im_filestorage_folder_perms"
    set perm [im_filestorage_folder_perms $file $top_folder $folder_type $user_id $id]
    ns_log Notice "im_filestorage_base_component: perm=$perm"
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
	append component_body [im_gif "exp-folder"]
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
	ns_log Notice "im_filestorage_component: exec /bin/mkdir -p $base_path"
	ns_log Notice "im_filestorage_component: exec /bin/chmod ug+w $base_path"

	exec /bin/mkdir -p $base_path
	exec /bin/chmod ug+w $base_path
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
# All pathes end WITHOUT a trailing "/"
# ---------------------------------------------------------------------

ad_proc im_filestorage_home_path { } {
    Determine the location where global company files
    are stored on the hard disk 
} {
    return [util_memoize "im_filestorage_home_path_helper"]
}

ad_proc im_filestorage_home_path_helper { } {
    Helper to determine the location where global company files
    are stored on the hard disk 
} {
    set package_key "intranet-filestorage"
    set package_id [db_string package_id "select package_id from apm_packages where package_key=:package_key" -default 0]
    set base_path_unix [parameter::get -package_id $package_id -parameter "HomeBasePathUnix" -default "/tmp/home"]
    ns_log Notice "im_filestorage_home_path: base_path_unix=$base_path_unix"
    return "$base_path_unix"
}


ad_proc im_filestorage_project_path { project_id } {
    Determine the location where the project files
    are stored on the hard disk for this project
} {
    return [util_memoize "im_filestorage_project_path_helper $project_id"]
}

ad_proc im_filestorage_project_path_helper { project_id } {
    Determine the location where the project files
    are stored on the hard disk for this project
} {
    set package_key "intranet-filestorage"
    set package_id [db_string package_id "select package_id from apm_packages where package_key=:package_key" -default 0]
    set base_path_unix [parameter::get -package_id $package_id -parameter "ProjectBasePathUnix" -default "/tmp/projects"]

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
    set package_key "intranet-filestorage"
    set package_id [db_string package_id "select package_id from apm_packages where package_key=:package_key" -default 0]
    set base_path_unix [parameter::get -package_id $package_id -parameter "UserBasePathUnix" -default "/tmp/users"]

    # Return a demo path for all project, clients etc.
    if {[string equal "true" [ad_parameter "TestDemoDevServer" "" "false"]]} {
	set path [ad_parameter "TestDemoDevUserPath" intranet "users"]
	ns_log Notice "im_filestorage_project_path: TestDemoDevServer: $path"
	return "$base_path_unix/$path"
    }
    
    return "$base_path_unix/$user_id"
}


ad_proc im_filestorage_customer_path { customer_id } {
    Determine the location where the project files
    are stored on the hard disk
} {
    return [util_memoize "im_filestorage_customer_path_helper $customer_id"]
}

ad_proc im_filestorage_customer_path_helper { customer_id } {
    Determine the location where the project files
    are stored on the hard disk
} {
    set package_key "intranet-filestorage"
    set package_id [db_string package_id "select package_id from apm_packages where package_key=:package_key" -default 0]
    set base_path_unix [parameter::get -package_id $package_id -parameter "CustomerBasePathUnix" -default "/tmp/customers"]

    # Return a demo path for all project, clients etc.
    if {[string equal "true" [ad_parameter "TestDemoDevServer" "" "false"]]} {
	set path [ad_parameter "TestDemoDevPath" intranet "customers"]
	ns_log Notice "im_filestorage_project_path: TestDemoDevServer: $path"
	return "$base_path_unix/$path"
    }

    set customer_path "undefined"
    if {[catch {
	set customer_path [db_string get_customer_path "select customer_path from im_customers where customer_id=:customer_id"]
    } errmsg]} {
	ad_return_complaint 1 "<LI>Internal Error: Unable to determine the file path for customer \#$customer_id"
	return
    }

    return "$base_path_unix/$customer_path"
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
    ns_log Notice "im_filestorage_project_workflow_dirs: project_type_id=$project_type_id"
    switch $project_type_id {
	
	87 { 
	    # Trans + Edit
	    return [list deliv trans edit]
	}

	88 {
	    # Edit Only
	    return [list deliv edit]
	}

	89 {
	    # Trans + Edit + Proof
	    return [list deliv trans edit proof]
	}

	90 {
	    # Linguistic
	    return [list deliv]
	}

	91 {
	    # Localization
	    return [list deliv]
	}

	92 {
	    # Technology
	    return [list deliv]
	}

	93 {
	    # Trans Only
	    return [list deliv trans]
	}

	94 {
	    # Trans + Int. Spotcheck
	    return [list deliv trans edit]
	}

	95 {
	    # Proof Only
	    return [list deliv proof]
	}

	96 {
	    # Glossary Compilation
	    return [list deliv]
	}

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

    # Get some missing variables about the project and the customer
    set query "
select
	p.project_type_id,
	p.project_path,
	p.customer_id,
	im_category_from_id(p.source_language_id) as source_language,
	c.customer_path
from
	im_projects p,
	im_customers c
where 
	p.project_id = :project_id
	and p.customer_id = c.customer_id
"
    if { ![db_0or1row projects_info_query $query] } {
	return "Can't find the project with group id of $project_id"
    }

    # Make sure the directories exists:
    #	- Client directy
    #	- Project directory


    set package_key "intranet-filestorage"
    set package_id [db_string parameter_package "select package_id from apm_packages where package_key=:package_key" -default 0]
    set base_path_unix [parameter::get -package_id $package_id -parameter "ProjectBasePathUnix" -default "/tmp/projects"]

    # Create a customer directory if it doesn't already exist
    set customer_dir "$base_path_unix/$customer_path"
    ns_log Notice "im_filestorage_create_directories: customer_dir=$customer_dir"
    if { [catch {
	if {![file exists $customer_dir]} { 
	    ns_log Notice "exec /bin/mkdir -p $customer_dir"
	    exec /bin/mkdir -p $customer_dir 
	    ns_log Notice "exec /bin/chmod ug+w $customer_dir"
	    exec /bin/chmod ug+w $customer_dir
	}
    } err_msg] } { return $err_msg }

    # Create the project dir if it doesn't already exist
    set project_dir "$customer_dir/$project_path"
    ns_log Notice "im_filestorage_create_directories: project_dir=$project_dir"
    if { [catch { 
	if {![file exists $project_dir]} {
	    ns_log Notice "exec /bin/mkdir -p $project_dir"
	    exec /bin/mkdir -p $project_dir 
	    ns_log Notice "exec /bin/chmod ug+w $project_dir"
	    exec /bin/chmod ug+w $project_dir 
	}
    } err_msg]} { return $err_msg }

    # Create a source language directory
    # if source_language is defined...
    if {"" != $source_language} {
	set source_dir "$project_dir/source_$source_language"
	ns_log Notice "im_filestorage_create_directories: source_dir=$source_dir"
	if {[catch {
	    if {![file exists $source_dir]} {
		ns_log Notice "exec /bin/mkdir -p $source_dir"
		exec /bin/mkdir -p $source_dir
		ns_log Notice "exec /bin/chmod ug+w $source_dir"
		exec /bin/chmod ug+w $source_dir
	    } 
	} err_msg]} { return $err_msg }
    }
    
    # Create a new target language director for every
    # target language and every stage of the translation
    # workflow
    #
    set target_languages [im_target_languages $project_id]
    ns_log Notice "im_filestorage_create_directories: target_languages=$target_languages"
    set workflow_dirs [im_filestorage_project_workflow_dirs $project_type_id]
    ns_log Notice "im_filestorage_create_directories: workflow_dirs=$workflow_dirs"

    foreach workflow_dir $workflow_dirs {
	foreach target_language $target_languages {
	    if {[string equal $target_language "none"]} { continue }
	    set dir "$project_dir/${workflow_dir}_$target_language"
	    ns_log Notice "im_filestorage_create_directories: dir=$dir"
	    if {![file exists $dir]} {
		if {[catch {
		    ns_log Notice "exec /bin/mkdir -p $dir"
		    exec /bin/mkdir -p $dir
		    ns_log Notice "exec /bin/chmod ug+w $dir"
		    exec /bin/chmod ug+w $dir
		} err_msg] 
		} { return $err_msg }
	    }
	}
    }

    return ""
}





ad_proc im_filestorage_tools_bar { folder folder_type project_id return_url up_link } {
    Returns a formatted HTML component with a number of GIFs.
} {
    return "
<br>
<table border=0 cellpadding=0 cellspacing=0>
<tr> 
   <td align=center>
       $up_link
       <input type=image src=/intranet-filestorage/images/up-folder.gif width=21 height=21 border=0>
       </a> |
       <a href=/intranet-filestorage/create-folder?[export_url_vars folder folder_type project_id return_url]>
       <input type=image src=/intranet-filestorage/images/newfol.gif width=23 height=22 border=0>
       </a>|
       <input type=image src=/intranet-filestorage/images/upload.gif width=21 height=21>|
       <a href=INT-ADM-Knowledge%20Management-createDocument.htm>
       <input type=image src=/intranet-filestorage/images/new-doc.gif width=21 height=21 border=0>
       </a>|
       <a href=javascript:var agree = confirm ('Are you sure you want to move the selected object(s) to Deleted Items?'); if (agree) document.someonechecked.submit();>
       <input type=image src=/intranet-filestorage/images/del.gif width=21 height=21 border=0>
       </a>|
       <input type=image src=/intranet-filestorage/images/zip.gif width=21 height=21>
   </td>
</tr>
</table>"
}

ad_proc im_filestorage_bread_crum { } {
    Returns a formatted HTML component indicating the relative
    position in th current folder
} {
    set return_url [im_url_with_query]
    set new_url [split $return_url "&"]
    set return_url [lindex $new_url 0]
    return "$return_url"
}

ad_proc im_filestorage_header { object_id return_url } {
    return "
<br>
<form method='post' name='someonechecked' action='erase'>
<input type=hidden name=object_id value=$object_id>
<input type=hidden name=return_url value=$return_url>
<table align='center'>
  <tr>
    <td align='center'></td>
    <td align='center'>Type</td>
    <td align='center'>Name</td>
    <td align='center'>Size</td>
    <td align='center'>Date</td>
    <td align='center'>Description</td>
  </tr>
</table>
<br>\n"
}

ad_proc -public im_filestorage_pol_component { user_id object_id project_name { bread_crum_path "" } } {
    Main funcion to generate the filestorage page ( create folder, bread crum, ....)
    @param user_id: the user who is attempting to view the filestorage
    @param object_id: from wich group is pending this user?
    @param project_name: in wich project tree directory wants this user to view?
    @param bread_crum_path: the root of the tree directory view selected by the user
} {

    ns_log Notice "------------------ bread_crum_path: $bread_crum_path"

    #The filestorage start path for this object_id
    set base_path [im_filestorage_project_path $object_id]

    # Save the path in a list, a deph path for a list position
    set org_paths [split $base_path "/"]

    # Set the name type folder (actually static name, always project type)
    set folder_type "project"

    # folder path separator
    set folder "/"

    # Get the actual url
    set return_url [im_url_with_query]

    # Once we've got the root... next step is to execute the find command to 
    # know the content of the project
    set file_list ""
    if { [catch {
    	# If the root selected does not exist we create the folder
	ns_log Notice "im_filestorage_component: exec /bin/mkdir -p $base_path/$bread_crum_path"
	exec /bin/mkdir -p "$base_path/$bread_crum_path"
	# Executing the find command
	ns_log Notice "im_filestorage_component: exec /usr/bin/find $base_path/$bread_crum_path"
	set file_list [exec /usr/bin/find "$base_path/$bread_crum_path"]
    } err_msg] } { 
	return "<ul><li>Unable to get file list from '$bread_crum_path'</ul>"
    }
    ns_log Notice "im_filestorage_component: file_list=$file_list"

    # Save each result of the find in a list
    set files [lsort [split $file_list "\n"]]

    # ------------------------------------------------------------------
    #---- Start Bread crum code
    # ------------------------------------------------------------------
    
    set texte "<table align=center><tr><td>"

    # The base path selected by the user
    set bread_crum [split $bread_crum_path "/"]
    set bread_paths_len [llength $bread_crum]
    set bread_index [expr $bread_paths_len -1]

    # Extracting the original url and the extra variables
    set lreturn_url [split $return_url "&"]

    # First bread_crum is the project name - always visible
    append texte "<a href=[lindex $lreturn_url 0]>$project_name</a> :"
    set current_path ""
    set up_link ""
    foreach crum $bread_crum {
	append current_path "/$crum"
	append texte "<a href=[lindex $lreturn_url 0]?bread_crum_path=$current_path> $crum </a> :"
	
	if {![string equal $current_path $bread_crum_path]} {
	    set uplink $current_path
	}
    }
    append texte "</td></tr></table>\n"

    append texte [im_filestorage_tools_bar $bread_crum_path $folder_type $object_id $return_url $up_link]
    append texte [im_filestorage_header $object_id $return_url]

    # ------------------------------------------------------------------
    # Query: select the last status of the tree for the actual user_id
    # ------------------------------------------------------------------
    set query "
select 
	folder_id, 
	path, 
	open_p 
from 
	im_fs_folder_status 
where 
	user_id = :user_id
	and object_id = :object_id
"

    #for each result of the query...
    db_foreach hash_query $query {
    	# create an hash array where the index is the path of the dir and the value 
	# is the status (open/close) of the dir
	set hash_table($path) $open_p

	# save another hash array using the same index, the value now is the folder_id 
	# of the directory stored in the sql table
	set folder_id_table($path) $folder_id

    } if_no_rows {
	# Nothing - there were not rows for this project/user yet...
    }
    
    #-----------------------Init the table contents

    append texte "<table align=center>\n"
	
    #----------------------- Init the table contents
    # The next loop evaluates each result of the find, we need to make some 
    # initializations the first time this variable makes it possible
    set init 1

    # To control that the father folder don't be printed in the tree as its childs
    set id_file 0 
	
    #----------------------- For every result of FIND ( generate the tree table) 
    foreach file $files { 
	
	# count the deph of the file (how many directories depends the file)
	#ex (/home - /cluster - /Data - /Internal- /INT-ADM-KNOWMG - /file.dat)
	set file_paths [split $file "/"]
	set file_paths_len [llength $file_paths] 
	set body_index [expr $file_paths_len -1] 

	# store the name of the file ("file.dat")
	set file_body [lindex $file_paths $body_index] 
	
	# -- Evaluated only the first time that foreach is executed
	if { $init == 1 } {

	    #just a quicky solution for the integrity of file_paths_len
	    set file_paths_len [expr $file_paths_len -1]

	    # next_dir -> to know witch branch of the tree view we are evaluating
	    set next_dir [expr $file_paths_len]

	    # root_dir -> to know witch is the depth of the root folder for the filestorage tree view
	    set root_dir $next_dir

	    # root -> the complete path and name of the root directory for the filestorage tree view
	    set root $file
	    
	    set init 0
	}

	# initialize the file type(dir/file) and its size
	set file_type ""
	set file_size ""
	
	#Getting the real type and size of the file
	if { [catch {
	    set file_type [file type $file]
	    set file_size [expr [file size $file] / 1024]
	} err_msg] } {
	    
	}

	# Actions executed if the file type is "directory"
	if { [string compare $file_type "directory"] == 0 } {
		
	    # Generate a new position in the hash array that control the dependency of this folder
	    set path_dependency($file_paths_len) $file
	    ns_log Notice "-------- im_filestorage_pol_component: dependency $file_paths_len: $path_dependency($file_paths_len)"
	    # If the actual directory depth is greather than the last deph evaluated
	    if { $next_dir < $body_index } {
	    	#Set the actual directory deph as new deph 
	    	set body_index $next_dir 
	    }	    

	    # If the path status is not in the hash array
	    if { ![info exists hash_table($file)] } {
		# Force the entrance of this new directory in de hash array and in the 
		# sql table with a close status
		set hash_table($file) "c"
		db_dml init_insert "
insert into im_fs_folder_status (
	folder_id, 
	object_id,
	user_id, 
	path, 
	open_p
) values (
	im_fs_folder_status_seq.nextval,
	:object_id,
	:user_id,
	'$file',
	'c'
)"
		db_0or1row max_id_query "select max(folder_id) max_id from im_fs_folder_status"
		# Save the identifier of the folder generated in the sql table in the folder_id_table hash array
		set folder_id_table($file) $max_id
	    }

	    #If the actual deph depends of an uplevel directory
	    if { [info exists path_dependency($body_index)] } {
				
		# If the father directory of our evaluated directory is openned
		# or it depends of the directory selected by the user as root of the directory tree view
		if { ($hash_table($path_dependency($body_index)) == "o") || ($path_dependency($body_index) == $root)} {				    
		    
		    #We don't want to print the root folder like a child folder, we control this with the id_file var
		    if { $id_file != 0 } {
		    	# Printing one row with the directory information
		    	append texte [im_filestorage_dir_row $file_body $user_id $folder_id_table($file) $hash_table($file) $return_url $object_id $root_dir $file_paths_len $hash_table($file) $id_file $file $bread_crum_path]
		    }
		    # Refresh the directory branch that we start to evaluate
		    set next_dir $file_paths_len
		} else {									
		    #if the folder is close we don't parse any more files until next_dir == file_paths_len
		}
	    # If the actual deph is the root of the project, the base path
	    } else {

		if { $hash_table($file) == "c" } {
		    set next_dir $file_paths_len
		}	

		    #We don't want to print the root folder like a child folder, we control this with the id_file var
		    if { $id_file != 0 } {
		    	# Printing one row with the directory information
		    	append texte [im_filestorage_dir_row $file_body $user_id $folder_id_table($file) $hash_table($file) $return_url $object_id $root_dir $file_paths_len $hash_table($file) $id_file $file $bread_crum_path]
		    }
	    }
	} else {
	    # If the file type is file
	    if { [string compare $file_type "file"] == 0 } {
		
	    if { $next_dir < $body_index } {set body_index $next_dir }
	    	#Checking the dependency of the file
		if { [info exists hash_table($path_dependency($body_index))]} {
		    # If the father directory of our evaluated directory is openned
		    # or it depends of the directory selected by the user as root of the directory tree view
		    if { ($hash_table($path_dependency($body_index)) == "o") || ($path_dependency($body_index) == $root) } {
		    	#checking if we are at the first time, no tine sentido! sin esto tendria que funcionar!!!!
		    	if { $id_file != 0 } {
				append texte [im_filestorage_file_row $file_body $file $root_dir $file_paths_len $id_file $file]
			}
		    } 			
		}
	    }
	}
	incr id_file
    }
    append texte "</table></form>"
    return "$texte" 
}


ad_proc im_filestorage_dir_row { file_body user_id folder_id status return_url object_id root_dir file_paths_len open_p id_file file bread_crum_path} {

} {
    append texte "
<tr class=rowfilestorage>
  <td align=center valign=middle>
    <input type=checkbox name=id_row.$id_file value=$file_body>
    <input type=hidden name=id_file.$id_file value=$file>    
  </td>
  <td align=center id=idrow_$id_file>
    <div align=left>
" 
 
    set i $root_dir
    incr i 
    while {$i < $file_paths_len} {
	append texte [im_gif empty21]
	incr i 
    } 
    append texte "
   <a href=/intranet-filestorage/folder_status_update?[export_url_vars folder_id status object_id bread_crum_path return_url]>"

    if {$open_p == "o"} {
	append texte [im_gif foldin2]
    } else {
	append texte [im_gif foldout2]
    }
    set bread_crum_path $file
    append texte "<img src=/intranet-filestorage/images/folder_s.gif border=0 width=21 height=21 hspace=0 vspace=0></a>
		  <a href=/intranet-filestorage/index?[export_url_vars user_id bread_crum_path object_id return_url]>$file_body</a>
		    </a>
		    </div>
		    </td>
		    <td align=center class=rowfilestorage>
		    <div align=center>
		    </div>
		    </td>
		    <td align=center class=rowfilestorage>
		    <div align=center>
		    </div>
		    </td>
		    <td align=center class=rowfilestorage>
		    <div align=center>
		    
		    </div>
		    </td>
		  </tr>
		"
return "$texte"

}

ad_proc im_filestorage_file_row { file_body file root_dir file_paths_len id_file file} {

}   {
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

    append texte "
<tr class=rowfilestorage>
  <td align=center valign=middle>
    <input type=checkbox name=id_row.$id_file value=$file_body>
    <input type=hidden name=id_file.$id_file value=$file>    
  </td>
  <td id=idrow_$id_file>" 
    set i $root_dir 
    incr i
    while {$i < $file_paths_len} {
	append texte [im_gif empty21]
	incr i
    }
    
    set i $root_dir 
    if {$file_paths_len!=$i} {
	#append texte "<img src=/intranet-filestorage/images/adots_T.gif width=21>"
    } 
    
    # Choose a suitable icon
    set icon [im_gif exp-unknown]
    switch $file_extension {
	".xls" { set icon [im_gif exp-excel] }
	".doc" { set icon [im_gif exp-word] }
	".rtf" { set icon [im_gif exp-word] }
	".txt" { set icon [im_gif exp-text] }
	default {
	    ns_log Notice "im_file_component: unknown file_extension: '$file_extension'"
	}
    }

    append texte "
  $icon
  </a>
  $file_body
  </td>
  <td align=center class=rowfilestorage>
    $file_size Kb
  </td>
  <td align=center class=rowfilestorage>
    $file_modified
  </td>
  <td align=center class=rowfilestorage>
  </td>
</tr>\n"

    return "$texte"
}



ad_proc im_filestorage_create_folder {folder folder_name} {

} {
     if { [catch {
	 exec mkdir $folder/$folder_name
     } err_msg] } { return $err_msg }   
}


ad_proc im_filestorage_is_directory_empty {folder} {

} {
    set num ""
    if { [catch {
	append num [exec /usr/bin/find $folder]
    } err_msg] } {
	
    }
    
    return "$num"
}

ad_proc im_filestorage_delete_folder {project_id folder} {
    
} {
    if { [catch {
	ns_rmdir $folder
    } err_msg] } { return $err_msg }
}

ad_proc im_filestorage_erase_files { project_id file_name } {

} {
    if { [catch {
	exec rm $file_name 
    } err_msg] } { return $err_msg }
}