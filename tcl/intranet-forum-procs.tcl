# /tcl/intranet-forum.tcl

ad_library {
    The intranet forum provides a unified aprearance of 
    Tasks, Incidents, News & Discussions (TIND)

    @author fraber@fraber.de
    @creation-date 23 September 2003
}

# ----------------------------------------------------------------------
# Select Boxes
# ----------------------------------------------------------------------

ad_proc -public im_topic_status_id_open { } {Returns Topic Status ID} { return [ad_parameter TopicStatusOpen intranet 1200] }
ad_proc -public im_topic_status_id_assigned { } {Returns Topic Status ID} { return [ad_parameter TopicStatusAssigned intranet 1202] }
ad_proc -public im_topic_status_id_accepted { } {Returns Topic Status ID} { return [ad_parameter TopicStatusAccepted intranet 1204] }
ad_proc -public im_topic_status_id_rejected { } {Returns Topic Status ID} { return [ad_parameter TopicStatusRejected intranet 1206] }
ad_proc -public im_topic_status_id_needs_clarify { } {Returns Topic Status ID} { return [ad_parameter TopicStatusNeedsClarify intranet 1208] }
ad_proc -public im_topic_status_id_closed { } {Returns Topic Status ID} { return [ad_parameter TopicStatusClosed intranet 1210] }

ad_proc -public im_forum_topic_type_select { select_name { default "" } } {
    Returns an html select box named $select_name and defaulted to
    $default with a list of all topic types (task, incident, news, ...)
} {
    return [im_category_select "Intranet Topic Type" $select_name $default]
}

ad_proc -public im_forum_topic_status_select { select_name { default "" } } {
    Returns an html select box named $select_name and defaulted to
    $default with a list of all stati for Tasks and Incidents
} {
    return [im_category_select "Intranet Topic Status" $select_name $default]
}


# ------------------------------------------------------------------
# Procedures
# ------------------------------------------------------------------

ad_proc -public im_forum_potential_asignees {user_id group_id} {
    Return a key-value list of all persons to whom the current
    user may assign his task or issue.
    Project: 
	This list is restricted to the PM for customers 
	and freelancers.
    Customer:
	May be restricted to the Key Account
} {
    set project_admin_sql "(
select distinct
	u.user_id,
	im_name_from_user_id(u.user_id) as user_name
from	group_member_map m,
	users u
where	m.group_id=:group_id
	and m.member_id=u.user_id
	and m.rel_type='administrator'
)"

    set project_group_sql "(
select distinct
	u.user_id,
	im_name_from_user_id(u.user_id) as user_name
from	group_member_map m,
	users u
where	m.group_id=:group_id
	and m.member_id=u.user_id
)"

    set public_sql "(
select distinct
	u.user_id,
	im_name_from_user_id(u.user_id) as user_name
from	group_member_map m,
	users u
where	m.group_id in (14,15,16,18,19)
	and m.member_id=u.user_id
)"

    set project_client_sql "(
select distinct
	u.user_id,
	im_name_from_user_id(u.user_id) as user_name
from	group_member_map m,
	users u
where	m.group_id=:group_id
	and m.member_id=u.user_id
	and u.user_id in (
		select user_id
		from group_member_map
		where group_id=6
	)
)"

    set project_non_client_sql "(
select distinct
	u.user_id,
	im_name_from_user_id(u.user_id) as user_name
from	group_member_map m,
	users u
where	m.group_id=:group_id
	and m.member_id=u.user_id
	and u.user_id not in (
		select user_id
		from group_member_map
		where group_id=6
	)
)"

    set project_staff_sql "(
select distinct
	u.user_id,
	im_name_from_user_id(u.user_id) as user_name
from	group_member_map m,
	users u
where	m.group_id=:group_id
	and m.member_id=u.user_id
	and u.user_id in (
		select user_id
		from group_member_map
		where group_id=9
	)
)"

    set sql_list [list]
