# /admin/monitoring/cassandracle/objects/describe-table.tcl

ad_page_contract {
    Displays info about objects of a particular type owned by a particular user.
    Called from ../users/one-user-specific-objects.tcl

    @cvs-id $Id: describe-table.tcl,v 1.1.1.2 2006/08/24 14:41:40 alessandrol Exp $
} {
    object_name
}



# check arguments -----------------------------------------------------

# it is not clear to me whey we have one object_name argument here
# of the format OWNER.TABLE_NAME that needs to be parsed, rather than 
# two seperate arguments?

# $object_name   REQUIRED ARGUMENT
set object_info [split $object_name .]
set owner [lindex $object_info 0]
set object_name [lindex $object_info 1]

# check parameter to see if we want to display SQL as comments
# actually hardcoded now during development, but will use ns_info later

set show_sql_p "t"

# arguments OK, get database handle, start building page ----------------------------------------

set page_name "Description of table $owner.$object_name"


set page_content "

[ad_header "$page_name"]

<h2>$page_name</h2>

[ad_context_bar [list "[ad_conn package_url]/cassandracle" "Cassandracle"] [list "[ad_conn package_url]/cassandracle/users/" "Users"] [list "[ad_conn package_url]/cassandracle/users/user-owned-objects.tcl" "Objects" ] [list "[ad_conn package_url]/cassandracle/users/one-user-specific-objects.tcl?owner=$owner&object_type=TABLE" "One Object Type"] "One Object"]

<!-- version 1.1, 1999-12-08, Dave Abercrombie, abe@arsdigita.com -->
<hr>
<a NAME=\"columns\"></a>
"

# tabular display of column names, datatypes, etc -------------------------------
# the main table that displays column datatype information
# also shows foreign keys and primary keys. The foreign
# key is shown as a link to the appropriate parent table.
# The SQL is rather complicated. It does an outer join
# from the list of columns to two subqueries: one for
# priomary keys, and the other for foreign keys. Since
# the SQL and subqueries are complicated, I use Tcl to
# form the subqueries, send them out as HTML comments,
# and include them in the main query. This makes the main
# query easier to maintain, and the subqueries can be snagged
# from the browser 'view source' and run as standalone
# queries for testing, etc. 

# build the foreign key subquery, display as comment, then use below
set fk_subquery "
     -- /objects/describe-table.tcl
     -- subquery to get foreign key data for a given child table
     -- can be run as stand-alone 
     select
          chld_tbl.table_name        as child_table_name,
          chld_col.column_name       as child_column_name,
          chld_tbl.constraint_name   as child_fk_constraint_name,
          prnt_tbl.table_name        as parent_table_name,
          chld_tbl.r_constraint_name as parent_pk_constraint_name,
          '(FK)'                     as fk_display_flag
     from
          dba_constraints prnt_tbl,
          dba_cons_columns chld_col,
          dba_constraints chld_tbl
     where
          -- start with child table name and owner
          chld_tbl.owner = :owner
     and  chld_tbl.table_name = :object_name
          -- get only foreign key constraints for child table
     and  chld_tbl.constraint_type = 'R'
          -- get column names for each constraint
     and  chld_tbl.constraint_name = chld_col.constraint_name
          -- join child FK constraint to parent PK constraint
     and  chld_tbl.r_constraint_name = prnt_tbl.constraint_name
          -- The remaining two criteria help performance.
          -- Our test case runs in 0.10 second with BOTH criteria. we
          -- gave up after 20 seconds without prnt_tbl criterion, and
          -- it took about six seconds without chld_tbl criterion.
          -- Our use of these critera limits our display to foreign keys 
          -- and parents that have the same owner as the child table.
     and  prnt_tbl.owner = :owner
     and  chld_col.owner = :owner
"
if { [string compare $show_sql_p "t" ]==0 } {
    append page_content "<!-- $fk_subquery -->\n"
}

