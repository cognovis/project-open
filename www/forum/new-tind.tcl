# /packages/intranet-forum//www/new-tind.tcl

ad_page_contract {
    Create a new Task, Incident, News or Discussion (TIND)
    @author fraber@project-open.com
    @param group_id: Project or Client to refer to
    @topic_type: "news", "disussion", "incident" or "task"
    @param display_style: 
	topic		= full topic (subject+message), no subtopics
	thread		= complete tree of subjects
	topic_thread	= full topic plus subtopics subjects
	full		= topic+all subtopics
    @creation-date 9/2003
} {
    {topic_id:integer 0}
    {group_id:integer 0}
    {display_style "all"}
    {submit ""}
    {subject ""}
    {message ""}
    {topic_type_id 0}
    {asignee_id 0}
    {return_url ""}
} 

# ------------------------------------------------------------------
# Procedures
# ------------------------------------------------------------------


ad_proc -public im_forum_scope_select {select_name user_id {default ""} } {
    Returns a formatted HTML "scope" select, according to user
    permissions.
    If the scope is limited to a the PM, just display a HTML
    text instead of a SelectBox.
} {
    set public_selected ""
    set group_selected ""
    set staff_selected ""
    set client_selected ""
    set non_client_selected ""
    set pm_selected ""
    switch $default {
	public { set public_selected "selected" }
	group { set group_selected "selected" }
	staff { set staff_selected "selected" }
	client { set client_selected "selected" }
	non_client { set non_client_selected "selected" }
	pm { set pm_selected "selected" }
    }

    set option_list [list]
    if {[im_permission $user_id create_topic_scope_public]} { lappend option_list "<option value=public $public_selected>Public (everybody in the system)</option>\n" }
    if {[im_permission $user_id create_topic_scope_group]} { lappend option_list "<option value=group $group_selected>Project (all project members)</option>" }
    if {[im_permission $user_id create_topic_scope_staff]} { lappend option_list "<option value=staff $staff_selected>Staff (employees only)</option>" }
    if {[im_permission $user_id create_topic_scope_client]} { lappend option_list "<option value=client $client_selected>Clients and PM only</option>" }
    if {[im_permission $user_id create_topic_scope_non_client]} { lappend option_list "<option value=not_client $non_client_selected>Provider (project members without clients)</option>" }
    if {[im_permission $user_id create_topic_scope_pm]} { lappend option_list "<option value=pm $pm_selected>Project Manager</option>" }

    if {1 == [llength $option_list]} {
	return "ProjectManager<input type=hidden name=scope value=\"pm\">"
    } else {
	return "<select name=scope>[join $option_list " "]</select>"
    }
}

ad_proc -public im_forum_scope_html {scope } {
    Returns a formatted HTML "scope"
} {
    set html ""
    switch $scope {
	public { set html "Public (everybody in the system)"}
	group {set html "All group members"}
	staff { set html "Staff group members only"}
	client { set html "Client group members and the PM only"}
	non_client { set html "Staff and Freelance group members"}
	pm { set html "Project Manager only"}
	default { set html "undefined"}
    }
    return $html
}




# ------------------------------------------------------------------
# Parameters & Default
# ------------------------------------------------------------------

set current_user_id [ad_maybe_redirect_for_registration]
set group_name ""

set todays_date [lindex [split [ns_localsqltimestamp] " "] 0]
set bgcolor(0) " class=roweven"
set bgcolor(1) " class=rowodd"

# Only incidents and tasks have priority, status, asignees and 
# due_dates
#
set task_or_incident_p 0
if {$topic_type_id == 1102 || $topic_type_id == 1104} {
    set task_or_incident_p 1
}

# Return to this page for edit actions, if not being called
# from another page.
if {"" == $return_url} {
    set return_url [im_url_with_query]
}

# ------------------------------------------------------------------
# New Message or Reply
# ------------------------------------------------------------------

set asignee_id ""
set asignee_name ""
set action_type "undefined"
set topic_status_id ""
set done 0