#    if {[im_permission $user_id create_topic_scope_public]} {
#	lappend sql_list $public_sql
#    }
    if {[im_permission $user_id create_topic_scope_group]} {
	lappend sql_list $project_group_sql
    }
    if {[im_permission $user_id create_topic_scope_staff]} {
	lappend sql_list $project_staff_sql
    }
    if {[im_permission $user_id create_topic_scope_client]} {
	lappend sql_list $project_client_sql
    }
    if {[im_permission $user_id create_topic_scope_non_client]} {
	lappend sql_list $project_non_client_sql
    }
    if {[im_permission $user_id create_topic_scope_pm]} {
	lappend sql_list $project_admin_sql
    }

    set sql [join $sql_list " UNION "]
    ns_log Notice "new-tind: $sql"


    set asignee_list [list]
    db_foreach project_admins $sql {
	lappend asignee_list $user_id
	lappend asignee_list $user_name
    }

    if {0 == [llength $asignee_list]} {
	lappend asignee_list 3
	lappend asignee_list "System Administrator"
    }
    return $asignee_list
}


# ----------------------------------------------------------------------
# Render a single TIND (Task, Incident, News or Discussion)
# ----------------------------------------------------------------------

ad_proc -public im_forum_render_tind {
	topic_id 
	topic_type_id topic_type 
        topic_status_id topic_status
	owner_id asignee_id owner_name asignee_name
	user_id group_id group_name
	subject message
	posting_date due_date
	priority scope
} {
    Render the rows of a single TIND
} {
    set bgcolor(0) " class=roweven"
    set bgcolor(1) " class=rowodd"

    set user_is_group_member_p [ad_user_group_member $group_id $user_id]
    set ctr 1
    set tind_html "
		<tr $bgcolor([expr $ctr % 2])>
		  <td>Subject:</td>
		  <td>
		    [im_gif $topic_type_id "New $topic_type"] 
		    $subject"
    if {$user_id == $owner_id} {
append tind_html " &nbsp; (<A href=new-tind?topic_id=$topic_id&submit=Edit>Edit</A>)"
    }
    if {$user_is_group_member_p} {
append tind_html " (<A href=new-tind?topic_id=$topic_id&submit=Reply>Reply</A>)"
    }
    append tind_html "
		  </td>
		</tr>"
    incr ctr

    append tind_html "
		<tr $bgcolor([expr $ctr % 2])>
		  <td>Posted in:</td>
		  <td><A href='/intranet/projects/view?group_id=$group_id'>$group_name</A></td>
		</tr>\n"
    incr ctr

    append tind_html "
		<tr $bgcolor([expr $ctr % 2])>
		  <td>From:</td><td>
		    <A HREF=/intranet/users/view?user_id=$owner_id>
		      $owner_name
		   </A>
		  </td>
		</tr>\n"
    incr ctr

if {$topic_status_id != ""} {
    append tind_html "
		<tr $bgcolor([expr $ctr % 2])>
		  <td>Status:</td><td>$topic_status</td>
		  </td>
		</tr>\n"
    incr ctr
}

    append tind_html "
		<tr $bgcolor([expr $ctr % 2])>
		  <td>Posting Date:</td>
		  <td>$posting_date</td>
		</tr>\n"
    incr ctr

    append tind_html "
		<tr $bgcolor([expr $ctr % 2])>
		  <td>Priority:</td>
		  <td>$priority</td>
		</tr>\n"
    incr ctr

    if {$asignee_id != ""} {
	append tind_html "
		<tr $bgcolor([expr $ctr % 2])>
		  <td>Assigned to:</td>
		  <td>
		    <A href=/intranet/users/view?user_id=$asignee_id>
		      $asignee_name
		    </A>"
    if {$user_id == $asignee_id || $user_id == $owner_id} {
        append tind_html " &nbsp; (<A href=new-tind?topic_id=$topic_id&submit=Assign>Assign</A>)"
    }
	append tind_html "
		  </td>
		</tr>\n"
	incr ctr
    }

#    append tind_html "
#		<tr $bgcolor([expr $ctr % 2])>
#		  <td>Visible for:</td>
#		  <td>$scope</td>
#		</tr>\n"
#    incr ctr

    if {$due_date != ""} {
	append tind_html "
		<tr $bgcolor([expr $ctr % 2])>
		  <td>Due Date:</td>
		  <td>$due_date</td>
		</tr>\n"
	incr ctr
    }
    
#    append tind_html "
#		<tr $bgcolor([expr $ctr % 2])><td colspan=2 align=center>
#		<input type=submit name=submit value='Edit'>
#		<input type=submit name=submit value='Reply'>
#		</td></tr>
#    "
#    incr ctr

    # Only allow plain text messages
    set html_p "f"
    append tind_html "
		<tr bgcolor=white><td colspan=2>
		  <pre>[ad_convert_to_html -html_p $html_p -- $message]</pre>
		</td></tr>
    "
    return $tind_html
}