set pk_subquery "
     -- /objects/describe-table.tcl
     -- subquery to get primary key data for a given table
     -- can be run as stand-alone 
     select
          dc1.table_name,
          dcc1.column_name,
          dcc1.constraint_name,
          '(PK)' as pk_display_flag
     from
          dba_cons_columns dcc1,
          dba_constraints  dc1
     where
          -- select constraints for this table
          dc1.owner = :owner
     and  dc1.table_name = :object_name
          -- limit to only primary key constraints
     and  dc1.constraint_type = 'P'
          -- link to dba_cons_columns to get column names
     and  dc1.constraint_name = dcc1.constraint_name
          -- specify owner for preformance (takes 5 seconds without)
     and  dcc1.owner = :owner
"
if { [string compare $show_sql_p "t" ]==0 } {
    append page_content "<!-- $pk_subquery -->\n"
}

set ak_constraint_subquery "
     -- /objects/describe-table.tcl
     -- subquery to get alternate keys implemented as constraints
     -- can be run as stand-alone 
     select
          dc2.table_name,
          dcc2.column_name,
          dcc2.constraint_name,
          '(AKc)' as akc_display_flag
     from
          dba_cons_columns dcc2,
          dba_constraints  dc2
     where
          -- select constraints for this table
          dc2.owner = :owner
     and  dc2.table_name = :object_name
          -- limit to only unique constraints
     and  dc2.constraint_type = 'U'
          -- link to dba_cons_columns to get column names
     and  dc2.constraint_name = dcc2.constraint_name
          -- specify owner for preformance (takes 5 seconds without)
     and  dcc2.owner = :owner
"
if { [string compare $show_sql_p "t" ]==0 } {
    append page_content "<!-- $ak_constraint_subquery -->\n"
}

set ak_index_subquery "
     -- /objects/describe-table.tcl
     -- subquery to get alternate keys implemented as indexes
     -- can be run as stand-alone 
     select
          di.table_name,
          dic.column_name,
          dic.index_name,
          '(AKi)' as aki_display_flag
     from
          dba_ind_columns dic,
          dba_indexes  di
     where
          -- select indexes for this table
          di.owner='ACS'
     and  di.table_name = :object_name
          -- limit to only unique indexes
     and  di.uniqueness = 'UNIQUE'
          -- link to dba_ind_columns to get column names
     and  di.index_name = dic.index_name
          -- specify owner for preformance (takes 5 seconds without)
     and  dic.table_owner = :owner
          -- but we do not want primary key index constraints
     and not exists
         (select
               dc3.constraint_name
          from
               dba_constraints  dc3
          where
               -- PK constrain name = unique index name
               dc3.constraint_name =  di.index_name
               -- the following are redundant, but help performance
               -- select constraints for this table
          and  dc3.owner = :owner
          and  dc3.table_name = :object_name
               -- limit to only primary key constraints
          and  dc3.constraint_type = 'P')
"
if { [string compare $show_sql_p "t" ]==0 } {
    append page_content "<!-- $ak_index_subquery -->\n"
}

# build the SQL and write out as comment
set main_query "
-- /objects/describe-table.tcl
-- includes pk_subquery and fk_subquery
select
     dtc.column_name, 
     dtc.data_type, 
     dtc.data_scale, 
     dtc.data_precision, 
     dtc.data_length,
     dtc.nullable,
     pk.pk_display_flag,
     fk.fk_display_flag,
     fk.parent_table_name,
     akc.akc_display_flag,
     aki.aki_display_flag
from
     DBA_TAB_COLUMNS dtc,
     ($fk_subquery) fk,
     ($pk_subquery) pk,
     ($ak_constraint_subquery) akc,
     ($ak_index_subquery) aki
where
     dtc.owner = :owner
and  dtc.table_name= :object_name
and  dtc.table_name = pk.table_name(+)
and  dtc.column_name = pk.column_name(+)
and  dtc.table_name = fk.child_table_name(+)
and  dtc.column_name = fk.child_column_name(+)
and  dtc.table_name = akc.table_name(+)
and  dtc.column_name = akc.column_name(+)
and  dtc.table_name = aki.table_name(+)
and  dtc.column_name = aki.column_name(+)
order by
     dtc.column_id
