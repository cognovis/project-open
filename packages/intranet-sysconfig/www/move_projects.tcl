# /packages/intranet-sysconfig/www/move_projects.tcl
#
# Copyright (c) 2003-2006 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

# ---------------------------------------------------------------
# Page Contract
# ---------------------------------------------------------------

ad_page_contract {
    Configures the system according to Wizard variables
} {
}

set current_user_id [ad_maybe_redirect_for_registration]
set user_is_admin_p [im_is_user_site_wide_or_intranet_admin $current_user_id]
if {!$user_is_admin_p} {
    ad_return_complaint 1 "<li>[_ intranet-core.lt_You_need_to_be_a_syst]"
    return
}


# ---------------------------------------------------------------
# Output headers
# Allows us to write out progress info during the execution
# ---------------------------------------------------------------

set content_type "text/html"
set http_encoding "iso8859-1"

append content_type "; charset=$http_encoding"

set all_the_headers "HTTP/1.0 200 OK
MIME-Version: 1.0
Content-Type: $content_type\r\n"

util_WriteWithExtraOutputHeaders $all_the_headers
ns_startcontent -type $content_type

ns_write "[im_header] [im_navbar]"


# ---------------------------------------------------------------
# Move projects forward until atleast on project works in the future
# ---------------------------------------------------------------

ns_write "<h2>Moving projects forward</h2>\n"
ns_write "<li>Moving ...\n"

set future_projects_sql "
	select	count(*)
	from	im_projects
	where	end_date > now()
"

set future_projects [db_string future_projects $future_projects_sql]
while {0 == $future_projects} {
    db_dml move_projects "
	update im_projects set
		start_date = start_date::date + 60,
		end_date = end_date::date + 60
    "
    set future_projects [db_string future_projects $future_projects_sql]
}


ns_write "done\n"


# ---------------------------------------------------------------
# Distribute Projects across the calendar
# ---------------------------------------------------------------

ns_write "<h2>distributing Projects across the calendar</h2>\n"
ns_write "<li>Moving ...\n"

db_dml distribute_projects "
	update im_projects set
		start_date = start_date::date + (random() * 100 - 50)::integer,
		end_date = end_date::date + (random() * 100 - 50)::integer
"

ns_write "done\n"





# ---------------------------------------------------------------
# Move forum_topics forward until atleast on forum_topic works in the future
# ---------------------------------------------------------------

ns_write "<h2>Moving forum_topics forward</h2>\n"
ns_write "<li>Moving ...\n"

set future_forum_topics_sql "
	select	count(*)
	from	im_forum_topics
	where	due_date > now()
"

set future_forum_topics [db_string future_forum_topics $future_forum_topics_sql]
while {0 == $future_forum_topics} {
    db_dml move_forum_topics "
	update im_forum_topics set
		due_date = due_date ::date + 30
    "
    set future_forum_topics [db_string future_forum_topics $future_forum_topics_sql]
}


ns_write "done\n"


# ---------------------------------------------------------------
# Distribute forum topics across the calendar
# ---------------------------------------------------------------

ns_write "<h2>distributing Fforum Topics across the calendar</h2>\n"
ns_write "<li>Moving ...\n"

db_dml distribute_forum_topics "
	update im_forum_topics set
		due_date = due_date ::date + (random() * 100 - 50)::integer
"

ns_write "done\n"

# ---------------------------------------------------------------
# Finish off page
# ---------------------------------------------------------------

# Remove all permission related entries in the system cache
util_memoize_flush_regexp ".*"
im_permission_flush


ns_write "[im_footer]\n"


