# /packages/intranet-portfolio-management/lib/department-planner.tcl
#
# Copyright (c) 2003-2010 ]project-open[
#
# All rights reserved.
# Please see http://www.project-open.com/ for licensing.

# Expects the variables:
# - start_date
# - end_date
# - view_name
# - ajax_p

# ---------------------------------------------------------------
# Constants
# ---------------------------------------------------------------


set project_base_url "/intranet/projects/view"
set this_base_url "/intranet-budget/department-planner/index"
set bgcolor(0) " class=roweven "
set bgcolor(1) " class=rowodd "

# ---------------------------------------------------------------
# Start and End Date
# ---------------------------------------------------------------

db_1row todays_date "
	select
	        to_char(sysdate::date, 'YYYY') as todays_year,
	        to_char(sysdate::date, 'MM') as todays_month,
	        to_char(sysdate::date, 'DD') as todays_day
	from dual
"


set start_date "${filter_year}-01-01"
set end_date "[expr ${filter_year} +1]-01-01"

if {![info exists start_date] || "" == $start_date} { set start_date "$todays_year-01-01" }
if {![info exists end_date] || "" == $end_date} { set end_date "[expr $todays_year+1]-01-01" }

# Check that Start & End-Date have correct format
im_date_ansi_to_julian $start_date
im_date_ansi_to_julian $end_date


# ---------------------------------------------------------------
# Get the multirow for the table
# ---------------------------------------------------------------

# Get the "department_planner" multirows:
#	- dynview_columns: The first columns with priority, project name 
#	  and customer extensible columns
#	- cost_centers:
#	  The list of cost centers to be shown.
#	- department_planner:
#	  The main "body" of the planner: One row per project,
#	  with columns for DynView and CostCenters
#



set error_html [im_department_planner_get_list_multirow \
		    -start_date $start_date \
		    -end_date $end_date \
		    -view_name $view_name \
            -project_status_id $project_status_id
		   ]


set view_type_id [db_string get_view_id "select view_type_id from im_views where view_name=:view_name" -default 0]

if { "Ajax" == [im_category_from_id $view_type_id] } {
    set ajax_p 1
} else {
    set ajax_p 0
}

set view_id [db_string get_view_id "select view_id from im_views where view_name='$view_name'" -default 0]
set sql " 
		select  ajax_configuration, column_name
		from    im_view_columns vc
        	where   view_id = $view_id
		order by sort_order
    	"

set ctr 0
set response_schema "fields: \["
set column_defs ""
set column_types [list]
set column_names [list]

set editors_conf ""	
set editors_init ""	

template::head::add_javascript -src "/resources/intranet-budget/js/yahoo-dom-event.js" -order "100"
template::head::add_javascript -src "/resources/intranet-budget/js/container-min.js" -order "101"
template::head::add_javascript -src "/resources/intranet-budget/js/connection-min.js" -order "102"
template::head::add_javascript -src "/resources/intranet-budget/js/element-min.js" -order "103"
template::head::add_javascript -src "/resources/intranet-budget/js/paginator-min.js" -order "104"
template::head::add_javascript -src "/resources/intranet-budget/js/datasource-min.js" -order "105"
template::head::add_javascript -src "/resources/intranet-budget/js/datatable-min.js" -order "106"
template::head::add_javascript -src "/resources/intranet-budget/js/json-min.js" -order "107"
template::head::add_javascript -src "/resources/intranet-budget/js/button-min.js" -order "108"

template::head::add_css -href "/resources/intranet-budget/css/container.css" -media "screen" -order "103"
template::head::add_css -href "/resources/intranet-budget/css/paginator.css" -media "screen" -order "104"
template::head::add_css -href "/resources/intranet-budget/css/datatable.css" -media "screen" -order "105"

# template::head::add_css -href "http://yui.yahooapis.com/2.8.0/build/reset-fonts-grids/reset-fonts-grids.css" -media "screen" -order "106"
# template::head::add_css -href "http://yui.yahooapis.com/2.8.0/build/base/base.css" -media "screen" -order "107"
template::head::add_css -href "/resources/intranet-budget/css/skin.css" -media "screen" -order "108"

