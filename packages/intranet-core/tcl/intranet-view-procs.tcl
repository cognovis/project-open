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
	    set url [export_vars -base "/intranet/admin/views/new-column" {column_id return_url}]
	    set admin_html "<a href='$url'>[im_gif wrench ""]</a>" 
	}
	
	if {"" == $visible_for || [eval $visible_for]} {
	    lappend column_headers "[lang::util::localize $column_name]"
	    lappend column_vars "$column_render_tcl"
	    lappend column_headers_admin $admin_html
	    if {"" != $extra_select} { lappend extra_selects $extra_select }
	    if {"" != $extra_from} { lappend extra_froms $extra_from }
	    if {"" != $extra_where} { lappend extra_wheres $extra_where }
	    if {"" != $order_by_clause && $order_by==$column_name} {
		set view_order_by_clause $order_by_clause
	    }
	}
    }

    # Build the array
    set view_array(column_headers) $column_headers
    set view_array(column_vars) $column_vars
    set view_array(column_headers_admin) $column_headers_admin
    set view_array(extra_select) $extra_select
    set view_array(extra_from) $extra_from
    set view_array(extra_where) $extra_where
    set view_array(order_by_clause) $view_order_by_clause

}