"
if { [string compare $show_sql_p "t" ]==0 } {
    append page_content "<!-- $main_query -->\n"
}

# specify output columns       1             2          3       4     5     6       7
set description_columns [list "Column Name" "Datatype" "NULL?" "PK?" "FK?" "AK(c)?" "AK(i)?"]
set column_html ""
foreach column_heading $description_columns {
    append column_html "<th>$column_heading</th>"
}

# begin main table
append page_content "
<table border=1>
<tr>$column_html</tr>
"

# run query and output rows

db_foreach mon_table_describe $main_query {
    
    # start row
    set row_html "<tr>\n"

    # 1) column_name
    append row_html "   <td>$column_name</td>\n"

    # 2) datatype
    set datatype_list [list $data_type $data_scale $data_precision $data_length ]
    append row_html "   <td>[cassandracle_format_data_type_column $datatype_list]</td>\n"

    # 3) null - replace with non-breaking space if Y, otherwise say NOT NULL
    if { [string compare $nullable "Y"]==0 } {
	set nullable "&nbsp;"
    } else {
	set nullable "NOT NULL"
    }
    append row_html "   <td>$nullable</td>\n"

    # 4) PK - replace with non-breaking space if null
    if { [string compare $pk_display_flag ""]==0 } {
	set pk_display_flag "&nbsp;"
    }
    append row_html "   <td>$pk_display_flag</td>\n"

    # 5) FK - replace with non-breaking space if null
    #         otherwise make a link to parent table (assumes same owner)
    if { [string compare $fk_display_flag ""]==0 } {
	set fk_display_flag "&nbsp;"
    } else {
	set fk_display_flag "<a href=\"./describe-table?object_name=$owner.$parent_table_name\">$fk_display_flag</a>"
    }
    append row_html "   <td>$fk_display_flag</td>\n"

    # 6) AK constraint - replace with non-breaking space if null
    if { [string compare $akc_display_flag ""]==0 } {
	set akc_display_flag "&nbsp;"
    }
    append row_html "   <td>$akc_display_flag</td>\n"

    # 6) AK index - replace with non-breaking space if null
    if { [string compare $aki_display_flag ""]==0 } {
	set aki_display_flag "&nbsp;"
    }
    append row_html "   <td>$aki_display_flag</td>\n"

    # close up row
    append row_html "</tr>\n"

    # write row
    append page_content $row_html
}

# close up table 
append page_content "</table>
<a NAME=\"comments\"></a>
<hr>
"

# display comments on tables and columns, if any exist -------------------------------

# we do two seperate queries: one for the table (0 or 1)
# and one for the columns (0, 1, or many)
# note that these same queries are run in /objects/add-comments.tcl

set table_comment_query "
-- /objects/describe-table.tcl
-- get table comments
select
     dtc.comments as table_comment
from
     DBA_TAB_COMMENTS dtc
where
     dtc.owner = :owner
and  dtc.table_name= :object_name
and  dtc.comments is not null
"
if { [string compare $show_sql_p "t" ]==0 } {
    append page_content "<!-- $table_comment_query -->\n"
}

# run query (already have db handle) and row 
# if it exists as a paragraph of plain text
# (hmmm... one could probably put some strange HTML
# in the comment that could be good or bad!)
db_foreach mon_table_comments $table_comment_query {
    append page_content "<p>$table_comment</p>"
}

set column_comment_query "
-- /objects/describe-table.tcl
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
and  dcc.owner= :owner
and  dcc.table_name= :object_name
     -- specify table to dtc
     -- this is obviuosly redundant (given the join),
     -- but it helps performance on these Oracle 
     -- data dictionary views
and  dtc.owner=:owner
and  dtc.table_name=:object_name
     -- make sure there really is a comment
and  dcc.comments is not null
order by 
     dtc.column_id
"
if { [string compare $show_sql_p "t" ]==0 } {
    append page_content "<!-- $column_comment_query -->\n"
}

