# /admin/monitoring/cassandracle/users/one-user-specific-objects.tcl

ad_page_contract {
    Displays info about objects of a particular type owned by a particular user.
    Called from ./user-owned-objects.tcl

    @author Dave Abercrombie (abe@arsdigita.com)
    @creation-date 20 October 1999
    @cvs-id $Id: one-user-specific-objects.tcl,v 1.1.1.2 2006/08/24 14:41:41 alessandrol Exp $
} {
    object_type 
    owner
    {order_by "object_name"}
}

# check arguments -----------------------------------------------------

# $order_by   TWO VALUES ONLY ARE VALID
if { [string compare $order_by "object_name"] != 0 && [string compare $order_by "last_ddl_time"] != 0 } {
    ad_return_complaint 1 "<li>Invalid value of \$order_by: $order_by, Valid values include only  \"object_name\" and \"last_ddl_time\" "
    return
}

# $order_by - If order is "last_ddl_time", then order descending
if { [string compare $order_by "last_ddl_time"]==0 } {
    append order_by " DESC"
}

# arguments OK, start building page ----------------------------------------

set page_name "Objects of type $object_type owned by $owner"

set page_content "

[ad_header "$page_name"]

<h2>$page_name</h2>

[ad_context_bar [list "[ad_conn package_url]/cassandracle" "Cassandracle"] [list \"[ad_conn package_url]/cassandracle/users/\" "Users"] [list "[ad_conn package_url]/cassandracle/users/user-owned-objects.tcl" "Objects" ] "One Object Type"]

<hr>
"

# set $href variable used for linking from object_name column of table (after substitution)
if {$object_type=="FUNCTION"||$object_type=="PROCEDURE"} {
    set href "<a href=\"../objects/detail-function-or-procedure?object_name=\[lindex \$row 0]&owner=$owner\">\[lindex \$row 0]</a>"    
} elseif  {$object_type=="TABLE"||$object_type=="VIEW"} {
    set href "<a href=\"../objects/describe-table?object_name=${owner}.\[lindex \$row 0]\">\[lindex \$row 0]</a>"    
} else {
    set href "\[lindex \$row 0\]"
}

# write the table headers
# put sort links in as appropriate
# headers depend on sort order, I use a switch for future flexibility
switch -exact -- $order_by {
    "object_name" {
	set object_name_header "Object Name"
	set last_ddl_time_header "<a href=\"one-user-specific-objects?order_by=last_ddl_time&[export_url_vars owner object_type]\">Last DDL</a>"
    }
    "last_ddl_time DESC" {
	set object_name_header "<a href=\"one-user-specific-objects?order_by=object_name&[export_url_vars owner object_type]\">Object Name</a>"
	set last_ddl_time_header "Last DDL"
    }
}

append page_content "
<table cellpadding=3 border=1>
<tr>
  <th>$object_name_header</th>
  <th>Created</th>
  <th>$last_ddl_time_header</th>
  <th>Status</th>
</tr>
"

# run query
set object_ownership_info [db_list_of_lists mon_user_specific_objects "
-- /users/one-user-specific-objects.tcl
select
    do.object_name, 
    do.created, 
    do.last_ddl_time, 
    lower(do.status) as status
from
    dba_objects do
where
    do.owner=:owner
and do.object_type=:object_type
order by
  :order_by"]

# output rows
if {[llength $object_ownership_info]==0} {
    append page_content "<tr><td>No objects found!</td></tr>"
} else {
    foreach row $object_ownership_info {
	append page_content "
        <tr>
	  <td>[subst $href] &nbsp;</td>
	  <td align=right>[lindex $row 1]</td>
	  <td align=right>[lindex $row 2]</td>
	  <td>[lindex $row 3]</td>
	</tr>\n"
    }
}

# close up shop
append page_content "</table>
<hr>
<H4>More information:</h4>
<p>See Oracle documentation about view <a target=second href=\"http://oradoc.photo.net/ora81/DOC/server.815/a67790/ch2.htm#51392\">dba_objects</a> on which this page is based.</p>
[ad_admin_footer]
"


doc_return 200 text/html $page_content