# -------------- We are creating a new message -----------------

if {!$done && $topic_id == 0} {
    set action_type "new_message"

    # We can create new messages either within a project (group_id != 0)
    # or at the HomePage or the ForumPage (group_id == 0).
    # Let's get the group_name if group_id != 0:
    if {$group_id > 0} {
	set group_name [db_string group_name "select project_name from im_projects where project_id=:group_id"]
#set group_name [db_string group_name "select group_name from user_groups where group_id=:group_id"]
    }

    # doubleclick protection: get the topic ID right now.
    set topic_id [db_nextval "im_forum_topics_seq"]
    set parent_id ""
    set read_p "f"
    set scope "pm"
    set folder_id 0
    set receive_updates "major"
    set topic_status_id [im_topic_status_id_open]
    set topic_status "Open"
    set owner_id $current_user_id
    set asignee_id ""
    set due_date $todays_date
    set topic_type [db_string topic_sql "select category from categories where category_id=:topic_type_id" -default ""]

    set submit_action "New $topic_type"
    set page_title "New $topic_type"
    set context_bar [ad_context_bar [list /intranet/forum/ Forum] $page_title]
    set done 1
}

# -------------- We are creating a reply message -----------------

if {!$done && $topic_id != 0 && [string equal $submit "Reply"]} {
    set action_type "reply_message"
    # doubleclick protection: get the topic ID right now.
    set topic_id [db_nextval "im_forum_topics_seq"]

    # Save the topic_id!
    set parent_id $topic_id

    # Get some information about the parent topic:
    set topic_sql "
select
	t.group_id as group_id,
	ug.project_name,
	t.scope
from
	im_forum_topics t,
	im_projects ug
where
	topic_id=:parent_id
	and ug.project_id=t.group_id"

    db_1row get_topic $topic_sql

    # doubleclick protection: get the topic ID right now.
    set owner_id $current_user_id
    set asignee_id ""
    set read_p "f"
    set folder_id 0
    set receive_updates "major"
    set topic_id [db_nextval "im_forum_topics_seq"]
    set topic_status_id [im_topic_status_id_open]
    set topic_status "Open"
    set due_date $todays_date

    # This is a "Reply" message
    set topic_type_id 1190
    set topic_type "Reply"

    set submit_action "New $topic_type"
    set page_title "New $topic_type"

# We change the previous /intranet/forum/ with /forum/
    set context_bar [ad_context_bar [list /forum/ Forum] $page_title]
    set done 1
}

# -------------- We are editing an already existing message-------------

