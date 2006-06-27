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
ad_register_proc GET /intranet/download/project_sales/* intranet_project_sales_download
ad_register_proc GET /intranet/download/company/* intranet_company_download
ad_register_proc GET /intranet/download/user/* intranet_user_download
ad_register_proc GET /intranet/download/home/* intranet_home_download
ad_register_proc GET /intranet/download/zip/* intranet_zip_download


ad_proc im_file_action_upload {} { return 2420 }
ad_proc im_file_action_download {} { return 2421 }

ad_proc intranet_project_download {} { intranet_download "project" }
ad_proc intranet_project_sales_download {} { intranet_download "project_sales" }
ad_proc intranet_company_download {} { intranet_download "company" }
ad_proc intranet_user_download {} { intranet_download "user" }
ad_proc intranet_home_download {} { intranet_download "home" }
ad_proc intranet_zip_download {} { intranet_download "zip" }


# -------------------------------------------------------
# 
# -------------------------------------------------------

ad_proc -public im_package_filestorage_id {} {
    Returns the package id of the intranet-filestorage module
} {
    return [util_memoize "im_package_filestorage_id_helper"]
}

ad_proc -private im_package_filestorage_id_helper {} {
    return [db_string im_package_core_id {
        select package_id from apm_packages
        where package_key = 'intranet-filestorage'
    } -default 0]
}


ad_proc -public im_filestorage_find_cmd {} {
    Returns the Unix/Linux/CygWin find command as specified in the
    intranet-core.FindCmd command
} {

    # -------------------------------------------------
    # First check for a default value for each platform:
    global tcl_platform

    set find_cmd ""
    set platform [lindex $tcl_platform(platform) 0]
    switch $platform {
        unix { 
	    # Let's use a Linux sefault
	    set find_cmd "/usr/bin/find" 
	}
        windows { 
	    # Windows CygWin default
	    set find_cmd "/bin/find" 
	}
        default { 
	    # Probably some kind of Unix derivate
	    set find_cmd "/usr/bin/find" 
	}
    }

    if { ![catch {
	# Just run find on itself - this should return exactly one file
        set file_list [exec $find_cmd $find_cmd -maxdepth 0]
    } err_msg]} { 
	return $find_cmd
    }

    # -------------------------------------------------
    # Check for an explicit the parameter
    set find_cmd [parameter::get -package_id [im_package_core_id] -parameter "FindCmd" -default "/bin/find"]

    # Make sure it works
    if { [catch {

	# Just run find on itself - this should return exactly one file
        set file_list [exec $find_cmd $find_cmd -maxdepth 0]

    } err_msg]} { 
	ad_return_complaint 1 "<B>Configuration Error</b>:
        <p>
        Command '$find_cmd' does not seem to exist on this system.<br>
        This error is probably due to a bad configuration of the 
        parameter 'intranet-core.FindCmd' or due to the lack of the
        file packages/acs-tcl/windows-procs.tcl (on a Win32 system).
        </p>
        <ul>
          <li>Please contact your application administrator in order to
              change the value of the parameter.
          <li>Please make sure that CygWin is installed correctly if you are 
              running on a Windows platform.
        </ul>
        <p>
        Here is the error message for reference:
        </p><br>
        <pre>$err_msg</pre>"
	return ""
    }
    return $find_cmd
}


ad_proc -public im_filestorage_profiles { user_id object_id } {
    Returns a list of profile_id-profile_gif-profile_name tuples
    for a given filestorage.
} {
    set profiles [list]

    set project_profile_sql "
select distinct 
	p.profile_id,
	p.profile_gif,
	g.group_name as profile_name
from 
	im_profiles p,
	groups g,
	((select
		p.profile_id
	from
		im_fs_folder_perms p,
		im_fs_folders f,
		im_profiles prof
	where
		f.folder_id = p.folder_id
		and f.object_id = :object_id
		and p.profile_id = prof.profile_id
	)
	UNION (select [im_customer_group_id] from dual)
	UNION (select [im_employee_group_id] from dual)
	UNION (select [im_freelance_group_id] from dual)
	UNION (select [im_wheel_group_id] from dual)
	) r
where
	r.profile_id = g.group_id (+)
	and r.profile_id = p.profile_id (+)
"
    db_foreach project_profiles $project_profile_sql {
	set profile_name_txt [lang::util::suggest_key $profile_name]
	if {"" == $profile_gif} { set profile_gif "profile" }
	lappend profiles [list $profile_id $profile_gif [_ intranet-filestorage.$profile_name_txt] ]
    }
    return $profiles
}


ad_proc -public im_filestorage_roles { user_id object_id } {
    Returns a list of role_id-role_gif-role_name tuples
    for a given filestorage.    
} {
    set roles [list]

    set project_roles_sql "
select distinct
	c.category_id,
	c.category,
	c.category_gif,
	c.category_description
from 
	im_biz_object_role_map m,
	im_categories c,
	acs_objects o
where
	o.object_id = :object_id
	and m.acs_object_type = o.object_type
	and m.object_role_id = c.category_id
"
    db_foreach project_roles $project_roles_sql {
	lappend roles [list $category_id $category_gif $category]
    }

    return $roles
}



ad_proc -public im_filestorage_profile_tds { user_id object_id } {
    Returns a rendered HTML component showing the icons of all
    profiles and object roles for a specific business objects.
} {
    set profile_icons ""

    set roles [im_filestorage_roles $user_id $object_id]
    foreach role $roles {
	ns_log Notice "im_filestorage_profile_tds: role: $role"
	append profile_icons "<td>[im_gif [lindex $role 1] [lindex $role 2]]</td>\n"
    }

    set profiles [im_filestorage_profiles $user_id $object_id]
    foreach profile $profiles {
	ns_log Notice "im_filestorage_profile_tds: profile: $profile"
	append profile_icons "<td>[im_gif [lindex $profile 1] [lindex $profile 2]]</td>\n"
    }

    return $profile_icons
}


# Serve the abstract URL 
# /intranet/download/<group_id>/...
#
proc intranet_download { folder_type } {
    global tcl_platform
	set platform [lindex $tcl_platform(platform) 0]
    
    set url "[ns_conn url]"
    set user_id [ad_maybe_redirect_for_registration]

    ns_log Notice "intranet_download: url=$url"

    # /intranet/download/projects/1934/source_en_US/help.rtf?
    # Using the group_id as selector for various storage types.
    set path_list [split $url {/}]
    set len [expr [llength $path_list] - 1]

    # skip: +0:/ +1:intranet, +2:download, +3:folder_type, +4:<object_id>, +5:...
    set group_id [lindex $path_list 4]
    ns_log Notice "group_id=$group_id"

     # Start retreiving the path starting at:
    set start_index 5

    set file_comps [lrange $path_list $start_index $len]
    set file_name [join $file_comps "/"]

    set base_path [im_filestorage_base_path $folder_type $group_id]
    if {"" == $base_path} {
	ad_return_complaint 1 "<LI>[_ intranet-filestorage.Unknown_folder_type]"
	return
    }

    set file "$base_path/$file_name"
    ns_log Notice "file_name=$file_name file=$file"

    if { [catch {
        set file_readable [file readable $file]
    } err_msg] } {
        # Probably some strange filename
        ad_return_complaint 1 "<LI>$err_msg<br>
	[_ intranet-filestorage.lt_This_issue_is_most_li]"
	return
    }

    if $file_readable {
		rp_serve_concrete_file $file		
    } else {
		doc_return 500 text/html "[_ intranet-filestorage.lt_Did_not_find_the_spec]"
    }
}




ad_proc -public im_package_filestorage_id { } {
} {
    return [util_memoize "im_package_filestorage_id_helper"]
}

ad_proc -private im_package_filestorage_id_helper {} {
    return [db_string im_package_core_id {
        select package_id from apm_packages
        where package_key = 'intranet-filestorage'
    } -default 0]
}




ad_proc -private im_filestorage_base_path { folder_type object_id } {
    Returns the base_path for the determined object or ""
    to indicate an error.
} {
    switch $folder_type {
	project {return [im_filestorage_project_path $object_id]}
	project_sales {return [im_filestorage_project_sales_path $object_id]}
	company {return [im_filestorage_company_path $object_id]}
	user {return [im_filestorage_user_path $object_id]}
	home {return [im_filestorage_home_path]}
	zip {return [im_filestorage_zip_path]}
    }
    return ""
}



ad_proc -public im_filestorage_find_files { project_id } {
    Returns a list of files in a project directory
} {
    set project_path [im_filestorage_project_path $project_id]
    set find_cmd [im_filestorage_find_cmd]
    if { [catch {
	ns_log Notice "im_filestorage_find_files: Checking $project_path"

	exec /bin/mkdir -p $project_path
        exec /bin/chmod ug+w $project_path
	set file_list [exec $find_cmd $project_path -type f]

    } err_msg] } {
	# Probably some permission errors - return empty string
	set err "'exec $find_cmd $project_path' failed with error:
	err_msg=$err_msg\n"
	set file_list ""
    }

    set files [lsort [split $file_list "\n"]]
    return $files
}


ad_proc im_filestorage_home_component { user_id } {
    Filestorage for global corporate files
} {
    set base_path [im_filestorage_home_path]
    set object_name "Home"
    set folder_type "home"
    set object_id [ad_conn subsite_id]
    set object_id 0
    set return_url "/intranet/"
    set home_path [im_filestorage_home_path]
    return [im_filestorage_base_component $user_id $object_id $object_name $base_path $folder_type "o"]
}

ad_proc im_filestorage_project_component { user_id project_id project_name return_url} {
    Filestorage for projects
} {
    set project_path [im_filestorage_project_path $project_id]
    set folder_type "project"
    set object_name "Project"
    return [im_filestorage_base_component $user_id $project_id $object_name $project_path $folder_type]
}

ad_proc im_filestorage_project_sales_component { user_id project_id project_name return_url} {
    Filestorage for project sales (protected)
} {

    if {![im_permission $user_id view_filestorage_sales]} { return ""}

    set project_path [im_filestorage_project_sales_path $project_id]
    set folder_type "project_sales"
    set object_name "Project Sales"
    return [im_filestorage_base_component $user_id $project_id $object_name $project_path $folder_type]
}

ad_proc im_filestorage_company_component { user_id company_id company_name return_url} {
    Filestorage for companies
} {
    set company_path [im_filestorage_company_path $company_id]
    set folder_type "company"
    return [im_filestorage_base_component $user_id $company_id $company_name $company_path $folder_type]
}


ad_proc im_filestorage_user_component { user_id user_to_show_id user_name return_url} {
    Filestorage for users
} {
    set user_path [im_filestorage_user_path $user_to_show_id]
    set folder_type "user"
    return [im_filestorage_base_component $user_id $user_to_show_id $user_name $user_path $folder_type]
}


# ---------------------------------------------------------------------
# Determine pathes for project, companies and users
# All pathes end WITHOUT a trailing "/"
# ---------------------------------------------------------------------

ad_proc im_filestorage_zip_path { } {
    Determine the location where zips are located
} {
    return "/tmp"
}


ad_proc im_filestorage_home_path { } {
    Helper to determine the location where global company files
    are stored on the hard disk 
} {
    set package_id [im_package_filestorage_id]
    set base_path_unix [parameter::get -package_id $package_id -parameter "HomeBasePathUnix" -default "/tmp/home"]
    return "$base_path_unix"
}


ad_proc im_filestorage_backup_path { } {
    Helper to determine the location where global backup files
    are stored on the hard disk 
} {
    set backup_path [parameter::get -package_id [im_package_core_id] -parameter "BackupBasePathUnix" -default "/tmp"]
    return $backup_path
}


ad_proc im_filestorage_project_path { project_id } {
    Determine the location where the project files
    are stored on the hard disk for this project
} {
    return [util_memoize "im_filestorage_project_path_helper $project_id"]
#    return [im_filestorage_project_path_helper $project_id]
}

ad_proc im_filestorage_project_path_helper { project_id } {
    Determine the location where the project files
    are stored on the hard disk for this project
} {
    set package_key "intranet-filestorage"
    set package_id [db_string package_id "select package_id from apm_packages where package_key=:package_key" -default 0]
    set base_path_unix [parameter::get -package_id $package_id -parameter "ProjectBasePathUnix" -default "/tmp/projects"]

    # Return a demo path for all project, clients etc.
    if {[ad_parameter -package_id [im_package_core_id] TestDemoDevServer "" 0]} {
	set path [ad_parameter "TestDemoDevPath" intranet "internal/demo"]
	ns_log Notice "im_filestorage_project_path: TestDemoDevServer: $path"
	return "$base_path_unix/$path"
    }

    set query "
select
	p.project_nr,
	p.project_path,
	p.project_name,
	c.company_path
from
	im_projects p,
	im_companies c
where
	p.project_id=:project_id
	and p.company_id=c.company_id(+)
"

    if { ![db_0or1row projects_info_query $query] } {
	ad_return_complaint 1 "Can't find the project with group 
	id of $project_id"
	return
    }

    return "$base_path_unix/$company_path/$project_path"
}


ad_proc im_filestorage_project_sales_path { project_id } {
    Determine the location where the project files
    are stored on the hard disk for this project
} {
#    return [util_memoize "im_filestorage_project_sales_path_helper $project_id"]
    return [im_filestorage_project_sales_path_helper $project_id]
}

ad_proc im_filestorage_project_sales_path_helper { project_id } {
    Determine the location where the project files
    are stored on the hard disk for this project
} {
    set package_key "intranet-filestorage"
    set package_id [db_string package_id "select package_id from apm_packages where package_key=:package_key" -default 0]
    set base_path_unix [parameter::get -package_id $package_id -parameter "ProjectSalesBasePathUnix" -default "/tmp/project_sales"]

    # Return a demo path for all project, clients etc.
    if {[ad_parameter -package_id [im_package_core_id] TestDemoDevServer "" 0]} {
	set path [ad_parameter "TestDemoDevPath" "" "internal/demo"]
	ns_log Notice "im_filestorage_project_path: TestDemoDevServer: $path"
	return "$base_path_unix/$path"
    }

    set query "
select
	p.project_nr,
	p.project_path,
	p.project_name,
	c.company_path
from
	im_projects p,
	im_companies c
where
	p.project_id=:project_id
	and p.company_id=c.company_id(+)
"

    if { ![db_0or1row projects_info_query $query] } {
	ad_return_complaint 1 "Can't find the project with group 
	id of $project_id"
	return
    }

    return "$base_path_unix/$company_path/$project_path"
}


ad_proc im_filestorage_user_path { user_id } {
    Determine the location where the user files
    are stored on the hard disk
} {
    set package_key "intranet-filestorage"
    set package_id [db_string package_id "select package_id from apm_packages where package_key=:package_key" -default 0]
    set base_path_unix [parameter::get -package_id $package_id -parameter "UserBasePathUnix" -default "/tmp/users"]

    # Return a demo path for all project, clients etc.
    if {[ad_parameter -package_id [im_package_core_id] TestDemoDevServer "" 0]} {
	set path [ad_parameter "TestDemoDevUserPath" "" "users"]
	ns_log Notice "im_filestorage_project_path: TestDemoDevServer: $path"
	return "$base_path_unix/$path"
    }
    
    return "$base_path_unix/$user_id"
}


ad_proc im_filestorage_company_path { company_id } {
    Determine the location where the project files
    are stored on the hard disk
} {
    return [im_filestorage_company_path_helper $company_id]
#    return [util_memoize "im_filestorage_company_path_helper $company_id"]
}

ad_proc im_filestorage_company_path_helper { company_id } {
    Determine the location where the project files
    are stored on the hard disk
} {
    set base_path_unix [parameter::get -package_id [im_package_filestorage_id] -parameter "CompanyBasePathUnix" -default "/tmp/companies"]

    set company_path "undefined"
    if {[catch {
	set company_path [db_string get_company_path "select company_path from im_companies where company_id=:company_id"]
    } errmsg]} {
	ad_return_complaint 1 "<LI>[_ intranet-filestorage.lt_Internal_Error____Una]"
	return
    }

    return "$base_path_unix/$company_path"
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

    # Localize the workflow stage directories
    set locale "en_US"
    set source [lang::message::lookup $locale intranet-translation.Workflow_source_directory "source"]
    set trans [lang::message::lookup $locale intranet-translation.Workflow_trans_directory "trans"]
    set edit [lang::message::lookup $locale intranet-translation.Workflow_edit_directory "edit"]
    set proof [lang::message::lookup $locale intranet-translation.Workflow_proof_directory "proof"]
    set deliv [lang::message::lookup $locale intranet-translation.Workflow_deliv_directory "deliv"]
    set other [lang::message::lookup $locale intranet-translation.Workflow_other_directory "other"]

    switch $project_type_id {
	
	87 { 
	    # Trans + Edit
	    return [list $deliv $trans $edit]
	}

	88 {
	    # Edit Only
	    return [list $deliv $edit]
	}

	89 {
	    # Trans + Edit + Proof
	    return [list $deliv $trans $edit $proof]
	}

	90 {
	    # Linguistic
	    return [list $deliv]
	}

	91 {
	    # Localization
	    return [list $deliv]
	}

	92 {
	    # Technology
	    return [list $deliv]
	}

	93 {
	    # Trans Only
	    return [list $deliv $trans]
	}

	94 {
	    # Trans + Int. Spotcheck
	    return [list $deliv $trans $edit]
	}

	95 {
	    # Proof Only
	    return [list $deliv $proof]
	}

	96 {
	    # Glossary Compilation
	    return [list $deliv]
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
    # Localize the workflow stage directories
    set locale "en_US"
    set source [lang::message::lookup $locale intranet-translation.Workflow_source_directory "source"]

    if {[ad_parameter -package_id [im_package_core_id] TestDemoDevServer "" 0]} {
	# We're at a demo server, so don't create any directories!
	return
    }

    # Get some missing variables about the project and the company
    set query "
select
	p.project_type_id,
	p.project_path,
	p.company_id,
	im_category_from_id(p.source_language_id) as source_language,
	c.company_path
from
	im_projects p,
	im_companies c
where 
	p.project_id = :project_id
	and p.company_id = c.company_id
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

    # Create a company directory if it doesn't already exist
    set company_dir "$base_path_unix/$company_path"
    ns_log Notice "im_filestorage_create_directories: company_dir=$company_dir"
    if { [catch {
	if {![file exists $company_dir]} { 
	    ns_log Notice "exec /bin/mkdir -p $company_dir"
	    exec /bin/mkdir -p $company_dir 
	    ns_log Notice "exec /bin/chmod ug+w $company_dir"
	    exec /bin/chmod ug+w $company_dir
	}
    } err_msg] } { return $err_msg }

    # Create the project dir if it doesn't already exist
    set project_dir "$company_dir/$project_path"
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
	set source_dir "$project_dir/${source}_$source_language"
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


ad_proc im_filestorage_tool_tds { folder folder_type project_id return_url up_link } {
    Returns a formatted HTML component with a number of GIFs.
} {
    return "
   <td align=center>
     <input type=hidden name=actions value=\"none\">
   </td>
<!-- 
  Folder-up has some particular problems because it is actively
  modifying the URL variables. Doesn't work yet 100%, so better
  disable meanwhile...
   <td>
     <input type=image src=/intranet/images/up-folder.gif width=21 height=21 onClick=\"window.document.$folder_type.actions.value='up-folder'; submit();\" title='[_ intranet-filestorage.Folder_up]' alt='[_ intranet-filestorage.Folder_up]'>
   </td>
-->
   <td>
     <input type=image src=/intranet/images/newfol.gif width=21 height=21 onClick=\"window.document.$folder_type.actions.value='new-folder'; submit();\" title='[_ intranet-filestorage.Create_a_new_folder]' alt='[_ intranet-filestorage.Create_a_new_folder]'>
   </td><td>
     <input type=image src=/intranet/images/upload.gif width=21 height=21 onClick=\"window.document.$folder_type.actions.value='upload'; submit();\" title='[_ intranet-filestorage.Upload_a_file]' alt='[_ intranet-filestorage.Upload_a_file]'>
   </td><td>
<!--     <input type=image src=/intranet/images/new-doc.gif width=21 height=21 onClick=\"window.document.$folder_type.actions.value='new-doc'; submit();\" title='[_ intranet-filestorage.lt_Create_a_new_document]' alt='[_ intranet-filestorage.lt_Create_a_new_document]'> -->
   </td><td>
     <input type=image src=/intranet/images/del.gif width=21 height=21 onClick=\"window.document.$folder_type.actions.value='del'; submit();\" title='[_ intranet-filestorage.lt_Delete_files_and_fold]' alt='[_ intranet-filestorage.lt_Delete_files_and_fold]'>
   </td><td>
     <input type=image src=/intranet/images/zip.gif width=21 height=21 onClick=\"window.document.$folder_type.actions.value='zip'; submit();\" title='[_ intranet-filestorage.lt_Download_all_files_as]' alt='[_ intranet-filestorage.lt_Download_all_files_as]'>
   </td><td>

    <table border=0 cellspacing=0 cellpadding=0 width=20>
    <tr><td align=center>
     <input type=image src=/intranet/images/plus_9.gif width=9 height=9 onClick=\"window.document.$folder_type.actions.value='add-perms'; submit();\" title='[_ intranet-filestorage.lt_Add_permissions_to_fo]' alt='[_ intranet-filestorage.lt_Add_permissions_to_fo]'>
    </td></tr>
    <tr><td align=center>
     <input type=image src=/intranet/images/minus_9.gif width=9 height=9 onClick=\"window.document.$folder_type.actions.value='del-perms'; submit();\" title='[_ intranet-filestorage.lt_Remove_permissions_fr]' alt='[_ intranet-filestorage.lt_Remove_permissions_fr]'>
    </td></tr>
    </table>
  </td>
"
}


ad_proc im_filestorage_bread_crum { } {
    Returns a formatted HTML component indicating the relative
    position in the current folder
} {
    set return_url [im_url_with_query]
    set new_url [split $return_url "&"]
    set return_url [lindex $new_url 0]
    return "$return_url"
}


ad_proc export_url_bind_vars { bind_vars } {
    Returns the variable tail of the URL based on the variables
    found in the bind_vars parameter.
} {
    set vars ""
    set ctr 0
    foreach var [ad_ns_set_keys $bind_vars] {
	set value [ns_set get $bind_vars $var]
	if {$ctr > 0} { append vars "&" }
	append vars "$var=[ns_urlencode $value]"
	incr ctr
    }
    return "$vars"
}



ad_proc -private im_filestorage_user_memberships { user_id object_id } {
    Returns a list of all profiles and roles to whom the current
    user belongs.
} {
    set sql "
	-- Get the list of all profiles (=group) to which
	-- the current user belongs
	select distinct
		profile_id
	from
		im_profiles p,
		group_distinct_member_map m
	where
		m.member_id = :user_id
		and m.group_id = p.profile_id
    UNION
	-- get the list of roles that the current user
	-- has in his relationship with the object_id
	select distinct
		m.object_role_id as profile_id
	from
		acs_rels r,
		im_biz_object_members m
	where
		r.object_id_one = :object_id
		and r.object_id_two = :user_id
		and r.rel_id = m.rel_id"

    set profile_list [db_list user_profiles $sql]

    # Make sure there is atleast on element to the list
    # in order to avoid errors when using it in a where ...in (...)
    # statement
    if {0 == [llength $profile_list]} {
	set profile_list [list 0]
    }

    return $profile_list
}

ad_proc -private im_filestorage_merge_perms { perms1 perms2 } {
    Merge (=add) the perms of a subdirectory to the perms of another
    directory. In the future, this may also include subtraction
    of perms.
} {
    set perms [list]
    for {set ctr 0} {$ctr <= 3} {incr ctr} {
	set perm1 [lindex $perms1 $ctr]
	set perm2 [lindex $perms2 $ctr]
	lappend perms [expr $perm1+$perm2]
    }
    return $perms
}

ad_proc -public im_filestorage_path_perms { path perm_hash_array roles profiles} {
    Returns a hash of (profile_ids -> [1 1 1 1]) for the given path,
    inheriting permissions from all super-directories
    @param roles list of [role_id role_gif role_name] triples for each role
    @param profiles list of [profile_id profile_gif profile_name] triples 
} {
    ns_log Notice "im_filestorage_path_perms: roles=$roles"
    ns_log Notice "im_filestorage_path_perms: profiles=$profiles"
    ns_log Notice "im_filestorage_path_perms: perm_hash_array=$perm_hash_array"
    
    array set perm_hash $perm_hash_array
    foreach profile $profiles {
	set profile_id [lindex $profile 0]

	# Initialize the perms with the perms of the root directory
	set cur_path ""
	set hash_key "$cur_path-$profile_id"
	set path_perms $perm_hash($cur_path)

	# Loop for all paths and check if there are other perms defined
	set path_list [split $path "/"]
	foreach cur_path_fragment $path_list {
	    # Calculate the new cur_path
	    if {"" != $cur_path} { append cur_path "/" }
	    append cur_path $cur_path_fragment
	    
	    # Add the perms of the current directory
	    set hash_key "$cur_path-$profile_id"
	    if {[info exists perm_hash($hash_key)]} {
		set cur_path_perms $perm_hash($hash_key)
		set path_perms [im_filestorage_merge_perms $path_perms $cur_path_perms]
	    }
	}
	set perms($profile_id) $path_perms
	ns_log Notice "im_filestorage_path_perms: perms=[array get perms]"
    }

    foreach role $roles {
	set role_id [lindex $role 0]

	# Initialize the perms with the perms of the root directory
	set cur_path ""
	set hash_key "$cur_path-$role_id"
	set path_perms $perm_hash($cur_path)

	# Loop for all paths and check if there are other perms defined
	set path_list [split $path "/"]
	foreach cur_path_fragment $path_list {
	    # Calculate the new cur_path
	    if {"" != $cur_path} { append cur_path "/" }
	    append cur_path $cur_path_fragment
	    
	    # Add the perms of the current directory
	    set hash_key "$cur_path-$role_id"
	    if {[info exists perm_hash($hash_key)]} {
		set cur_path_perms $perm_hash($hash_key)
		set path_perms [im_filestorage_merge_perms $path_perms $cur_path_perms]
	    }
	}
	set perms($role_id) $path_perms
	ns_log Notice "im_filestorage_path_perms: perms=[array get perms]"

    }

    # Return hash as a list
    return [array get perms]
}


ad_proc -public im_filestorage_get_perm_hash { 
    user_id
    object_id 
    user_memberships
} {
    Returns a hash (path -> [v r w a]) for all pathes of the
    current object.
    This routine is used inside the main filestorage
    and "stand alone" to determine permission on folders
    for the add/del permissions screens
} {

    set last_perm_parent ""
    set last_perm_parent_depth 0
    # The root is always readable for everybody
    set root_path ""
    set perm_hash($root_path) [list 0 0 0 0]

    # Extract all (path - profile_id) -> permission
    # information from the DB and store them in a 
    # hash array for fast access
    set perm_sql "
select
        p.profile_id,
	f.path as folder_path,
	p.view_p,
	p.read_p,
	p.write_p,
	p.admin_p
from
	im_fs_folder_perms p,
	im_fs_folders f
where
	f.object_id = :object_id
	and p.folder_id = f.folder_id
"

    set ctr 0
    db_foreach perm_init $perm_sql {

	incr ctr
	set hash_key "$folder_path-$profile_id"
	
	if {$view_p} {
	    set perms [list 1 0 0 0]
	    if {[info exists perm_hash($hash_key)]} { 
		set old_perms $perm_hash($hash_key)
		set perms [im_filestorage_merge_perms $old_perms $perms]
	    }
	    set perm_hash($hash_key) $perms
	}
	if {$read_p} {
	    set perms [list 0 1 0 0]
	    if {[info exists perm_hash($hash_key)]} { 
		set old_perms $perm_hash($hash_key)
		set perms [im_filestorage_merge_perms $old_perms $perms]
	    }
	    set perm_hash($hash_key) $perms
	}
	if {$write_p} {
	    set perms [list 0 0 1 0]
	    if {[info exists perm_hash($hash_key)]} { 
		set old_perms $perm_hash($hash_key)
		set perms [im_filestorage_merge_perms $old_perms $perms]
	    }
	    set perm_hash($hash_key) $perms
	}
	if {$admin_p} {
	    set perms [list 0 0 0 1]
	    if {[info exists perm_hash($hash_key)]} { 
		set old_perms $perm_hash($hash_key)
		set perms [im_filestorage_merge_perms $old_perms $perms]
	    }
	    set perm_hash($hash_key) $perms
	}
    }

    # Default value if no permissions have been set for
    # a folder: make everything readable for everybody.
    if {!$ctr} { 
	set view [im_permission $user_id fs_root_view]
	set read [im_permission $user_id fs_root_read]
	set write [im_permission $user_id fs_root_write]
	set admin [im_permission $user_id fs_root_admin]

	set perm_hash($root_path) [list $view $read $write $admin]
    }

    return [array get perm_hash]
}


ad_proc -public im_filestorage_folder_permissions { 
    user_id
    object_id
    rel_path
    user_memberships
    roles
    profiles
    perm_hash_array
} {
    Get the userss permissions for a specific path.
    Returns a list [v r w a].
} {

    # Loop for all profile memberships of the current user
    # and "or-join" the permissions together
    
    array set profile_perms [im_filestorage_path_perms $rel_path $perm_hash_array $roles $profiles]
    
    set user_perms [list 0 0 0 0]
    foreach profile_id $user_memberships {
	set hash_key "$profile_id"
	if {[info exists profile_perms($hash_key)]} {
	    set perms $profile_perms($hash_key)
	    set user_perms [im_filestorage_merge_perms $user_perms $perms]
	}
    }

    # Give base-object administrators (write permissions to the object)
    # full access to all files
    if {$object_id > 0} {
	
	# Permissions for all usual projects, companies etc.
	set object_type [db_string acs_object_type "select object_type from acs_objects where object_id=:object_id"]
	set perm_cmd "${object_type}_permissions \$user_id \$object_id object_view object_read object_write object_admin"
	
	eval $perm_cmd
	if {$object_write} { set user_perms [list 1 1 1 1] }
	
    } else {
	
	# The home-component has object_id==0
	# Set the default permissions as "read"
	set object_view 1
	set object_read 1
	set object_write 0
	set object_admin 0
	
	# Check if the user has more permissions:
	# We use "edit_internal_offices", because the home FS belongs
	# to the "internal offices". Well, not 100%, but that's fairly ok..
	if {[im_permission $user_id edit_internal_offices]} { 
	    set object_write 1
	}
	if {$object_write} { set user_perms [list 1 1 1 1] }
	
    }

    return $user_perms
}




ad_proc -private im_filestorage_render_perms { perm } {
    Returns a formatted HTML like "RW", indicating that
    a directory is readable and writable, but not administrtable.
} {
    set result ""
    if {[lindex $perm 0]} { append result "v" }
    if {[lindex $perm 1]} { append result "r" }
    if {[lindex $perm 2]} { append result "w" }
    if {[lindex $perm 3]} { append result "a" }

    if {"" == $result} { set result "-" }
    return $result
}

ad_proc -public im_filestorage_base_component { user_id object_id object_name base_path folder_type { default_open "c"} } {
    Main funcion to generate the filestorage page ( create folder, bread crum, ....)
    @param user_id: the user who is attempting to view the filestorage
    @param object_id: from wich group is pending this user?
    @param project_name: in wich project tree directory wants this user to view?
    @param base_path: finishes _without_ a trailing "/"
    @param bread_crum_path: a relative path, starting from the base_path
           "" = root directory, "dir1" = next directory, "dir1/dir2" = second next, etc.
} {
    ns_log Notice "im_filestorage_base_component $user_id $object_id $object_name $base_path $folder_type"

    set bgcolor(0) "roweven"
    set bgcolor(1) "rowodd"

    set find_cmd [im_filestorage_find_cmd]
    set current_url_without_vars [ns_conn url]
    set user_id [ad_maybe_redirect_for_registration]

    # Extract the bread_crum variable and delete from URL variables
    set bind_vars [ns_conn form]
    if {"" == $bind_vars} { set bind_vars [ns_set create] }

    # Remove return_url from current vars, because it's too long
    # to be incorporated into the local return_url
    ns_set delkey $bind_vars return_url
    set return_url "$current_url_without_vars?[export_url_bind_vars $bind_vars]"
    set bread_crum_path [ns_set get $bind_vars bread_crum_path]
    set base_path_depth [llength [split $base_path "/"]]
    ns_set delkey $bind_vars bread_crum_path

    set user_is_employee_p [im_user_is_employee_p $user_id]
    set user_is_customer_p [im_user_is_customer_p $user_id]

    # Customer shouldn't see their filestorage
    if {[string equal "customer" $folder_type] || [string equal "user" $folder_type]} {
	if {!$user_is_employee_p} { return "" }
    }


    # ------------------------------------------------------------------
    # Start initializing the tree algrorithm

    # Get the list of files using "find"
    # Start at $base_bath/$bread_crum_path
    set file_list ""
    set bread_crum_join ""
    if {"" != $bread_crum_path} { set bread_crum_join "/" }

    # Get the list of all files and split by end of line
    set find_path "$base_path$bread_crum_join$bread_crum_path"

    if { [catch {
	# Executing the find command
        exec /bin/mkdir -p $find_path
        exec /bin/chmod ug+w $find_path
	set file_list [exec $find_cmd $find_path]
	set files [lsort [split $file_list "\n"]]

    } err_msg] } { 
	return "<ul><li>[_ intranet-filestorage.lt_Unable_to_get_file_li]:<br><pre>find_path=$find_path\n$err_msg</pre></ul>"
    }

    # remove the first (root path) from the list of files returned by "find".
    set files [lrange $files 1 [llength $files]]


    # ------------------------------------------------------------------
    # Format the bread crum bar
    
    # The base path selected by the user
    set bread_crum_html "<table><tr><td>\n"
    set bread_crum_list [split $bread_crum_path "/"]

    # First bread_crum is the project name - always visible
    append bread_crum_html "<a href=$current_url_without_vars?[export_url_bind_vars $bind_vars]>$object_name</a> : "
    set current_path ""
    set up_link ""

    set crum_vars [ns_set copy $bind_vars]
    foreach crum $bread_crum_list {
	if {"" != $current_path} { append current_path "/" }
	append current_path "$crum"

	# Set the current bread_crum_path
	ns_set delkey $crum_vars bread_crum_path
	ns_set put $crum_vars bread_crum_path $current_path

	append bread_crum_html "<a href=$current_url_without_vars?[export_url_bind_vars $crum_vars]>$crum</a> : "
    }
    append bread_crum_html "</td></tr></table>\n"


    # ------------------------------------------------------------------
    # Extract the folder status from the DB table.
    # ------------------------------------------------------------------
    set query "
select 
	f.folder_id, 
	f.path, 
	s.open_p 
from 
	im_fs_folders f,
	im_fs_folder_status s
where 
	s.user_id = :user_id
	and f.object_id = :object_id
	and f.folder_id = s.folder_id
"
 
    set last_folder_id 0
    set folder_id_hash() 0
    db_foreach hash_query $query {
    	# Hash: Path -> open/closed
	set open_p_hash($path) $open_p
	ns_log Notice "$path -> $open_p"

	# Hash: Path -> folder_id
	set folder_id_hash($path) $folder_id
	set last_folder_id [expr $folder_id * 10]
	ns_log Notice "$path -> $folder_id"
    }

    # ------------------------------------------------------------------
    # Setup the variables for the "Root Path" 
    # (=the first line returned by "find")
    # ------------------------------------------------------------------
    
    # Setup the "last parent" - the directory on which we depend.
    # In the beginning it's the top level directory ("" relative)
    # This normally corresponds to the last _closed_ directory
    # on top of us.
    set last_parent_path ""
    set last_parent_path_depth 0
    set open_p_hash($last_parent_path) "o"

    # Always show the root of the filestorage as "open"
    set open_p_hash("") "o"

    # Always show the bread_crum "root" as open
    set open_p_hash($current_path) "o"


    # ------------------------------------------------------------------
    # Start initializing the permission system
    # Permissions are stored in a list with elements
    # [view - read - write - asmin]
    # ------------------------------------------------------------------

    # Get the list of all relevant roles and profiles for permissions
    set roles [im_filestorage_roles $user_id $object_id]
    set profiles [im_filestorage_profiles $user_id $object_id]

    # Get the group membership of the current (viewing) user
    set user_memberships [im_filestorage_user_memberships $user_id $object_id]

    set perm_hash_array [im_filestorage_get_perm_hash $user_id $object_id $user_memberships]
    array set perm_hash $perm_hash_array

    # ------------------------------------------------------------------
    # Here we start rendering the file tree
    # ------------------------------------------------------------------

    set files_html ""
    set ctr 0
    foreach file $files { 

	# count the deph of the file (how many directories depends the file)
	# example: (INT-ADM-KNOWMG/file.dat)
	set file_paths [split $file "/"]
	set file_paths_len [llength $file_paths]

	# Calculate the relative path (relative to base_path)
	set rel_path_list [lrange $file_paths $base_path_depth $file_paths_len]
	set rel_path [join $rel_path_list "/"]
	set current_depth [llength $rel_path_list]

	# Get more information about the file
	set file_body [lindex $rel_path_list [expr $current_depth -1]]
	set file_type ""
	set file_size "invalid"
	set file_modified "invalid"
	set file_extension ""

	# fraber 050803: Nope, doesn't work...
	# in windows add install directory to file
	# global tcl_platform 
	# if { [string match $tcl_platform(platform) "windows"] } {
    	#    set file "C:/ProjectOpen/cygwin${file}"
	#}
	
	if { [catch {
	    set file_type [file type $file]
	    set file_size [expr [file size $file] / 1024]
	    set file_modified [ns_fmttime [file mtime $file] "%d/%m/%Y"]
	    set file_extension [file extension $file]
	} err_msg] } { }
	ns_log Notice "file=$file, rel_path=$rel_path, current_depth=$current_depth"
	ns_log Notice "file_body=$file_body, file_type=$file_type, file_size=$file_size, file_modified=$file_modified"

	# Make sure we get always hava an open/close value for the
	# current directory, even if there was no information about
	# the current folder in the DB.
	if { ![info exists open_p_hash($rel_path)]} {
	    set open_p_hash($rel_path) $default_open
	    incr last_folder_id
	    set folder_id_hash($rel_path) $last_folder_id
	}

	# The core of the algorithm: check our visibility in dependency
	# of the open/close status of our "last parent"
	# (=the topmost folder that was closed):
	#
	if {$current_depth > $last_parent_path_depth} {
	    # We are in a  subdirectory of parent_path.
	    # So our visibility depends on whether last_parent
	    # is open or not.
	    set visible_p $open_p_hash($last_parent_path)

	    if {[string equal "o" $visible_p]} {
		# Our parent was open, so this subdirectory becomes
		# the new last_parent.
		set last_parent_path $rel_path
		set last_parent_path_depth $current_depth
	    }
	} else {
	    # We are at the same level as last_parent.
	    # So we know that we are visible here (because
	    # last_parent was visible).
	    set visible_p "o"

	    # We become the new last_parent.
	    set last_parent_path $rel_path
	    set last_parent_path_depth $current_depth
	}

	# Now we know that we need to render this line.
	if {![string equal "o" $visible_p]} { continue }


	# ----------------------------------------------------
	# Determine access permissions

	set user_perms [im_filestorage_folder_permissions $user_id $object_id $rel_path $user_memberships $roles $profiles $perm_hash_array]

	# Don't even enter into the folder/file procs if the user shoudln't see it
	set view_p [lindex $user_perms 0]
	if {!$view_p} { continue }


	# ----------------------------------------------------
	# Count the lines starting with 1.
	# We need this counter to mark rows as even/odd alternatingly
	# and to provide a unique identifier for each line for the 
	# file_id/dir_id/id_path construction.
	set rowclass $bgcolor([expr $ctr % 2])
	incr ctr

	# Actions executed if the file type is "directory"
	if { [string compare $file_type "directory"] == 0 } {

	    set dir_bread_crum_list [lrange $file_paths $base_path_depth [llength $file_paths]]
	    set dir_bread_crum_path [join $dir_bread_crum_list "/"]

	    # Printing one row with the directory information
	    append files_html [im_filestorage_dir_row \
			    -user_id $user_id \
			    -file_body $file_body  \
			    -base_path $base_path \
			    -bind_vars $bind_vars  \
			    -current_url_without_vars $current_url_without_vars  \
			    -return_url $return_url  \
			    -folder_id $folder_id_hash($rel_path)  \
			    -object_id $object_id \
			    -base_path_depth $base_path_depth  \
			    -current_depth $current_depth  \
			    -open_p $open_p_hash($rel_path) \
			    -ctr $ctr \
			    -rel_path $rel_path  \
			    -bread_crum_path $dir_bread_crum_path \
			    -rowclass $rowclass \
			    -roles $roles \
			    -profiles $profiles \
			    -perm_hash_array $perm_hash_array \
			    -user_perms $user_perms \
	    ]

	} else {
	    # Skip the line if it's not a file
	    if {![string equal $file_type "file"]} { continue }
	    append files_html [im_filestorage_file_row \
			      $file_body \
			      $base_path \
			      $folder_type \
			      $rel_path \
			      $object_id \
			      $base_path_depth \
			      $current_depth \
			      $rel_path \
			      $ctr \
			      $rowclass \
			      $file_type \
			      $file_size \
			      $file_modified \
			      $file_extension \
			      $user_perms \
		           ]
	}
    }

    if {"" == $files_html} {
	append files_html "<tr><td colspan=99>[_ intranet-filestorage.No_files_found]</td></tr>\n"
    }

    set tool_tds [im_filestorage_tool_tds $bread_crum_path $folder_type $object_id $return_url $up_link]

    set profile_tds [im_filestorage_profile_tds $user_id $object_id]


    set component_html "
<form name=\"$folder_type\" method=POST action=\"/intranet-filestorage/action\">
[export_form_vars object_id bread_crum_path folder_type return_url]

<TABLE border=0 cellpadding=0 cellspacing=0>
  <TR align=center valign=middle class=rowtitle> 
    <TD colspan=5>
      <table border=0 cellspacing=0 cellpadding=1>
      <tr>
      $tool_tds
      </tr>
      </table>
    </TD>
    $profile_tds
  </TR>
  <TR class=rowplain> 
    <TD colspan=5>
      $bread_crum_html
    </TD>
  </TR>
  <TBODY>
    $files_html
  </TBODY>
</TABLE>
</form>\n"

    return $component_html
}




ad_proc im_filestorage_dir_row { 
    -user_id
    -file_body
    -base_path
    -bind_vars
    -current_url_without_vars
    -return_url
    -folder_id
    -object_id
    -base_path_depth
    -current_depth
    -open_p
    -rel_path
    -ctr
    -bread_crum_path
    -rowclass
    -roles
    -profiles
    -perm_hash_array
    -user_perms
} {
    Create a directory row with links for open/close and bread_crum enter
} {
    array set perm_hash $perm_hash_array

    # ----------------------------------------------------
    # Determine access permissions

    # Decode the permissions calculated at the main routine
    set view_p [lindex $user_perms 0]
    set read_p [lindex $user_perms 1]
    set write_p [lindex $user_perms 2]
    set admin_p [lindex $user_perms 3]

    # Get the profile_id -> [1 1 1 1] hash
    array set perms [im_filestorage_path_perms $rel_path $perm_hash_array $roles $profiles]

    # ----------------------------------------------------
    # Render the main line
    set line_html ""
    set i 1
    while {$i < $current_depth} {
	append line_html [im_gif empty21]
	incr i 
    } 
    set status $open_p
    append line_html "<a href=/intranet-filestorage/folder_status_update?[export_url_vars status object_id rel_path return_url]>"

    if {$open_p == "o"} {
	append line_html [im_gif foldin2]
    } else {
	append line_html [im_gif foldout2]
    }

    append line_html "</a>"
    append line_html "[im_gif folder_s]"

    set bind_vars_bread_crum [ns_set copy $bind_vars]
    ns_set put $bind_vars_bread_crum bread_crum_path $bread_crum_path
    ns_set delkey $bind_vars_bread_crum return_url

    append line_html "<a href=\"$current_url_without_vars?[export_url_bind_vars $bind_vars_bread_crum]\">$file_body</a>"


    # ----------------------------------------------------
    # Format the permission columns
    
    set roles_tds ""
    foreach role $roles {
	set role_id [lindex $role 0]
	set p $perms($role_id)

	# Draw the inherited permissions in grey
	set hash_key "$rel_path-$role_id"
	if {[info exists perm_hash($hash_key)]} {
	    append roles_tds "<td align=center>[im_filestorage_render_perms $p]&nbsp;</td>\n"
	} else {
	    append roles_tds "<td align=center><font color=\#888888>[im_filestorage_render_perms $p]&nbsp;</font></td>\n"
	}
    }

    set profiles_tds ""
    foreach profile $profiles {
	set profile_id [lindex $profile 0]
	set p $perms($profile_id)

	# Draw the inherited permissions in grey
	set hash_key "$rel_path-$profile_id"
	if {[info exists perm_hash($hash_key)]} {
	    append profiles_tds "<td align=center>[im_filestorage_render_perms $p]&nbsp;</td>\n"
	} else {
	    append profiles_tds "<td align=center><font color=\#888888>[im_filestorage_render_perms $p]&nbsp;</font></td>\n"
	}
    }

    return "
<tr class=$rowclass>
  <td align=center valign=middle>
    <input type=checkbox name=dir_id.$ctr>
    <input type=hidden name=id_path.$ctr value=\"$rel_path\">    
  </td>
  <td valign=middle>
    $line_html
  </td>
  <td align=center></td>
  <td align=center></td>
  <td align=center></td>
  $roles_tds
  $profiles_tds
</tr>\n"
}


ad_proc im_filestorage_file_row { file_body base_path folder_type rel_path object_id base_path_depth current_depth file ctr rowclass file_type file_size file_modified file_extension user_perms} {

}   {
    # ----------------------------------------------------
    # Determine access permissions

    # Decode the permissions calculated at the main routine
    set view_p [lindex $user_perms 0]
    set read_p [lindex $user_perms 1]
    set write_p [lindex $user_perms 2]
    set admin_p [lindex $user_perms 3]


    # ----------------------------------------------------
    # Render the file

    append component_html "
<tr class=$rowclass>
  <td align=center valign=middle>
    <input type=checkbox name=file_id.$ctr>
    <input type=hidden name=id_path.$ctr value=\"$rel_path\">
  </td>
  <td>" 
    set i 1
    while {$i < $current_depth} {
	append component_html [im_gif empty21]
	incr i
    }
    
    set i $base_path_depth 
    if {$current_depth!=$i} {
	#append component_html "<img src=/intranet/images/adots_T.gif width=21>"
    } 
    
    # Choose a suitable icon
     
    set icon [im_gif exp-unknown]
    switch $file_extension {
	".arj" { set icon [im_gif exp-arj] }
	".book" { set icon [im_gif exp-book] }
	".bz" { set icon [im_gif exp-bz] }
	".bz2" { set icon [im_gif exp-bz2] }
	".chm" { set icon [im_gif exp-chm] }
	".cross" { set icon [im_gif exp-cross] }
	".doc" { set icon [im_gif exp-word] }
	".excel" { set icon [im_gif exp-excel] }
	".gif" { set icon [im_gif exp-gif] }
	".jpg" { set icon [im_gif exp-jpg] }
	".mp3" { set icon [im_gif exp-mp3] }
	".pdf" { set icon [im_gif exp-pdf] }
	".ppt" { set icon [im_gif exp-ppt] }
	".rar" { set icon [im_gif exp-rar] }
	".rtf" { set icon [im_gif exp-word] }
	".sit" { set icon [im_gif exp-sit] }
	".text" { set icon [im_gif exp-text] }
	".tgz" { set icon [im_gif exp-tgz] }
	".txt" { set icon [im_gif exp-text] }
	".wav" { set icon [im_gif exp-wav] }
	".xls" { set icon [im_gif exp-excel] }
	".zip" { set icon [im_gif exp-zip] }
	"" { set icon [im_gif exp-unknown] }
	default {
#	    set ext [string range $file_extension 1 end]
#	    set icon [im_gif "exp-$ext"]
	    set icon [im_gif exp-unknown]
	}
    }

    if {$read_p} {
	append component_html "<A href=\"/intranet/download/$folder_type/$object_id/$rel_path\">$icon</A>"
    } else {
	append component_html "$icon"
    }

    append component_html "
  $file_body
  
  </td>
  <td>$file_size Kb</td>
  <td>$file_modified</td>
  <td colspan=99></td>
</tr>\n"

    return "$component_html"
}



ad_proc im_filestorage_create_folder {folder folder_name} {

} {
     if { [catch {
	 exec mkdir $folder/$folder_name
     } err_msg] } { return $err_msg }   
}


ad_proc im_filestorage_is_directory_empty {folder} {

} {
    set sub_files -1
    if { [catch {
	set sub_files [llength [fileutil::find $folder]]
	set sub_files [string trim $sub_files]
    } err_msg] } { }
    ns_log Notice "im_filestorage_is_directory_empty: sub_files='$sub_files'"
    # sub_files=1: empty dir
    # sub_files>1: some files below
    # sub_files<0: error
    
    if {$sub_files <= 1} { return 1} else { return 0}
}

ad_proc im_filestorage_delete_folder {project_id folder_id folder} {
    
} {

    db_dml delete_folder_status "
	delete from im_fs_folder_status
	where folder_id = :folder_id
    "

    db_dml delete_folder_perms "
	delete from im_fs_folder_perms
	where folder_id = :folder_id
    "

    db_dml delete_folders "
	delete from im_fs_folders
	where folder_id = :folder_id
    "

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



# -------------------------------------------------------
# Permission Procs
# -------------------------------------------------------


ad_proc im_filestorage_perm_add_profile { folder_id perm profile_id p} {
    ns_log Notice "add-perms-2: profile_id=$profile_id, folder_id=$folder_id, perm=$perm, p=$p"

    # Don't add empty permissions...
    if {!$p} { continue }

    # Make sure the perm entry exists
    set exists_p [db_string perms_exists "select count(*) from im_fs_folder_perms where folder_id = :folder_id and profile_id = :profile_id" -default 0]
    if {!$exists_p} {
	    if { [catch {
        	db_dml add_perms  "
insert into im_fs_folder_perms 
(folder_id, profile_id) 
values (:folder_id, :profile_id)
"
        } err_msg] } {  
            ad_return_complaint 1 "<li>[_ intranet-filestorage.Internal_Error]<br><pre>$err_msg</pre>"
        }
    }

    # Update the perm column
    db_dml update_perms "
update 
	im_fs_folder_perms
set 
	${perm}_p = 1
where 
	folder_id = :folder_id
	and profile_id = :profile_id"
}


ad_proc im_filestorage_perm_add_role { folder_id perm role_id p} {
    ns_log Notice "add-perms-2: role_id=$role_id, folder_id=$folder_id, perm=$perm, p=$p"

    # Don't add empty permissions...
    if {!$p} { continue }

    # Make sure the perm entry exists
    set exists_p [db_string perms_exists "select count(*) from im_fs_folder_perms where folder_id = :folder_id and profile_id = :role_id" -default 0]
    if {!$exists_p} {
	    if { [catch {
        	db_dml add_perms  "
insert into im_fs_folder_perms 
(folder_id, profile_id) 
values (:folder_id, :role_id)
"
        } err_msg] } {  
            ad_return_complaint 1 "<li>[_ intranet-filestorage.Internal_Error]<br><pre>$err_msg</pre>"
        }
    }

    # Update the perm column
    db_dml update_perms "
update 
	im_fs_folder_perms
set 
	${perm}_p = 1
where 
	folder_id = :folder_id
	and profile_id = :role_id"
}




