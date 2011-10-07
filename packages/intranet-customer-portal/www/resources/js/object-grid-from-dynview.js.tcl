# /packages/intranet-customer-portal/www/resources/js/object-grid-from-dynview.js.tcl
#
# Copyright (C) 2011, ]project-open[
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

ad_page_contract {
    List all projects with dimensional sliders.

    @param dynview
    @author klaus.hofeditz@project-open.com
} {
    { view_name "" }
    { object_table "" }
}

# ---------------------------------------------------------------
# Security 
# ---------------------------------------------------------------

# Prevents SQL injections and provides sanity check 
if { ![db_string no_tables "select count(*) from pg_tables where tablename = :object_table"] } { ad_return_complaint 1 "Table not found"}

# ---------------------------------------------------------------
# Defaults and settings  
# ---------------------------------------------------------------

set object_table_name $object_table
set dyn_columns [list]

# ---------------------------------------------------------------
# Set column model 
# ---------------------------------------------------------------

# Define the column headers and column contents that
# we want to show:
#
set view_id [db_string get_view_id "select view_id from im_views where view_name=:view_name" -default 0]
if {!$view_id } {
    ad_return_complaint 1 "<b>Unknown View Name</b>:<br>
    The view '$view_name' is not defined. <br>
    Please notify your system administrator."
    return
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


# --------------------------
# Default setting 
# --------------------------

set column_model "var colModel = new Ext.grid.ColumnModel(\[\n"
set json_list [list]
set cnt 0

# -----------------------------------------------------------
# Loop through DynView to create column model & sql for data 
# -----------------------------------------------------------


db_foreach query_name $column_sql {

    # Build list of columns  
    lappend dyn_columns $column_name	

    append column_model "			\{header: \"[eval $column_render_tcl]\""

    switch [lindex $ajax_configuration 0] {
	def {
	    if { ![info exists [lindex $ajax_configuration 1]] } {
		append column_model ", width: auto"		
	    } else {
		append column_model ", width: [lindex $ajax_configuration 1]"
	    }
	    append column_model ", dataIndex: '$column_name'\}\n"
	}

	dropdown {
	    append column_model ", formatter:'lookup'\n""
	        # custom sort
	    append column_model ", sortOptions:\{sortFunction:customDropdownSort\}\n"

	        # add editor
	    append column_model ", editor:ddEditor_[lindex $ajax_configuration 1]\n"
	    # sortable?
	    if { "1" == [lindex $ajax_configuration 4] } {
		            append column_model ", sortable:true"
	    }
	        # resizeable
	    if { "1" == [lindex $ajax_configuration 5] } {
		            append column_model ", resizeable:true"
	    }

	    append editors_init "var ddEditor_[lindex $ajax_configuration 1] = new YAHOO.widget.DropdownCellEditor();\n"
	    append editors_conf "ddEditor_[lindex $ajax_configuration 1].dropdownOptions = \[\n"
	    set key_value_list "[expr [lindex $ajax_configuration 2]]"

	    foreach x $key_value_list {
		append editors_conf "\{value:[lindex $x 0], label:'[lindex $x 1]'\},\n"
	    }
	    set editors_conf [string range $editors_conf 0 [expr [string length $editors_conf]-3]]
	    append editors_conf "\n\];\n ddEditor_[lindex $ajax_configuration 1].render();\n\n"
	}
	link {
	    # sortable?
	    if { "1" == [lindex $ajax_configuration 4] } {
		            append column_model ", sortable:true"
	    }
	    # resizeable
	    if { "1" == [lindex $ajax_configuration 5] } {
		            append column_model ", resizeable:true"
	    }
	} hidden {
	    # works only using function ?? - append column_model ", width:0"
	}
	
	zerovalue {
	    if { "1" == [lindex $ajax_configuration 4] } {
		append column_model ", sortable:true"
	    }
            # resizeable
	    if { "1" == [lindex $ajax_configuration 5] } {
		append column_model ", resizeable:true"
	    }
	}
    }
    append column_model "		\]); \n"   
}


set object_sql "
        select  
		[join $dyn_columns ", "]
        from   
		$object_table_name
"

set valid_vars {excerpt}

db_foreach obj $object_sql {

        set json_row [list]

	foreach dyn_field $dyn_columns {
	        lappend json_row "\$dyn_field"\": \"$$dyn_field\""
	}

        # lappend json_row "\"project_id\": \"$project_id\""
        # lappend json_row "\"project_name\": \"$project_name\""

        foreach v $valid_vars {
                eval "set a $$v"
                regsub -all {\n} $a {\n} a
                regsub -all {\r} $a {} a
                lappend json_row "\"$v\": \"[ns_quotehtml $a]\""
        }

        lappend json_list "{[join $json_row ", "]}"
}


ad_return_complaint 1 $json_list	


# Build record part 


# Wrapping record part 
set json_data = "var myData = \[\n"
append json_data $json_list
append json_data "\];" 


# remove last comma and complete strings
set column_model [string range $column_model 0 [expr [string length $column_model]-3]]
# append column_model "\]\};\n"

# set type to JS
ns_set put [ad_conn outputheaders] "content-type" "application/x-javascript; charset=utf-8"



