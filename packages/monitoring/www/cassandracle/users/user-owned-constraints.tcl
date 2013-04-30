# /admin/monitoring/cassandracle/users/user-owned-constraints.tcl

ad_page_contract {
    Display summary of constraints that have been defined by each user

    @author Dave Abercrombie (abe@arsdigita.com)
    @creation-date 29 January 2000
    @cvs-id $Id: user-owned-constraints.tcl,v 1.1.1.2 2006/08/24 14:41:42 alessandrol Exp $
} {
}

set page_name "User Owned Constraints"

# build the SQL and write out as comment
set constraint_query "
-- cassandracle/users/user-owned-constraints.tcl
select 
     dc.owner,
     -- use decode to decode these codes!
     decode(dc.constraint_type,'C','table check constraint',
                               'P','primary key',
                               'U','unique key',
                               'R','referential integrity',
                               'V','view check option',
                               'O','view with read only',
                               'unknown') as decoded_constraint_type,
     count(dc.constraint_name) as constraint_count
from 
     dba_constraints dc
where
     -- do not need system tables
     dc.owner not in ('SYS','SYSTEM')
group by
    dc.owner,
    dc.constraint_type
order by
    dc.owner,
    dc.constraint_type
"

set page_content "

[ad_header "$page_name"]

<h2>$page_name</h2>

[ad_context_bar [list "[ad_conn package_url]/cassandracle" "Cassandracle"] [list "[ad_conn package_url]/cassandracle/users/" "Users"]  "Constraints"]

<!-- version 1.2, 2000-01-29, Dave Abercrombie -->

<hr>
<!-- $constraint_query -->
"

# I do not want to show an empty table,
# so I initialize a flag to a value of "f"
# then I flip it to 't' on the first row (after doing table header)
set at_least_one_row_already_retrieved "f"

# run query

db_foreach mon_all_constraints $constraint_query {

    if { [string compare $at_least_one_row_already_retrieved "f"]==0 } {

        # we get here only on first row,
        # so I start the table and flip the flag
        set at_least_one_row_already_retrieved "t"

	# I want to suppress display of owner on rows after the first
	# one in which it shows up - I will use this for comparison
	set last_row_owner ""

        # table title
        append page_content "<p>This instance has the following constraints</p>"

        # specify output columns
        # 1
        set description_columns [list "Owner" ] 
        lappend description_columns   "Type" 
        lappend description_columns   "Count" 
        set column_html ""
        foreach column_heading $description_columns {
            append column_html "<th>$column_heading</th>"
        }

        # begin main table
        append page_content "
        <table>
        <tr>$column_html</tr>
        "

	# end of first row tricks
    }

    # start row
    set row_html "<tr>\n"

    # 1) owner
    if { [string compare $owner $last_row_owner]==0 } {
	# same owner as before so we suppress its display
	append row_html "<td>&nbsp;</td>"
    } else {
	# new owner, so we store and display
	set last_row_owner $owner
	append row_html "   <td><a href=\"./one-user-constraints?owner=$owner\">$owner</a></td>\n"
    }

    # 2) decoded_constraint_type
    append row_html "   <td>$decoded_constraint_type</td>\n"

    # 3) constraint_count
    append row_html "   <td align=right>$constraint_count</td>\n"

    # close up row
    append row_html "</tr>\n"

    # write row
    append page_content $row_html
}

# close up table if present, otherwise indicate that there were none
if { [string compare $at_least_one_row_already_retrieved "t"]==0 } {
    append page_content "</table><p></p>\n"
} else {
    append page_content "<p>This instance has no constraints! Why?</p>"
}

# I am thinking about adding a table of disabled constraints

append page_content "
<hr>
<H4>More information:</h4>
<p>See Oracle documentation about view <a target=second href=\"http://oradoc.photo.net/ora81/DOC/server.815/a67790/ch2.htm#1175\">dba_constraints</a> on which this page is based.</p>
[ad_admin_footer]
"


doc_return 200 text/html $page_content