if {!$done && $topic_id != 0 && ![string equal $submit "Reply"]} {
    set action_type "edit_message"
    set topic_sql "
select
	t.*,
	m.read_p,
	m.folder_id,
	m.receive_updates,
	im_name_from_user_id(ou.user_id) as user_name,
	im_name_from_user_id(au.user_id) as asignee_name,
	ug.project_name,
	ftc.category as topic_type,
	sc.category as topic_status
from
	im_forum_topics t,
      (select * from im_forum_topic_user_map where user_id=:current_user_id) m,
	users ou,
	users au,
	im_projects ug,
	categories ftc,
	categories sc
where
	t.topic_id=:topic_id
	and t.topic_id=m.topic_id(+)
	and t.owner_id=ou.user_id
	and t.asignee_id=au.user_id(+)
	and t.topic_status_id=sc.category_id(+)
	and ug.project_id=t.group_id
	and t.topic_type_id=ftc.category_id(+)
"

     db_1row get_topic $topic_sql
     if {$due_date == ""} { set due_date $todays_date }
     set submit_action "Save Changes"
     set page_title "Edit Topic"
     set context_bar [ad_context_bar [list /intranet/forum/ Forum] $page_title]
     set done 1
 }

 #####     F I N S    A Q U I    #############     F I N S    A Q U I    #############     F I N S    A Q U I    ########
 #####     F I N S    A Q U I    #############     F I N S    A Q U I    #############     F I N S    A Q U I    ########
 #####     F I N S    A Q U I    #############     F I N S    A Q U I    #############     F I N S    A Q U I    ########
 #####     F I N S    A Q U I    #############     F I N S    A Q U I    #############     F I N S    A Q U I    ########
 #####     F I N S    A Q U I    #############     F I N S    A Q U I    #############     F I N S    A Q U I    ########
 #####     F I N S    A Q U I    #############     F I N S    A Q U I    #############     F I N S    A Q U I    ########
 #####     F I N S    A Q U I    #############     F I N S    A Q U I    #############     F I N S    A Q U I    ########


 # Save the old value for asingee_id and status_id to allow 
 # new-tind-2.tcl to alert owners and asignee about these changes.
 set old_asignee_id $asignee_id
 set old_topic_status_id $topic_status_id

 ns_log Notice "new-tind: action_type=$action_type"
 ns_log Notice "new-tind: topic_status_id=$topic_status_id, old_topic_status_id=$old_topic_status_id"


 # ------------------------------------------------------------------
 # Security, Parameters & Default
 # ------------------------------------------------------------------

 set user_is_admin_p [im_is_user_site_wide_or_intranet_admin $current_user_id]
 set user_is_group_member_p [ad_user_group_member $group_id $current_user_id]
 set user_is_group_admin_p [im_can_user_administer_group $group_id $current_user_id]
 set user_is_employee_p [im_user_is_employee_p $current_user_id]
 set user_admin_p [expr $user_is_admin_p || $user_is_group_admin_p]


 # ------------------------------------------------------------------
 # Format the page body
 # ------------------------------------------------------------------

 # During the course of the formatting, we will find that several
 # variables are already specified, for example due to URL parameters
 # or due to access restrictions of the user. These variables just
 # have to be passed on to the next page, using hidden input fields.
 # However, we only know at the end of the "body formatting" what
 # variables to pass on, so that we will format the table and form
 # headers at the end.

 set ctr 1
 set table_body ""
 set export_var_list [list owner_id old_asignee_id parent_id topic_id return_url action_type read_p folder_id]

 # -------------- Topic Type -----------------------------

 # We have to render a select box for it 
 # if it hasn't been specified in the URL.

 if {!$topic_type_id} {
     append table_body "
	 <tr $bgcolor([expr $ctr % 2])>
	   <td>Topic Type</td>
	   <td>
	     [im_forum_topic_type_select topic_type_id]
	   </td>
	 </tr>"
 } else {
     lappend export_var_list "topic_type_id"
     append table_body "
	 <tr $bgcolor([expr $ctr % 2])>
	   <td>Topic Type</td>
	   <td valign=center>
	     [im_gif $topic_type_id "New $topic_type"] 
	     $topic_type
	   </td>
	 </tr>\n"
 }
 incr ctr


 # -------------- Subject Line -----------------------------

 # Show editing widgets when we are editing a new page
 # and for the owner (to make changes to his text).
 #
 if {$current_user_id == $owner_id || [string equal $action_type "new_message"]} {
     append table_body "
	 <tr $bgcolor([expr $ctr % 2])>
	   <td>$topic_type Subject</td>
	   <td>
	     <input type=text size=50 name=subject value=\"$subject\">
	   </td>
	 </tr>\n"
     incr ctr
 } else {
     append table_body "
	 <tr $bgcolor([expr $ctr % 2])>
	   <td>$topic_type Subject</td>
	   <td>$subject</td>
	 </tr>\n"
     incr ctr
     lappend export_var_list "subject"
 }

 # -------------- Group -----------------------------

 # New messages created from HomePage or ForumIndexPage 
 # don't have a group (project) assigned. So we have to do
 # that here:

 set project_status_open "76"
 ns_log Notice "new-tind: group_id=$group_id"
 if {$group_id == 0 && [string equal $action_type "new_message"]} {
    append table_body "
	<tr $bgcolor([expr $ctr % 2])>
	  <td>In Group</td><td>
[im_project_select group_id $project_status_open "" "" "" $current_user_id]
	  </td>
	</tr>\n"
    incr ctr
} else {
    append table_body "
	<tr $bgcolor([expr $ctr % 2])>
	  <td>In Group</td>
	  <td>$group_name</td>
	</tr>\n"
    incr ctr

    lappend export_var_list "group_id"
}


