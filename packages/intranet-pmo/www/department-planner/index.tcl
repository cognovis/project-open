# /packages/intranet-pmo/www/department-planner/index.tcl
#
# Copyright (c) 2011, cognovís GmbH, Hamburg, Germany
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
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
# 
#

# ---------------------------------------------------------------
# Page Contract
# ---------------------------------------------------------------

ad_page_contract {
    Shows a portfolio of projects ordered by priority.
    The assigned work days to the project's tasks are deduced from the
    resources available per cost_center.

    Note: There is only a single portfolio here, as the cost center's 
    resources are not separated per portfolio.

    @author frank.bergmann@project-open.com
    @author malte.sussdorff@cognovis.de
} {
    { view_name "" }
    { view_type "" }
    { project_id "" }
    { project_status_id ""}
    { ajax_p "0" }
}

# ---------------------------------------------------------------
# Title
# ---------------------------------------------------------------

set page_title [lang::message::lookup "" intranet-pmo.Department_Planner "Department Planner"]
set context_bar [im_context_bar $page_title]

# ---------------------------------------------------------------
# Permissions
# ---------------------------------------------------------------

# Label: Provides the security context for this report
# because it identifies unquely the report's Menu and
# its permissions.
set current_user_id [im_require_login]
set menu_label "reporting-department-planner"
set read_p [db_string report_perms "
        select  im_object_permission_p(m.menu_id, :current_user_id, 'read')
        from    im_menus m
        where   m.label = :menu_label
" -default 'f']
set read_p "t"
if {![string equal "t" $read_p]} {
    ad_return_complaint 1 [lang::message::lookup "" intranet-reporting.You_dont_have_permissions "You don't have the necessary permissions to view this page"]
    ad_script_abort
}


# ---------------------------------------------------------------
# Constants
# ---------------------------------------------------------------

set project_base_url "/intranet/projects/view"
set this_base_url "/intranet-pmo/department-planner/index"
set bgcolor(0) " class=roweven "
set bgcolor(1) " class=rowodd "


# ---------------------------------------------------------------
# Project Menu
# ---------------------------------------------------------------

set sub_navbar ""
set main_navbar_label "projects"

set project_menu ""
if {[llength $project_id] == 1} {

    # Exactly one project - quite a frequent case.
    # Show a ProjectMenu so that it looks like we've gone to a different tab.
    set bind_vars [ns_set create]
    ns_set put $bind_vars project_id $project_id
    set project_menu_id [db_string parent_menu "select menu_id from im_menus where label='project'" -default 0]
    set sub_navbar [im_sub_navbar \
       -components \
       -base_url "/intranet/projects/view?project_id=$project_id" \
       $project_menu_id \
       $bind_vars "" "pagedesriptionbar" "project_resources"] 
    set main_navbar_label "projects"

} else {

    # Show the same header as the ProjectListPage
    set letter ""
    set next_page_url ""
    set previous_page_url ""
    set menu_select_label "department_planner"
    set sub_navbar [im_project_navbar $letter "/intranet/projects/index" $next_page_url $previous_page_url [list start_idx order_by how_many view_name letter project_status_id] $menu_select_label]

}

# ---------------------------------------------------------------
# Start and End Date
# ---------------------------------------------------------------

db_1row todays_date "
        select
                to_char(sysdate::date, 'YYYY') as todays_year
        from dual
"
set year $todays_year
set year_list [list]
while {$year < [expr $todays_year + 5]} {
    lappend year_list [list $year $year]
    incr year
}

# ---------------------------------------------------------------
# Format the Filter
# ---------------------------------------------------------------

ad_form -name department_planner_filter -form {
    {filter_year:text(select),optional
	{label "[_ intranet-pmo.filter_year]"}
	{options "$year_list"}
    }
    {include_remaining_p:text(checkbox),optional
	{label "[_ intranet-pmo.include_remaining_effort]"}
	{options {{"" 1}}}
    }
    {view_name:text(hidden) {value $view_name}}
    {ajax_p:text(hidden) {value $ajax_p}}
    {view_type:text(select),optional {label "#intranet-openoffice.View_type#"} {options {{Tabelle ""} {Excel xls} {OpenOffice ods} {PDF pdf}} }}
    {project_status_id:text(im_category_tree),optional {label \#intranet-core.Project_Status\#} {custom {category_type "Intranet Project Status" translate_p 1}} }

} -on_request {   
    set filter_year $todays_year
    set include_remaining_p 0
} 

switch $view_type {
    json {
        set start_date "${filter_year}-01-01"
        set end_date "[expr ${filter_year} +1]-01-01"
        
        set error_html [im_department_planner_get_list_multirow \
                            -start_date $start_date \
                            -end_date $end_date \
                            -view_name $view_name \
                           ]

        # Get the list of variable from the dynview and the cost_centers
        set variables [list]
        set cc_variables [list]
        template::multirow foreach dynview_columns {
            lappend variables "col_$column_ctr" 
        }
                
        template::multirow foreach cost_centers {
            set remaining_days($cost_center_id) $department_remaining_days
            lappend cc_variables "cc_$cost_center_id" 
        }

        set counter 0
        set json_lists [list]
        template::multirow foreach department_planner {
            set json_list [list]
            foreach variable $variables {
                set value [ad_html_to_text -no_format [set $variable]]
                lappend json_list $variable
                lappend json_list $value
            }
            foreach variable $cc_variables {
                set value [ad_html_to_text -no_format [set $variable]]
                set cost_center_id [string trimleft $variable "cc_"]
                set rem_days [expr $remaining_days($cost_center_id) - $value]
                set remaining_days($cost_center_id) $rem_days
                set value $rem_days
                lappend json_list $variable
                lappend json_list $value
            }
            regsub -all "\"" $json_list {\"} json_list

            # Generate the json object for this ROW and append it to
            # the json lists
            lappend json_lists [util::json::object::create $json_list]
            incr counter
        }

        # Generate the array of items
        set json_array(results) $counter
        set json_array(items) [util::json::array::create $json_lists]
        ns_return 200 text/text [util::json::gen [util::json::object::create [array get json_array]]]
    }
    ods - pdf - xls {
        # -----------------------
        # Code for OO based spreadsheets
        # ----------------------
        set start_date "${filter_year}-01-01"
        set end_date "[expr ${filter_year} +1]-01-01"
        
        set error_html [im_department_planner_get_list_multirow \
                            -start_date $start_date \
                            -end_date $end_date \
                            -view_name $view_name \
                           ]
        
        # ---------------------------------------------------------------
        # Build the the columns
        # ---------------------------------------------------------------
        
        set variables [list]
        set __column_defs ""
        set __header_defs ""
        
        template::multirow foreach dynview_columns {
            append __column_defs "<table:table-column table:style-name=\"co1\" table:default-cell-style-name=\"ce3\"/>\n"
            append __header_defs " <table:table-cell office:value-type=\"string\"><text:p>$column_title</text:p></table:table-cell>\n"
            set datatype_arr(col_$column_ctr) string
            lappend variables "col_$column_ctr" 
        }
        
        
        template::multirow foreach cost_centers {
            set column_title "$cost_center_name\n $available_days => $department_remaining_days"
            append __column_defs " <table:table-column table:style-name=\"co2\" table:default-cell-style-name=\"ce5\"/>\n"
            append __header_defs " <table:table-cell office:value-type=\"string\"><text:p>$column_title</text:p></table:table-cell>\n"
            set datatype_arr(cc_$cost_center_id) float
            set remaining_days($cost_center_id) $department_remaining_days
            lappend variables "cc_$cost_center_id" 
        }
        
        set __output $__column_defs
        
        # Set the first row
        append __output "<table:table-row table:style-name=\"ro1\">\n$__header_defs</table:table-row>\n"
        ns_log Notice "Variabels: $variables"
        template::multirow foreach department_planner {
            append __output "<table:table-row table:style-name=\"ro1\">\n"
            foreach variable $variables {
                set value [ad_html_to_text -no_format [set $variable]]
                # Use the trick that the datatype for cost center is
                # float!
                if {$datatype_arr($variable) eq "float"} {
                    set cost_center_id [string trimleft $variable "cc_"]
                    # For cost_centers we actually need to count down from
                    # the remaining days the hours for this
                    # project. That’s the number to display
                    set rem_days [expr $remaining_days($cost_center_id) - $value]
                    set remaining_days($cost_center_id) $rem_days
                    set value $rem_days
                }
                
                switch $datatype_arr($variable) {
                    float {
                        append __output " <table:table-cell office:value-type=\"float\" office:value=\"$value\"></table:table-cell>\n"
                    }
                    string {
                        append __output " <table:table-cell office:value-type=\"string\"><text:p>$value</text:p></table:table-cell>\n"
                    }
                }
            }
            append __output "</table:table-row>\n"
        }
        
        set ods_file "[acs_package_root_dir "intranet-openoffice"]/templates/table.ods"
        if {![file exists $ods_file]} {
            ad_return_error "Missing ODS" "We are missing your ODS file $ods_file . Please make sure it exists"
        }
        
        set table_name "Department Planner"
        intranet_oo::parse_content -template_file_path $ods_file -output_filename department_planer.$view_type
    }    
}    
    