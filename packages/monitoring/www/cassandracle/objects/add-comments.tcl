# /www/admin/monitoring/cassandracle/objects/add-comment.tcl

ad_page_contract {

    allows comments to be added/updated for a table.  called
    from ./describe-table.tcl

    @param object_name encodes the owner and table name as owner.table_name

    @author Ron Henderson (ron@arsdigita.com)
    @cvs-id $Id: add-comments.tcl,v 1.1.1.2 2006/08/24 14:41:40 alessandrol Exp $
} {
    object_name:notnull
}


set object_info [split $object_name .]
set owner [lindex $object_info 0]
set object_name [lindex $object_info 1]

# check parameter to see if we want to display SQL as comments
# actually harcoded now during development, but will use ns_info later

set show_sql_p "t"

# start building page ----------------------------------------

set page_name "Add or update comments on table $owner.$object_name"

set page_content "
[ad_header $page_name]
<h2>$page_name</h2>

[ad_context_bar [list "../users/" "Users"] \
	[list "../users/user-owned-objects" "Object Ownership"] \
	[list "../users/one-user-specific-objects?owner=$owner&object_type=TABLE" "Tables"] \
	[list "describe-table?object_name=$owner.$object_name" "One Table"] \
	"Add comment"]

<hr>
<form method=post action=\"add-comments-2\">
<input type=hidden name=object_name value=$owner.$object_name>
<p>
"

# we do two seperate queries: one for the table (0 or 1)
# and one for the columns (0, 1, or many)
# note that these same queries are similar to 
# those run in /objects/describe-table.tcl, excpet
# I do not have the not null conditions

set table_comment_query "
-- /objects/add-comments.tcl
-- get table comments
-- 
select
     dtc.comments as table_comment
from
     DBA_TAB_COMMENTS dtc
where
     dtc.owner=:owner 
and  dtc.table_name=:object_name
     -- do NOT need to make sure there really is a comment
-- and  dtc.comments is not null
"
if { [string compare $show_sql_p "t" ]==0 } {
    append page_content "<!-- $table_comment_query -->\n"
}

set column_comment_query "
-- /objects/add-comments.tcl
-- get column comments
select
     dtc.column_id,
     dtc.column_name,
     dcc.comments as column_comment
from
     DBA_COL_COMMENTS dcc,
     dba_tab_columns dtc
where
     -- join dtc to dcc
     -- dtc is getting involved so I can order by column_id
     dcc.owner = dtc.owner
and  dcc.table_name = dtc.table_name
and  dcc.column_name = dtc.column_name
     -- specify table to dcc
and  dcc.owner=:owner
and  dcc.table_name=:object_name
     -- specify table to dtc
     -- this is obviuosly redundant (given the join),
     -- but it helps performance on these Oracle 
     -- data dictionary views
and  dtc.owner=:owner
and  dtc.table_name=:object_name
     -- do NOT need to make sure there really is a comment
-- and  dcc.comments is not null
order by 
     dtc.column_id
"
if { [string compare $show_sql_p "t" ]==0 } {
    append page_content"<!-- $column_comment_query -->\n"
}

set table_comment ""

db_0or1row table_comment_query $table_comment_query 

# write user input text box for table comment
# need to quote value arg in case it contains spaces
append page_content "
<p>Table: $object_name <input type=submit value=\"update all\"></p><textarea cols=40 rows=6 name=\"table_comment\" wrap=VIRTUAL value=\"$table_comment\">$table_comment</textarea>
"

# run column query and output rows as form text areas
# with comuted names.  I create variable names like
# "columnComment_1", etc. so the "...-2" page needs
# to know about this format.  bind_vars are same as
# previously defined

db_foreach column_comment_query $column_comment_query {
    append page_content "
    <p>Column $column_id: $column_name <input type=submit value=\"update all\"></p><textarea cols=40 rows=6 name=\"dynamic.columnComment_$column_id\" wrap=VIRTUAL value=\"$column_comment\">$column_comment</textarea>
    "
}

append page_content "
</form>
[ad_admin_footer]
"

doc_return 200 text/html $page_content
