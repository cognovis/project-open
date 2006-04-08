# /packages/intranet-ganttproject/tcl/intranet-ganttproject.tcl
#
# Copyright (C) 2003-2006 Project/Open
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

ad_library {
    Integrate ]project-open[ tasks and resource assignations
    with GanttProject and its data structure

    @author frank.bergmann@project-open.com
}


# ----------------------------------------------------------------------
# 
# ----------------------------------------------------------------------

ad_proc -public im_package_ganttproject_id {} {
    Returns the package id of the intranet-ganttproject module
} {
    return [util_memoize "im_package_ganttproject_id_helper"]
}

ad_proc -private im_package_ganttproject_id_helper {} {
    return [db_string im_package_core_id {
        select package_id from apm_packages
        where package_key = 'intranet-ganttproject'
    } -default 0]
}


# ----------------------------------------------------------------------
# Project Page Component 
# ----------------------------------------------------------------------

ad_proc -public im_ganttproject_component { 
    -project_id
    -current_page_url
    -return_url
    -export_var_list
    -forum_type
} {
    Returns a tumbnail of the project and some links for management.
    Check for "project.thumb.xxx" and a "project.full.xxx"
    files with xxx in (gif, png, jpg)
} {
    set user_id [ad_get_user_id]
    set thumbnail_size [parameter::get -package_id [im_package_ganttproject_id] -parameter "GanttProjectThumbnailSize" -default "360x360"]

    # This is the filename to look for in the toplevel folder
    set ganttproject_preview [parameter::get -package_id [im_package_ganttproject_id] -parameter "GanttProjectPreviewFilename" -default "ganttproject.preview"]

    # get the current users permissions for this project
    im_project_permissions $user_id $project_id view read write admin
    if {!$read} { return "" }

    set download_url "/intranet/download/project/$project_id"
    set project_name [db_string project_name "select project_name from im_projects where project_id = :project_id" -default "unknown"]

    set base_path [im_filestorage_base_path project $project_id]
    set base_paths [split $base_path "/"]
    set base_path_len [llength $base_paths]

    set project_files [im_filestorage_find_files $project_id]
    set thumb ""
    set full ""
    foreach project_file $project_files {
	set file_paths [split $project_file "/"]
	set file_paths_len [llength $file_paths]
	set rel_path_list [lrange $file_paths $base_path_len $file_paths_len]
	set rel_path [join $rel_path_list "/"]
	if {[regexp "^$ganttproject_preview\.$thumbnail_size\....\$" $rel_path match]} { set thumb $rel_path}
	if {[regexp "^$ganttproject_preview\....\$" $rel_path match]} { set full $rel_path}
    }

    # Include the thumbnail in the project's view
    set img ""
    if {"" != $thumb} {
	set img "<img src=\"$download_url/$thumb\" title=\"$project_name\" alt=\"$project_name\" border=0>"
    }

    if {"" != $full && $img != ""} {
	set img "<a href=\"$download_url/$full\">$img</a>\n"
    }

    if {"" == $img} {
	set img [lang::message::lookup "" intranet-ganttproject.No_Gantt_preview_available "No Gantt preview available.<br>Please use GanttProject and 'export' a preview."]
    }

    set help [lang::message::lookup "" intranet-ganttproject.ProjectComponentHelp \
    "GanttProject is a free Gantt chart viewer (http://sourceforge.net/project/ganttproject/)"]

    set result "
	$img<br>
	<li><A href=\"[export_vars -base "/intranet-ganttproject/gantt-project.gan" {project_id}]\"
	>[lang::message::lookup "" intranet-ganttproject.Download_Gantt_File "Download GanttProject.gan File"]</A>[im_gif help $help]
    "

    set ok_string [lang::message::lookup "" intranet-ganttproject.OK "OK"]

    set bread_crum_path ""
    set folder_type "project"
    set object_id $project_id
    set fs_filename "$ganttproject_preview.png"

    if {$admin} {
	append result "
	<table cellspacing=1 cellpadding=1>
	<tr>
	<td>
	  [im_gif "exp-gan" "Upload GanttProject Schedule"]
	  Upload .gan 
        </td>
	<td>
		<form enctype=multipart/form-data method=POST action=/intranet-ganttproject/gantt-upload-2.tcl>
		[export_form_vars return_url project_id]
		<table cellspacing=0 cellpadding=0>
		<tr>
		<td><input type=file name=upload_gan size=10></td>
		<td><input type=submit name=button_gan value='$ok_string'></td>
		</tr>
		</table>
		</form>
	</td></tr>
	<tr>
	<td>
	  [im_gif "exp-gif" "Upload Preview Image"]
	  Upload .png
	</td>
	<td>
		<form enctype=multipart/form-data method=POST action=/intranet-filestorage/upload-2.tcl>
		[export_form_vars project_id return_url folder_type fs_filename object_id thumbnail_size bread_crum_path]
		<table cellspacing=0 cellpadding=0>
		<tr>
		<td><input type=file name=upload_file size=10></td>
		<td><input type=submit name=button_gan value='$ok_string'></td>
		</tr>
		</table>
		</form>
	</td>
	<tr><td colspan=2 class=small>
	    Warning: Don't modify the project structure
	    while the project is being executed. Changes
            may lead to deleted timesheet hours, cost
	    items and others. Please read the manual and/or
	    request more information.<br>
	You need to install <a href='http://prdownloads.sourceforge.net/ganttproject/ganttproject-2.0.exe?download'>GanttProject</a> on your computer.


	</td></tr>
	</table>
        "
    }
    return $result
}