# run query and output rows as emphasized text (not table)
db_foreach mon_column_comments $column_comment_query {
    append page_content "<p><em>$column_name:</em> $column_comment<p>"
}

append page_content "
<p><a href=\"add-comments?object_name=$owner.$object_name\">Add or update</a> comments on this table or its columns</p>
" 

append page_content "<a NAME=\"child_tables\"></a>\n"
# display child tables, if any exist -------------------------------
append page_content "<hr>"

# it would be nice to do this as a CONNECT BY query to get all children, 
# but dba_constraints is a view, and you will get a ORA-01437 error.
# it might be possible to wrte some procedure or use a tmp table, but later...

# build the SQL and write out as comment
set child_query "
-- /objects/describe-table.tcl
-- get child tables based on actual foreign key constraints
select 
     c2.table_name as child, 
     c2.constraint_name as fk
from 
     dba_constraints c1,
     dba_constraints c2
where 
     -- specify parent table
     c1.table_name = :object_name
and  c1.owner = :owner
     -- get primary key of this table (parent)
and  c1.constraint_type = 'P'
     -- get foreign key constraints in children 
     -- equal to parent primary key
and  c2.constraint_type = 'R'
and  c2.r_constraint_name = c1.constraint_name
     -- redundantly specifying this owner
     -- speeds up query by a factor of 30 or so
and  c2.owner = :owner
order by
     c2.table_name
"

if { [string compare $show_sql_p "t" ]==0 } {
    append page_content "<!-- $child_query -->\n"
}

# I do not want to show an empty table,
# so I initialize a flag to a value of "f"
# then I flip it to 't' on the first row (after doing table header)
set at_least_one_row_already_retrieved "f"

# run query (already have db handle) 

db_foreach mon_child_tables $child_query {

    if { [string compare $at_least_one_row_already_retrieved "f"]==0 } {

	# we get here only on first row,
	# so I start the table and flip the flag

	set at_least_one_row_already_retrieved "t"

	# table title
	append page_content "<p>This table has the following child tables.</p>"

	# specify output columns       1             2          
	set description_columns [list "Child Table" "Constraint" ]
	set column_html ""
	foreach column_heading $description_columns {
	    append column_html "<th>$column_heading</th>"
	}

	# begin main table
	append page_content "
	<table border=1>
	<tr>$column_html</tr>
	"
    # end of first row tricks
    }

    append page_content "
    <tr>
       <td><a href=\"./describe-table?object_name=$owner.$child\">$child</a></td>
       <td>$fk</td>
    </tr>
    "
}

# close up table if present, otherwise indicate that there were none
if { [string compare $at_least_one_row_already_retrieved "t"]==0 } {
    append page_content "</table><p></p>\n"
} else {
    append page_content "<p>This table has no child tables.</p>"
}

append page_content "<a NAME=\"constraints\"></a>\n"
# display constraints, if any exist -------------------------------------------
append page_content "<hr>"

# build the SQL and write out as comment
set constraint_query "
-- /objects/describe-table.tcl
-- I include all dba_constraint columns, but comment out those which I do not need
select
     dc.constraint_name,
     dcc.column_name,
     dc.constraint_type,
     -- use decode to decode these codes!
     decode(dc.constraint_type,'C','table check constraint',
                               'P','primary key',
                               'U','unique key',
                               'R','referential integrity',
                               'V','view check option',
                               'O','view with read only',
                               'unknown') as decoded_constraint_type,
     dc.search_condition,
     dc.r_owner,
     dc.r_constraint_name,
     -- get table name so we can make a link
     dc2.table_name as r_table_name,
     dc.delete_rule,
     dc.status,
     -- dc.deferrable,
     -- dc.deferred,
     dc.validated,
     -- dc.generated,
     -- dc.bad,
     dc.last_change
from
     dba_constraints dc,
     -- these inline views speed up performance drastically in databases
     -- with many objects, but they do assume that parent are owned
     -- by the same owner as the child table
     (select table_name, constraint_name 
      from dba_constraints 
      where owner = :owner) dc2,
     (select column_name, constraint_name 
      from dba_cons_columns 
      where owner = :owner 
      and table_name = :object_name) dcc