# -------------- Priority -----------------------------

# Only incidents and tasks have priority, status, asignees 
# and due_dates

if {$task_or_incident_p} {
    append table_body "
	<tr $bgcolor([expr $ctr % 2])>
	  <td>Priority</td>
	  <td>
		<select name=priority>
		<option value=1>1 - Emergency</option>
		<option value=2>2 - Very Urgent</option>
		<option value=3>3 - Urgent</option>
		<option value=4>4 - High Normal</option>
		<option value=5 selected>5 - Normal</option>
		<option value=6>6 - Low Normal</option>
		<option value=7>7 - Not that urgent</option>
		<option value=8>8 - Needs to be done</option>
		<option value=9>9 - Optional</option>
		</select>
	  </td></tr>"
    incr ctr
}

# -------------- Asignee -----------------------------

# Only for Incidents and Tasks and only when the message is new:

if {$task_or_incident_p && [string equal $action_type "new_message"]} {

    # calculate the list of potential asignees ( id-name pairs ) 
    # based on user permissions, the project members and the PM.
    set asignee_list [im_forum_potential_asignees $current_user_id $group_id]

    if {2 == [llength $asignee_list]} {
	# only the PM is available: pass the variable on
	set asignee_id [lindex $asignee_list 0]
	lappend export_var_list "asignee_id"

	append table_body "
	<tr $bgcolor([expr $ctr % 2])>
	  <td>Assign to</td>
	  <td>[lindex $asignee_list 1]</td>
	</tr>\n"
	incr ctr

    } else {
	# Build a select box to let the user chose
	append table_body "
	<tr $bgcolor([expr $ctr % 2])>
	  <td>Assign to</td>
	  <td>
	    [im_select asignee_id $asignee_list $asignee_id]
	  </td>
	</tr>\n"
	incr ctr
    }

} else {

    append table_body "
	<tr $bgcolor([expr $ctr % 2])>
	  <td>Assigned to</td>
	  <td>$asignee_name</td>
	</tr>\n"
    incr ctr
    lappend export_var_list "asignee_id"

}

# -------------- Due Date -----------------------------

if {$task_or_incident_p} {

    append table_body "
	<tr $bgcolor([expr $ctr % 2])>
	  <td>Due Date</td>
	  <td>[philg_dateentrywidget due_date $due_date]</td>
	</tr>\n"
    incr ctr
}

# -------------- Status -----------------------------

# If this is a new message, then the status is either "Open"
# for discussions and news or "Assigned" for tasks & incidents.

if {[string equal $action_type "new_message"]} {
    if {$task_or_incident_p} {
	# A new taks/incident is in status "Assigned"
	set topic_status_id [im_topic_status_id_assigned]
	lappend export_var_list "topic_status_id"
    } else {
	# It's a discussion or news item without attached workflow,
	# So the status is "open".
	set topic_status_id [im_topic_status_id_open]
	lappend export_var_list "topic_status_id"
    }

} else {

    # We are editing an existing topic,
    # so we display the current status as a static text.
    # Below the user can take actions, depending on his role and
    # permissions.

    # Some extra messages, depending on status etc:
    set topic_status_msg $topic_status

    if {$current_user_id == $asignee_id && $topic_status_id == [im_topic_status_id_assigned]} {
	# We are assigned to this task/incident,
	# but we haven't confirmed yet
	append topic_status_msg " : <font color=red>Please Accept or Reject the $topic_type</font>"
    }


    append table_body "
	<tr $bgcolor([expr $ctr % 2])>
	  <td>Status</td>
	  <td>$topic_status_msg</td>
	</tr>"
    incr ctr
    lappend export_var_list "topic_status_id"
}

