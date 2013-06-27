# packages/intranet-core/tcl/intranet-view-procs.tcl

## Copyright (c) 2013, cognovís GmbH, Hamburg, Germany
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see
# <http://www.gnu.org/licenses/>.
# 

ad_library {
    
    Procedures to handle display of views nicely
    
    @author Malte Sussdorff (malte.sussdorff@cognovis.de)
    @creation-date 2013-05-19
    @cvs-id $Id$
}

ad_proc -public im_view_set_def_vars { 
    {-view_id ""}
    {-view_name ""}
    {-order_by ""}
    {-url ""}
    -array_name:required
 } {
     Set the vars defining a view for reuse in the column definition and the SQL statements
     @return extra_select, extra_from ....
} {

    set user_id [ad_maybe_redirect_for_registration]
    set admin_p [im_is_user_site_wide_or_intranet_admin $user_id]
    
    if {"" == $view_id} {
	if {"" == $view_name} {
	    ad_return_complaint 1 "You have to either provide view_name or view_id"
	    return
	}
	set view_id [db_string get_view_id "select view_id from im_views where view_name=:view_name" -default 0]
    }
    
    if {!$view_id } {
	ad_return_complaint 1 "<b>Unknown View Name</b>:<br>
    The view '$view_name' is not defined. <br>
    Maybe you need to upgrade the database. <br>
    Please notify your system administrator."
	return
    }

    upvar 1 $array_name view_array
    if { [info exists view_array] } {
	unset view_array
    }
    set column_headers [list]
    set column_vars [list]
    set column_headers_admin [list]
    set extra_selects [list]
    set extra_froms [list]
    set extra_wheres [list]
    set view_order_by_clause ""
    
    set column_sql "
select
	vc.*
from
	im_view_columns vc
where
	view_id=:view_id
	and group_id is null
order by
	sort_order"

    db_foreach column_list_sql $column_sql {
	
	set admin_html ""
	if {$admin_p} { 
	    set admin_url [export_vars -base "/intranet/admin/views/new-column" {column_id return_url}]
	    set admin_html "<a href='$admin_url'>[im_gif wrench ""]</a>" 
	}
	
	if {"" == $visible_for || [eval $visible_for]} {
	    lappend column_headers "[lang::util::localize $column_name]"
	    lappend column_vars "$column_render_tcl"
	    lappend column_headers_admin $admin_html
	    if {"" != $extra_select} { lappend extra_selects $extra_select }
	    if {"" != $extra_from} { lappend extra_froms $extra_from }
	    if {"" != $extra_where} { lappend extra_wheres $extra_where }
	    if {"" != $order_by_clause} {
		lappend order_by_clauses $order_by_clause
	    } elseif {"" != $variable_name} {
		lappend order_by_clauses $variable_name
	    } else {
		# Desparate ploy to find the correct order by
		lappend order_by_clauses [string trim [lindex [split $column_render_tcl] 0] "$"]
	    }
	}
    }

    # Prepare the column headers
    set column_headers_pretty [list]
    set ctr 0
    foreach col $column_headers {
	set wrench_html [lindex $column_headers_admin $ctr]
	regsub -all " " $col "_" col_txt
	set col_txt [lang::message::lookup "" intranet-core.$col_txt $col]
	set order_by_clause [lindex $order_by_clauses $ctr] 
	set old_order_bys [split $order_by ","]	
	if {$order_by_clause == [lindex $old_order_bys 0]} {
	    lappend column_headers_pretty "$col_txt$wrench_html"
	} else {
	    # If we have already an order_by, sort by that secondarily
	    # This way the user can click through multiple orderings
	    # and gets a good combination
	    set order_bys [list $order_by_clause]
	    foreach old_order_by $old_order_bys {
		if {[lsearch $old_order_by $order_bys]<0} {
		    # This clause wasn't found already, so just append
		    # it
		    lappend order_bys $old_order_by
		}
	    }
	   
	    #set col [lang::util::suggest_key $col]
	    lappend column_headers_pretty "<a href=\"${url}&order_by=[join $order_bys ","]\">$col_txt</a>$wrench_html"
	}
	incr ctr
    }

    # Build the array
    set view_array(column_headers) $column_headers
    set view_array(column_headers_pretty) $column_headers_pretty
    set view_array(column_vars) $column_vars
    set view_array(column_headers_admin) $column_headers_admin
    set view_array(extra_selects) $extra_selects
    set view_array(extra_froms) $extra_froms
    set view_array(extra_wheres) $extra_wheres
    set view_array(order_by_clause) $view_order_by_clause

}

ad_proc -public im_view_process_def_vars { 
    -array_name:required
} {
     Process the vars of the table to correctly format the headers and join the extra statements
    This is separate from the define statement, so you can add additional elements in the code.

    Will set the following in the array:
    - table_header_html
    - extra_selects 
    - extra_froms
    - extra_wheres
} {
    upvar 1 $array_name view_array
    set view_array(table_header_html) ""
    set view_array(extra_froms_sql) ""
    set view_array(extra_selects_sql) ""
    set view_array(extra_wheres_sql) ""
    set view_array(extra_group_by_sql) ""

    foreach col $view_array(column_headers_pretty) {
	ds_comment "column: $col"
	# Append the months to the header
	append view_array(table_header_html) "<td class=rowtitle>$col</td>\n"
    }

    foreach extra_from $view_array(extra_froms) {
	append view_array(extra_froms_sql) ",$extra_from \n\t"
    }

    foreach extra_select $view_array(extra_selects) {
	append view_array(extra_selects_sql) ",$extra_select \n\t"
	append view_array(extra_group_by_sql) ",[lindex [split $extra_select " "] 0] \n\t"
    }
    
    foreach extra_where $view_array(extra_wheres) {
	append view_array(extra_wheres_sql) ",$extra_where \n\t"
    }

}

