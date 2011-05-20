# packages/extjs/tcl/intranet-extjs-procs.tcl

## Copyright (c) 2011, cognovís GmbH, Hamburg, Germany
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
    
    Wrapper procedures to make use of extjs in ]project-open[
    
    @author Malte Sussdorff (malte.sussdorff@cognovis.de)
    @creation-date 2011-03-29
    @cvs-id $Id$
}

namespace eval intranet_extjs {}
namespace eval intranet_extjs::combobox {}

ad_proc -public intranet_extjs::combobox::categories {
    {-category_type ""}
    {-parent_id ""}
    {-combo_name:required}
    {-form_name:required}
} {
    Generates the combobox code for an ExtJS categories combobox with all the categories of the category type
    in hierarchical order

    @param category_type the CATEGORY Type
    @param combo_name name of the combobox element
    @param form_name name of the form
    @param parent_id Parent Category_id
} {
    if {$parent_id ne ""} {
        set sql "select category_id, category from im_categories c left outer join im_category_hierarchy h on (c.category_id = h.child_id) where parent_id = $parent_id"
    } else {
        set sql "select category_id, category from im_categories where category_type = '$category_type'"
    }
    set benefit_category_combobox [extjs::RowEditor::ComboBox -combo_name "$combo_name" -form_name "$form_name" -sql $sql]
}

ad_proc -public intranet_extjs::json {
    {-sql:required}
    {-view_name:required}
    {-variable_set ""}
} {
    Takes a SQL statement and a view_name to create a JSON for each column in the view with all the rows from the SQL
    
    @param sql A SQL statement which is used to get each row of the spreadsheet
    @param view_name Name of the dynfield view for which to generate the Spreadsheet
    @param variable_set ns_set of variables we need locally.
} {

    # Get the "view" (=list of columns to show)
    set view_id [util_memoize [list db_string get_view_id "select view_id from im_views where view_name = '$view_name'" -default 0]]
    if {0 == $view_id} {
        ad_return_error Error "intranet_openoffice::spreadsheet: We didn't find view_name=$view_name"
    }

    if {$variable_set ne ""} {
        ad_ns_set_to_tcl_vars -duplicates ignore $variable_set
    }
    
    set variables [db_list get_variables "
	select	variable_name
	from	im_view_columns
	where	view_id=:view_id
		and group_id is null
        and variable_name is not null
	order by sort_order
    "]

    # No create the single rows for each Object
    db_foreach elements $sql {
        foreach variable $variables {
            lappend json_list $variable
            lappend json_list [set $variable]
        }
    }
    # Make sure we have no " " " unescaped
    regsub -all {"} $json_list {\"} json_list
    return [util::json::gen [util::json::object::create $json_list]]
}