# -------------- Message Body -----------------------------

set html_p "f"

if {$current_user_id == $owner_id || [string equal $action_type "new_message"]} {
    append table_body "
	<tr $bgcolor([expr $ctr % 2])>
	  <td>$topic_type Body</td>
	  <td>
	    <textarea name=message rows=5 cols=50 wrap=soft>[ad_convert_to_html -html_p $html_p -- $message]</textarea>
	  </td>
	</tr>\n"

    incr ctr
} else {
    append table_body "
	<tr $bgcolor([expr $ctr % 2])>
	  <td>$topic_type Body</td>
	  <td>[ad_convert_to_html -html_p $html_p -- $message]</td>
	</tr>\n"
    incr ctr
    lappend export_var_list "message"
}

# -------------- Scope -----------------------------

if {$topic_type_id != 1190} {
    # Topic Tzpe "Reply"

    if {$current_user_id == $owner_id} {
	append table_body "
		<tr $bgcolor([expr $ctr % 2])>
		  <td>Access permissions</td>
		  <td>
                    [im_forum_scope_select "scope" $current_user_id $scope]
		  </td>
		</tr>"
	incr ctr
    } else {
	append table_body "
		<tr $bgcolor([expr $ctr % 2])>
		  <td>Access permissions</td>
		  <td>[im_forum_scope_html $scope]
		  </td>
		</tr>"
	incr ctr

    }
}

# -------------- Receive Updates -----------------------------

ad_proc -public im_forum_update_select {name {default ""}} {
    Return a formatted HTML select box with the update
    options for a im_forum_topic.
} {
    set checked_major ""
    set checked_all ""
    set checked_none ""
    if {[string equal $default "major"]} { set checked_major "checked" }
    if {[string equal $default "all"]} { set checked_all "checked" }
    if {[string equal $default "none"]} { set checked_none "checked" }

    return "
<input type=radio name=$name value=major $checked_major>Important Updates
<input type=radio name=$name value=all $checked_all>All Updates
<input type=radio name=$name value=none $checked_none>No Updates
"
}

append table_body "
<tr $bgcolor([expr $ctr % 2])>
  <td>Do you want to <br>receive updates?</td>
 <td>[im_forum_update_select "receive_updates" $receive_updates]</td>
</tr>"
incr ctr

# -------------- Comments Field -----------------------------

if {![string equal $action_type "new_message"] && ![string equal $action_type "reply_message"]} {
    append table_body "
	<tr $bgcolor([expr $ctr % 2])>
	  <td>Optional comment to add (Accept / Reject / Close)</td>
	  <td>
	    <textarea name=comments rows=4 cols=50 wrap=soft></textarea>
	  </td>
	</tr>\n"
    incr ctr
} else {
    set comments ""
    lappend export_var_list "comments"
}

# -------------- Action Area -----------------------------

# Apart from just saving changes we allow the user to reply
# to the topic, depending on role and topic status.

set actions ""
set added_closed 0

append actions "<option value=reply selected>Reply</option>\n"

if {[string equal $action_type "new_message"]} {
    # The only action for new messages is "Save".
    append actions "<option value=save selected>$submit_action</option>\n"

} else {

    if {$user_admin_p || $current_user_id == $owner_id} {
	append actions "<option value=save selected>$submit_action</option>\n"
    }

    # The only action of the ticket owner is to "Close" the ticket.
    if {$current_user_id == $owner_id && ![string equal $topic_status_id [im_topic_status_id_closed]]} {
	append actions "<option value=close>Close $topic_type</option>\n"
	set added_closed 1
    }

    if {$current_user_id == $asignee_id} {
	# Allow to mark task as "closed" if it hasn't been added before
	if {!$added_closed} {
	    append actions "<option value=close>Close $topic_type</option>\n"
	}
	# Add Accept/Reject for "assigned" tasks
	if {$topic_status_id == [im_topic_status_id_assigned]} {
	    # Asignee has not "accepted" yet
	    append actions "<option value=accept>Accept $topic_type</option>\n"
	    append actions "<option value=reject>Reject $topic_type</option>\n"
        }
	# Always allow to ask for clarification from owner
	append actions "<option value=clarify>$topic_type needs clarify</option>\n"
    }

}

