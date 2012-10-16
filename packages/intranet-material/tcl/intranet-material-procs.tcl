# /packages/intranet-material/tcl/intranet-material.tcl
#
# Copyright (C) 2003 - 2009 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

ad_library {
    @author frank.bergmann@project-open.com
}


# ----------------------------------------------------------------------
# Category Constants
# ----------------------------------------------------------------------

ad_proc -public im_material_status_active { } { return 9100 }
ad_proc -public im_material_status_inactive { } { return 9102 }

ad_proc -public im_material_type_other { } { return 9000 }
ad_proc -public im_material_type_maintenance { } { return 9002 }
ad_proc -public im_material_type_licenses { } { return 9004 }
ad_proc -public im_material_type_consulting { } { return 9006 }
ad_proc -public im_material_type_software_dev { } { return 9008 }
ad_proc -public im_material_type_web_site_dev { } { return 9010 }
ad_proc -public im_material_type_generic_pm { } { return 9012 }
ad_proc -public im_material_type_translation { } { return 9014 }

# reserved until 9099



ad_proc -public im_package_material_id {} {
    Returns the package id of the intranet-material module
} {
    return [util_memoize "im_package_material_id_helper"]
}

ad_proc -private im_package_material_id_helper {} {
    return [db_string im_package_core_id {
	select package_id from apm_packages
	where package_key = 'intranet-material'
    } -default 0]
}