# ----------------------------------------------------------------------
# Forum List Page Component
# ---------------------------------------------------------------------

ad_proc -public im_forum_component {user_id group_id current_page_url return_url export_var_list {view_name "forum_list_short"} {forum_order_by "priority"} {restrict_to_mine_p f} {restrict_to_topic_type_id 0} {restrict_to_topic_status_id 0} {restrict_to_asignee_id 0} {max_entries_per_page 0} {start_idx 1} {restrict_to_new_topics 0} {restrict_to_folder 0} } {
    Creates a HTML table showing a table of "Discussion Topics" of 
    various types. Parameters:
    - restrict_to_topic_type_id: 0=All, 1=Tasks & Incidents, other=Specific
} {
    set bgcolor(0) " class=roweven"
    set bgcolor(1) " class=rowodd"

    if {!$max_entries_per_page} { set max_entries_per_page 10 }

    set end_idx [expr $start_idx + $max_entries_per_page - 1]

    # ---------------------- Get Columns ----------------------------------

    # Define the column headers and column contents that
    # we want to show:
    #
    set view_id [db_string get_view_id "select view_id from im_views where view_name=:view_name" -default 0]
    if {!$view_id} {
	return "<H1>Unable to find view '$view_name'</H1>\n"
    }

    set column_headers [list]
    set column_vars [list]

    set column_sql "
	select
	        column_name,
	        column_render_tcl,
	        visible_for
	from
	        im_view_columns
	where
	        view_id=:view_id
	        and group_id is null
	order by
	        sort_order
    "

    db_foreach column_list_sql $column_sql {
	if {[eval $visible_for]} {
        lappend column_headers "$column_name"
        lappend column_vars "$column_render_tcl"
	}
    }

    # -------- Compile the list of parameters to pass-through-------

    set bind_vars [ns_set create]
    foreach var $export_var_list {
        upvar 1 $var value
        if { [info exists value] } {
            ns_set put $bind_vars $var $value
            ns_log Notice "im_forum_component: $var <- $value"
        }
    }

    ns_set delkey $bind_vars "forum_order_by"
    set params [list]
    set len [ns_set size $bind_vars]
    for {set i 0} {$i < $len} {incr i} {
        set key [ns_set key $bind_vars $i]
        set value [ns_set value $bind_vars $i]
        if {![string equal $value ""]} {
            lappend params "$key=[ns_urlencode $value]"
        }
    }
    set pass_through_vars_html [join $params "&"]

    # ---------------------- Format Header ----------------------------------

    # Set up colspan to be the number of headers + 1 for the # column
    set colspan [expr [llength $column_headers] + 1]

    # Format the header names with links that modify the
    # sort order of the SQL query.
    #
    set table_header_html "<tr>\n"
    foreach col $column_headers {

	set cmd_eval ""
	set cmd "set cmd_eval $col"
        eval $cmd

	if { [string compare $forum_order_by $cmd_eval] == 0 } {
	    append table_header_html "  <td class=rowtitle>$col</td>\n"
	} else {
	    append table_header_html "  <td class=rowtitle>
            <a href=$current_page_url?$pass_through_vars_html&forum_order_by=[ns_urlencode $cmd_eval]>$cmd_eval</a>
            </td>\n"
	}
    }
    append table_header_html "</tr>\n"

    # ---------------------- Build the SQL query ---------------------------

    set order_by_clause "order by priority"
    switch $forum_order_by {
	"P" { set order_by_clause "order by priority" }
	"Subject" { set order_by_clause "order by upper(subject)" }
	"Type" { set order_by_clause "order by topic_type_id" }
	"Due" { set order_by_clause "order by due_date" }
	"Who" { set order_by_clause "order by upper(owner_initials)" }
    }

    set restrictions []
    if {$group_id} {lappend restrictions "t.group_id=:group_id" }
    if {[string equal "t" $restrict_to_mine_p]} {lappend restrictions "(owner_id=:user_id or asignee_id=:user_id)" }
    if {$restrict_to_topic_status_id} {lappend restrictions "topic_status_id=:restrict_to_topic_status_id" }
    if {$restrict_to_asignee_id} {lappend restrictions "asignee_id=:restrict_to_asignee_id" }
    if {$restrict_to_new_topics} {lappend restrictions "(m.read_p is null or m.read_p='f')" }
    if {$restrict_to_folder} {
	lappend restrictions "m.folder_id=:restrict_to_folder" 
    } else {
	lappend restrictions "(m.folder_id is null or m.folder_id=0)" 
    }

    if {$restrict_to_topic_type_id} {
	# 0=All, 1=Tasks & Incidents, other=Specific Type
	if {1 == $restrict_to_topic_type_id} {
	    lappend restrictions "(topic_type_id=1102 or topic_type_id=1104)"
	} else {
	    lappend restrictions "topic_type_id=:restrict_to_topic_type_id"
	}
    }

    set restriction_clause [join $restrictions "\n\tand "]
    if {"" != $restriction_clause} { 
	set restriction_clause "and $restriction_clause" 
    }

    set user_is_employee_p [im_user_is_employee_p $user_id]
    set user_is_customer_p [im_user_is_customer_p $user_id]

    # Get permission together with the forum_topics in an inner
    # select to allow the outer SQL to use a WHERE clause to
    # limit the number returned rows.
    # This way we handle all permissions in SQL, allowing to
    # count the number of returned rows for the << and >> buttons.
    set inner_forum_sql "
select
	t.*,
	im_category_from_id(t.topic_type_id) as topic_type,
	CASE
		WHEN scope='public' THEN 1
		WHEN scope='group' THEN member_groups.p
		WHEN scope='client' and 1=:user_is_customer_p THEN member_groups.p
		WHEN scope='staff' and 1=:user_is_employee_p THEN member_groups.p
		WHEN scope='not_client' and 0=:user_is_customer_p THEN member_groups.p
		WHEN scope='pm' THEN admin_groups.p
		ELSE 0
	END as permission_p,
	CASE WHEN t.owner_id=:user_id THEN 1 ELSE 0 END as owner_p,
	CASE WHEN t.asignee_id=:user_id THEN 1 ELSE 0 END as asignee_p
from
	im_forum_topics t,
	-- return 1 if the user is admin of a group
	(select 1 as p, group_id from group_member_map where
	 member_id=:user_id and rel_type='administrator') admin_groups,
	-- return 1 if the user is member of a group
	(select 1 as p, group_id from group_member_map where
	 member_id=:user_id) member_groups
where
	t.group_id=admin_groups.group_id(+)
	and t.group_id=member_groups.group_id(+)
"


    set forum_sql "
select
	t.*,
	m.read_p,
	m.folder_id,
	f.folder_name,
	m.receive_updates,
	im_initials_from_user_id(t.owner_id) as owner_initials,
	im_initials_from_user_id(t.asignee_id) as asignee_initials
from
	($inner_forum_sql) t,
	(select * from im_forum_topic_user_map where user_id=:user_id) m,
	im_forum_folders f
where
        (t.permission_p = 1 or t.owner_p = 1 or t.asignee_id = 1)
        and t.group_id != 1
        and (t.parent_id is null or t.parent_id=0)
	and t.topic_id=m.topic_id(+)
	and m.folder_id=f.folder_id(+)
	$restriction_clause
$order_by_clause"


	ns_log Notice "forum_sql=$forum_sql"

    # ---------------------- Limit query to MAX rows -------------------------
    
    # We can't get around counting in advance if we want to be able to
    # sort inside the table on the page for only those rows in the query 
    # results
    
    set limited_query [im_select_row_range $forum_sql $start_idx $end_idx]
    set total_in_limited_sql "
	select count(*)
	from 
		im_forum_topics t,
		im_forum_topic_user_map m,
		im_forum_folders f
	where 
		group_id != 1
		and (t.parent_id is null or t.parent_id=0)
		and t.topic_id=m.topic_id(+)
		and m.folder_id=f.folder_id(+)
		$restriction_clause
    "

    ns_log Notice "total_in_limited_sql=$total_in_limited_sql"
    set total_in_limited [db_string projects_total_in_limited $total_in_limited_sql]
    set selection "select z.* from ($limited_query) z $order_by_clause"

    # How many items remain unseen?
    set remaining_items [expr $total_in_limited - $start_idx - $max_entries_per_page + 1]

    # ---------------------- Format the body -------------------------------

    set table_body_html ""
    set ctr 0
    set idx $start_idx
    set old_group_id 0


    set limited_query $forum_sql

    db_foreach forum_query $limited_query {
        if {$read_p == "t"} {set read 1} else {set read 0}
        if {$folder_id == ""} {set folder_name "Inbox"}

        # insert intermediate headers for every project
        if {[string equal "Project" $forum_order_by]} {
            if {$old_group_id != $group_id} {
                append table_body_html "
                <tr><td colspan=$colspan>&nbsp;</td></tr>
                <tr><td class=rowtitle colspan=$colspan>
                  <A href=/intranet/projects/view?group_id=$group_id>
                    $short_name</A>: $group_name
                  </A>
                </td></tr>\n"
                set old_group_id $group_id
            }
        }

        append table_body_html "<tr$bgcolor([expr $ctr % 2])>\n"
        foreach column_var $column_vars {
            append table_body_html "\t<td valign=top>"
            set cmd "append table_body_html $column_var"
            eval $cmd
            append table_body_html "</td>\n"
        }
        append table_body_html "</tr>\n"

        incr ctr
        if { $max_entries_per_page > 0 && $ctr >= $max_entries_per_page } {
            break
	}
    }
    # Show a reasonable message when there are no result rows:
    if { [empty_string_p $table_body_html] } {
	set table_body_html "
	<tr><td colspan=$colspan align=center><b>
	There are no active items.
	</b></td></tr>"
    }

    if { $ctr == $max_entries_per_page && $end_idx < $total_in_limited } {
	# This means that there are rows that we decided not to return
	# Include a link to go to the next page
	set next_start_idx [expr $end_idx + 1]
	set next_page_html "($remaining_items more) <A href=$current_page_url?$pass_through_vars_html&start_idx=$next_start_idx>&gt;&gt;</a>"
    } else {
	set next_page_html ""
    }

    if { $start_idx > 1 } {
	# This means we didn't start with the first row - there is
	# at least 1 previous row. add a previous page link
	set previous_start_idx [expr $start_idx - $max_entries_per_page]
	if { $previous_start_idx < 1 } {
	set previous_start_idx 1
	}
	set previous_page_html "<A href=$current_page_url?$pass_through_vars_html&start_idx=$previous_start_idx>&lt;&lt;</a>"
    } else {
	set previous_page_html ""
    }


    # ---------------------- Format the action bar at the bottom ------------

    set table_footer "
<tr>
  <td $bgcolor([expr $ctr % 2]) colspan=$colspan align=right>
    $previous_page_html
    $next_page_html
    <select name=action>
	<option value=mark_as_read>Mark as read</option>
	<option value=mark_as_unread>Mark as unread</option>
	<option value=move_to_deleted>Move to Deleted</option>
	<option value=move_to_inbox>Move to Active</option>
    </select>
    <input type=submit name=submit value='Apply'>
  </td>
</tr>"

    # ---------------------- Join all parts together ------------------------
#<form action=/intranet/forum/forum-action method=POST>
    set component_html "

<form action=/intranet-forum/forum/forum-action method=POST>
[export_form_vars group_id return_url]
<table bgcolor=white border=0 cellpadding=1 cellspacing=1>
  $table_header_html
  $table_body_html
  $table_footer
</table>
</form>\n"

    return $component_html
}


