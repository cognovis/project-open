# /www/admin/monitoring/cassandracle/objects/add-comments-2.tcl

ad_page_contract {

    @param object_name a string owner.table_name
    @param table_comment the comment to add on the table
    @param dynamic an array of column comments (a classic example of
           a bad variable name)

    @author Micheal Bryzek (mbryzek@arsdigita.com)
    @cvs-id $Id: add-comments-2.tcl,v 1.1.1.2 2006/08/24 14:41:40 alessandrol Exp $

} {
    object_name:notnull
    table_comment:notnull
    dynamic:array
}

# start processing --------------------------------------------------------

set object_info [split $object_name .]
set owner [lindex $object_info 0]
set object_name [lindex $object_info 1]

# table ----------------------------------------------------------------------
# update table comment

set target "$owner.$object_name"
ns_log Notice "DRH->$target"
set table_sql "
-- update table comment in a redirect page
-- /objects/add-comments-2.tcl
comment on table :target is :table_comment
"
db_dml table_comment_update $table_sql

# columns ---------------------------------------------------------------------

# for columns, we need to 1) know how manty there are, 
# and 2) know their names. This allows us to loop as needed.
set get_column_info_sql "
-- get column name and id in preparation 
-- for comment updates in a redirect page
-- /objects/add-comments-2.tcl
select
     dtc.column_id,
     dtc.column_name
from
     dba_tab_columns dtc
where
     -- specify table to dtc
     dtc.owner=:owner
and  dtc.table_name=:object_name
order by 
     dtc.column_id
"

db_foreach update_table_comment_loop $get_column_info_sql {

    set column_comment $dynamic(columnComment_$column_id)

    set target "$owner.$object_name.$column_name"
    set sql_query "comment on column :target is :column_comment"
    db_dml column_comment_update $sql_query
}


# return to main table page
ad_returnredirect "describe-table?object_name=$owner.$object_name"