where
     -- join dc and dcc
     dc.constraint_name = dcc.constraint_name
     -- user (Tcl) specifies table and owner
and  dc.owner = :owner
and  dc.table_name = :object_name
     -- obviously need outer join here since most
     -- constraints are NOT foreign keys
and  dc.r_constraint_name = dc2.constraint_name (+)
order by
     dc.constraint_name,
     dcc.column_name
"

if { [string compare $show_sql_p "t" ]==0 } {
    append page_content "<!-- $constraint_query -->\n"
}

# I do not want to show an empty table,
# so I initialize a flag to a value of "f"
# then I flip it to 't' on the first row (after doing table header)
set at_least_one_row_already_retrieved "f"

# run query (already have db handle)
db_foreach mon_constraints $constraint_query {

    if { [string compare $at_least_one_row_already_retrieved "f"]==0 } {

        # we get here only on first row,
        # so I start the table and flip the flag

        set at_least_one_row_already_retrieved "t"

        # table title
        append page_content "<p>This table has the following constraints</p>"

        # specify output columns       1            2        3      4           5        6             7        8          9
        set description_columns [list "Constraint" "Column" "Type" "Condition" "Parent" "Delete Rule" "Status" "Validity" "Changed" ]
        set column_html ""
        foreach column_heading $description_columns {
            append column_html "<th>$column_heading</th>"
        }

        # begin main table
        append page_content "
        <table border=1>
        <tr>$column_html</tr>
        "

    # end of first row tricks
    }

    # start row
    set row_html "<tr>\n"

    # 1) constraint_name
    append row_html "   <td>$constraint_name</td>\n"

    # 2) column_name - set lower case since not in cut-and-paste
    set column_name [string tolower $column_name]
    append row_html "   <td>$column_name</td>\n"

    # 3) decoded_constraint_type - set lower case since not on cut-paste-paste
    set decoded_constraint_type [string tolower $decoded_constraint_type]
    append row_html "   <td>$decoded_constraint_type</td>\n"

    # 4) search_condition - replace with non-breaking space if null
    if { [empty_string_p $search_condition] } {
	set search_condition "&nbsp;"
    } 
    append row_html "   <td>$search_condition</td>\n"

    # 5) r_table_name - replace with non-breaking space if null
    # othwise replace with link to parent
    if { [empty_string_p $r_table_name] } {
	set r_table_name "&nbsp;"
    } else {
	set r_table_name "<a href=\"./describe-table?object_name=$r_owner.$r_table_name\">[string tolower $r_table_name]</a>"
    }
    append row_html "   <td>$r_table_name</td>\n"

    # 6) delete_rule - replace with non-breaking space if null
    #    else set to lower to save space since will not be cut-and-paste
    if { [empty_string_p $delete_rule] } {
	set delete_rule "&nbsp;"
    } else {
	set delete_rule [string tolower $delete_rule]
    }
    append row_html "   <td>$delete_rule</td>\n"

    # 7 status - set to lower case since it will not be cut-and-paste
    # never null
    set status [string tolower $status]
    append row_html "   <td>$status</td>\n"

    # 8 validated - set to lower case since it will not be cut-and-paste
    # never null
    set validated [string tolower $validated]
    append row_html "   <td>$validated</td>\n"

    # 9 last_change - never null
    append row_html "   <td>$last_change</td>\n"

    # close up row
    append row_html "</tr>\n"

    # write row
    append page_content "$row_html"
}

# close up table if present, otherwise indicate that there were none
if { [string compare $at_least_one_row_already_retrieved "t"]==0 } {
    append page_content "</table><p></p>\n"
} else {
    append page_content "<p>This table has no constraints! Why?.</p>"
}

append page_content "
<p>See <a href=\"../users/one-user-constraints?owner=$owner\">other constraints</a> for this user.</p>\n"

append page_content "
[ad_admin_footer]
"


doc_return 200 text/html $page_content