# ----------------------------------------------------------------------
# List Functions
# ----------------------------------------------------------------------

# Flatten
# Convert a tree of integer-list pairs to a flat list
# of integers
#
ad_proc -public im_gp_flatten { tree } {
    Takes an integer-list tree and returns the list of
    integers
} {
    switch [llength $tree] {
	0 { return [list] }
	1 { return [list $tree] }
	default {
	    set l [list]
	    foreach leave $tree {
		set l [concat $l [im_gp_flatten $leave]]
	    }
	    return $l
	}
    }
}


ad_proc -public im_gp_difference { list1 list2 } {
    Calculate the difference, i.e. the list of elements in
    list1 that are not in list2
} {
    set result [list]
    foreach elem $list1 {
	if {-1 == [lsearch $list2 $elem]} {
	    lappend result $elem
	}
    }
    return $result
}


# ---------------------------------------------------------------
# Create Database Task Tree (recursively
#
# Takes the ID of the topmost project (always a project!) and
# returns a tree of project and tasks as leaves.
# ---------------------------------------------------------------

ad_proc -public im_gp_extract_db_tree { project_id} {
    Recursively write out the information about the tasks
    below a specific project.
} {
    # Initialize the list of tasks for this project
    set project_task_list [list]

    # --------- Check the Tasks Just Below Project --------
    set project_tasks_sql "
    	select	t.*
    	from 	im_timesheet_tasks t
    	where	t.project_id = :project_id
    "
    db_foreach project_tasks $project_tasks_sql {
	lappend project_task_list $task_id
    }

    # ------------ Recurse into Sub-Projects -------------
    set subproject_sql "
	select	project_id as sub_project_id
	from	im_projects
	where	parent_id = :project_id
    "
    db_foreach sub_projects $subproject_sql {
	# ToDo: Check infinite loop!!!
	lappend project_task_list [im_gp_extract_db_tree $sub_project_id]
    }

    return [list $project_id $project_task_list]
}






# -------------------------------------------------------------------
# Map the XML tasks (GanttProject) to the DB tasks (]project-open[)
# -------------------------------------------------------------------

