# /packages/intranet-timesheet/tcl/intranet-timesheet-procs.tcl
#
# Copyright (C) 1998-2004 various parties
# The code is based on ArsDigita ACS 3.4
#
# This program is free software. You can redistribute it
# and/or modify it under the terms of the GNU General
# Public License as published by the Free Software Foundation;
# either version 2 of the License, or (at your option)
# any later version. This program is distributed in the
# hope that it will be useful, but WITHOUT ANY WARRANTY;
# without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.
# See the GNU General Public License for more details.

ad_library {
    Procs used in riskmanagement module

    @author unknown@arsdigita.com
    @author mai-bee@gmx.net
}

# ---------------------------------------------------------------------
# Analyze logged hours
# ---------------------------------------------------------------------

ad_proc -public im_risk_project_component {user_id project_id} {
    Creates a view of the risks concerning this project an provied a link
    to a graphical representation of this data. This is a classical list page.
} {
    # defaults
    set view_name "risk_list_home"

    # check permissions
    if {![im_permission $user_id "view_risks"]} {
        return ""
    }
    set return_html ""

    # Define Table Columns
    set view_id [db_string get_view_id "select view_id from im_views where view_name=:view_name"]
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
        sort_order"

    db_foreach column_list_sql $column_sql {
	if {$visible_for == "" || [eval $visible_for]} {
        lappend column_headers "$column_name"
        lappend column_vars "$column_render_tcl"
	}
    }

    # define sql
    set sql "
select
        risk_id,
        type as risk_type,
        im_category_from_id(type) as risk_type_name,
        title as risk_title,
        probability as risk_probability,
        impact as risk_impact
from
        im_risks
where
        project_id = :project_id
order by
        title"

    # Format the List Table Header

    # Set up colspan to be the number of headers + 1 for the # column
    set colspan [expr [llength $column_headers] + 1]

    append return_html "<table border=0><tr><td colspan=$colspan align=center class=rowtitle>Risks</td><tr>\n"

    append return_html "<tr>\n"
    foreach col $column_headers {
        append return_html "<td class=rowtitle>$col</td>\n"
    }
    append return_html "</tr>\n"

    # add data
    set table_body_html ""
    set bgcolor(0) " class=roweven "
    set bgcolor(1) " class=rowodd "
    set ctr 0
    db_foreach risk_query $sql {
       #Append together a line of data based on the "column_vars" parameter list
       append table_body_html "<tr$bgcolor([expr $ctr % 2])>\n"
       foreach column_var $column_vars {
          append table_body_html "\t<td valign=top>"
          set cmd "append table_body_html $column_var"
          eval $cmd
          append table_body_html "</td>\n"
       }
       append table_body_html "</tr>\n"
       incr ctr
    }

    # Show a reasonable message when there are no result rows:
    if { $ctr == 0 } {
       set table_body_html "
        <tr><td colspan=$colspan class=rowodd><div align=center><i>No risks specified for this project</i></div></td></tr>"
    }
    append return_html $table_body_html

    append return_html "</table>"

    # add links to graph and to form to add risks
    append return_html "<a href=\"/intranet-riskmanagement/graph?project_id=$project_id\">See graphical representation</a>"
    if {[im_permission $user_id "add_risks"]} {
        append return_html "<br><a href=\"/intranet-riskmanagement/view?curr_project_id=$project_id\">Add risk</a>"
    }

    return "$return_html<br><br>"
}