append table_body "
	<tr $bgcolor([expr $ctr % 2])>
	  <td>Actions</td>
	  <td>
	    <select name=actions>
	    $actions
	    </select>
	    <input type=submit value=\"Apply\">
	  </td>
	</tr>\n"
incr ctr

# -------------- Show History/Comments -----------------------------

set topic_sql "
select
	t.*,
	ug.project_name,
	tr.indent_level,
	(10-tr.indent_level) as colspan_level,
	ftc.category as topic_type,
	fts.category as topic_status,
	im_name_from_user_id(ou.user_id) as owner_name,
	im_name_from_user_id(au.user_id) as asignee_name
from
	(select
		topic_id,
		(level-1) as indent_level
	from
		im_forum_topics t
	start with
		topic_id=:topic_id
	connect by
		parent_id = PRIOR topic_id
	) tr,
	im_forum_topics t,
	users ou,
	users au,
	im_projects ug,
	categories ftc,
	categories fts
where
	tr.topic_id = t.topic_id
	and t.owner_id=ou.user_id
	and ug.project_id=t.group_id
	and t.asignee_id=au.user_id(+)
	and t.topic_type_id=ftc.category_id(+)
	and t.topic_status_id=fts.category_id(+)
"

# -------------- Setup the outer table with indents-----------------------

# outer table with 10 columns for indenting
set thread_html "
<table cellspacing=0 border=0 cellpadding=3>
<tr>
  <td>&nbsp; &nbsp; &nbsp; &nbsp; &nbsp; </td>
  <td>&nbsp; &nbsp; &nbsp; &nbsp; &nbsp; </td>
  <td>&nbsp; &nbsp; &nbsp; &nbsp; &nbsp; </td>
  <td>&nbsp; &nbsp; &nbsp; &nbsp; &nbsp; </td>
  <td>&nbsp; &nbsp; &nbsp; &nbsp; &nbsp; </td>
  <td>&nbsp; &nbsp; &nbsp; &nbsp; &nbsp; </td>
  <td>&nbsp; &nbsp; &nbsp; &nbsp; &nbsp; </td>
  <td>&nbsp; &nbsp; &nbsp; &nbsp; &nbsp; </td>
  <td>&nbsp; &nbsp; &nbsp; &nbsp; &nbsp; </td>
  <td>&nbsp; &nbsp; &nbsp; &nbsp; &nbsp; </td>
</tr>
"


# -------------- Render all TIND elements -----------------------

set msg_ctr 1
db_foreach get_topic $topic_sql {

    # skip the first message, displayed above.
    if {$msg_ctr != 1} {

	# position table within the outer indent-table
	append thread_html "<tr>"
	if {$indent_level > 0} {
	    append thread_html "<td colspan=$indent_level>&nbsp;</td>"
	}
	append thread_html "
		  <td colspan=$colspan_level>
		     <table border=0 cellpadding=0 bgcolor=#E0E0E0>"
	append thread_html " [im_forum_render_tind $topic_id $topic_type_id $topic_type $topic_status_id $topic_status $owner_id $asignee_id $owner_name $asignee_name $current_user_id $group_id $group_name $subject $message $posting_date $due_date $priority $scope]

		    </table>
		  </td>
		</tr>\n"
    }
    incr msg_ctr
}


# -------------- Table and Form Start -----------------------------

set page_body "

<form action=new-tind-2 method=POST>
[eval "export_form_vars [join $export_var_list " "]"]

<table cellspacing=1 border=0 cellpadding=1>
$table_body
</table>
</form>

$thread_html
"

doc_return  200 text/html [im_return_template]








