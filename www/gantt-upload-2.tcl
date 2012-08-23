# /packages/intranet-ganttproject/www/gantt-upload-2.tcl
#
# Copyright (C) 2003 - 2009 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

# ---------------------------------------------------------------
# Page Contract
# ---------------------------------------------------------------

ad_page_contract {
    Save/Upload a GanttProject XML structure

    @author frank.bergmann@project-open.com
} {
    { expiry_date "" }
    project_id:integer 
    { security_token "" }
    { upload_gan ""}
    { upload_gif ""}
    { debug_p 0 }
    return_url
}

# ---------------------------------------------------------------
# Defaults & Security
# ---------------------------------------------------------------

set user_id [ad_maybe_redirect_for_registration]
im_project_permissions $user_id $project_id view read write admin
if {!$write} { 
    ad_return_complaint 1 "You don't have permissions to see this page" 
    ad_script_abort
}

if {"" == $upload_gan && "" == $upload_gif} {
    ad_return_complaint 1 "You need to specify a file to upload"
}

set today [db_string today "select to_char(now(), 'YYYY-MM-DD')"]
set page_title [lang::message::lookup "" intranet-ganttproject.Import_Gantt_Tasks "Import Gantt Tasks"]
set context_bar [im_context_bar $page_title]
set reassign_title [lang::message::lookup "" intranet-ganttproject.Delete_Gantt_Tasks "Reassign Resources of Removed Tasks"]
set missing_resources_title [lang::message::lookup "" intranet-ganttproject.Missing_Resources_title "Missing Resources"]
set missing_resources_msg [lang::message::lookup "" intranet-ganttproject.Missing_Resources_msg "The following MS-Project resources could not be found in \]po\[. Please correct the resource names in your MS-Project plan or click on the links below in order to create new resources."]

# Write audit trail
im_project_audit -project_id $project_id -action before_update

db_1row project_info "
	select	project_id as org_project_id,
		project_name as org_project_name
	from	im_projects
	where	project_id = :project_id
"


# -------------------------------------------------------------------
# Get the file from the user.
# -------------------------------------------------------------------

# Get the file from the user.
# number_of_bytes is the upper-limit
set max_n_bytes [ad_parameter -package_id [im_package_filestorage_id] MaxNumberOfBytes "" 0]
set tmp_filename [ns_queryget upload_gan.tmpfile]
ns_log Notice "upload-2: tmp_filename=$tmp_filename"
set file_size [file size $tmp_filename]

# Check for the extension of the uploaded file.
set gantt_file_extension [string tolower [lindex [split $upload_gan "."] end]]

