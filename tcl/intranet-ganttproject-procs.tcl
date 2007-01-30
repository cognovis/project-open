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
# Recursively write out task structure
# ----------------------------------------------------------------------

ad_proc -public im_ganttproject_write_task { 
    { -default_start_date "" }
    { -default_duration "" }
    project_id
    doc
    tree_node 
} {
    Recursively write out the information about projects and tasks
    below a specific project
} {
    ns_log Notice "im_ganttproject_write_task: doc=$doc, tree_node=$tree_node, project_id=$project_id, default_start_date=$default_start_date, default_duration=$default_duration"
    if { [security::secure_conn_p] } {
	set base_url "https://[ad_host][ad_port]"
    } else {
	set base_url "http://[ad_host][ad_port]"
    }
    set task_view_url "$base_url/intranet-timesheet2-tasks/new?task_id="
    set project_view_url "$base_url/intranet/projects/view?project_id="

    # ------------ Get everything about the project -------------
    if {![db_0or1row project_info "
        select  p.*,
		t.*,
		o.object_type,
                p.start_date::date as start_date,
                p.end_date::date as end_date,
		p.end_date::date - p.start_date::date as duration,
                c.company_name
        from    im_projects p
		LEFT OUTER JOIN im_timesheet_tasks t on (p.project_id = t.task_id),
		acs_objects o,
                im_companies c
        where   p.project_id = :project_id
		and p.project_id = o.object_id
                and p.company_id = c.company_id
    "]} {
	ad_return_complaint 1 [lang::message::lookup "" intranet-ganttproject.Project_Not_Found "Didn't find project \#%project_id%"]
	return
    }

    # Make sure some important variables are set to default values
    # because empty values are not accepted by GanttProject:
    #
    if {"" == $percent_completed} { set percent_completed "0" }
    if {"" == $priority} { set priority "1" }
    if {"" == $start_date} { set start_date $default_start_date }
    if {"" == $start_date} { set start_date [db_string today "select to_char(now(), 'YYYY-MM-DD')"] }
    if {"" == $duration} { set duration $default_duration }
    if {"" == $duration} { set duration 1 }
    if {"0" == $duration} { set duration 1 }

    set project_node [$doc createElement task]
    $tree_node appendChild $project_node
    $project_node setAttribute id $project_id
    $project_node setAttribute name $project_name
    $project_node setAttribute meeting "false"
    $project_node setAttribute start $start_date
    $project_node setAttribute duration $duration
    $project_node setAttribute complete $percent_completed
    $project_node setAttribute priority $priority
    $project_node setAttribute webLink "$project_view_url$project_id"
    $project_node setAttribute expand "true"

    # Custom Property "task_nr"
    # <customproperty taskproperty-id="tpc0" value="linux_install" />
    set task_nr_node [$doc createElement customproperty]
    $project_node appendChild $task_nr_node
    $task_nr_node setAttribute taskproperty-id tpc0
    $task_nr_node setAttribute value $project_nr
   
    # Custom Property "task_id"
    # <customproperty taskproperty-id="tpc1" value="12345" />
    set task_id_node [$doc createElement customproperty]
    $project_node appendChild $task_id_node
    $task_id_node setAttribute taskproperty-id tpc1
    $task_id_node setAttribute value $project_id

    if {$note != ""} {
	set note_node [$doc createElement "notes"]
	$note_node appendChild [$doc createTextNode $note]
	$project_node appendChild $note_node
    }


    # Add dependencies to predecessors 
    # 9650 == 'Intranet Timesheet Task Dependency Type'
    set dependency_sql "
	    	select	* 
		from	im_timesheet_task_dependencies 
	    	where	task_id_one = :task_id AND dependency_type_id=9650
    "
    db_foreach dependency $dependency_sql {
	set depend_node [$doc createElement depend]
	$project_node appendChild $depend_node
	$depend_node setAttribute id $task_id_two
	$depend_node setAttribute type 2
	$depend_node setAttribute difference 0
	$depend_node setAttribute hardness "Strong"
    }

    im_ganttproject_write_subtasks \
	-default_start_date $start_date \
	-default_duration $duration \
	$project_id \
	$doc \
	$project_node
}

ad_proc -public im_ganttproject_write_subtasks { 
    { -default_start_date "" }
    { -default_duration "" }
    project_id
    doc
    tree_node 
} {
    
    # ------------ Get Sub-Projects and Tasks -------------
    # ... in the right sort_order

    set object_list_list [db_list_of_lists sorted_query "
	select
		p.project_id as object_id,
		o.object_type,
		p.sort_order
	from	
		im_projects p,
		acs_objects o
	where
		p.project_id = o.object_id
		and parent_id = :project_id
                and p.project_status_id not in (
			[im_project_status_deleted], 
			[im_project_status_closed]
		)
	order by sort_order
    "]

    foreach object_record $object_list_list {
	set object_id [lindex $object_record 0]

	im_ganttproject_write_task \
	    -default_start_date $default_start_date \
	    -default_duration $default_duration \
	    $object_id \
	    $doc \
	    $tree_node
    }
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
    # Is this a "Consulting Project"?
    if {![im_project_has_type $project_id "Consulting Project"]} {
        return ""
    }

    set user_id [ad_get_user_id]
    set thumbnail_size [parameter::get -package_id [im_package_ganttproject_id] -parameter "GanttProjectThumbnailSize" -default "360x360"]
    ns_log Notice "im_ganttproject_component: thumbnail_size=$thumbnail_size"

    # This is the filename to look for in the toplevel folder
    set ganttproject_preview [parameter::get -package_id [im_package_ganttproject_id] -parameter "GanttProjectPreviewFilename" -default "ganttproject.preview"]
    ns_log Notice "im_ganttproject_component: ganttproject_preview=$ganttproject_preview"

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
    ns_log Notice "im_ganttproject_component: thumb=$thumb, full=$full"

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
		<form enctype=multipart/form-data method=POST action=/intranet-ganttproject/gantt-upload-2>
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

# ---------------------------------------------------------------
# Get a list of Database task_ids (recursively)
# ---------------------------------------------------------------

ad_proc -public im_gp_extract_db_tree { project_id } {

    # I do the sql query here first and then the recursion, otherwise there
    # will be to many open db connections
    set task_list [list]
    set subproject_sql "
	select	project_id as sub_project_id
	from	im_projects
	where	parent_id = :project_id
    "
    db_foreach sub_projects $subproject_sql {
	# ToDo: Check infinite loop!!!
	lappend task_list $sub_project_id
    }
    
    set r $project_id
    foreach i $task_list {
	set r "$r [im_gp_extract_db_tree $i]"
    }
    return $r
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
		from	im_timesheet_tasks_view
		where	gantt_project_id = :task_id_one
        " -default 0]
    }
    if {!$task_id_one} {ad_return_complaint 1 "task_id_one is 0"} 

    if {![string equal $task_objtype_two "im_timesheet_task"]} {
	# Search for a task in this project with the "gantt_task_id = task_id_two"
	set task_id_two [db_string recover_task_id_two "
		select	task_id
		from	im_timesheet_tasks_view
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
    {-create_tasks 1}
    {-save_dependencies 1}
    {-task_hash_array ""}
    {-debug 0}
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
	if {$debug} { ns_write "<li>Child: [$child nodeName]\n<ul>\n" }

	switch [$child nodeName] {
	    "task" {
		set task_hash_array [im_gp_save_tasks2 \
			-create_tasks $create_tasks \
			-save_dependencies $save_dependencies \
			-debug $debug \
			$child \
			$super_project_id \
			sort_order \
			[array get task_hash] \
		]
		array set task_hash $task_hash_array
	    }
	    default {}
	}

	if {$debug} { ns_write "</ul>\n" }
    }
    # Return the mapping hash
    return [array get task_hash]
}


ad_proc -public im_gp_save_tasks2 {
    {-debug 0}
    -create_tasks
    -save_dependencies
    task_node 
    super_project_id 
    sort_order_name
    task_hash_array
} {
    Stores a single task into the database
} {
    upvar 1 $sort_order_name sort_order
    incr sort_order
    set my_sort_order $sort_order 

    array set task_hash $task_hash_array
    if {$debug} { ns_write "<li>GanttProject($task_node, $super_project_id): '[array get task_hash]'\n" }
    set task_url "/intranet-timesheet2-tasks/new?task_id="

    # What does this mean???
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
    set note ""
    set task_nr ""
    set task_id 0
    set has_subobjects_p 0

    # -----------------------------------------------------
    # Extract the custom properties tpc0 (task_nr) and tpc1 (task_id)
    # for tasks that have been exported out of ]project-open[
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
    set task_status_id [im_project_status_open]
    set task_type_id [im_project_type_task]
    set uom_id [im_uom_hour]
    set cost_center_id ""
    set material_id [im_material_default_material_id]

    # Get the customer of the super-project
    db_1row super_project_info "
	select	company_id
	from	im_projects
	where	project_id = :super_project_id
    "

    if {$debug} { ns_write "<li>$task_name...\n<li>task_nr='$task_nr', gantt_id=$gantt_project_id, task_id=$task_id" }


    # -----------------------------------------------------
    # Check if we had mapped this task from a GanttProject ID
    # to a different task_id or project_id in the database
    #
    if {[info exists task_hash($gantt_project_id)]} {
	set task_id $task_hash($gantt_project_id)
    }

    # -----------------------------------------------------
    # Check if the task already exists in the database
    set task_exists_p [db_string tasks_exists "
	select	count(*)
	from	im_timesheet_tasks_view
	where	task_id = :task_id
    "]

    # -----------------------------------------------------
    # Give it a second chance to deal with the case that there is
    # already a task with the same task_nr in the same project (same level!):
    set existing_task_id [db_string task_id_from_nr "
	select	task_id 
	from	im_timesheet_tasks_view
	where	project_id = :super_project_id and task_nr = :task_nr
    " -default 0]

    if {0 != $existing_task_id} {
	set task_hash($gantt_project_id) $existing_task_id
	set task_id $existing_task_id
	set task_exists_p 1
        if {$debug} { ns_write "<li>GanttProject: found task_id=$existing_task_id for task with task_nr=$task_nr" }
    }


    # -----------------------------------------------------
    # Create a new task if:
    # - if task_id=0 (new task created in GanttProject)
    # - if there is a task_id, but it's not in the DB (import from GP)
    if {0 == $task_id || !$task_exists_p} {

	if {$create_tasks} {
	    if {$debug} { ns_write "Creating new task with task_nr='$task_nr'\n" }
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
			:note
		)"
	    ]
	    set task_hash($gantt_project_id) $task_id
	}

    } else {
	if {$create_tasks && $debug} { ns_write "Updating existing task\n" }
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
    if {$debug} { ns_write "<ul>\n" }
    foreach taskchild [$task_node childNodes] {
	switch [$taskchild nodeName] {
	    notes { 
		set note [$taskchild text] 
	    }
	    depend { 
		if {$save_dependencies} {

		    if {$debug} { ns_write "<li>Creating dependency relationship\n" }
		    im_ganttproject_create_dependency $taskchild $task_node [array get task_hash]

		}
	    }
	    customproperty { }
	    task {
		# Recursive sub-tasks
		set task_hash_array [im_gp_save_tasks2 \
			-create_tasks $create_tasks \
			-save_dependencies $save_dependencies \
			$taskchild \
			$gantt_project_id \
			sort_order \
			[array get task_hash] \
		]
		array set task_hash $task_hash_array
	    }
	}
    }
    if {$debug} { ns_write "</ul>\n" }

    db_dml project_update "
	    update im_projects set
		project_name	= :task_name,
		project_nr	= :task_nr,
		parent_id	= :super_project_id,
		start_date	= :start_date,
		end_date	= :end_date,
		note		= :note,
		sort_order	= :my_sort_order,
		percent_completed = :percent_completed
	    where
		project_id = :task_id
    "

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
    {-debug 0}
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
		if {![info exists task_hash($task_id)]} {
		    if {$debug} { ns_write "<li>Allocation: <font color=red>Didn't find task \#$task_id</font>. Skipping... \n" }
		    continue
		}
		set task_id $task_hash($task_id)

		set resource_id [$child getAttribute resource-id ""]
		if {![info exists resource_hash($resource_id)]} {
		    if {$debug} { ns_write "<li>Allocation: <font color=red>Didn't find user \#$resource_id</font>. Skipping... \n" }
		    continue
		}
		set resource_id $resource_hash($resource_id)

		set function [$child getAttribute function ""]
		set responsible [$child getAttribute responsible ""]
		set percentage [$child getAttribute load "0"]
		
		set role_id [im_biz_object_role_full_member]
		if {[string equal "Default:1" $function]} { 
		    set role_id [im_biz_object_role_project_manager]
		}

		# Add the dude to the task with a given percentage
		im_biz_object_add_role -percentage $percentage $resource_id $task_id $role_id

		set user_name [im_name_from_user_id $resource_id]
		set task_name [db_string task_name "select project_name from im_projects where project_id=:task_id" -default $task_id]
		if {$debug} { ns_write "<li>Allocation: $user_name allocated to $task_name with $percentage%\n" }
		ns_log Notice "im_gp_save_allocations: [$child asXML]"

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


ad_proc -public im_gp_find_person_for_name { 
    -name
    -email
} {
    Tries to determine the person_id for a name string.
    Uses all kind of fuzzy matching trying to be intuitive...
} {
    # Check for an exact match with the User Name
    set person_id [db_string resource_id "
			select	person_id
			from	persons
			where	:name = lower(im_name_from_user_id(person_id))
    " -default 0]
		
    # Check for an exact match with Email
    if {0 == $person_id} {
		    set person_id [db_string email_check "
			select	party_id
			from	parties
			where	lower(trim(email)) = lower(trim(:email))
    " -default 0]
    }

    # Check if we get a single match looking for the pieces of the
    # resources name
    if {0 == $person_id} {
	set name_pieces [split $name " "]
	# Initialize result to the list of all persons
	set result [db_list all_resources "
				select	person_id
				from	persons
	"]

	# Iterate through all parts of the name and 
	#make sure we find all pieces of name in the name
	foreach piece $name_pieces {
	    if {[string length $piece] > 1} {
		set person_ids [db_list resource_id "
					select	person_id
					from	persons
					where	position(:piece in lower(im_name_from_user_id(person_id))) > 0
		"]
		set result [set_intersection $result $person_ids]
	    }
	}

	# Assign the guy only if there is exactly one match.
	if {1 == [llength $result]} {
	    set person_id [lindex $result 0]
	}
    }
    
    return $person_id
}


ad_proc -public im_gp_save_resources { 
    {-debug 0}
    {-project_id 0}
    resources_node
} {
    Saves resource information from GanttProject
} {

    foreach child [$resources_node childNodes] {
	switch [$child nodeName] {
	    "resource" {
		set resource_id [$child getAttribute id ""]
		set name [string tolower [string trim [$child getAttribute name ""]]]
		set function [$child getAttribute function ""]
		set email [$child getAttribute contacts ""]

		# Do all kinds of fuzzy searching
		set person_id [im_gp_find_person_for_name -name $name -email $email]

		if {0 != $person_id} {
		    if {$debug} { ns_write "<li>Resource: $name as $function\n" }
		    set resource_hash($resource_id) $person_id

		    # make the resource a member of the project
		    im_biz_object_add_role $person_id $project_id [im_biz_object_role_full_member]

		} else {
		    if {$debug} { ns_write "<li>Resource: $name - <font color=red>Unknown Resource</font>\n" }
		}

		if {$debug} { ns_write "<li>Resource: ($resource_id) -&gt; $person_id\n" }

		ns_log Notice "im_gp_save_resources: [$child asXML]"
	    }
	    default { }
	}
    }

    return [array get resource_hash]
}