# set response_schema & column_defs
db_foreach query_name $sql {
    lappend column_types [lindex $ajax_configuration 0]		
    lappend column_names "\"[lindex $ajax_configuration 1]\""
    #lappend column_names "\"$column_name\""
    # Build Response Schema 
    append response_schema "\"[lindex $ajax_configuration 1]\", "
    #append response_schema "\"$column_name\", "
    
    # Build Column Defs set  
#   append column_defs "\{key:\"$column_name\""
    append column_defs "\{key:\"[lindex $ajax_configuration 1]\""
    append column_defs "\, label:\"$column_name\""
    #append column_defs "\, label:\"[lindex $ajax_configuration 1]\""    
    
    switch [lindex $ajax_configuration 0] {
	dropdown {
	    # add formatter 
	    append column_defs ", formatter:'lookup'"			
	    
	    # custom sort
	    append column_defs ", sortOptions:\{sortFunction:customDropdownSort\}"
	    
	    # add editor
	    append column_defs ", editor:ddEditor_[lindex $ajax_configuration 1]"
	    # sortable?	
	    if { "1" == [lindex $ajax_configuration 4] } {
            append column_defs ", sortable:true"
	    }
	    # resizeable
	    if { "1" == [lindex $ajax_configuration 5] } {
            append column_defs ", resizeable:true"
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
            append column_defs ", sortable:true"
	    }
	    # resizeable
	    if { "1" == [lindex $ajax_configuration 5] } {
            append column_defs ", resizeable:true"
	    }				
	} hidden {
	    # works only using function ??
	    # append column_defs ", width:0"
	}
	zerovalue {
	    if { "1" == [lindex $ajax_configuration 4] } {
            append column_defs ", sortable:true"
	    }
	    # resizeable
	    if { "1" == [lindex $ajax_configuration 5] } {
            append column_defs ", resizeable:true"
	    }
	}
	
    }
    append column_defs "\},\n" 
}

set days_planned_arr "var days_planned_arr=\[\];\n"

template::multirow foreach cost_centers {
    if {$available_days eq ""} { set available_days 0}
    if {$department_remaining_days eq ""} { set department_remaining_days 0}
    
    append column_defs "{key:\"key_cc_$cost_center_id\", label:\"$cost_center_name<br>$available_days => $department_remaining_days\", sortable:true, formatter:\"myCustom\"},\n"
    append days_planned_arr "days_planned_arr\[$cost_center_id\]=$department_remaining_days;\n"
    append response_schema "\"key_cc_$cost_center_id\","
    lappend column_names "\"key_cc_$cost_center_id\""
    incr ctr
    set remaining_days($cost_center_id) $department_remaining_days
}


# remove last comma and complete strings
set column_defs [string range $column_defs 0 [expr [string length $column_defs]-3]]
set response_schema [string range $response_schema 0 [expr [string length $response_schema]-2]]
append response_schema "\]"

# build body
set data_source ""
set available_days_cc_arr ""
set ctr 0 

template::multirow foreach department_planner {
    append data_source "\{"
    template::multirow foreach dynview_columns {
        switch [lindex $column_types $ctr] {
            dropdown {
                # add column_name of dynview field
                append data_source "[lindex $column_names $ctr]: "
                
                # ...
                set dynview_var "col_$column_ctr"
                
                # get current value   					
                set dynview_val [expr $$dynview_var] 
                if { "" != $dynview_val } {
                    append data_source "\"$dynview_val\", "
                } else {
                    append data_source "\"Not set\", "
                }
            }
            link {
                append data_source "[lindex $column_names $ctr]: "
                set dynview_var "col_$column_ctr"
                set dynview_val [expr $$dynview_var]
                append data_source "\"$dynview_val\", "
            } 
            hidden {
                append data_source "[lindex $column_names $ctr]: "
                set dynview_var "col_$column_ctr"
                set dynview_val [expr $$dynview_var]
                append data_source "\"$dynview_val\", "
            }
            zerovalue {
                append data_source "[lindex $column_names $ctr]: "
                append data_source "\"0\", " 
            }
        }
        incr ctr 
    }
    
    template::multirow foreach cost_centers {
        append data_source "[lindex $column_names $ctr]: "
        set cc_var "cc_$cost_center_id"
        set rem_days [round -number [expr $remaining_days($cost_center_id) - $$cc_var] -digits 1]
        append available_days_cc_arr "var available_days_cc_arr_" $cost_center_id "_" $project_id "= \"[expr  $$cc_var]\";\n"
        set remaining_days($cost_center_id) $rem_days
        append data_source "\"$rem_days\", "
        incr ctr
    }
    set data_source [string range $data_source 0 [expr [string length $data_source]-3]]
    append data_source "\},\n"
    set ctr 0
}

# remove last comma and complete strings
set data_source [string range $data_source 0 [expr [string length $data_source]-3]]
set return_url [ad_return_url]
# ad_return_complaint 1 $data_source 
# ad_return_complaint 1 $response_schema 
# ad_return_complaint 1 $column_defs
# ad_return_complaint 1 $editors_conf
# ad_return_complaint 1 $cc_arr