if {"pod" == $gantt_file_extension} {
    ad_return_complaint 1 "
	<b>[lang::message::lookup "" intranet-ganttproject.Invalid_OpenProj_File_Type "Invalid OpenProj File Type"]</b>:<br>
	[lang::message::lookup "" intranet-ganttproject.Invalid_File_Type "
		You are trying to upload an OpenProj 'Serana (.pod)' file, which is not supported.<br>
		Please export your OpenProj file in format <b>'MS-Project 2003 XML (.xml)'</b>.
	"]
    "
    ad_script_abort
}

if {$max_n_bytes && ($file_size > $max_n_bytes) } {
    ad_return_complaint 1 "Your file is larger than the maximum permissible upload size: 
    [util_commify_number $max_n_bytes] bytes"
    return 0
}


# -------------------------------------------------------------------
# Determine the type of the file
# -------------------------------------------------------------------

set file_type [fileutil::fileType $tmp_filename]
if {[lsearch $file_type "ms-office"] >= 0} {
    # We've found a binary MS-Office file, probably MPP

    ad_return_complaint 1 "
	<b>[lang::message::lookup "" intranet-ganttproject.Invalid_XML "Invalid XML Format"]</b>:<br>&nbsp;<br>
	[lang::message::lookup "" intranet-ganttproject.Invalid_MS_Office_Document "
		You have uploaded a Microsoft Office document. This is not supported.<br>
		In MS-Project please choose:<br>
		<b>File -&gt; Save As -&gt; Save as type -&gt; XML Format (*.xml)</b><br>
		in order to save your file in XML format.
	"]
    "
    ad_script_abort

}

# -------------------------------------------------------------------
# Read the file from the HTTP session's TMP file
# -------------------------------------------------------------------

if {[catch {
    set fl [open $tmp_filename]
    fconfigure $fl -encoding "utf-8"
    set binary_content [read $fl]
    close $fl
} err]} {
    ad_return_complaint 1 "Unable to open file $tmp_filename:
    <br><pre>\n$err</pre>"
    return
}

# -------------------------------------------------------------------
# Parse the MS-Project/GanttProject XML
# -------------------------------------------------------------------

set doc ""
if {[catch {set doc [dom parse $binary_content]} err_msg]} {
    ad_return_complaint 1 "
	<b>[lang::message::lookup "" intranet-ganttproject.Invalid_XML "Invalid XML Format"]</b>:<br>
	[lang::message::lookup "" intranet-ganttproject.Invalid_XML_Error "
		Our XML parser has returned an error meaning that that your file is not a valid XML file.<br>
		Here is the original error message:<br>&nbsp;<br>
		<pre>$err_msg</pre>
	"]
    "
    ad_script_abort
}

set root_node [$doc documentElement]
# ad_return_complaint 1 "<pre>[ns_quotehtml [$root_node asXML -indent 8 -escapeNonASCII]]</pre>"


set format "gantt"

if {[string equal [$root_node nodeName] "Project"] 
    && [string equal [$root_node getAttribute "xmlns" ""] \
	"http://schemas.microsoft.com/project"]} {
    set format "ms"
}
ns_log Notice "gantt-upload-2: format=$format"



# -------------------------------------------------------------------
# Save the tasks.
# The task_hash contains a mapping table from gantt_project_ids to task_ids.
# -------------------------------------------------------------------

# First delete the dependencies.
# This is brute force and might be handled better....
set del_dep_task_ids [im_project_subproject_ids -project_id $project_id -type task]
if {$del_dep_task_ids ne ""} {
    db_dml delete_dependencies "delete from im_timesheet_task_dependencies where task_id_one in ([template::util::tcl_to_sql_list $del_dep_task_ids])"
}
if {$debug_p} { ns_write "<h2>Pass 1: Saving Tasks</h2>\n" }
set task_hash_array [list]


if {[catch {
    set task_hash_array [im_gp_save_tasks \
			     -format $format \
			     -create_tasks 1 \
			     -save_dependencies 0 \
			     -task_hash_array $task_hash_array \
			     -debug_p $debug_p \
			     $root_node \
			     $project_id \
			    ]
    array set task_hash $task_hash_array

    if {$debug_p} {
	set debug_html ""
	foreach k [lsort [array names task_hash]] { append debug_html "$k	$task_hash($k)\n" }
	ad_return_complaint 1 "<pre>$debug_html</pre>"
    }

    if {$debug_p} { ns_write "<h2>Pass 2: Saving Dependencies</h2>\n" }
    set task_hash_array [im_gp_save_tasks \
			     -format $format \
			     -create_tasks 0 \
			     -save_dependencies 1 \
			     -task_hash_array $task_hash_array \
			     -debug_p $debug_p \
			     $root_node \
			     $project_id \
			    ]

    ns_log Notice "Pass3: Make sure that tasks with sub-tasks become im_project"
    if {$debug_p} { ns_write "<h2>Pass 3: Make sure that tasks with sub-tasks become im_project</h2>\n" }
    im_gp_save_tasks_fix_structure $project_id

} err_msg]} {
    
    global errorInfo
    set stack_trace $errorInfo
    set latest_version_url "http://www.project-open.org/documentation/developers_cvs_checkout"
    set params [list]
    lappend params [list stacktrace $stack_trace]
    lappend params [list error_type gantt_import]
    lappend params [list error_content $binary_content]
    lappend params [list error_content_filename $upload_gan]
    lappend params [list top_message "
	<h1>Error Parsing Project XML</h1>
	<p>We have found an error parsing your project file.	<br>&nbsp;<br>
	<ol>
	<li>Please make sure you are running the <a href='$latest_version_url'>latest version</a> of &#93;project-open&#91;.<br>
	    There is a good chance that your issue has already been fixed.
	    <br>&nbsp;<br>
	</li>
	<li>Please help us to identify and fix the issue by clicking on the 'Report this Error' button.<br>
	    Please note that this function will transmit your XML file.<br>
	    This is necessary in order to allow the &#93;po&#91; team to reproduce the error.
	    <br>&nbsp;<br>
	</li>
	</ol>
	<br>
    "]
    lappend params [list bottom_message "
	<br>&nbsp;<br>
    "]
    
    set error_html [ad_parse_template -params $params "/packages/acs-tcl/lib/page-error"]

            db_release_unused_handles
            ns_return 200 text/html $error_html
            ad_script_abort

    ad_return_complaint 1 "
	<b>[lang::message::lookup "" intranet-ganttproject.Error_Parsing_XML_Title "Error parsing XML file"]</b>:<br>
	[lang::message::lookup "" intranet-ganttproject.Error_Parsing_XML_Message "
		We have found an error parsing your XML file.
		Here is the original error message:
	"]
	<br>&nbsp;<br>
	<pre>$stack_trace</pre>
	<form
	<input type=submit name='A' value='$report_this_error_l10n'>
	<input type=hidden name=stack_trace value='[ns_quotehtml $stack_trace]'>
	<input type=hidden name=binary_content value='[ns_quotehtml $binary_content]'>
	</form>

    "
    ad_script_abort

}

# -------------------------------------------------------------------
# Description
# -------------------------------------------------------------------

if {[set node [$root_node selectNodes /project/description]] != ""} {
    set description [$node text]
    db_dml project_update "
	update im_projects 
	set description = :description
	where project_id = :project_id
    "
}


# -------------------------------------------------------------------
# Process Calendars
# -------------------------------------------------------------------

if {[set calendars_node [$root_node selectNodes /project/calendars]] == ""} {
    set calendars_node [$root_node selectNodes -namespace { "project" "http://schemas.microsoft.com/project" } "project:Calendars" ]
}

if {$calendars_node != ""} {
    if {$debug_p} {
	ns_write "<h2>Saving Calendars</h2>\n"
	ns_write "<ul>\n"
    }

    set calendar_nodes [$calendars_node childNodes]
    foreach calendar_node $calendar_nodes {
	array unset cal_hash
	array set cal_hash [im_ms_calendar::from_xml $calendar_node]
	set calendar_uid ""
	if {[info exists cal_hash(uid)]} { 
	    set calendar_uid $cal_hash(uid) 
	    set calendar_hash($calendar_uid) [array get cal_hash]
	}
    }
   
    if {$debug_p} { ns_write "</ul>\n" }
}


# -------------------------------------------------------------------
# Save the project Calendar
# -------------------------------------------------------------------

set calendar_uid [db_string cal_uid "select xml_calendaruid from im_gantt_projects where project_id = :project_id" -default ""]

if {$calendar_uid != ""} {
    set cal_list ""
    if {[info exists calendar_hash($calendar_uid)]} {
	array unset cal_hash
	array set cal_hash $calendar_hash($calendar_uid)
	if {[info exists cal_hash(week_days)]} {
	    set cal_list $cal_hash(week_days)
	    db_dml project_update "
		update im_projects 
		set project_calendar = :cal_list
		where project_id = :project_id
            "
	}
    }
}


# -------------------------------------------------------------------
# Process Resources
# -------------------------------------------------------------------

if {[set resource_node [$root_node selectNodes /project/resources]] == ""} {
    set resource_node [$root_node selectNodes -namespace { "project" "http://schemas.microsoft.com/project" } "project:Resources" ]
}

if {$resource_node != ""} {
    if {$debug_p} { ns_write "<h2>Saving Resources</h2>\n" }
    if {$debug_p} { ns_write "<ul>\n" }

    set resource_hash_array [im_gp_save_resources -debug_p $debug_p $resource_node]
    array set resource_hash $resource_hash_array
    if {$debug_p} { ns_write "<li>\n<pre>resource_hash_array=$resource_hash_array</pre>" }
    if {$debug_p} { ns_write "</ul>\n" }

}

# Prepare to write out a useful error message if we didn't find a resource.
set resources_to_assign_p 0
set resource_html ""
foreach rid [array names resource_hash] {
    set v $resource_hash($rid)

    # Skip if we correctly found an (integer) value for the resource
    if {[string is integer $v]} { continue }

    set resources_to_assign_p 1
    append resource_html "$v\n"
}


# -------------------------------------------------------------------
# Process Allocations
# <allocation task-id="12391" resource-id="7" function="Default:0" responsible="true" load="100.0"/>
# -------------------------------------------------------------------

if {[set allocations_node [$root_node selectNodes /project/allocations]] == ""} {
    set allocations_node [$root_node selectNodes -namespace { "project" "http://schemas.microsoft.com/project" } "project:Assignments" ]
}

if {$allocations_node != ""} {
    if {$debug_p} {
	ns_write "<h2>Saving Allocations</h2>\n"
	ns_write "<ul>\n"
    }

    im_gp_save_allocations \
	-debug_p $debug_p \
	-main_project_id $project_id \
	$allocations_node \
	$task_hash_array \
        $resource_hash_array
    
    if {$debug_p} { ns_write "</ul>\n" }
}


# -------------------------------------------------------------------
# Check if we have to delete some tasks
# -------------------------------------------------------------------

# Get all the tasks about the current project
array set db_task_ids {} 
foreach i [im_gp_extract_db_tree $project_id] {
    set db_task_ids($i) 1
}

# we don't want to delete the project (which never is in the xml)
if {[info exists db_task_ids($project_id)]} {
    unset db_task_ids($project_id)
}

# Remove all tasks from the GanttProject .gan file
array set task_hash $task_hash_array

set task_hash_tasks [list 0]
foreach task_hash_key [array names task_hash] {
    set task_hash_value $task_hash($task_hash_key)
    if [info exists db_task_ids($task_hash_value)] {
	unset db_task_ids($task_hash_value)
    }
    lappend task_hash_tasks $task_hash_value
}

# Check if there are tasks to delete...
set tasks_to_delete_p 1
if {"" == [set ids [array names db_task_ids]]} { set tasks_to_delete_p 0}


# -------------------------------------------------------------------
# Check if there were no errors/decisions to take
# -------------------------------------------------------------------

if {!$tasks_to_delete_p && !$resources_to_assign_p} {
    ad_returnredirect $return_url
}


# -------------------------------------------------------------------
# Create task reassignation screen
# -------------------------------------------------------------------

# Create the list of candidate project to which we could reasonably reassign the resources:
set reassign_tasks ""
db_foreach reassign_tasks "
	SELECT	project_id as task_id,
		project_name,
		project_nr,
		tree_level(tree_sortkey)-1 as level
	FROM	im_projects
	WHERE	project_id IN (:project_id, [join $task_hash_tasks ","])
	ORDER BY tree_sortkey
" {
    set indent ""
    for {set i 0} {$i < $level} { incr i} { append indent "&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;" }
    set selected ""
    if {$task_id == $project_id} { set selected "selected" }
    append reassign_tasks "<option value=\"$task_id\" $selected>$indent $project_nr : $project_name</option>"
}

lappend ids 0
db_multirow -extend {project_indent } delete_tasks delete_tasks "
	SELECT	project_id as task_id,
		project_name,
		project_nr,
		tree_level(tree_sortkey) as project_level
	FROM	im_projects
	WHERE 	project_id IN ([join $ids ,])
	ORDER by
	      tree_sortkey
" {
  set space "&nbsp; &nbsp; &nbsp; "
  set project_indent ""
  for {set i 0} {$i < $project_level} {incr i} { append project_indent $space }
}

template::list::create \
    -pass_properties { reassign_tasks } \
    -bulk_actions [list \
	[lang::message::lookup {} intranet-ganttproject.Delete_and_Reassign {Delete Tasks and Reassign Resources}] \
	"/intranet-timesheet2-tasks/task-delete" \
	[lang::message::lookup {} intranet-ganttproject.Delete_selected_tasks {Delete the selected tasks and reassign their resources to the choosen task/project}] \
    ] \
    -bulk_action_export_vars { return_url project_id } \
    -bulk_action_method post \
    -name delete_tasks \
    -key task_id \
    -elements {
        project_nr {
            label "[lang::message::lookup {} intranet-ganttproject.Task_Nr {Task Nr.}]"
        } 
        project_name {
            label "[lang::message::lookup {} intranet-ganttproject.Task_Name {Task Name}]"
	    display_template { <nobr>@delete_tasks.project_indent;noquote@ @delete_tasks.project_name@</nobr> }
        }
	assign_to {
	    label "[lang::message::lookup {} intranet-ganttproject.Reassign_Resources_To {Reassign Resources To}]"
	    display_template { <select name=\"assign_to.@delete_tasks.task_id@\">$reassign_tasks</select> }
	}
    }

# Write audit trail
im_project_audit -project_id $project_id



# ---------------------------------------------------------------------
# Projects Submenu
# ---------------------------------------------------------------------

set bind_vars [ns_set create]
ns_set put $bind_vars project_id $project_id
set parent_menu_id [util_memoize [list db_string parent_menu "select menu_id from im_menus where label='project'" -default 0]]
set menu_label ""

set sub_navbar [im_sub_navbar \
		    -components \
		    -base_url [export_vars -base "/intranet/projects/view" {project_id}] \
		    $parent_menu_id \
		    $bind_vars \
		    "" \
		    "pagedesriptionbar" \
		    $menu_label \
		   ]