ad_proc -public im_gp_extract_xml_tree { 
    root_node 
    task_hash_array
} {
    Solving the mapping issue upfront is going to save us a lot of 
    hassle when it comes to saving the changes to the database.
    And we can - somehow - separate synchronization logic from
    the database commands.
} {
    ns_log Notice "im_gp_extract_xml_tree: Extract XML Tree"
    set xml_tree [list]
    set tasks_node [$root_node selectNodes /project/tasks]
    set super_task_node ""
    foreach child [$tasks_node childNodes] {
	switch [$child nodeName] {
	    "task" {
		set task_id [$child getAttribute id ""]
		if {[info exists task_hash($task_id)]} { set task_id $task_hash($task_id) }

		set object_type [db_string obj_type "
		select object_type from acs_objects 
		where object_id = :task_id" -default "none"]
		
		if {"im_project" != $object_type} {
		    ad_return_complaint 1 "<b>Invalid GanttProject File Structure</b><br>
		GanttProject files need to contain 'Projects' at the top level of
		the file. Instead, we have found the type: '$object_type'"
		    return
		}
		
		# Go through sub-tasks
		foreach task_child [$child childNodes] {
		    if {"task" == [$task_child nodeName]} {
			ns_log Notice "im_gp_extract_xml_tree: [$task_child nodeName]"
			lappend xml_tree [im_gp_extract_xml_tree2 $task_child $task_hash_array]
		    }
		}
	    }
	    default {}
	}
    }
    return $xml_tree
}


ad_proc -public im_gp_extract_xml_tree2 { 
    task_node 
    task_hash_array
} {
    Creates a recursive tree from the information in the XML file
    Return the "tasks" node of the XML data structure as a tree.
     The tree consists of nodes like:
    {gantt_id task_id task_nr children}
} {
    array set task_hash $task_hash_array

    set gantt_id [$task_node getAttribute id ""]
    set task_nr ""
    set task_id "0"
    # Process task sub-nodes
    set task_children [list]
    foreach taskchild [$task_node childNodes] {
	switch [$taskchild nodeName] {
	    notes { }
	    depend { }
	    customproperty {
		# task_nr and task_id are stored as custprops
		set cust_key [$taskchild getAttribute taskproperty-id ""]
		set cust_value [$taskchild getAttribute value ""]
		switch $cust_key {
		    tpc0 { set task_nr $cust_value}
		    tpc1 { set po_task_id $cust_value}
		}
	    }
	    task {
		# Recursive sub-tasks
		lappend task_children [im_gp_extract_xml_tree2 $taskchild $task_hash_array]
	    }
	}
    }

    # Which ID to choose?
    # If there is a mapping from GP to PO ids then trust that mapping
    # Otherwise take the PO id from the XML
    #
    if {[info exists task_hash($gantt_id)]} { 
	set task_id $task_hash($gantt_id) 
    } else {
	set task_id $po_task_id
    }

    # Return single value or list.
    if {0 == [llength $task_children]} {
	return $task_id
    } else {
	return [list $task_id $task_children]
    }
}



# ---------------------------------------------------------------
# Procedure: Dependency
# ---------------------------------------------------------------

ad_proc -public im_ganttproject_create_dependency { depend_node task_node task_hash_array} {
    Stores a dependency between two tasks into the database
    Depend: <depend id="2" type="2" difference="0" hardness="Strong"/>
    Task: <task id="1" name="Linux Installation" ...>
            <notes>Note for first task</notes>
            <depend id="2" type="2" difference="0" hardness="Strong"/>
            <customproperty taskproperty-id="tpc0" value="nothing..." />
          </task>
} {
    array set task_hash $task_hash_array

    set task_id_one [$task_node getAttribute id]
    set task_id_two [$depend_node getAttribute id]
    set depend_type [$depend_node getAttribute type]
    set difference [$depend_node getAttribute difference]
    set hardness [$depend_node getAttribute hardness]

    set org_task_id_one task_id_one
    set org_task_id_two task_id_two

    if {[info exists task_hash($task_id_one)]} { set task_id_one $task_hash($task_id_one) }
    if {[info exists task_hash($task_id_two)]} { set task_id_two $task_hash($task_id_two) }

#    ns_write "<li>im_ganttproject_create_dependency($org_task_id_one =&gt; $task_id_one, $org_task_id_two =&gt; $task_id_two, $depend_type, $hardness)\n"

    # ----------------------------------------------------------
    # Check if the two task_ids exist
    #
    set task_objtype_one [db_string task_objtype_one "select object_type from acs_objects where object_id=:task_id_one" -default "unknown"]
    set task_objtype_two [db_string task_objtype_two "select object_type from acs_objects where object_id=:task_id_two" -default "unknown"]
    
    if {![string equal $task_objtype_one "im_timesheet_task"]} {
	# Search for a task in this project with the "gantt_task_id = task_id_one"
	set task_id_one [db_string recover_task_id_one "
		select	task_id
		from	im_timesheet_tasks
		where	gantt_project_id = :task_id_one
        " -default 0]
    }
    if {!$task_id_one} {ad_return_complaint 1 "task_id_one is 0"} 

    if {![string equal $task_objtype_two "im_timesheet_task"]} {
	# Search for a task in this project with the "gantt_task_id = task_id_two"
	set task_id_two [db_string recover_task_id_two "
		select	task_id
		from	im_timesheet_tasks
		where	gantt_project_id = :task_id_two
        " -default 0]
    }
    if {!$task_id_two} {ad_return_complaint 1 "task_id_two is 0"} 


    # ----------------------------------------------------------
    #
    set map_exists_p [db_string map_exists "select count(*) from im_timesheet_task_dependencies where task_id_one = :task_id_one and task_id_two = :task_id_two"]

    if {!$map_exists_p} {
	db_dml insert_dependency "
		insert into im_timesheet_task_dependencies 
		(task_id_one, task_id_two) values (:task_id_one, :task_id_two)
 	"
    }

    set dependency_type_id [db_string dependency_type "select category_id from im_categories where category = :depend_type and category_type = 'Intranet Timesheet Task Dependency Type'" -default ""]
    set hardness_type_id [db_string dependency_type "select category_id from im_categories where category = :hardness and category_type = 'Intranet Timesheet Task Dependency Hardness Type'" -default ""]

    db_dml update_dependency "
	update im_timesheet_task_dependencies set
		dependency_type_id = :dependency_type_id,
		difference = :difference,
		hardness_type_id = :hardness_type_id
	where	task_id_one = :task_id_one
		and task_id_two = :task_id_two
    "
}




# -------------------------------------------------------------------
# Save Tasks
# -------------------------------------------------------------------

ad_proc -public im_gp_save_tasks { 
    {-enable_save_dependencies 1}
    {-task_hash_array ""}
    root_node 
    super_project_id 
} {
    The top task entries should actually be projects, otherwise
    we return an "incorrect structure" error.
} {
    set tasks_node [$root_node selectNodes /project/tasks]
    set super_task_node ""

    set sort_order 0

    # Tricky: The task_hash contains the mapping from gantt_task_id => task_id
    # for both tasks and projects. We have to pass this array around between the
    # recursive calls because TCL doesnt have by-value variables
    array set task_hash $task_hash_array

    foreach child [$tasks_node childNodes] {
	incr sort_order
	switch [$child nodeName] {
	    "task" {
		set task_id [$child getAttribute id ""]
		set object_type [db_string obj_type "
		select object_type from acs_objects 
		where object_id = :task_id" -default "none"]
		
		if {"im_project" != $object_type} {
		    ad_return_complaint 1 "<b>Invalid GanttProject File Structure</b><br>
		GanttProject files need to contain 'Projects' at the top level of
		the file. Instead, we have found the type: '$object_type'"
		    return
		}
		
		# Go through sub-tasks
		foreach task_child [$child childNodes] {
		    incr sort_order
		    if {"task" == [$task_child nodeName]} {
			set task_hash_array [im_gp_save_tasks2 \
				-enable_save_dependencies $enable_save_dependencies \
				$task_child \
				$super_project_id \
				$sort_order \
				[array get task_hash] \
			]
			array set task_hash $task_hash_array
		    }
		}
		ns_write "</ul>\n"
	    }
	    default {}
	}
    }
    # Return the mapping hash
    return [array get task_hash]
}


ad_proc -public im_gp_save_tasks2 {
    -enable_save_dependencies
    task_node 
    super_project_id 
    sort_order
    task_hash_array
} {
    Stores a single task into the database
} {
    array set task_hash $task_hash_array
#    ns_write "<li>im_gp_save_tasks2($task_node, $super_project_id): '[array get task_hash]'\n"
    set task_url "/intranet-timesheet2-tasks/new?task_id="

    set org_super_project_id $super_project_id
    if {[info exists task_hash($super_project_id)]} {
        set super_project_id $task_hash($super_project_id)
    }

    # The gantt_project_id as returned from the XML file.
    # This ID does not correspond to a OpenACS object,
    # because GanttProject generates simply consecutive
    # IDs for new objects.
    set gantt_project_id [$task_node getAttribute id ""]

    set task_name [$task_node getAttribute name ""]
    set start_date [$task_node getAttribute start ""]
    set duration [$task_node getAttribute duration ""]
    set percent_completed [$task_node getAttribute complete "0"]
    set priority [$task_node getAttribute priority ""]
    set expand_p [$task_node getAttribute expand ""]
    set end_date [db_string end_date "select :start_date::date + :duration::integer"]
    set description ""
    set task_nr ""
    set task_id 0
    set has_subobjects_p 0

    # -----------------------------------------------------
    # Extract the custom properties tpc0 (task_nr) and tpc1 (task_id)
    foreach taskchild [$task_node childNodes] {
        switch [$taskchild nodeName] {
            task { set has_subobjects_p 1 }
            customproperty {
                # task_nr and task_id are stored as custprops
                set cust_key [$taskchild getAttribute taskproperty-id ""]
                set cust_value [$taskchild getAttribute value ""]
                switch $cust_key {
                    tpc0 { set task_nr $cust_value}
                    tpc1 { set task_id $cust_value}
                }
            }
        }
    }

    # Normalize task_id from "" to 0
    if {"" == $task_id} { set task_id 0 }

    # Create a reasonable and unique "task_nr" if there wasn't (new task)
    # ToDo: Potentially dangerous - there could be a case with
    # a duplicated gantt_id.
    if {"" == $task_nr} {
	set task_nr "task_$gantt_project_id"
    }


    # -----------------------------------------------------
    # Set some default variables for new tasks
    set task_status_id [im_timesheet_task_status_active]
    set task_type_id [im_timesheet_task_type_standard]
    set uom_id [im_uom_hour]
    set cost_center_id ""
    set material_id [im_material_default_material_id]

    ns_write "<li>GanttProject: $task_nr: '$gantt_project_id' =&gt; task_id='$task_id'"


    # Set some default variables for new project
    db_1row super_project_info "
	select	company_id,
		project_type_id,
		project_status_id
	from
		im_projects
	where
		project_id = :super_project_id
    "

    # -----------------------------------------------------
    # Check if we had mapped this task from a GanttProject ID
    # to a different task_id or project_id in the database
    #
    if {[info exists task_hash($gantt_project_id)]} {
	set task_id $task_hash($gantt_project_id)
    }

    set task_otype [db_string task_otype "
	select	object_type
	from	acs_objects o
	where	o.object_id=:task_id
    " -default ""]


    # -----------------------------------------------------
    # Check if the task already exists in the database
    set task_exists_p [db_string tasks_exists "
	select	count(*)
	from	im_timesheet_tasks
	where	task_id = :task_id
    "]
    # Give it a second chance to deal with the case that there is
    # already a task with the same task_nr in the same project (same level!):
    set existing_task_id [db_string task_id_from_nr "
	select	task_id 
	from	im_timesheet_tasks 
	where	project_id = :super_project_id and task_nr = :task_nr
    " -default 0]

    if {0 != $existing_task_id} {
	set task_hash($gantt_project_id) $existing_task_id
	set task_id $existing_task_id
	set task_exists_p 1
    }


    # -----------------------------------------------------
    # Check if the project already exists in the database
    set project_exists_p [db_string project_exists "
        select  count(*)
        from    im_projects
        where   project_id = :task_id
    "]
    # Give it a second chance to deal with the case that there is
    # a project with the same project_nr in the same project (same level!):
    set existing_project_id [db_string project_id_from_nr "
        select	project_id
        from	im_projects
        where	parent_id = :super_project_id 
		and project_nr = :task_nr
    " -default 0]

    if {0 != $existing_project_id} {
	set task_hash($gantt_project_id) $existing_project_id
#        ns_write "<li>im_gp_save_tasks2: found project_id=$existing_project_id for project with project_nr=$task_nr"
        set task_id $existing_project_id
        set project_exists_p 1
    }

    # Check the cases that the "task" has changed its type
    set cur_object_type [db_string cur_object_type "select object_type from acs_objects where object_id = :task_id" -default ""]



    # -----------------------------------------------------
    # Now we have several cases:


    # Inconsistency handling:
    # Both a project and a task exist.
    # This error occurs during "demotion"
    #
    if {$task_exists_p && $project_exists_p} {
#	ad_return_complaint 1 "Not implemented yet: Both a project and a task exist with task_nr=$task_nr."
    }


    # -----------------------------------------------------
    # Needs to be "demoted" from project to task
    if {!$has_subobjects_p && [string equal "im_project" $cur_object_type]} {

	ns_write "<li>im_gp_save_tasks2: <font color=red>Demote</font> project# $task_id to a task"
	# Nuke the old project
	im_project_nuke $task_id

	# Set the task_id to 0 to initiate project creation further below.
	set task_id 0
    }


    # -----------------------------------------------------
    # Needs to be "promoted" from task to project
    if {$has_subobjects_p && [string equal "im_timesheet_task" $cur_object_type]} {

	ns_write "<li>im_gp_save_tasks2: <font color=red>Promote</font> task# $task_id to a project"
	# Nuke the old task
	im_timesheet_task_nuke $task_id

	# Set the task_id to 0 to initiate project creation further below.
	set task_id 0
    }


    # -----------------------------------------------------
    # Needs to be "demoted" from project to task
    #
    # Does a project really needs to be "demoted" to a task?
    # It seems that a project can accomodate the same data as
    # task. This way we don't have to delete all the forums,
    # permission, Filestorage, ...
    #
    if {0 && !$has_subobjects_p && [string equal "im_project" $cur_object_type]} {
	ad_return_complaint 1 "Demotion from Project to Task is not implemented yet:<br>
	<li>Name = $task_name
	<li>Nr = $task_nr
	<li>ID = $task_id
        "
	return [array get task_hash]
    }


    # Create a new task if:
    # - if the task_id is "" or 0 (new task created in GanttProject)
    # - if there is a task_id, but it's not in the DB (import from GP)
    if {!$has_subobjects_p} {
	if {0 == $task_id || !$task_exists_p} {

	    ns_write "<li>im_gp_save_tasks2: Creating new task: nr=$task_nr, name=$task_name, super_project=$super_project_id"

	    set task_id [im_exec_dml task_insert "
	    	im_timesheet_task__new (
			null,			-- p_task_id
			'im_timesheet_task',	-- object_type
			now(),			-- creation_date
			null,			-- creation_user
			null,			-- creation_ip
			null,			-- context_id
			:task_nr,
			:task_name,
			:super_project_id,
			:material_id,
			:cost_center_id,
			:uom_id,
			:task_type_id,
			:task_status_id,
			:description
		)"
	    ]
	    ns_write "<li>im_gp_save_tasks2: Creating new task: gp_id=$gantt_project_id =&gt; $task_id"
	    set task_hash($gantt_project_id) $task_id
	}
    }

    # Create a new project if:
    # - if the task_id is "" or 0 (new task created in GanttProject)
    # - if there is a task_id, but it's not in the DB (import from GP)


    # No task_id means that it's a new item:
    #
    if {$has_subobjects_p} {
	if {0 == $task_id || !$project_exists_p} {

	    ns_write "<li>Creating new project nr=$task_nr"
	    set task_id [project::new \
                -project_name           $task_name \
                -project_nr             $task_nr \
                -project_path           $task_nr \
                -company_id             $company_id \
                -parent_id              $super_project_id \
                -project_type_id        $project_type_id \
                -project_status_id      $project_status_id \
	    ]

	    set task_id [db_string project_id "select project_id from im_projects where project_nr = :task_nr"]
	    set task_hash($gantt_project_id) $task_id
	    set parent_id [db_string parent_id "select parent_id from im_projects where project_nr = :task_nr"]
	    if {$parent_id != $super_project_id} {
		ad_return_complaint 1 "Error with project_nr:<br>
		The project with project_nr='$task_nr' already exists outside of the 
		scope of this project. We can't overwrite this project.
		Please either rename this project or modify the task_nr in GanttProject."
	    }

	}
    }



    # Now the object type is OK. We still need to update the object:
    set object_type [db_string cur_object_type "
	select object_type 
	from acs_objects 
	where object_id = :task_id
    " -default ""]

    if {[string equal "im_project" $object_type]} {
	db_dml project_update "
	    update im_projects set
		project_name	= :task_name,
		project_nr	= :task_nr,
		parent_id	= :super_project_id,
		start_date	= :start_date,
		end_date	= :end_date,
		note		= :description,
		sort_order	= :sort_order
	    where
		project_id = :task_id
        "
    }

    if {[string equal "im_timesheet_task" $object_type]} {
	db_dml task_update "
	update im_timesheet_tasks set
		task_name	= :task_name,
		task_nr		= :task_nr,
		project_id	= :super_project_id,
		description	= :description,
		gantt_project_id= :gantt_project_id,
		start_date	= :start_date,
		end_date	= :end_date,
		sort_order	= :sort_order
	where
		task_id = :task_id"
    }


    if {"" != $super_project_id} {

	set task_id_one $super_project_id
	set task_id_two $task_id

	set map_exists_p [db_string map_exists "select count(*) from im_timesheet_task_dependencies where task_id_one = :task_id_one and task_id_two = :task_id_two"]
	if {!$map_exists_p} {
	    db_dml insert_super_dependency "
                insert into im_timesheet_task_dependencies (
			task_id_one, task_id_two, dependency_type_id
		) values (
			:task_id_one, :task_id_two, 9652
		)
            "
	}
    }

    # ---------------------------------------------------------------
    # Process task sub-nodes
    ns_write "<ul>\n"
    foreach taskchild [$task_node childNodes] {
	incr sort_order
	switch [$taskchild nodeName] {
	    notes { set description [$taskchild nodeValue]}
	    depend { 
		if {$enable_save_dependencies} {
		    im_ganttproject_create_dependency $taskchild $task_node [array get task_hash]
		}
	    }
	    customproperty { }
	    task {
		# Recursive sub-tasks
		set task_hash_array [im_gp_save_tasks2 -enable_save_dependencies $enable_save_dependencies $taskchild $gantt_project_id [expr 10 * $sort_order] [array get task_hash]]
		array set task_hash $task_hash_array
	    }
	}
    }
    ns_write "</ul>\n"

    return [array get task_hash]
}


# ----------------------------------------------------------------------
# Allocations
#
# Assigns users with a percentage to a task.
# Also addes the user to sub-projects if they are assigned to
# sub-tasks of a sub-project.
# ----------------------------------------------------------------------

ad_proc -public im_gp_save_allocations { 
    allocations_node
    task_hash_array
    resource_hash_array
} {
    Saves allocation information from GanttProject
} {
    array set task_hash $task_hash_array
    array set resource_hash $resource_hash_array

    foreach child [$allocations_node childNodes] {
	switch [$child nodeName] {
	    "allocation" {
		set task_id [$child getAttribute task-id ""]
		if {[info exists task_hash($task_id)]} { set task_id $task_hash($task_id) }
		set resource_id [$child getAttribute resource-id ""]
		if {[info exists resource_hash($resource_id)]} { set resource_id $resource_hash($resource_id) }

		set function [$child getAttribute function ""]
		set responsible [$child getAttribute responsible ""]
		set percentage [$child getAttribute load "0"]
		
		set allocation_exists_p [db_0or1row allocation_info "
			select	* 
			from	im_timesheet_task_allocations 
			where	task_id = :task_id 
				and user_id = :resource_id
	        "]

		set role_id [im_biz_object_role_full_member]
		if {[string equal "Default:1" $function]} { 
		    set role_id [im_biz_object_role_project_manager]
		}
		if {!$allocation_exists_p} { 
		    db_dml insert_allocation "
			insert into im_timesheet_task_allocations 
			(task_id, user_id) values (:task_id, :resource_id)"
		}
		db_dml update_allocation "
			update im_timesheet_task_allocations set
				role_id	= [im_biz_object_role_full_member],
				percentage = :percentage
			where	task_id = :task_id
				and user_id = :resource_id
	        "
		ns_write "<li>Allocation: User# $resource_id allocated to task# $task_id with $percentage%\n"
		ns_log Notice "im_gp_save_allocations: [$child asXML]"

		set project_id [db_string project_id "select project_id from im_timesheet_tasks where task_id = :task_id"]

		# Check if the resource is already member of the project
		im_biz_object_add_role $resource_id $project_id [im_biz_object_role_full_member]
	    }
	    default { }
	}
    }
}




# ----------------------------------------------------------------------
# Resources
#
# <resource id="8869" name="Andrew Accounting" function="Default:0" contacts="aac@asdf.com... />
#
# ----------------------------------------------------------------------

ad_proc -public im_gp_save_resources { 
    resources_node
} {
    Saves resource information from GanttProject
} {

    foreach child [$resources_node childNodes] {
	switch [$child nodeName] {
	    "resource" {
		set resource_id [$child getAttribute id ""]
		set name [$child getAttribute name ""]
		set function [$child getAttribute function ""]

		set person_id [db_string resource_id "
			select	person_id
			from	persons
			where	lower(trim(:name)) = lower(trim(first_names || ' ' || last_name))
		" -default 0]

		if {0 != $person_id} {
		    ns_write "<li>Resource: $name ($resource_id) -&gt; $person_id as $function\n"
		    set resource_hash($resource_id) $person_id
		} else {
		    ns_write "<li>Unknown Resource: $name ($resource_id)\n"
		}

		ns_log Notice "im_gp_save_resources: [$child asXML]"
	    }
	    default { }
	}
    }

    return [array get resource_hash]
}