ad_proc -private im_material_default_material_id {} {
    set material_id [util_memoize {db_string default_material "select material_id from im_materials where material_nr='default'" -default 0}]
    if {0 == $material_id} {
	ad_return_complaint 1 "<b>[lang::message::lookup "" intranet-material.Bad_Config_title "Bad 'Material' Configuration"]</b>:
		<br>[lang::message::lookup "" intranet-material.Bad_Config_msg "
		Unable to find any 'material' with name 'default'.<br>
		We need this 'default material' in order to assign a type of service
		to objects that otherwise don't have service information, such as projects etc.<br>
		Please inform your System Administrator and tell him to create a 'default' 
		material in the <a href='/intranet-material/'>Material Administration Page</a>.
				  "]
	"

	# Un'cache' the value for the material just reported missing...
	im_permission_flush

	ad_script_abort
    }
    return $material_id
}


ad_proc -private im_material_default_translation_material_id {} {
    set material_id [util_memoize {db_string default_material "select material_id from im_materials where material_nr='tr_task'" -default 0}]
    if {0 == $material_id} {
        ad_return_complaint 1 "<b>[lang::message::lookup "" intranet-material.Bad_Config_title "Bad 'Material' Configuration"]</b>:
                <br>[lang::message::lookup "" intranet-material.Bad_Config_msg "
                Unable to find any 'material' with name 'tr_task'.<br>
                Please inform your System Administrator and ask him to verify if ''tr_task'
                material can be found in the <a href='/intranet-material/'>Material Administration Page</a>.
	        An update of the material package should resolve the issue.
	"]
        "

        # Un'cache' the value for the material just reported missing...
        im_permission_flush

        ad_script_abort
    }
    return $material_id
}




# ----------------------------------------------------------------------
# Options
# ---------------------------------------------------------------------

ad_proc -private im_material_type_options { 
    {-include_empty 1} 
} {
    set options [db_list_of_lists material_type_options "
	select	category, category_id
	from	im_categories
	where	category_type = 'Intranet Material Type'
		and (enabled_p = 't' OR enabled_p is null)
    "]
    if {$include_empty} { set options [linsert $options 0 { "" "" }] }
    return $options
}

ad_proc -private im_material_status_options { {-include_empty 1} } {

    set options [db_list_of_lists material_status_options "
	select	category, category_id
	from	im_categories
	where	category_type = 'Intranet Material Status'
		and (enabled_p = 't' OR enabled_p is null)
	order by category
    "]
    if {$include_empty} { set options [linsert $options 0 { "" "" }] }
    return $options
}


# Get a list of available materials
ad_proc -private im_material_options { 
    {-restrict_to_status_id 0} 
    {-restrict_to_type_id 0} 
    {-restrict_to_uom_id 0} 
    {-include_empty 1}
    {-show_material_codes_p 0}
    {-max_option_len 25 }
} {
    set where_clause ""
    if {0 != $restrict_to_status_id} {
	append where_clause "and material_status_id = :restrict_to_status_id\n"
    }
    if {0 != $restrict_to_type_id} {
	append where_clause "and material_type_id = :restrict_to_type_id\n"
    }
    if {0 != $restrict_to_uom_id} {
	append where_clause "and material_uom_id = :restrict_to_uom_id\n"
    }

    # Exclude inactive materials
        append where_clause "and material_status_id <> " [im_material_status_inactive]

    if {$show_material_codes_p} {
	    set sql "
		select	substring(material_nr for :max_option_len) as material_nr,
			material_id
		from	im_materials
		where 	1=1
			$where_clause
		order by
			material_nr
	    "
    } else {
	    set sql "
		select	substring(material_name for :max_option_len) as material_name,
			material_id
		from	im_materials
		where 	1=1
			$where_clause
		order by
			material_name
	    "
    }

    set options [db_list_of_lists material_options $sql]
    if {$include_empty} { set options [linsert $options 0 { "" "" }] }
    return $options
}


ad_proc -public im_material_select { 
    {-include_empty_p 0} 
    {-restrict_to_status_id 0}
    {-restrict_to_type_id 0}
    {-show_material_codes_p 0}
    {-max_option_len 25 }
    select_name
    default
} {
    Returns a select box with all Materials.
} {
    set options [im_material_options -include_empty $include_empty_p -restrict_to_status_id $restrict_to_status_id -restrict_to_type_id $restrict_to_type_id -show_material_codes_p $show_material_codes_p -max_option_len $max_option_len]

    return [im_options_to_select_box $select_name $options $default [list id $select_name]]
}


# ----------------------------------------------------------------------
# Material List Page Component
# ---------------------------------------------------------------------

ad_proc -public im_material_list_component {
    {-view_name ""} 
    {-order_by "priority"} 
    {-restrict_to_type_id 0} 
    {-restrict_to_status_id 0} 
    {-max_entries_per_page ""} 
    {-start_idx 0} 
    -user_id 
    -current_page_url 
    -return_url 
    -export_var_list
} {
    Creates a HTML table showing a table of Materials 
} {
    set bgcolor(0) " class=roweven"
    set bgcolor(1) " class=rowodd"
    set date_format "YYYY-MM-DD"

    if { "" == $max_entries_per_page || "0" == $max_entries_per_page } {
        set max_entries_per_page [ad_parameter -package_id [im_package_core_id] NumberResultsPerPage "" 50]
    }

    set end_idx [expr $start_idx + $max_entries_per_page - 1]

    if {![im_permission $user_id view_materials]} { return ""}

    set view_id [db_string get_view_id "select view_id from im_views where view_name=:view_name" -default 0]
    if {0 == $view_id} {
	# We haven't found the specified view, so let's emit an error message
	# and proceed with a default view that should work everywhere.
	ns_log Error "im_material_component: we didn't find view_name=$view_name"
	set view_name "material_list"
	set view_id [db_string get_view_id "select view_id from im_views where view_name=:view_name"]
    }

    # ---------------------- Get Columns ----------------------------------
    # Define the column headers and column contents that
    # we want to show:
    #
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
		sort_order
    "

    db_foreach column_list_sql $column_sql {
	if {"" == $visible_for || [eval $visible_for]} {
	lappend column_headers "$column_name"
	lappend column_vars "$column_render_tcl"
	}
    }
    ns_log Notice "im_material_component: column_headers=$column_headers"

    # -------- Compile the list of parameters to pass-through-------

    set form_vars [ns_conn form]
    if {"" == $form_vars} { set form_vars [ns_set create] }

    set bind_vars [ns_set create]
    foreach var $export_var_list {
	upvar 1 $var value
	if { [info exists value] } {
	    ns_set put $bind_vars $var $value
	    ns_log Notice "im_material_component: $var <- $value"
	} else {
	
	    set value [ns_set get $form_vars $var]
	    if {![string equal "" $value]} {
 		ns_set put $bind_vars $var $value
 		ns_log Notice "im_material_component: $var <- $value"
	    }
	    
	}
    }

    ns_set delkey $bind_vars "order_by"
    ns_set delkey $bind_vars "start_idx"
    set params [list]
    set len [ns_set size $bind_vars]
    for {set i 0} {$i < $len} {incr i} {
	set key [ns_set key $bind_vars $i]
	set value [ns_set value $bind_vars $i]
	if {![string equal $value ""]} {
	    lappend params "$key=[ns_urlencode $value]"
	}
    }
    set pass_through_vars_html [join $params "&"]

    # ---------------------- Format Header ----------------------------------

    # Set up colspan to be the number of headers + 1 for the # column
    set colspan [expr [llength $column_headers] + 1]

    # Format the header names with links that modify the
    # sort order of the SQL query.
    #
    set table_header_html "<tr>\n"
    foreach col $column_headers {

	set cmd_eval ""
	ns_log Notice "im_material_component: eval=$cmd_eval $col"
	set cmd "set cmd_eval $col"
	eval $cmd
	if { [regexp "im_gif" $col] } {
	    set col_tr $cmd_eval
	} else {
	    set col_tr [lang::message::lookup "" intranet-material.[lang::util::suggest_key $cmd_eval] $cmd_eval]
	}

	if { [string compare $order_by $cmd_eval] == 0 } {
	    append table_header_html "  <td class=rowtitle>$col_tr</td>\n"
	} else {
	    append table_header_html "  <td class=rowtitle>
	    <a href=$current_page_url?$pass_through_vars_html&order_by=[ns_urlencode $cmd_eval]>$col_tr</a>
	    </td>\n"
	}
    }
    append table_header_html "</tr>\n"


    # ---------------------- Build the SQL query ---------------------------

    set order_by_clause "order by m.material_nr"
    set order_by_clause_ext "order by material_nr"
    switch [string tolower $order_by] {
	"nr" { 
	    set order_by_clause "order by m.material_nr" 
	    set order_by_clause_ext "order by material_nr"
	}
	"name" { 
	    set order_by_clause "order by m.material_name" 
	    set order_by_clause_ext "order by material_name"
	}
	"type" { 
	    set order_by_clause "order by m.material_type_id, m.material_nr" 
	    set order_by_clause_ext "order by material_type_id, material_nr"
	}
	"uom" { 
	    set order_by_clause "order by m.material_uom_id" 
	    set order_by_clause_ext "order by material_uom_id"
	}
    }
	
	
    set restrictions [list]
    if {0 != $restrict_to_status_id} {
	lappend restrictions "m.material_status_id in ([join [im_sub_categories $restrict_to_status_id] ","])"
    }
    if {0 != $restrict_to_type_id} {
	lappend restrictions "m.material_type_id in ([join [im_sub_categories $restrict_to_type_id] ","])"
    }

    set restriction_clause [join $restrictions "\n\tand "]
    if {"" != $restriction_clause} { 
	set restriction_clause "and $restriction_clause" 
    }
    set restriction_clause "1=1 $restriction_clause"
    ns_log Notice "im_material_component: restriction_clause=$restriction_clause"
		
    set material_statement [db_qd_get_fullname "material_query" 0]
    set material_sql_uneval [db_qd_replace_sql $material_statement {}]
    set material_sql [expr "\"$material_sql_uneval\""]
	
    # ---------------------- Limit query to MAX rows -------------------------
    
    # We can't get around counting in advance if we want to be able to
    # sort inside the table on the page for only those rows in the query 
    # results
    
    set limited_query [im_select_row_range $material_sql $start_idx [expr $start_idx + $max_entries_per_page]]
    set total_in_limited_sql "select count(*) from ($material_sql) f"
    set total_in_limited [db_string total_limited $total_in_limited_sql]
    set selection "select z.* from ($limited_query) z $order_by_clause_ext"
    
    # How many items remain unseen?
    set remaining_items [expr $total_in_limited - $start_idx - $max_entries_per_page]
    ns_log Notice "im_material_component: total_in_limited=$total_in_limited, remaining_items=$remaining_items"
    
    # ---------------------- Format the body -------------------------------
    
    set table_body_html ""
    set ctr 0
    set idx $start_idx
    set old_material_type_id 0
	
    db_foreach material_query_limited $selection {
	
	# insert intermediate headers for every material type
	if {[string equal "Type" $order_by]} {
	    if {$old_material_type_id != $material_type_id} {
		append table_body_html "
    		    <tr><td colspan=$colspan>&nbsp;</td></tr>
    		    <tr><td class=rowtitle colspan=$colspan>
    		      <A href=index?[export_url_vars material_type_id project_id]>
    			$material_type
    		      </A>
    		    </td></tr>\n"
		set old_material_type_id $material_type_id
	    }
	}
	
	append table_body_html "<tr$bgcolor([expr $ctr % 2])>\n"
	foreach column_var $column_vars {
	    append table_body_html "\t<td valign=top>"
	    set cmd "append table_body_html $column_var"
	    eval $cmd
	    append table_body_html "</td>\n"
	}
	append table_body_html "</tr>\n"
	
	incr ctr
	if { $max_entries_per_page > 0 && $ctr >= $max_entries_per_page } {
	    break
	}
    }
    # Show a reasonable message when there are no result rows:
    if { [empty_string_p $table_body_html] } {
	set table_body_html "
		<tr><td colspan=$colspan align=center><b>
		[_ intranet-material.There_are_no_active_materials]
		</b></td></tr>"
    }
    
    if { $ctr == $max_entries_per_page && $end_idx < [expr $total_in_limited - 1] } {
	# This means that there are rows that we decided not to return
	# Include a link to go to the next page
	set next_start_idx [expr $end_idx + 1]
	set next_page_url  "$current_page_url?[export_url_vars max_entries_per_page order_by]&start_idx=$next_start_idx&$pass_through_vars_html"
	set next_page_html "($remaining_items more) <A href=\"$next_page_url\">&gt;&gt;</a>"
    } else {
	set next_page_html ""
    }
    
    if { $start_idx > 0 } {
	# This means we didn't start with the first row - there is
	# at least 1 previous row. add a previous page link
	set previous_start_idx [expr $start_idx - $max_entries_per_page]
	if { $previous_start_idx < 0 } { set previous_start_idx 0 }
	set previous_page_html "<A href=$current_page_url?$pass_through_vars_html&order_by=$order_by&start_idx=$previous_start_idx>&lt;&lt;</a>"
    } else {
	set previous_page_html ""
    }
    

    # ---------------------- Join all parts together ------------------------

    set component_html "
<table bgcolor=white border=0 cellpadding=1 cellspacing=1>
  $table_header_html
  $table_body_html
</table>
"

    return $component_html
}




# ----------------------------------------------------------------------
# Create Parametrized Material for a number of parameters
# ---------------------------------------------------------------------

ad_proc -private im_material_create_from_parameters {
    -material_uom_id:required
    {-debug 0}
    {-material_type_id ""}
} {
    This function selects or creates a material based on a number of
    parameters. It checks if a materials for these parameters already
    exists and creates a new material otherwise.
    The parameters are defined as the DynFields of 'im_material'.
    In order to create the material, the procedure expects the parameters
    to be avaiable as variables in the calling stackframe.
} {
    if {"" == $material_type_id} { set material_type_id [im_material_type_translation] }

    # ----------------------------------------------------
    # Get the list of parameters as the DynFields of object type "im_material".
    # 
    set dynfield_sql "
	select	*
	from	acs_attributes aa,
		im_dynfield_widgets dw,
		im_dynfield_attributes da
		LEFT OUTER JOIN im_dynfield_layout dl ON (da.attribute_id = dl.attribute_id)
	where	aa.object_type = 'im_material' and
		aa.attribute_id = da.acs_attribute_id and
		da.widget_name = dw.widget_name and
		coalesce(dl.page_url,'default') = 'default'
	order by dl.pos_y, aa.attribute_id
    "

    # params is a list of "variables" ordered by the sort order of the material's DynFields.
    set params [db_list params "select attribute_name from ($dynfield_sql) t"]

    # ----------------------------------------------------
    # Map the parameters from the calling stack frame to this stack frame
    foreach param $params {
	upvar 1 $param $param
    }

    # ----------------------------------------------------
    # Search for an existing material with the same parameter combination
    set sql "
	select	min(material_id)
	from	im_materials m
	where	1=1
    "
    foreach param $params {

	# This eval may fail if the parameter doesn't exist in the calling stack frame
	catch {
	    eval "set val $$param"
	} err_msg

	if {"" == $val} {
	    append sql "\t\tand m.$param is null\n"
	} else {
	    append sql "\t\tand m.$param = :$param\n"
	}
    }
    append sql "\tLIMIT 1\n"
    set material_id [db_string existing_material $sql -default ""]

    # ----------------------------------------------------
    # Create a new material if it didn't exist
    if {"" == $material_id || 0 == $material_id} {

	# Calculate the Material Name from parameters
	set material_name "Translation"
	set param_derefs [db_list_of_lists param_derefs "select attribute_name, deref_plpgsql_function, sql_datatype from ($dynfield_sql) t"]

	foreach row $param_derefs {
	    set attribute_name [lindex $row 0]
	    set deref_plpgsql_function [lindex $row 1]
	    set sql_datatype [lindex $row 2]

	    # Append the key=value pair, unless the value is NULL
	    eval "set val $$attribute_name"
	    if {"" != $val} {
		set param_deref [db_string deref "select ${deref_plpgsql_function}(:${attribute_name}::$sql_datatype)" -default ""]
		if {"" != $material_name} { append material_name ", " }
		append material_name $param_deref
	    }
	}

	# Eliminate all spaces
	regsub -all { } [string trim [string tolower $material_name]] "" material_nr

	# material_nr is unique. Avoid errors by checking for the name.
	set material_id [db_string material_by_name "select material_id from im_materials where material_nr = :material_nr" -default ""]

	if {"" == $material_id || 0 == $material_id} {
	    db_transaction {
		set material_id [db_string material_create "
		select im_material__new (
			[db_nextval acs_object_id_seq], 'im_material', now(), [ad_get_user_id], '[ns_conn peeraddr]', null,
			:material_name, :material_nr, :material_type_id, [im_material_status_active],
			:material_uom_id, 'Automatically generated'
		)
	        "]

		# Update the new material to set the corresponding parameters
		set material_update_sql "\t\tupdate im_materials set\n"
		set ctr 0
		foreach param $params {
		    set komma ""
		    if {$ctr > 0} { set komma "," } 
		    append material_update_sql "\t\t${komma}${param} = :$param\n"
		    incr ctr
		}
		append material_update_sql "\twhere material_id = :material_id\n"
		db_dml material_update $material_update_sql
	    }
	}

	# End of creating new material
    }
    
    return $material_id
}


