# /packages/intranet-ganttproject/tcl/intranet-ganttproject.tcl
#
# Copyright (C) 2003 - 2009 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

ad_library {
    Integrate ]project-open[ tasks and resource assignations
    with GanttProject, MS-Project and OpenProj.

    This library contains helper procedures for the 
    /intranet-ganttproject/www/gantt-upload-2.tcl
    file. Go there for an overview of functionality.

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

ad_proc -public im_ganttproject_write_subtasks { 
    { -default_start_date "" }
    { -default_duration "" }
    project_id
    doc
    tree_node 
} {
    Write out all the specific subtasks of a task or project.
    This procedure asumes that the current task has already 
    been written out and now deals with the subtasks.
} {
    ns_log Notice "im_ganttproject_write_subtasks: doc=$doc, tree_node=$tree_node, project_id=$project_id, default_start_date=$default_start_date, default_duration=$default_duration"

    # Get sub-tasks in the right sort_order
    # Don't include projects, they are handled differently.
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
                and p.project_type_id = [im_project_type_task]
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


ad_proc -public im_ganttproject_write_task { 
    { -default_start_date "" }
    { -default_duration "" }
    project_id
    doc
    tree_node 
} {
    Write out the information about one specific task and then call
    a recursive routine to write out the stuff below the task.
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
    if {$duration < 0} { set duration 1 }

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

    if {$note != ""} {
	set note_node [$doc createElement "notes"]
	$note_node appendChild [$doc createTextNode $note]
	$project_node appendChild $note_node
    }

    # Add dependencies to predecessors 
    # 9650 == 'Intranet Timesheet Task Dependency Type'
    set dependency_sql "
       SELECT	task_id_one AS other_task_id
       FROM	im_timesheet_task_dependencies 
       WHERE    task_id_two = :task_id AND dependency_type_id=9650
    "
    db_foreach dependency $dependency_sql {
	set depend_node [$doc createElement depend]
	$project_node appendChild $depend_node
	$depend_node setAttribute id $other_task_id
	$depend_node setAttribute type 2
	$depend_node setAttribute difference 0
	$depend_node setAttribute hardness "Strong"
    }

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

    im_ganttproject_write_subtasks \
	-default_start_date $start_date \
	-default_duration $duration \
	$project_id \
	$doc \
	$project_node
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
    # 070502 Fraber: Moved into intranet-core/projects/view.tcl
    return ""

    # Is this a "Consulting Project"?
    set consulting_project_category [parameter::get -package_id [im_package_ganttproject_id] -parameter "GanttProjectType" -default "Consulting Project"]
    if {![im_project_has_type $project_id $consulting_project_category]} {
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
	>[lang::message::lookup "" intranet-ganttproject.Download_Gantt_File "Download GanttProject.gan File"]</A></li>
	<li><A href=\"[export_vars -base "/intranet-ganttproject/openproj-project.xml" {project_id}]\"
	>[lang::message::lookup "" intranet-ganttproject.Download_OpenProj_File "Download OpenProj XML File (beta)"]</A></li>
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
		<td>
			<input type=file name=upload_gan size=10>
		</td>
		<td>
			<input type=submit name=button_gan value='$ok_string'>
		</td>
		</tr>
		</table>
		</form>
	</td></tr>
	</table>
        "
    }
    return $result
}

# ---------------------------------------------------------------
# Get a list of Database task_ids (recursively)
# ---------------------------------------------------------------

ad_proc -public im_gp_extract_db_tree { 
    project_id 
} {
    Returns a list of all task_ids below a top project.
} {
    set task_sql "
	select	child.project_id
	from	im_projects parent,
		im_projects child
	where	parent.project_id = :project_id and
		child.tree_sortkey between parent.tree_sortkey and tree_right(parent.tree_sortkey)
    "
    set result {}
    db_foreach sub_tasks $task_sql {
	lappend result $project_id
    }

    return $result
}

ad_proc -public im_gp_extract_db_tree_old_bad { 
    project_id 
} {
    Returns a list of all task_ids below a top project.
    We can filter out the sub-projects in a different way...
} {
    # We can't use the tree_sortkey query here because we need
    # to deal with sub-projects somewhere in the middel of the
    # structure.

    # We can't leave the DB connection "open" during a recursion,
    # because otherwise the DB connections would get exhausted.
    set task_list [db_list subproject_sql "
	select	project_id
	from	im_projects
	where	parent_id = :project_id
		and project_type_id = [im_project_type_task]
    "]

    set result $project_id
    foreach tid $task_list {
	set result [concat $result [im_gp_extract_db_tree $tid]]
    }
    return $result
}

# ---------------------------------------------------------------
# Procedure: Dependency
# ---------------------------------------------------------------

ad_proc -public im_project_create_dependency { 
    -task_id_one 
    -task_id_two 
    {-depend_type "2"}
    {-difference "0"}
    {-hardness "Strong"}
    -task_hash_array
} {
    Stores a dependency between two tasks into the database
    Depend: <depend id="2" type="2" difference="0" hardness="Strong"/>
    Task: <task id="1" name="Linux Installation" ...>
            <notes>Note for first task</notes>
            <depend id="2" type="2" difference="0" hardness="Strong"/>
            <customproperty taskproperty-id="tpc0" value="nothing..." />
          </task>
} {
    array set task_hash $task_hash_array

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
    
    # ----------------------------------------------------------
    #
    set map_exists_p [db_string map_exists "select count(*) from im_timesheet_task_dependencies where task_id_one = :task_id_one and task_id_two = :task_id_two"]

    if {!$map_exists_p} {
	db_dml insert_dependency "
		insert into im_timesheet_task_dependencies 
		(task_id_one, task_id_two) values (:task_id_one, :task_id_two)
 	"
    }

    set dependency_type_id [db_string dependency_type "select category_id from im_categories where category = :depend_type and category_type = 'Intranet Timesheet Task Dependency Type'" -default "9650"]
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



ad_proc -public im_gp_ms_project_time_to_seconds {
    time 
} {
    Converts a MS-Project time string to seconds.
    Example: PT289H48M0S are 289 hours, 48 minutes and 0 seconds
} {
    set days 0
    if {[regexp {PT([0-9]+)H([0-9]+)M([0-9]+)S} $time all hours minutes seconds]} {
	# MS-Project duration format
	return [expr $seconds + 60*$minutes + 60*60*$hours + 60*60*24*$days]
    }

    if {[regexp {^([0-9]+)$} $time match days]} {
	# GanttProject days
	return [expr $time * 60*60*24]
    }

    error "im_gp_ms_project_time_to_seconds: unable to parse data='$time'"
}


ad_proc -public im_gp_seconds_to_ms_project_time {
    seconds
} {
    Converts a number of seconds into a MS-Project time string.
    Example: PT289H48M0S are 289 hours, 48 minutes and 0 seconds
} {
    set minutes [expr int($seconds / 60.0)]
    set seconds [expr int($seconds - ($minutes * 60))]
    set hours [expr int($minutes / 60.0)]
    set minutes [expr int($minutes - ($hours * 60))]
    
    return "PT${hours}H${minutes}M${seconds}S"
}


ad_proc -public im_gp_save_tasks { 
    {-format "gantt" }
    {-create_tasks 1}
    {-save_dependencies 1}
    {-task_hash_array ""}
    {-debug_p 0}
    root_node 
    super_project_id 
} {
    Parse the XML tree of a MS-Project or OpenProj file and
    start the recursive iteration through all sub-tasks.
    The top task entries should actually be projects, otherwise
    we return an "incorrect structure" error.
} {
    ns_log Notice "im_gp_save_tasks: format=$format"

    # The /project/tasks node of the XML contains the list
    # of projects and sub-projects
    set tasks_node [$root_node selectNodes /project/tasks]

    if {$tasks_node == ""} {
	# Probably MS-Project format.
	# MS-Project stores the actual tasks in /project/tasks/task.

	# Check that we've got the newer version of tDom...
	if {[ns_info version] < 4} {
	    ad_return_complaint 1 "<b>Invalid AOLserver Version</b>:<br>
		Your server is still running on AOLserver version '[ns_info version]'.<br>
		However, you need at least AOLserver version '4.0' to use this functionalitly.
	    "
	    ad_script_abort
	}

	# Make sure there is an im_gantt_projects entry for the super_project
	if {[db_string check_gantt_project_entry "
		select	count(*)=0 
		from	im_gantt_projects 
		where	project_id = :super_project_id
        "]} {
	    db_dml add_gantt_project_entry "insert into im_gantt_projects (project_id,xml_elements) values (:super_project_id, '')"
	}

	# Store the information of the main project in the super_project's im_gantt_project entry.
	# This is not recursive. It's just the information about the main project.
	set xml_elements {}
	foreach child [$root_node childNodes] {
	    set nodeName [$child nodeName]
	    set nodeText [$child text]
	    # ns_log Notice "im_gp_save_tasks: nodeName=$nodeName, nodeText=$nodeText"

	    lappend xml_elements $nodeName

	    switch [string tolower $nodeName] {
		"name" - "title" - "manager" - "calendaruid" - "calendars" - 
		"tasks" - "resources" - "assignments" - "schedulefromstart" {
		    ns_log Notice "im_gp_save_tasks: Ignore project information"
		    # ignore these
		}
		"startdate" {
		    ns_log Notice "im_gp_save_tasks: StartDate: Update im_projects.start_date"
		    db_dml project_start_date "
			UPDATE im_projects SET start_date = :nodeText WHERE project_id = :super_project_id"
		}
		"finishdate" {		    
		    ns_log Notice "im_gp_save_tasks: StartDate: Update im_projects.end_date"
		    db_dml project_end_date "
			UPDATE im_projects SET end_date = :nodeText WHERE project_id = :super_project_id"
		}
		default {
		    im_ganttproject_add_import "im_gantt_project" $nodeName
		    set column_name "xml_$nodeName"
		    db_dml update_import_field "
			UPDATE	im_gantt_projects 
			SET	[plsql_utility::generate_oracle_name $column_name] = :nodeText
			WHERE	project_id = :super_project_id
                    "
		}
	    }	    
	}

	db_dml update_import_field "
		UPDATE	im_gantt_projects 
		SET	xml_elements = :xml_elements
		WHERE	project_id = :super_project_id
        "

	set tasks_node [$root_node selectNodes -namespace { "project" "http://schemas.microsoft.com/project" } "project:Tasks"]
    }
    
    set super_task_node ""
    set sort_order 0

    # Tricky: The task_hash contains the mapping from gantt_task_id => task_id
    # for both tasks and projects. We have to pass this array around between the
    # recursive calls because TCL doesnt have by-value variables
    array set task_hash $task_hash_array

    ns_log Notice "im_gp_save_tasks: Starting to iterate through task nodes"
    set child_nodes [$tasks_node childNodes]
    foreach child $child_nodes {

	if {$debug_p} { ns_write "<li>Child: [$child nodeName]\n<ul>\n" }

	switch [string tolower [$child nodeName]] {
	    "task" {
		set task_hash_array [im_gp_save_tasks2 \
			-create_tasks $create_tasks \
			-save_dependencies $save_dependencies \
			-debug_p $debug_p \
			$child \
			$super_project_id \
			sort_order \
			[array get task_hash] \
		]
		array set task_hash $task_hash_array
	    }
	    default {}
	}

	if {$debug_p} { ns_write "</ul>\n" }
    }
    # Return the mapping hash
    return [array get task_hash]
}


ad_proc -public im_gp_save_tasks2 {
    {-debug_p 0}
    -create_tasks
    -save_dependencies
    task_node 
    super_project_id 
    sort_order_name
    task_hash_array
} {
    Stores a single task into the database.
    Recursively descenses the XML tree with tasks and sub-tasks.
} {
    upvar 1 $sort_order_name sort_order
    incr sort_order
    set my_sort_order $sort_order 

    array set task_hash $task_hash_array
    if {$debug_p} { ns_write "<li>GanttProject($task_node, $super_project_id): '[array get task_hash]'\n" }
    set task_url "/intranet-timesheet2-tasks/new?task_id="

    # Check if the super_project_id was stored in the task_hash
    # This doesn't make sense if this procedure is used recursively...
    #    if {[info exists task_hash(super_project_id)]} {
    #        set super_project_id $task_hash($super_project_id)
    #    }

    # The gantt_project_id as returned from the XML file.
    # This ID does not correspond to a OpenACS object,
    # because GanttProject generates simply consecutive
    # IDs for new objects.
    set gantt_project_id [$task_node getAttribute id ""]

    set task_name		[$task_node getAttribute name ""]
    set start_date		[$task_node getAttribute start ""]
    set duration		[$task_node getAttribute duration ""]
    set percent_completed	[$task_node getAttribute complete "0"]
    set priority		[$task_node getAttribute priority ""]
    set expand_p		[$task_node getAttribute expand ""]
    set end_date		[db_string end_date "select :start_date::date + :duration::integer"]
    set is_null			0
    set milestone_p		""
    set effort_driven_p		"t"
    set effort_driven_type_id	0
    set note			""
    set task_nr			""
    set task_id			0
    set has_subobjects_p	0
    set work			0

    set outline_number		""
    set remaining_duration	""

    set gantt_field_update {}
    set xml_elements {}

    # Microsoft Project uses tags instead of attributes
    foreach taskchild [$task_node childNodes] {
	set nodeName [$taskchild nodeName]
	set nodeText [$taskchild text]
	ns_log Notice "im_gp_save_tasks2: $task_name: nodeName=$nodeName, nodeText=$nodeText"

        switch [string tolower $nodeName] {
            "name"              { set task_name $nodeText }
	    "uid"               { set gantt_project_id $nodeText }
	    "isnull"		{ set is_null $nodeText }
	    "duration"          { set duration $nodeText }
	    "remainingduration" { set remaining_duration $nodeText }
	    "effortdriven"	{ if {"1" == $nodeText} { set effort_driven_p "t" } else { set effort_driven_p "f" } }
	    "start"             { set start_date $nodeText }
	    "finish"            { set end_date $nodeText }
	    "priority"          { set priority $nodeText }
	    "notes"             { set note $nodeText }
	    "outlinenumber"     { set outline_number $nodeText }
	    "percentcomplete"	{ set percent_completed $nodeText }
	    "extendedattribute" {
		set fieldid ""
		set fieldvalue ""
		foreach attrtag [$taskchild childNodes] {
		    switch [$attrtag nodeName] {
			"FieldID" { set fieldid [$attrtag text] }
			"Value"   { set fieldvalue [$attrtag text] }
		    }
		}
		# the following numbers are set by the ms proj format
		# 188744006 : Text20 (used for task_nr)
		# 188744007 : Text21 (used for task_id)
		switch $fieldid {
		    "188744006" { set task_nr $fieldvalue } 
		    "188744007" { set task_id $fieldvalue }
		    default {
			# Any other extended attribute is ignored as specified
			# in the MS-Project integration docu
			continue
		    }
		}
	    }
	    "milestone"		{ if {"1" == $nodeText} { set milestone_p "t" }}
	    "type"	{
		switch $nodeText {
			0	{ set effort_driven_type_id [im_timesheet_task_effort_driven_type_fixed_units] }
			1	{ set effort_driven_type_id [im_timesheet_task_effort_driven_type_fixed_duration] }
			2	{ set effort_driven_type_id [im_timesheet_task_effort_driven_type_fixed_work] }
			default { ad_return_complaint 1 "im_gp_save_tasks2: Unknown task type '$nodeText'" }
		}
	    }
	    "work"		{ set work $nodeText }
	    "predecessorlink" { 
		# this is handled below, because we don't know our task id yet
		continue
	    }
	    "outlinelevel" - "id" - "calendaruid" {
		# ignored 
	    }
	    "customproperty" - "task" - "depend" {
		# these are from ganttproject. see below
		continue 
	    }
	    "timephaseddata" {
                # This is a timephased data assignment directly for a task.
	        # ]po[ can't handle this type of assignments yet.
                continue
            }
	    default {
		# Nothing
	    }
        }

	# Store the original value in the im_gantt_projects table
	# independent if we process the value or not..
	im_ganttproject_add_import "im_gantt_project" $nodeName
	set column_name "[plsql_utility::generate_oracle_name xml_$nodeName]"
	lappend gantt_field_update "$column_name = '[db_quote $nodeText]'"
	lappend xml_elements $nodeName
    }


    # Calculate the effective duration
    if {"" != $duration} {
    	set duration_seconds [im_gp_ms_project_time_to_seconds $duration]
    } else {
	set duration_seconds 0
    }

    # Calculate the effective work
    set work_seconds ""
    if {"" != $work} {
    	set work_seconds [im_gp_ms_project_time_to_seconds $work]
    }

    # If no percent_completed is given explicitely (GanttProject(?))
    # then calculate based on remaining duration. ToDo: Can we delete this piece?
    if {"" == $percent_completed} {
	if {$remaining_duration != "" && $duration != "" && 0 != $duration_seconds} {
	    set remaining_seconds [im_gp_ms_project_time_to_seconds $remaining_duration]
	    if {$duration_seconds == 0} {
		set percent_completed 100.0
	    } else {
		set percent_completed [expr round( 100.0 - (100.0 / $duration_seconds) * $remaining_seconds)]
	    }
	}
    }

    ns_log Notice "im_gp_save_tasks2: $task_name: work=$work"
    ns_log Notice "im_gp_save_tasks2: $task_name: duration=$duration"
    ns_log Notice "im_gp_save_tasks2: $task_name: percent_completed=$percent_completed"


    # -----------------------------------------------------
    # For GanttProject only:
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

    # MS-Project includes "tasks" for empty lines. We ignore these here.
    if {"1" == $is_null} { return }

    # MS-Project creates a task with ID=0 and an empty name,
    # probably to represent the top-project. Let's ignore this one:
    ns_log Notice "im_gp_save_tasks2: Found task with task_name='$task_name', uid='$gantt_project_id'"
    if {"" == $task_name || 0 == $gantt_project_id} { 
	ns_log Notice "im_gp_save_tasks2: Ignoring task with task_name='$task_name', uid=$gantt_project_id"
	return 
    }

    # Normalize task_id from "" to 0
    if {"" == $task_id} { set task_id 0 }


    # Create a reasonable and unique "task_nr" if there wasn't (new task)
    # ToDo: Potentially dangerous - there could be a case with
    # a duplicated gantt_id.
    if {"" == $task_nr} {
	set task_id_zeros $gantt_project_id
	while {[string length $task_id_zeros] < 4} { set task_id_zeros "0$task_id_zeros" }
	set task_nr "task_$task_id_zeros"
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

    if {$debug_p} { ns_write "<li>$task_name...\n<li>task_nr='$task_nr', gantt_id=$gantt_project_id, task_id=$task_id" }



    # -----------------------------------------------------
    # Determine the parent of the project.
    # GanttProject: The super_project_id is determined by the recursive structure of tasks within task elements
    set parent_id $super_project_id
    # Microsoft Project: The WBS field contains the hierarchy. We have to cut off the last element, though
    set outline_list [split $outline_number "\."]
    if {[llength $outline_list] >= 2} {
	# Cut off the last element of the list
	set outline_list [lrange $outline_list 0 end-1]

	# Join the elements together again with a "."
	set outline_task_key "o[join $outline_list "."]"
	
	# Lookup this outline in the task_hash
	if {[info exists task_hash($outline_task_key)]} {
	    set parent_id $task_hash($outline_task_key)
	}
    }

    # -----------------------------------------------------
    # Check if the task has already been mapped to a GanttID
    # in a previous run of this procedure.
    #
    if {[info exists task_hash($gantt_project_id)]} {
	set task_id $task_hash($gantt_project_id)
    }

    # -----------------------------------------------------
    # Check if a task with the task_nr or the task_name exists in the DB
    if {0 == $task_id} {
	set task_id [db_string task_id_from_nr "
		select	task_id 
		from	im_timesheet_tasks_view
		where	project_id = :parent_id and task_nr = :task_nr
        " -default 0]
    }
    if {0 == $task_id} {
	set task_id [db_string task_id_from_name "
		select	task_id 
		from	im_timesheet_tasks_view
		where	project_id = :parent_id and lower(task_name) = lower(:task_name)
        " -default 0]
    }

    # -----------------------------------------------------
    # Check if the task exists in the DB
    set task_exists_p [db_string task_exists_p "
	select	count(*)
	from	im_projects
	where	project_id = :task_id
    "]

    # -----------------------------------------------------
    # Create a new task if:
    # - if task_id=0 (new task created in GanttProject)
    # - if there is a task_id, but it's not in the DB (import from GP)
    set task_created_p 0
    if {0 == $task_id || !$task_exists_p} {

	if {$create_tasks} {
	    if {$debug_p} { ns_write "im_gp_save_tasks2: Creating new task with task_nr='$task_nr'\n" }
	    set task_id [im_exec_dml task_insert "
	    	im_timesheet_task__new (
			null,			-- p_task_id
			'im_timesheet_task',	-- object_type
			now(),			-- creation_date
			null,			-- creation_user
			null,			-- creation_ip
			null,			-- context_id
			:task_nr,		-- task_nr
			:task_name,		-- task_name
			:parent_id,		-- parent_id
			:material_id,		-- material_id
			:cost_center_id,	-- cost_center_id
			:uom_id,		-- uom_id
			:task_type_id,		-- task_type_id
			:task_status_id,	-- task_status_id
			:note			-- note
		)"
	    ]

	    # Remember that we have created the task, so that we can
	    # call the right im_audit action below.
	    set task_created_p 1
	}

    } else {
	if {$create_tasks && $debug_p} { ns_write "Updating existing task\n" }
    }


    # -----------------------------------------------------
    # Write the mapping of gantt_project_id and task_id to the task_hash
    if {0 != $task_id} {
	set task_hash($gantt_project_id) $task_id
	set task_hash(o$outline_number) $task_id
    }

    # -----------------------------------------------------
    # we have the proper task_id now, we can do the dependencies
    foreach taskchild [$task_node childNodes] {
	set nodeName [$taskchild nodeName]
	set nodeText [$taskchild text]
	ns_log Notice "im_gp_save_tasks2: nodeName=$nodeName, nodeText=$nodeText"

        switch $nodeName {
	    "PredecessorLink" {
		if {$save_dependencies} {

		    set linkid ""
		    set linktype ""
		    foreach attrtag [$taskchild childNodes] {
			switch [$attrtag nodeName] {
			    "PredecessorUID" { set linkid [$attrtag text] }
			    # TODO: the next one should obviously not be fixed
			    "Type"           { set linktype 2 }
			}
		    }
		    
		    im_project_create_dependency \
			-task_id_one $task_id \
			-task_id_two $linkid \
			-depend_type $linktype \
			-task_hash_array [array get task_hash]
		}
	    }
        }
    }

    # ---------------------------------------------------------------
    # Process task sub-nodes
    if {$debug_p} { ns_write "<ul>\n" }
    foreach taskchild [$task_node childNodes] {
	ns_log Notice "im_gp_save_tasks2: process subtasks: nodeName=[$taskchild nodeName]"

	switch [$taskchild nodeName] {
	    notes { 
		set note [$taskchild text] 
	    }
	    depend { 
		if {$save_dependencies} {
		    if {$debug_p} { ns_write "<li>Creating dependency relationship\n" }
		    im_project_create_dependency \
			-task_id_one [$taskchild getAttribute id] \
			-task_id_two [$task_node getAttribute id] \
			-depend_type [$taskchild getAttribute type] \
			-difference [$taskchild getAttribute difference] \
			-hardness [$taskchild getAttribute hardness] \
			-task_hash_array [array get task_hash]
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
    if {$debug_p} { ns_write "</ul>\n" }


    # ------------------------------------------------------
    # Save the detailed task information

    # "Milestone" is just a characteristic of the task.
    set milestone_sql ""
    if {[im_column_exists im_projects milestone_p]} {
	set milestone_sql "milestone_p	=	:milestone_p,"
    }

    db_dml project_update "
	update im_projects set
		project_name		= :task_name,
		project_nr		= :task_nr,
		parent_id		= :parent_id,
		start_date		= :start_date,
		end_date		= :end_date,
		$milestone_sql
		note			= :note,
		sort_order		= :my_sort_order,
		percent_completed	= :percent_completed
	where
		project_id = :task_id
    "

    set units_sql "
		planned_units = :duration_seconds / 3600.0,
		billable_units = :duration_seconds / 3600.0
    "
    if {"" != $work_seconds} {
	set units_sql "
		planned_units = :work_seconds / 3600.0,
		billable_units = :work_seconds / 3600.0
	"
    }

    db_dml update_task "
	update im_timesheet_tasks set
		effort_driven_p = :effort_driven_p,
		effort_driven_type_id = :effort_driven_type_id,
		uom_id = [im_uom_hour],
		$units_sql
	where
		task_id = :task_id
    "

    if {[llength $xml_elements]>0} {
	lappend gantt_field_update "xml_elements='[db_quote $xml_elements]'"

	if {[db_string check_gantt_project_entry "
		select	count(*) = 0
		from	im_gantt_projects 
		where	project_id=:task_id
        "]} {
	    db_dml add_gantt_project_entry "
		insert into im_gantt_projects (project_id, xml_elements) values (:task_id, '')
	    "
	}
	
	db_dml gantt_project_update "
	    update im_gantt_projects set
                [join $gantt_field_update ",\n\t\t"]
	    where
		project_id = :task_id
        " 
    }

    # Write audit trail
    if {$task_created_p} { set task_action "after_create" } else { set task_action "after_update" }
    im_project_audit -object_type "im_timesheet_task" -project_id $task_id -status_id $task_status_id -type_id $task_type_id -action $task_action

    return [array get task_hash]
}



ad_proc -public im_gp_save_tasks_fix_structure { 
    {-debug_p 0}
    project_id
} {
    Checks the entire project structure and assures that:
    <ul>
    <li>Tasks with sub-tasks become projects and
    <li>Tasks without sub-tasks are of type im_timesheet_task
    </ul>.
} {
    ns_log Notice "im_gp_save_tasks_fix_structure: project_id=$project_id"
    db_1row project_info "
	select	p.project_type_id,
		o.object_type
	from	im_projects p,
		acs_objects o
	where	p.project_id = :project_id and
		p.project_id = o.object_id
    "

    set sub_tasks [db_list sub_tasks "
	select	project_id
	from	im_projects
	where	parent_id = :project_id
    "]

    ns_log Notice "im_gp_save_tasks_fix_structure: project_id=$project_id, project_type_id=$project_type_id, sub_tasks=$sub_tasks"

    if {[llength $sub_tasks] > 0} {

	# The task has children. Make sure it has the object type "im_project"
	if {[im_project_type_consulting] != $project_type_id} {
	    if {$debug_p} { ns_write "<li>Setting the project_type_id to 'Consulting project' because there are children\n" }
	    db_dml update_import_field "
		UPDATE	im_projects
		SET	project_type_id = [im_project_type_consulting]
		WHERE	project_id = :project_id
            "
	}
	if {"im_project" != $object_type} {
	    if {$debug_p} { ns_write "<li>Setting the object_type to 'im_project' because there are children\n" }
	    db_dml update_otype "
		UPDATE	acs_objects
		SET	object_type = 'im_project'
		WHERE	object_id = :project_id
            "
	}

    } else {

	# The task has no sub-tasks, make it a "im_timeheet_task"
	if {[im_project_type_task] != $project_type_id} {
	    if {$debug_p} { ns_write "<li>Setting the object type to 'im_timesheet_task' because there are NO children\n" }
	    db_dml update_import_field "
		UPDATE	im_projects
		SET	project_type_id = [im_project_type_task]
		WHERE	project_id = :project_id
            "
	}
	if {"im_timesheet_task" != $object_type} {
	    if {$debug_p} { ns_write "<li>Setting the object_type to 'im_project' because there are children\n" }
	    db_dml update_otype "
		UPDATE	acs_objects
		SET	object_type = 'im_timesheet_task'
		WHERE	object_id = :project_id
            "
	}

    }

    # Recursively descend
    foreach tid $sub_tasks {
	im_gp_save_tasks_fix_structure -debug_p $debug_p $tid
    }

}




# ----------------------------------------------------------------------
# Allocations
#
# Assigns users with a percentage to a task.
# Also adds the user to sub-projects if they are assigned to
# sub-tasks of a sub-project.
# ----------------------------------------------------------------------

ad_proc -public im_gp_save_allocations { 
    {-debug_p 0}
    {-main_project_id 0}
    allocations_node
    task_hash_array
    resource_hash_array
} {
    Saves allocation information from GanttProject
} {
    ns_log Notice "im_gp_save_allocations: task_hash_array='$task_hash_array', resource_hash_array='$resource_hash_array'"

    array set task_hash $task_hash_array
    array set resource_hash $resource_hash_array


    # Reset the allocation of the entire project to "NULL percent":
    # We don't want to completely remove users from assigned tasks 
    # (otherwise they might not be able to access their logged 
    # hours anymore), but we want to reset their assignment %
    # to "" (NULL).
    set reset_allocation_sql "
	select	r.rel_id
	from	im_projects parent,
		im_projects child,
		acs_rels r,
		im_biz_object_members bom
	where	parent.project_id = :main_project_id and
		child.tree_sortkey between parent.tree_sortkey and tree_right(parent.tree_sortkey) and
		child.project_id = r.object_id_one and
		r.rel_id = bom.rel_id
    "
    db_foreach reset_allocations $reset_allocation_sql {
	ns_log Notice "im_gp_save_allocations: Reset percentag of rel_id=$rel_id"
	db_dml reset "update im_biz_object_members set percentage = NULL where rel_id = :rel_id"
    }

    foreach child [$allocations_node childNodes] {
	ns_log Notice "im_gp_save_allocations: nodeName=[$child nodeName]"
	switch [string tolower [$child nodeName]] {
	    "allocation" - "assignment" {
		
		# Check for GanttProject specific format
		set task_id [$child getAttribute task-id ""]
		set resource_id [$child getAttribute resource-id ""]
		set function [$child getAttribute function ""]
		set responsible [$child getAttribute responsible ""]
		set percentage [$child getAttribute load "0"]

		# Check for MS-Project specific format
		foreach attr [$child childNodes] {
		    set nodeName [$attr nodeName]
		    set nodeText [$attr text]
    		    switch $nodeName {
			"TaskUID" { set task_id $nodeText }
			"ResourceUID" { set resource_id $nodeText }
			"Units" { set percentage [expr round(100.0*$nodeText)] }
		    }
		}
		ns_log Notice "im_gp_save_allocations: iter: task_uid=$task_id, resource_uid=$resource_id, function=$function, percentage=$percentage, responsible=$responsible"

		if {![info exists task_hash($task_id)]} {
		    ns_log Notice "im_gp_save_allocations: Didn't find task_id='$task_id' in task_hash."
		    if {$debug_p} { ns_write "<li>Allocation: <font color=red>Didn't find task \#$task_id</font>. Skipping... \n" }
		    continue
		}
		set task_id $task_hash($task_id)

		if {![info exists resource_hash($resource_id)]} {
		    ns_log Notice "im_gp_save_allocations: Didn't find resource_id='$resource_id' in resource_hash"
		    if {$debug_p} { ns_write "<li>Allocation: <font color=red>Didn't find user \#$resource_id</font>. Skipping... \n" }
		    continue
		}
		set resource_id $resource_hash($resource_id)
		if {![string is integer $resource_id]} { 
		    ns_log Notice "im_gp_save_allocations: found invalid resource_id='$resource_id'"
		    continue 
		}

		# What is the role of the resource in the project?
		# OpenProj contains this information while MS-Project don't.
		set role_id [im_biz_object_role_full_member]
		if {[string equal "Default:1" $function]} { 
		    # We found an OpenProj project manager.
		    set role_id [im_biz_object_role_project_manager]
		}

		# Add the dude to the task with a given percentage
		ns_log Notice "im_gp_save_allocations: Adding user=$resource_id to task=$task_id in role=$role_id"
		im_biz_object_add_role -percentage $percentage $resource_id $task_id $role_id

		if {$debug_p} {
		    set user_name [im_name_from_user_id $resource_id]
		    set task_name [db_string task_name "select project_name from im_projects where project_id=:task_id" -default $task_id]
		    ns_write "<li>Allocation: $user_name allocated to $task_name with $percentage%\n"
		    ns_log Notice "im_gp_save_allocations: [$child asXML]"
		}

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
    Returns "" if it didn't find the name.
} {
    # Remember just for 30 seconds - that's what it takes to import the MS-Project file...
    return [util_memoize [list im_gp_find_person_for_name_helper -name $name -email $email] 30]
}

ad_proc -public im_gp_find_person_for_name_helper { 
    -name
    -email
} {
    Tries to determine the person_id for a name string.
    Uses all kind of fuzzy matching trying to be intuitive...
    Returns "" if it didn't find the name.
} {
    set person_id ""

    # Check for an exact match with Email
    if {"" == $person_id} {
	set person_id [db_string email_check "
		select	min(party_id)
		from	parties
		where	lower(trim(email)) = lower(trim(:email))
        " -default ""]
    }

    # Check for an exact match with username (abbreviation?)
    if {"" == $person_id} {
	set person_id [db_string email_check "
		select	min(user_id)
		from	users
		where	lower(trim(username)) = lower(trim(:name))
        " -default ""]
    }

    # Check for an exact match with the User Name
    if {"" == $person_id} {
        set person_id [db_string resource_id "
		select	min(person_id)
		from	persons
		where	lower(im_name_from_user_id(person_id)) = :name
        " -default ""]		
    }

    # Check if we get a single match looking for the pieces of the
    # resources name
    # Fraber 110830: Disable, because "Architect" matches "Laura Leadarchitect"
    if {0 && "" == $person_id} {
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
    {-debug_p 0}
    {-project_id 0}
    resources_node
} {
    Saves resource information from GanttProject
} {

    foreach child [$resources_node childNodes] {
	switch [$child nodeName] {
	    "resource" - "Resource" {

		# Check for GanttProject resource format
		set resource_id [$child getAttribute id ""]
		set name [$child getAttribute name ""]
		set function [$child getAttribute function ""]
		set email [$child getAttribute contacts ""]

		# Check of MS-Project resource format
		foreach attr [$child childNodes] {
		    switch [$attr nodeName] {
			"UID" { set resource_id [$attr text] }
			"Name" { set name [$attr text] }
			"EmailAddress" { set email [$attr text] } 
		    }
		}
		
		if {$resource_id != "" && $resource_id != 0} {

		    set name [string tolower [string trim $name]]
		    
		    # Do all kinds of fuzzy searching
		    set person_id [im_gp_find_person_for_name -name $name -email $email]
		    
		    if {"" != $person_id} {
			if {$debug_p} { ns_write "<li>Resource: $name as $function\n" }
			set resource_hash($resource_id) $person_id
			
			# make the resource a member of the project
			im_biz_object_add_role $person_id $project_id [im_biz_object_role_full_member]
			
			set xml_elements {} 
			foreach attr [$child childNodes] {
			    set nodeName [$attr nodeName]
			    set nodeText [$attr text]
			    
			    lappend xml_elements $nodeName

			    switch $nodeName {
				"UID" - "Name" - "EmailAddress" - "ID" - 
				"IsNull" - "MaxUnits" - 
				"PeakUnits" - "OverAllocated" - "CanLevel" -
				"AccrueAt" { }
				default {
				    if {[db_string check_gantt_person_entry "
                                       select count(*)=0 
                                       from im_gantt_persons 
                                       where person_id=:person_id
                                    "]} {
					db_dml add_gantt_person_entry "
                                           insert into im_gantt_persons 
                                           (person_id,xml_elements) values (:person_id,'')"
                                    }

				    im_ganttproject_add_import "im_gantt_person" $nodeName
				    set column_name "[plsql_utility::generate_oracle_name xml_$nodeName]"

				    db_dml update_import_field "UPDATE im_gantt_persons
                                       SET $column_name=:nodeText
                                       WHERE person_id=:person_id
                                       "
				}
			    }
			}

			if {[llength $xml_elements]>0} {
			    db_dml update_import_field "
                               UPDATE im_gantt_persons
                               SET xml_elements=:xml_elements
                               WHERE person_id=:person_id"
			}
		    } else {
			if {$debug_p} { ns_write "<li>Resource: $name - <font color=red>Unknown Resource</font>\n" }
			set name_frags [split $name " "]
			set first_names [join [lrange $name_frags 0 end-1] ""]
			set last_name [join [lrange $name_frags end end] ""]
			set url [export_vars -base "/intranet/users/new" {email first_names last_name {username $name}}]
			set resource_hash($resource_id) "
			<li>[lang::message::lookup "" intranet-ganttproject.Resource_not_found "Resource %name% (%email%) not found"]:
			<br><a href=\"$url\" target=\"_\">
			[lang::message::lookup "" intranet-ganttproject.Create_Resource "Create %name% (%email%)"]:<br>
			</a><br>
		    "
		    }
		    
		    if {$debug_p} { ns_write "<li>Resource: ($resource_id) -&gt; $person_id\n" }
		    
		    ns_log Notice "im_gp_save_resources: [$child asXML]"
		}
	    }
	    default { }
	}
    }

    return [array get resource_hash]
}




# ----------------------------------------------------------------------
# Resource Report
# ----------------------------------------------------------------------

ad_proc -public im_ganttproject_resource_component {
    { -start_date "" }
    { -end_date "" }
    { -top_vars "" }
    { -left_vars "user_name_link project_name_link" }
    { -project_id "" }
    { -user_id "" }
    { -customer_id 0 }
    { -user_name_link_opened "" }
    { -return_url "" }
    { -export_var_list "" }
    { -zoom "" }
    { -auto_open 0 }
    { -max_col 8 }
    { -max_row 20 }
} {
    Gantt Resource "Cube"

    @param start_date Hard start of reporting period. Defaults to start of first project
    @param end_date Hard end of replorting period. Defaults to end of last project
    @param left_vars Variables to show at the left-hand side
    @param project_id Id of project(s) to show. Defaults to all active projects
    @param customer_id Id of customer's projects to show
    @param user_name_link_opened List of users with details shown
} {
    set rowclass(0) "roweven"
    set rowclass(1) "rowodd"
    set sigma "&Sigma;"

    if {0 != $customer_id && "" == $project_id} {
	set project_id [db_list pids "
	select	project_id
	from	im_projects
	where	parent_id is null
		and company_id = :customer_id
        "]
    }
    
    # No projects specified? Show the list of all active projects
    if {"" == $project_id} {
        set project_id [db_list pids "
	select	project_id
	from	im_projects
	where	parent_id is null
		and project_status_id = [im_project_status_open]
        "]
    }

    # ToDo: Highlight the sub-project if we're showning the sub-project
    # of a main-project and open the GanttDiagram at the right place
    if {[llength $project_id] == 1} {
	set parent_id [db_string parent_id "select parent_id from im_projects where project_id = :project_id" -default ""]
	while {"" != $parent_id} {
	    set project_id $parent_id
	    set parent_id [db_string parent_id "select parent_id from im_projects where project_id = :project_id" -default ""]
	}
    }

    # ------------------------------------------------------------
    # Start and End-Dat as min/max of selected projects.
    # Note that the sub-projects might "stick out" before and after
    # the main/parent project.
    
    if {"" == $start_date} {
	set start_date [db_string start_date "
	select
		to_char(min(child.start_date), 'YYYY-MM-DD')
	from
		im_projects parent,
		im_projects child
	where
		parent.project_id in ([join $project_id ", "])
		and parent.parent_id is null
		and child.tree_sortkey
			between parent.tree_sortkey
			and tree_right(parent.tree_sortkey)

        "]
    }

    if {"" == $end_date} {
	set end_date [db_string end_date "
	select
		to_char(max(child.end_date), 'YYYY-MM-DD')
	from
		im_projects parent,
		im_projects child,
		acs_rels r,
		im_biz_object_members m
	where
		r.object_id_one = child.project_id
		and r.rel_id = m.rel_id
		and m.percentage > 0

		and parent.project_id in ([join $project_id ", "])
		and parent.parent_id is null
		and child.tree_sortkey
			between parent.tree_sortkey
			and tree_right(parent.tree_sortkey)
        "]
    }

    # Adaptive behaviour - limit the size of the component to a summary
    # suitable for the left/right columns of a project.
    if {$auto_open | "" == $top_vars} {
	set duration_days [db_string dur "select to_date(:end_date, 'YYYY-MM-DD') - to_date(:start_date, 'YYYY-MM-DD')"]
	if {"" == $duration_days} { set duration_days 0 }
	if {$duration_days < 0} { set duration_days 0 }

	set duration_weeks [expr $duration_days / 7]
	set duration_months [expr $duration_days / 30]
	set duration_quarters [expr $duration_days / 91]

	set days_too_long [expr $duration_days > $max_col]
	set weeks_too_long [expr $duration_weeks > $max_col]
	set months_too_long [expr $duration_months > $max_col]
	set quarters_too_long [expr $duration_quarters > $max_col]

	set top_vars "week_of_year day_of_month"
	if {$days_too_long} { set top_vars "month_of_year week_of_year" }
	if {$weeks_too_long} { set top_vars "quarter_of_year month_of_year" }
	if {$months_too_long} { set top_vars "year quarter_of_year" }
	if {$quarters_too_long} { set top_vars "year quarter_of_year" }
    }

    set top_vars [im_ganttproject_zoom_top_vars -zoom $zoom -top_vars $top_vars]

    # ------------------------------------------------------------
    # Define Dimensions
    
    # The complete set of dimensions - used as the key for
    # the "cell" hash. Subtotals are calculated by dropping on
    # or more of these dimensions
    set dimension_vars [concat $top_vars $left_vars]


    # ------------------------------------------------------------
    # URLs to different parts of the system

    set company_url "/intranet/companies/view?company_id="
    set project_url "/intranet/projects/view?project_id="
    set user_url "/intranet/users/view?user_id="
    set this_url [export_vars -base "/intranet-ganttproject/gantt-resources-cube" {start_date end_date left_vars customer_id} ]
    foreach pid $project_id { append this_url "&project_id=$pid" }


    # ------------------------------------------------------------
    # Conditional SQL Where-Clause
    #
    
    set criteria [list]
    if {"" != $customer_id && 0 != $customer_id} { lappend criteria "parent.company_id = :customer_id" }
    if {"" != $project_id && 0 != $project_id} { lappend criteria "parent.project_id in ([join $project_id ", "])" }
    if {"" != $user_id && 0 != $user_id} { lappend criteria "u.user_id in ([join $user_id ","])" }

    set where_clause [join $criteria " and\n\t\t\t"]
    if { ![empty_string_p $where_clause] } {
	set where_clause " and $where_clause"
    }
    

    # ------------------------------------------------------------
    # Define the report SQL
    #
    
    # Inner - Try to be as selective as possible for the relevant data from the fact table.
    set inner_sql "
		select
		        child.*,
		        u.user_id,
			m.percentage as perc,
			d.d
		from
		        im_projects parent,
		        im_projects child,
		        acs_rels r
		        LEFT OUTER JOIN im_biz_object_members m on (r.rel_id = m.rel_id),
		        users u,
		        ( select im_day_enumerator_weekdays as d
		          from im_day_enumerator_weekdays(
				to_date(:start_date, 'YYYY-MM-DD'), 
				to_date(:end_date, 'YYYY-MM-DD')
			) ) d
		where
		        r.object_id_one = child.project_id
		        and r.object_id_two = u.user_id
		        and parent.project_status_id in ([join [im_sub_categories [im_project_status_open]] ","])
		        and parent.parent_id is null
		        and child.tree_sortkey 
				between parent.tree_sortkey 
				and tree_right(parent.tree_sortkey)
		        and d.d 
				between child.start_date 
				and child.end_date
			$where_clause
    "


    # Aggregate additional/important fields to the fact table.
    set middle_sql "
	select
		h.*,
		trunc(h.perc) as percentage,
		'<a href=${user_url}'||user_id||'>'||im_name_from_id(h.user_id)||'</a>' as user_name_link,
		'<a href=${project_url}'||project_id||'>'||project_name||'</a>' as project_name_link,
		to_char(h.d, 'YYYY') as year,
		'<!--' || to_char(h.d, 'YYYY') || '-->Q' || to_char(h.d, 'Q') as quarter_of_year,
		'<!--' || to_char(h.d, 'YYYY-MM') || '-->' || to_char(h.d, 'Mon') as month_of_year,
		'<!--' || to_char(h.d, 'YYYY-MM') || '-->W' || to_char(h.d, 'IW') as week_of_year,
		'<!--' || to_char(h.d, 'YYYY-MM') || '-->' || to_char(h.d, 'DD') as day_of_month
	from	($inner_sql) h
	where	h.perc is not null
    "

    set outer_sql "
	select
		sum(h.percentage) as percentage,
		[join $dimension_vars ",\n\t"]
	from
		($middle_sql) h
	group by
		[join $dimension_vars ",\n\t"]
    "


    # ------------------------------------------------------------
    # Create upper date dimension


    # Top scale is a list of lists such as {{2006 01} {2006 02} ...}
    # The last element of the list the grand total sum.
    set top_scale_plain [db_list_of_lists top_scale "
	select distinct	[join $top_vars ", "]
	from		($middle_sql) c
	order by	[join $top_vars ", "]
    "]
    lappend top_scale_plain [list $sigma $sigma $sigma $sigma $sigma $sigma]


    # Insert subtotal columns whenever a scale changes
    set top_scale [list]
    set last_item [lindex $top_scale_plain 0]
    foreach scale_item $top_scale_plain {
	
	for {set i [expr [llength $last_item]-2]} {$i >= 0} {set i [expr $i-1]} {
	    set last_var [lindex $last_item $i]
	    set cur_var [lindex $scale_item $i]
	    if {$last_var != $cur_var} {
		set item_sigma [lrange $last_item 0 $i]
		while {[llength $item_sigma] < [llength $last_item]} { lappend item_sigma $sigma }
		lappend top_scale $item_sigma
	    }
	}
	
	lappend top_scale $scale_item
	set last_item $scale_item
    }


    # ------------------------------------------------------------
    # Create a sorted left dimension
    
    # Scale is a list of lists. Example: {{2006 01} {2006 02} ...}
    # The last element is the grand total.
    set left_scale_plain [db_list_of_lists left_scale "
	select distinct	[join $left_vars ", "]
	from		($middle_sql) c
	order by	[join $left_vars ", "]
    "]

    set last_sigma [list]
    foreach t [lindex $left_scale_plain 0] { lappend last_sigma $sigma }
    lappend left_scale_plain $last_sigma


    # Add a "subtotal" (= {$user_id $sigma}) before every new ocurrence of a user_id
    set left_scale [list]
    set last_user_id 0
    foreach scale_item $left_scale_plain {
	set user_id [lindex $scale_item 0]
	if {$last_user_id != $user_id} {
	    lappend left_scale [list $user_id $sigma]
	    set last_user_id $user_id
	}
	lappend left_scale $scale_item
    }

    # ------------------------------------------------------------
    # Display the Table Header
    
    # Determine how many date rows (year, month, day, ...) we've got
    set first_cell [lindex $top_scale 0]
    set top_scale_rows [llength $first_cell]
    set left_scale_size [llength [lindex $left_scale 0]]
    
    set header ""
    for {set row 0} {$row < $top_scale_rows} { incr row } {
	
	append header "<tr class=rowtitle>\n"
	set col_l10n [lang::message::lookup "" "intranet-ganttproject.Dim_[lindex $top_vars $row]" [lindex $top_vars $row]]
	if {0 == $row} {
	    set zoom_in "<a href=[export_vars -base $this_url {top_vars {zoom "in"}}]>[im_gif "magnifier_zoom_in"]</a>\n" 
	    set zoom_out "<a href=[export_vars -base $this_url {top_vars {zoom "out"}}]>[im_gif "magifier_zoom_out"]</a>\n" 
	    set col_l10n "$zoom_in $zoom_out $col_l10n\n" 
	}
	append header "<td class=rowtitle colspan=$left_scale_size align=right>$col_l10n</td>\n"
	
	for {set col 0} {$col <= [expr [llength $top_scale]-1]} { incr col } {
	    
	    set scale_entry [lindex $top_scale $col]
	    set scale_item [lindex $scale_entry $row]
	    
	    # Skip the last line with all sigmas - doesn't sum up...
	    set all_sigmas_p 1
	    foreach e $scale_entry { if {$e != $sigma} { set all_sigmas_p 0 }	}
	    if {$all_sigmas_p} { continue }

	    
	    # Check if the previous item was of the same content
	    set prev_scale_entry [lindex $top_scale [expr $col-1]]
	    set prev_scale_item [lindex $prev_scale_entry $row]

	    # Check for the "sigma" sign. We want to display the sigma
	    # every time (disable the colspan logic)
	    if {$scale_item == $sigma} { 
		append header "\t<td class=rowtitle>$scale_item</td>\n"
		continue
	    }
	    
	    # Prev and current are same => just skip.
	    # The cell was already covered by the previous entry via "colspan"
	    if {$prev_scale_item == $scale_item} { continue }
	    
	    # This is the first entry of a new content.
	    # Look forward to check if we can issue a "colspan" command
	    set colspan 1
	    set next_col [expr $col+1]
	    while {$scale_item == [lindex [lindex $top_scale $next_col] $row]} {
		incr next_col
		incr colspan
	    }
	    append header "\t<td class=rowtitle colspan=$colspan>$scale_item</td>\n"	    
	    
	}
	append header "</tr>\n"
    }
    append html $header

    # ------------------------------------------------------------
    # Execute query and aggregate values into a Hash array

    set cnt_outer 0
    set cnt_inner 0
    db_foreach query $outer_sql {

	# Skip empty percentage entries. Improves performance...
	if {"" == $percentage} { continue }
	
	# Get all possible permutations (N out of M) from the dimension_vars
	set perms [im_report_take_all_ordered_permutations $dimension_vars]
	
	# Add the gantt hours to ALL of the variable permutations.
	# The "full permutation" (all elements of the list) corresponds
	# to the individual cell entries.
	# The "empty permutation" (no variable) corresponds to the
	# gross total of all values.
	# Permutations with less elements correspond to subtotals
	# of the values along the missing dimension. Clear?
	#
	foreach perm $perms {
	    
	    # Calculate the key for this permutation
	    # something like "$year-$month-$customer_id"
	    set key_expr "\$[join $perm "-\$"]"
	    set key [eval "set a \"$key_expr\""]
	    
	    # Sum up the values for the matrix cells
	    set sum 0
	    if {[info exists hash($key)]} { set sum $hash($key) }
	    
	    if {"" == $percentage} { set percentage 0 }
	    set sum [expr $sum + $percentage]
	    set hash($key) $sum
	    
	    incr cnt_inner
	}
	incr cnt_outer
    }

    # Skip component if there are not items to be displayed
    if {0 == $cnt_outer} { return "" }

    # ------------------------------------------------------------
    # Display the table body
    
    set ctr 0
    foreach left_entry $left_scale {
	
	# ------------------------------------------------------------
	# Check open/close logic of user's projects
	set project_pos [lsearch $left_vars "project_name_link"]
	set project_val [lindex $left_entry $project_pos]
	
	set user_pos [lsearch $left_vars "user_name_link"]
	set user_val [lindex $left_entry $user_pos]
	# A bit ugly - extract the user_id from user's URL...
	regexp {user_id\=([0-9]*)} $user_val match user_id
	
	if {$sigma != $project_val} {
	    # The current line is not the summary line (which is always shown).
	    # Start checking the open/close logic
	    
	    if {[lsearch $user_name_link_opened $user_id] < 0} { continue }
	}

	# ------------------------------------------------------------
	# Add empty line before the total sum. The total sum of percentage
	# shows the overall resource assignment and doesn't make much sense...
	set user_pos [lsearch $left_vars "user_name_link"]
	set user_val [lindex $left_entry $user_pos]
	if {$sigma == $user_val} {
	    continue
	}
	
	set class $rowclass([expr $ctr % 2])
	incr ctr
	

	# ------------------------------------------------------------
	# Start the row and show the left_scale values at the left
	append html "<tr class=$class>\n"
	set left_entry_ctr 0
	foreach val $left_entry { 
	    
	    # Special logic: Add +/- in front of User name for drill-in
	    if {"user_name_link" == [lindex $left_vars $left_entry_ctr] & $sigma == $project_val} {
		
		if {[lsearch $user_name_link_opened $user_id] < 0} {
		    set opened $user_name_link_opened
		    lappend opened $user_id
		    set open_url [export_vars -base $this_url {top_vars {user_name_link_opened $opened}}]
		    set val "<a href=$open_url>[im_gif "plus_9"]</a> $val"
		} else {
		    set opened $user_name_link_opened
		    set user_id_pos [lsearch $opened $user_id]
		    set opened [lreplace $opened $user_id_pos $user_id_pos]
		    set close_url [export_vars -base $this_url {top_vars {user_name_link_opened $opened}}]
		    set val "<a href=$close_url>[im_gif "minus_9"]</a> $val"
		} 
	    } else {
		
		# Append a spacer for better looks
		set val "[im_gif "cleardot" "" 0 9 9] $val"
	    }
	    
	    append html "<td><nobr>$val</nobr></td>\n" 
	    incr left_entry_ctr
	}


	# ------------------------------------------------------------
	# Write the left_scale values to their corresponding local 
	# variables so that we can access them easily when calculating
	# the "key".
	for {set i 0} {$i < [llength $left_vars]} {incr i} {
	    set var_name [lindex $left_vars $i]
	    set var_value [lindex $left_entry $i]
	    set $var_name $var_value
	}
	
   
	# ------------------------------------------------------------
	# Start writing out the matrix elements
	foreach top_entry $top_scale {
	    
	    # Skip the last line with all sigmas - doesn't sum up...
	    set all_sigmas_p 1
	    foreach e $top_entry { if {$e != $sigma} { set all_sigmas_p 0 }	}
	    if {$all_sigmas_p} { continue }
	    
	    # Write the top_scale values to their corresponding local 
	    # variables so that we can access them easily for $key
	    for {set i 0} {$i < [llength $top_vars]} {incr i} {
		set var_name [lindex $top_vars $i]
		set var_value [lindex $top_entry $i]
		set $var_name $var_value
	    }
	    
	    # Calculate the key for this permutation
	    # something like "$year-$month-$customer_id"
	    set key_expr_list [list]
	    foreach var_name $dimension_vars {
		set var_value [eval set a "\$$var_name"]
		if {$sigma != $var_value} { lappend key_expr_list $var_name }
	    }
	    set key_expr "\$[join $key_expr_list "-\$"]"
	    set key [eval "set a \"$key_expr\""]
	    
	    set val ""
	    if {[info exists hash($key)]} { set val $hash($key) }
	    
	    # ------------------------------------------------------------
	    # Format the percentage value for percent-arithmetics:
	    # - Sum up percentage values per day
	    # - When showing percentag per week then sum up and divide by 5 (working days)
	    # ToDo: Include vacation calendar and resource availability in
	    # the future.
	    
	    if {"" == $val} { set val 0 }

	    set period "day_of_month"
	    for {set top_idx 0} {$top_idx < [llength $top_vars]} {incr top_idx} {
		set top_var [lindex $top_vars $top_idx]
		set top_value [lindex $top_entry $top_idx]
		if {$sigma != $top_value} { set period $top_var }
	    }

	    set val_day $val
	    set val_week [expr round($val/5)]
	    set val_month [expr round($val/22)]
	    set val_quarter [expr round($val/66)]
	    set val_year [expr round($val/260)]

	    switch $period {
		"day_of_month" { set val $val_day }
		"week_of_year" { set val "$val_week" }
		"month_of_year" { set val "$val_month" }
		"quarter_of_year" { set val "$val_quarter" }
		"year" { set val "$val_year" }
		default { ad_return_complaint 1 "Bad period: $period" }
	    }

	    # ------------------------------------------------------------
	    
	    if {![regexp {[^0-9]} $val match]} {
		set color "\#000000"
		if {$val > 100} { set color "\#800000" }
		if {$val > 150} { set color "\#FF0000" }
	    }

	    if {0 == $val} { 
		set val "" 
	    } else { 
		set val "<font color=$color>$val%</font>\n"
	    }
	    
	    append html "<td>$val</td>\n"
	    
	}
	append html "</tr>\n"
    }


    # ------------------------------------------------------------
    # Show a line to open up an entire level

    # Check whether all user_ids are included in $user_name_link_opened
    set user_ids [lsort -unique [db_list user_ids "select distinct user_id from ($inner_sql) h order by user_id"]]
    set intersect [lsort -unique [set_intersection $user_name_link_opened $user_ids]]

    if {$user_ids == $intersect} {

	# All user_ids already opened - show "-" sign
	append html "<tr class=rowtitle>\n"
	set opened [list]
	set url [export_vars -base $this_url {top_vars {user_name_link_opened $opened}}]
	append html "<td class=rowtitle><a href=$url>[im_gif "minus_9"]</a></td>\n"
	append html "<td class=rowtitle colspan=[expr [llength $top_scale]+3]>&nbsp;</td></tr>\n"

    } else {

	# Not all user_ids are opened - show a "+" sign
	append html "<tr class=rowtitle>\n"
	set opened [lsort -unique [concat $user_name_link_opened $user_ids]]
	set url [export_vars -base $this_url {top_vars {user_name_link_opened $opened}}]
	append html "<td class=rowtitle><a href=$url>[im_gif "plus_9"]</a></td>\n"
	append html "<td class=rowtitle colspan=[expr [llength $top_scale]+3]>&nbsp;</td></tr>\n"

    }

    # ------------------------------------------------------------
    # Close the table

    set html "<table>\n$html\n</table>\n"

    return $html
}






# ----------------------------------------------------------------------
# GanttView to Project(s)
# ----------------------------------------------------------------------

ad_proc -public im_ganttproject_gantt_component {
    { -start_date "" }
    { -end_date "" }
    { -project_id "" }
    { -customer_id 0 }
    { -opened_projects "" }
    { -top_vars "" }
    { -return_url "" }
    { -export_var_list "" }
    { -zoom "" }
    { -auto_open 0 }
    { -max_col 10 }
    { -max_row 20 }
} {
    Gantt View

    @param start_date Hard start of reporting period. Defaults to start of first project
    @param end_date Hard end of replorting period. Defaults to end of last project
    @param project_id Id of project(s) to show. Defaults to all active projects
    @param customer_id Id of customer's projects to show
    @param user_name_link_opened List of users with details shown
} {
    set rowclass(0) "roweven"
    set rowclass(1) "rowodd"
    set sigma "&Sigma;"


    # -----------------------------------------------------------------
    # No project_id specified but customer - get all projects of this customer
    if {0 != $customer_id && "" == $project_id} {
	set project_id [db_list pids "
	select	project_id
	from	im_projects
	where	parent_id is null
		and company_id = :customer_id
		and project_status_id in ([join [im_sub_categories [im_project_status_open]] ","])
        "]
    }
    
    # No projects specified? Show the list of all active projects
    if {"" == $project_id} {
        set project_id [db_list pids "
	select	project_id
	from	im_projects
	where	parent_id is null
		and project_status_id in ([join [im_sub_categories [im_project_status_open]] ","])
        "]
    }

    # ToDo: Highlight the sub-project if we're showing the sub-project
    # of a main-project and open the GanttDiagram at the right place

    # One project specified - check parent_it to make sure we get the
    # top project.
    if {[llength $project_id] == 1} {
	set parent_id [db_string parent_id "
		select parent_id 
		from im_projects 
		where project_id = :project_id
	" -default ""]
	while {"" != $parent_id} {
	    set project_id $parent_id
	    set parent_id [db_string parent_id "
		select parent_id 
		from im_projects 
		where project_id = :project_id
	    " -default ""]
	}
    }

    # ------------------------------------------------------------
    # Start and End-Dat as min/max of selected projects.
    # Note that the sub-projects might "stick out" before and after
    # the main/parent project.
    
    if {"" == $start_date} {
	set start_date [db_string start_date "
	select	to_char(min(child.start_date), 'YYYY-MM-DD')
	from	im_projects parent,
		im_projects child
	where	parent.project_id in ([join $project_id ", "])
		and parent.parent_id is null
		and child.tree_sortkey
			between parent.tree_sortkey
			and tree_right(parent.tree_sortkey)

        "]
    }

    if {"" == $end_date} {
	set end_date [db_string end_date "
	select	to_char(max(child.end_date), 'YYYY-MM-DD')
	from	im_projects parent,
		im_projects child
	where	parent.project_id in ([join $project_id ", "])
		and parent.parent_id is null
		and child.tree_sortkey
			between parent.tree_sortkey
			and tree_right(parent.tree_sortkey)
        "]
    }

    if {"" == $end_date} {
	set end_date [db_string now "select now()::date"]
    } else {
	set end_date [db_string end_date "select to_char(:end_date::date+1, 'YYYY-MM-DD')"]
#	set end_date [ clock scan $end_date ]
#	set end_date [ clock scan {+1 day} -base $end_date ]
#	set end_date [ clock format "$end_date" -format %Y-%m-%d ]
    }

    if {"" == $start_date} {
	set start_date [db_string start_date "
	select	to_char(min(child.start_date), 'YYYY-MM-DD')
	from	im_projects parent,
		im_projects child
	where	parent.project_id in ([join $project_id ", "])
		and parent.parent_id is null
		and child.tree_sortkey
			between parent.tree_sortkey
			and tree_right(parent.tree_sortkey)
        "]
    }

    # -----------------------------------------------------------------
    # Adaptive behaviour - limit the size of the component to a summary
    # suitable for the left/right columns of a project.
    if {$auto_open || "" == $top_vars} {

	set duration_days [db_string dur "
		select to_date(:end_date, 'YYYY-MM-DD') - to_date(:start_date, 'YYYY-MM-DD')
	"]
	if {"" == $duration_days} { set duration_days 0 }
	if {$duration_days < 0} { set duration_days 0 }

	set duration_weeks [expr $duration_days / 7]
	set duration_months [expr $duration_days / 30]
	set duration_quarters [expr $duration_days / 91]
	set duration_years [expr $duration_days / 365]

	set days_too_long [expr $duration_days > $max_col]
	set weeks_too_long [expr $duration_weeks > $max_col]
	set months_too_long [expr $duration_months > $max_col]
	set quarters_too_long [expr $duration_quarters > $max_col]

	set top_vars "week_of_year day_of_month"
	if {$days_too_long} { set top_vars "month_of_year week_of_year" }
	if {$weeks_too_long} { set top_vars "month_of_year" }
	if {$months_too_long} { set top_vars "year quarter_of_year" }
	if {$quarters_too_long} { set top_vars "year quarter_of_year" }
    }

    set top_vars [im_ganttproject_zoom_top_vars -zoom $zoom -top_vars $top_vars]

    # Adaptive behaviour - Open up the first level of projects
    # unless that's more then max_cols
    if {$auto_open} {
	set opened_projects $project_id
    }

    # ------------------------------------------------------------
    # Define Dimensions
    
    set left_vars [list project_id]

    # The complete set of dimensions - used as the key for
    # the "cell" hash. Subtotals are calculated by dropping on
    # or more of these dimensions
    set dimension_vars [concat $top_vars $left_vars]


    # ------------------------------------------------------------
    # URLs to different parts of the system

    set company_url "/intranet/companies/view?company_id="
    set project_url "/intranet/projects/view?project_id="
    set user_url "/intranet/users/view?user_id="
    set this_url [export_vars -base "/intranet-ganttproject/gantt-view-cube" {start_date end_date left_vars customer_id} ]
    foreach pid $project_id { append this_url "&project_id=$pid" }


    # ------------------------------------------------------------
    # Conditional SQL Where-Clause
    #
    
    set criteria [list]
    
    if {"" != $customer_id && 0 != $customer_id} {
	lappend criteria "parent.company_id = :customer_id"
    }
    
    if {"" != $project_id && 0 != $project_id} {
	lappend criteria "parent.project_id in ([join $project_id ", "])"
    }
    
    set where_clause [join $criteria " and\n\t\t\t"]
    if { ![empty_string_p $where_clause] } {
	set where_clause " and $where_clause"
    }
    

    # ------------------------------------------------------------
    # Define the report - SQL, counters, headers and footers 
    #
    
    # Inner - Try to be as selective as possible for the relevant data from the fact table.
    set inner_sql "
		select
			1 as days,
			tree_level(child.tree_sortkey) - tree_level(parent.tree_sortkey) as level,
		        child.project_id,
		        child.project_name,
			child.project_nr,
			child.tree_sortkey,
			d.d
		from
		        im_projects parent,
		        im_projects child,
		        ( select im_day_enumerator as d
		          from im_day_enumerator (
				to_date(:start_date, 'YYYY-MM-DD'), 
				to_date(:end_date, 'YYYY-MM-DD')
			) ) d
		where
			parent.project_status_id in ([join [im_sub_categories [im_project_status_open]] ","])
		        and parent.parent_id is null
		        and child.tree_sortkey between parent.tree_sortkey and tree_right(parent.tree_sortkey)
		        and d.d between child.start_date and child.end_date
			$where_clause
    "

	# Add milestones as milestones

    # Aggregate additional/important fields to the fact table.
    set middle_sql "
	select
		h.*,
		'<a href=${project_url}'||project_id||'>'||project_name||'</a>' as project_name_link,
		to_char(h.d, 'YYYY') as year,
		'<!--' || to_char(h.d, 'YYYY') || '-->Q' || to_char(h.d, 'Q') as quarter_of_year,
		'<!--' || to_char(h.d, 'YYYY-MM') || '-->' || to_char(h.d, 'Mon') as month_of_year,
		'<!--' || to_char(h.d, 'YYYY-MM') || '-->W' || to_char(h.d, 'IW') as week_of_year,
		'<!--' || to_char(h.d, 'YYYY-MM') || '-->' || to_char(h.d, 'DD') as day_of_month
	from	($inner_sql) h
    "

    set outer_sql "
	select
		sum(h.days) as days,
		[join $dimension_vars ",\n\t"]
	from
		($middle_sql) h
	group by
		[join $dimension_vars ",\n\t"]
    "

    # Get the level of task indenting in the project
    set max_level [db_string max_depth "select max(level) from ($middle_sql) c" -default 0]


    # ------------------------------------------------------------
    # Create upper date dimension


    # Top scale is a list of lists such as {{2006 01} {2006 02} ...}
    # The last element of the list the grand total sum.
    set top_scale [db_list_of_lists top_scale "
	select distinct	[join $top_vars ", "]
	from		($middle_sql) c
	order by	[join $top_vars ", "]
    "]

    # ------------------------------------------------------------
    # Display the Table Header
    
    # Determine how many date rows (year, month, day, ...) we've got
    set first_cell [lindex $top_scale 0]
    set top_scale_rows [llength $first_cell]
    set left_scale_size $max_level
    set header_class "rowtitle"
    set header ""
    for {set row 0} {$row < $top_scale_rows} { incr row } {
	
	append header "<tr class=$header_class>\n"
	set col_l10n [lang::message::lookup "" "intranet-ganttproject.Dim_[lindex $top_vars $row]" [lindex $top_vars $row]]
	if {0 == $row} {
	    set zoom_in "<a href=[export_vars -base $this_url {top_vars opened_projects {zoom "in"}}]>[im_gif "magnifier_zoom_in"]</a>\n" 
	    set zoom_out "<a href=[export_vars -base $this_url {top_vars opened_projects {zoom "out"}}]>[im_gif "magifier_zoom_out"]</a>\n" 
	    set col_l10n "$zoom_in $zoom_out $col_l10n\n" 
	}
	append header "<td class=$header_class colspan=[expr $max_level+2] align=right>$col_l10n</td>\n"
	
	for {set col 0} {$col <= [expr [llength $top_scale]-1]} { incr col } {
	    
	    set scale_entry [lindex $top_scale $col]
	    set scale_item [lindex $scale_entry $row]
	    
	    # Skip the last line with all sigmas - doesn't sum up...
	    set all_sigmas_p 1
	    foreach e $scale_entry { if {$e != $sigma} { set all_sigmas_p 0 }	}
	    if {$all_sigmas_p} { continue }

	    
	    # Check if the previous item was of the same content
	    set prev_scale_entry [lindex $top_scale [expr $col-1]]
	    set prev_scale_item [lindex $prev_scale_entry $row]

	    # Check for the "sigma" sign. We want to display the sigma
	    # every time (disable the colspan logic)
	    if {$scale_item == $sigma} { 
		append header "\t<td class=$header_class>$scale_item</td>\n"
		continue
	    }
	    
	    # Prev and current are same => just skip.
	    # The cell was already covered by the previous entry via "colspan"
	    if {$prev_scale_item == $scale_item} { continue }
	    
	    # This is the first entry of a new content.
	    # Look forward to check if we can issue a "colspan" command
	    set colspan 1
	    set next_col [expr $col+1]
	    while {$scale_item == [lindex [lindex $top_scale $next_col] $row]} {
		incr next_col
		incr colspan
	    }
	    append header "\t<td class=$header_class colspan=$colspan>$scale_item</td>\n"	    
	    
	}
	append header "</tr>\n"
    }
    set html $header


    # ------------------------------------------------------------
    # Execute query and aggregate values into a Hash array

    set cnt_outer 0
    set cnt_inner 0
    db_foreach query $outer_sql {

	# Get all possible permutations (N out of M) from the dimension_vars
	set perms [im_report_take_all_ordered_permutations $dimension_vars]
	
	# Add the gantt hours to ALL of the variable permutations.
	# The "full permutation" (all elements of the list) corresponds
	# to the individual cell entries.
	# The "empty permutation" (no variable) corresponds to the
	# gross total of all values.
	# Permutations with less elements correspond to subtotals
	# of the values along the missing dimension. Clear?
	#
	foreach perm $perms {
	    
	    # Calculate the key for this permutation
	    # something like "$year-$month-$customer_id"
	    set key_expr "\$[join $perm "-\$"]"
	    set key [eval "set a \"$key_expr\""]
	    
	    # Sum up the values for the matrix cells
	    set sum 0
	    if {[info exists hash($key)]} { set sum $hash($key) }
	    
	    if {"" == $days} { set days 0 }
	    set sum [expr $sum + $days]
	    set hash($key) $sum
	    
	    incr cnt_inner
	}
	incr cnt_outer
    }

    # Skip component if there are not items to be displayed
    if {0 == $cnt_outer} { return "" }


    # ------------------------------------------------------------
    # Display the table body
    
    set left_sql "
		select
		        child.project_id,
		        child.project_name,
			child.parent_id,
			tree_level(child.tree_sortkey) - tree_level(parent.tree_sortkey) as level
		from
		        im_projects parent,
		        im_projects child
		where
			parent.project_status_id in ([join [im_sub_categories [im_project_status_open]] ","])
		        and parent.parent_id is null
		        and child.tree_sortkey 
				between parent.tree_sortkey 
				and tree_right(parent.tree_sortkey)
			$where_clause
    "
    db_foreach left $left_sql {

	# Store the project_id - project_name relationship
	set project_name_hash($project_id) "<a href=\"$project_url$project_id\">$project_name</a>"

	# Determine the number of children per project
	if {![info exists child_count_hash($project_id)]} { set child_count_hash($project_id) 0 }
	if {![info exists child_count_hash($parent_id)]} { set child_count_hash($parent_id) 0 }
	set child_count $child_count_hash($parent_id)
	set child_count_hash($parent_id) [expr $child_count+1]
	
	# Create a list of projects for each level for fast opening
	set level_list [list]
	if {[info exists level_lists($level)]} { set level_list $level_lists($level) }
	lappend level_list $project_id
	set level_lists($level) $level_list
    }
    
    # ------------------------------------------------------------
    # Display the table body
    
    set left_sql "
	select distinct
		c.project_id,
		c.project_name,	
		c.level,
		c.tree_sortkey
	from
		($middle_sql) c
	order by
		c.tree_sortkey
    "

    set ctr 0
    set project_name_hash($sigma) "sigma"
    set project_name_hash("") "empty"
    set project_name_hash() "empty"
    set project_hierarchy(0) 0

    db_foreach left $left_sql {

	# Store/overwrite the position of project_id in the hierarchy
	set project_hierarchy($level) $project_id
	ns_log Notice "im_ganttproject_gantt_component: project_hierarchy($level) = $project_id"

	# Determine the project-"path" from the top project to the current level
	set project_path [list]
	set open_p 1
	for {set i 0} {$i < $level} {incr i} { 
	    if {[info exists project_hierarchy($i)]} {
		lappend project_path $project_hierarchy($i) 
		if {[lsearch $opened_projects $project_hierarchy($i)] < 0} { set open_p 0 }
	    }
	}
	if {!$open_p} { continue }
	lappend project_path $project_id

	set org_project_id $project_id
	set class $rowclass([expr $ctr % 2])
	incr ctr
	

	# Start the row and show the left_scale values at the left
	append html "<tr class=$class>\n"

	set left_entry_ctr 0
	foreach project_id $project_path { 

	    set project_name $project_name_hash($project_id)
	    set left_entry_ctr_pp [expr $left_entry_ctr+1]
	    set left_entry_ctr_mm [expr $left_entry_ctr-1]

	    set open_p [expr [lsearch $opened_projects $project_id] >= 0]
	    if {$open_p} {
		set opened $opened_projects
		set project_id_pos [lsearch $opened $project_id]
		set opened [lreplace $opened $project_id_pos $project_id_pos]
		set url [export_vars -base $this_url {top_vars {opened_projects $opened}}]
		set gif [im_gif "minus_9"]
	    } else {
		set opened $opened_projects
		lappend opened $project_id
		set url [export_vars -base $this_url {top_vars {opened_projects $opened}}]
		set gif [im_gif "plus_9"]
	    }
	    
	    if {$child_count_hash($project_id) == 0} { 
		set url ""
		set gif [im_gif "cleardot" "" 0 9 9]
	    }
	    
	    set col_val($left_entry_ctr_mm) ""
	    set col_val($left_entry_ctr) "<a href=$url>$gif</a>"
	    set col_val($left_entry_ctr_pp) $project_name
	    
	    set col_span($left_entry_ctr_mm) 1
	    set col_span($left_entry_ctr) 1
	    set col_span($left_entry_ctr_pp) [expr $max_level+1-$left_entry_ctr]

	    incr left_entry_ctr
	}


	set left_entry_ctr 0
	foreach project_id $project_path { 
	    append html "<td colspan=$col_span($left_entry_ctr)><nobr>$col_val($left_entry_ctr)</nobr></td>\n" 
	    incr left_entry_ctr
	}
	append html "<td colspan=$col_span($left_entry_ctr)><nobr>$col_val($left_entry_ctr)</nobr></td>\n" 

	
   
	# ------------------------------------------------------------
	# Start writing out the matrix elements
	set project_id $org_project_id
	set last_days 0
	set last_colspan 0

	for {set top_entry_idx 0} {$top_entry_idx < [llength $top_scale]} {incr top_entry_idx} {

	    # --------------------------------------------------
	    # Get the "next_days" (=days of the next table column)
	    set top_entry_next [lindex $top_scale [expr $top_entry_idx+1]]
	    for {set i 0} {$i < [llength $top_vars]} {incr i} {
		set var_name [lindex $top_vars $i]
		set var_value [lindex $top_entry_next $i]
		set $var_name $var_value
	    }
	    set key_expr_list [list]
	    foreach var_name $dimension_vars {
		set var_value [eval set a "\$$var_name"]
		if {$sigma != $var_value} { lappend key_expr_list $var_name }
	    }
	    set key_expr "\$[join $key_expr_list "-\$"]"
	    set key [eval "set a \"$key_expr\""]
	    set next_days ""
	    if {[info exists hash($key)]} { set next_days $hash($key) }
	    if {"" == $next_days} { set next_days 0 }
	    if {1 < $next_days} { set next_days 1 }




	    # --------------------------------------------------
	    set top_entry [lindex $top_scale $top_entry_idx]
	    
	    # Skip the last line with all sigmas - doesn't sum up...
	    set all_sigmas_p 1
	    foreach e $top_entry { if {$e != $sigma} { set all_sigmas_p 0 } }
	    if {$all_sigmas_p} { continue }

	    # Write the top_scale values to their corresponding local 
	    # variables so that we can access them easily for $key
	    for {set i 0} {$i < [llength $top_vars]} {incr i} {
		set var_name [lindex $top_vars $i]
		set var_value [lindex $top_entry $i]
		set $var_name $var_value
	    }
	    
	    # Calculate the key for this permutation
	    # something like "$year-$month-$customer_id"
	    set key_expr_list [list]
	    foreach var_name $dimension_vars {
		set var_value [eval set a "\$$var_name"]
		if {$sigma != $var_value} { lappend key_expr_list $var_name }
	    }
	    set key_expr "\$[join $key_expr_list "-\$"]"
	    set key [eval "set a \"$key_expr\""]
	    set days ""
	    if {[info exists hash($key)]} { set days $hash($key) }
	    if {"" == $days} { set days 0 }
	    if {1 < $days} { set days 1 }


	    # --------------------------------------------------
	    # Determine how to render the combination of last_days - days $next_days

	    set cell_html ""
	    switch "$last_days$days$next_days" {
		"000" { set cell_html "<td></td>\n" }
		"001" { set cell_html "<td></td>\n" }
		"010" { 
		    set cell_html "<td><img src=\"/intranet-ganttproject/images/gant_bar_single_15.gif\"></td>\n"

		    set cell_html "<td>
			  <table width='100%' border=1 cellspacing=0 cellpadding=0 bordercolor=black bgcolor='\#8CB6CE'>
			    <tr height=11><td></td></tr>
			  </table>
		    </td>\n"

		}
		"011" { 
		    # Start of a new bar.
		    # Do nothing - delayed until "110"
		    set cell_html ""
		    set last_colspan 1
		}
		"100" { set cell_html "<td></td>\n" }
		"101" { set cell_html "<td></td>\n" }
		"110" { 
		    # Write out the entire cell with $last_colspan
		    incr last_colspan
		    set cell_html "
			<td colspan=$last_colspan>
			  <table width='100%' border=1 cellspacing=0 cellpadding=0 bordercolor=black bgcolor='\#8CB6CE'>
			    <tr height=11><td></td></tr>
			  </table>
			</td>\n"
		}
		"111" { incr last_colspan }
	    }

	    append html $cell_html
	    set last_days $days

	    
	}
	append html "</tr>\n"
    }


    # ------------------------------------------------------------
    # Show a line to open up an entire level

    append html "<tr class=$header_class>\n"
    set level_list [list]
    for {set col 0} {$col < $max_level} {incr col} {

	set local_level_list [list]
	if {[info exists level_lists($col)]} { set local_level_list $level_lists($col) }
	set level_list [lsort -unique [concat $level_list $local_level_list]]

	# Check whether all project_ids are included in $level_list
	set intersect [lsort -unique [set_intersection $opened_projects $level_list]]
	if {$level_list == $intersect} {

	    # Everything opened - display a "-" button
	    set opened [set_difference $opened_projects $local_level_list]
	    set url [export_vars -base $this_url {top_vars {opened_projects $opened}}]
	    append html "<td class=$header_class><a href=$url>[im_gif "minus_9"]</a></td>\n"

	} else {

	    set opened [lsort -unique [concat $opened_projects $level_list]]
	    set url [export_vars -base $this_url {top_vars {opened_projects $opened}}]
	    append html "<td class=$header_class><a href=$url>[im_gif "plus_9"]</a></td>\n"

	}


    }
    append html "<td class=$header_class colspan=[expr [llength $top_scale]+2]>&nbsp;</td></tr>\n"

    return "<table>\n$html\n</table>\n"
}


ad_proc -public im_ganttproject_zoom_top_vars {
    -zoom
    -top_vars
} {
    Zooms in/out of top_vars
} {
    if {"in" == $zoom} {
	# check for most detailed variable in top_vars
	if {[lsearch $top_vars "day_of_month"] >= 0} { return {week_of_year day_of_month} }
	if {[lsearch $top_vars "week_of_year"] >= 0} { return {week_of_year day_of_month} }
	if {[lsearch $top_vars "month_of_year"] >= 0} { return {month_of_year week_of_year} }
	if {[lsearch $top_vars "quarter_of_year"] >= 0} { return {quarter_of_year month_of_year} }
	if {[lsearch $top_vars "year"] >= 0} { return {year quarter_of_year} }
    }

    if {"out" == $zoom} {
	# check for most coarse-grain variable in top_vars
	if {[lsearch $top_vars "year"] >= 0} { return {year quarter_of_year} }
	if {[lsearch $top_vars "quarter_of_year"] >= 0} { return {year quarter_of_year} }
	if {[lsearch $top_vars "month_of_year"] >= 0} { return {quarter_of_year month_of_year} }
	if {[lsearch $top_vars "week_of_year"] >= 0} { return {month_of_year week_of_year} }
	if {[lsearch $top_vars "day_of_month"] >= 0} { return {week_of_year day_of_month} }
    }

    return $top_vars
}

ad_proc -public im_ganttproject_add_import {
    object_type
    name
} {
    set column_name "xml_$name"

    # Check if column exists
    set column_exists_p [im_column_exists ${object_type}s $column_name]
    if {$column_exists_p} { return }

    set field_present_command "attribute::exists_p $object_type $column_name"
    set field_present [util_memoize $field_present_command]
    if {!$field_present} {
	attribute::add  -min_n_values 0 -max_n_values 1 "$object_type" "string" $column_name $column_name
	ns_write [ns_cache flush util_memoize $field_present_command]
    }		
}



# ----------------------------------------------------------------------
# Show the extra GanttProject fields in a TaskViewPage
# ---------------------------------------------------------------------

ad_proc -public im_ganttproject_task_info_component {
    task_id
} {
    set html ""

    db_multirow member_list member_list "
        SELECT 
            user_id,
            im_name_from_user_id(user_id) as name,
            percentage,
            im_biz_object_members.rel_id AS rel_id
        from 
            acs_rels,users,im_biz_object_members 
        where 
            object_id_two=user_id and object_id_one=:task_id
            and acs_rels.rel_id=im_biz_object_members.rel_id
            "

    template::list::create \
	-name member_list \
	-key user_id \
	-pass_properties { return_url project_id task_id } \
	-elements {
	    name {
		label "[_ intranet-core.Name]"
		link_url_eval { 
		    [ return "/intranet/users/view?user_id=$user_id" ]
		}
	    }
	    percentage {
		label "[_ intranet-core.Percentage]"
		link_url_eval {
		    [ return "/intranet-timesheet2-tasks/edit-resource?[export_vars -url { return_url rel_id }]" ]
		}
	    }
	} \
	-bulk_actions [list [_ intranet-core.Delete] "/intranet-timesheet2-tasks/delete-resource" "delete resources" ] \
	-bulk_action_export_vars { return_url project_id task_id } \
	-bulk_action_method post
    
    append html [template::list::render -name member_list ]

    return $html
}


