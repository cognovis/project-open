# /packages/intranet-forum/www/intranet/forum/view-tind.tcl
#
# Copyright (C) 2003-2004 Project/Open
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

ad_page_contract {
    Create a new Task, Incident, News or Discussion (TIND)
    @param topic_id: Message to refer to
    @param display_style: 
	topic		= full topic (subject+message), no subtopics
	thread		= complete tree of subjects
	topic_thread	= full topic plus subtopics subjects
	full		= topic+all subtopics
    @author frank.bergmann@project-open.com
} {
    topic_id:integer
    {display_style "all"}
    {return_url ""}
} 

# -------------- Security, Parameters & Default --------------------------

set user_id [ad_maybe_redirect_for_registration]
set user_is_admin_p [im_is_user_site_wide_or_intranet_admin $user_id]
set user_is_wheel_p [ad_user_group_member [im_wheel_group_id] $user_id]

if {"" == $return_url} {
    set return_url [im_url_with_query]
}

set page_title "View Topic"
set context_bar [ad_context_bar [list /intranet/forum/ Forum] $page_title]


# -------------- Get the tree --------------------------

set topic_sql "
select
	t.*,
	ug.group_name,
	tr.indent_level,
	(10-tr.indent_level) as colspan_level,
	ftc.category as topic_type,
	fts.category as topic_status,
	ou.first_names||' '||ou.last_name as owner_name,
	au.first_names||' '||au.last_name as asignee_name
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
	user_groups ug,
	im_categories ftc,
	im_categories fts
where
	tr.topic_id = t.topic_id
	and t.owner_id=ou.user_id
	and ug.group_id=t.group_id
	and t.asignee_id=au.user_id(+)
	and t.topic_type_id=ftc.category_id(+)
	and t.topic_status_id=fts.category_id(+)
"


# -------------- Setup the outer table with indents-----------------------

append page_body "
<br>
[im_forum_navbar "/intranet/projects/index" [list]]"

# outer table with 10 columns for indenting
append page_body "
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

    # position table within the outer indent-table
    append page_body "<tr>"
    if {$indent_level > 0} {
	append page_body "<td colspan=$indent_level>&nbsp;</td>"
    }
    append page_body "
		  <td colspan=$colspan_level>
		     <table border=0 cellpadding=0 bgcolor=#E0E0E0>"
    if {$msg_ctr == 1} { append page_body "
		       <tr><td class=rowtitle colspan=2 align=center>
		       $topic_type</td></tr>"
    }
    append page_body " [im_forum_render_tind $topic_id $topic_type_id $topic_type $topic_status_id $topic_status $owner_id $asignee_id $owner_name $asignee_name $user_id $group_id $group_name $subject $message $posting_date $due_date $priority $scope]

		    </table>
		  </td>
		</tr>
    "

    incr msg_ctr
}

append page_body "</table>\n"

doc_return  200 text/html [im_return_template]