# ----------------------------------------------------------------------
# Forum Navigation Bar
# ----------------------------------------------------------------------

# <A HREF=/intranet/forum/index?[export_url_vars group_id return_url]>

ad_proc -public im_forum_create_bar { title_text group_id {return_url ""} } {
    Returns rendered HTML table with icons for creating new 
    forum elements
} {
    set html "
<table cellpadding=0 cellspacing=0 border=0>
<tr>
<td>
  <A HREF=/forum/index?[export_url_vars group_id return_url]>
    $title_text
  </A>
</td>
<td>
  <A href='/intranet-forum/forum/new-tind?topic_type_id=1102&[export_url_vars group_id return_url]'>
    [im_gif "incident" "Create new Incident"]
  </A>
</td>
<td>
  <A href='/intranet-forum/forum/new-tind?topic_type_id=1104&[export_url_vars group_id return_url]'>
    [im_gif "task" "Create new Task"]
  </A>
</td>
<td>
  <A href='/intranet-forum/forum/new-tind?topic_type_id=1106&[export_url_vars group_id return_url]'>
    [im_gif "discussion" "Create a new Discussion"]
  </A>
</td>
<td>
  <A href='/intranet-forum/forum/new-tind?topic_type_id=1100&[export_url_vars group_id return_url]'>
    [im_gif "news" "Create new News Item"]
  </A>
</td>
<td>
  <A href='/intranet-forum/forum/new-tind?topic_type_id=1108&[export_url_vars group_id return_url]'>
    [im_gif "note" "Create new Note"]
  </A>
</td>
</tr>
</table>
"
}



ad_proc -public im_forum_navbar { base_url export_var_list } {
    Returns rendered HTML code for a horizontal sub-navigation
    bar for /forum/.
} {
    # -------- Compile the list of parameters to pass-through-------
    set bind_vars [ns_set create]
    foreach var $export_var_list {
	upvar 1 $var value
	if { [info exists value] } {
	    ns_set put $bind_vars $var $value
	}
    }

    # --------------- Determine the calling page ------------------
    set user_id [ad_get_user_id]
    set section ""
    set url_stub [im_url_with_query]
    ns_log Notice "im_forum_navbar: url_stub=$url_stub"
    
    switch -regexp $url_stub {
	{index$} { set section "Active Topics" }
	{forum_folder=1} { set section "Deleted Topics" }
	{forum%5flist%5fdiscussion} { set section "Discussion View" }
	{forum%5flist%5fhistory} { set section "History" }
	{view-tind} { set section "One Topic" }
	{new-tind} { set section "One Topic" }
	default {
	    set section "Active Topics"
	}
    }

    set sel "<td class=tabsel>"
    set nosel "<td class=tabnotsel>"
    set a_white "<a class=whitelink"
    set tdsp "<td>&nbsp;</td>"

    set active_topics "$tdsp$nosel<a href='index'>Active Topics</a></td>"
    set deleted_topics "$tdsp$nosel<a href='index?forum_folder=1'>Deleted Topics</a></td>"
    set discussion_view "$tdsp$nosel<a href='index?forum_view_name=forum_list_discussion'>Discussion View</a></td>"
    set history "$tdsp$nosel<a href='index?forum_view_name=forum_list_history'>History</a></td>"

    switch $section {
"Active Topics" {set active_topics "$tdsp$sel Active Topics</td>"}
"Deleted Topics" {set deleted_topics "$tdsp$sel Deleted Topics</td>"}
"Discussion View" {set discussion_view "$tdsp$sel Discussion View</td>"}
"History" {set history "$tdsp$sel History</td>"}
default {
    # Nothing - just let all sections deselected
}
    }


# $discussion_view $history

    set navbar "
<table width=100% cellpadding=0 cellspacing=0 border=0>
  <tr>
    <td colspan=6 align=right>
      <table cellpadding=1 cellspacing=0 border=0>
	<tr>
	  $active_topics
	  $deleted_topics
	</tr>
      </table>
    </td>
  </tr>
  <tr>
    <td colspan=6 class=tabnotsel align=center>
	&nbsp;
    </td>
  </tr>
</table>
"
    return $navbar
}


