# /packages/intranet-sysconfig/tcl/intranet-sysconfig-procs.tcl
#
# Copyright (c) 2006 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

ad_library {
    SysConfig Conviguration Wizard
    @author frank.bergmann@project-open.com
}


# ----------------------------------------------------------------------
# 
# ----------------------------------------------------------------------

ad_proc -public im_package_sysconfig_id {} {
    Returns the package id of the intranet-sysconfig module
} {
    return [util_memoize "im_package_sysconfig_id_helper"]
}

ad_proc -private im_package_sysconfig_id_helper {} {
    return [db_string im_package_core_id {
        select package_id from apm_packages
        where package_key = 'intranet-sysconfig'
    } -default 0]
}


# ----------------------------------------------------------------------
# 
# ----------------------------------------------------------------------

ad_proc -public im_sysconfig_component { } {
    Returns a formatted HTML block as the very first page
    of a freshly installed V3.2 and higher system, allowing
    the user to configure the system
} {
    set bg ""
    set po "<span class=brandsec>&\#93;</span><span class=brandfirst>project-open</span><span class=brandsec>&\#91;</span>"

    set wizard "
	<h2>License Agreement</h2>

	<p>
	This software has been developed by $po<br>
	(<a href=http://www.project-open.org/>http://www.project-open.org/</a>) 
	based on the work of <br>
	several open-source projects and other contributors.
	</p>
<table cellpadding=2>
<tr><td>Novell/SuSE</td>	<td>http://www.novell.com/licensing/eula/suse_pro_93.pdf</td></tr>
<tr><td>&\#93;project-open&\#91;</td>	<td>http://www.project-open.com/license/</td></tr>
<tr><td>AOLserver</td>		<td>http://www.aolserver.com/license/</td></tr>
<tr><td>OpenACS</td>		<td>http://openacs.org/about/licensing/</td></tr>
<tr><td>VMWare Tools</td>	<td>http://www.vmware.com/support/</td></tr>
</table>

	<p>
	You need to agree with the license terms of ALL of <br>
	these authors prio to using the software.
	</p>

"

    set progress "
	<form action='/intranet-sysconfig/segment/sector' method=POST>
	<table cellspacing=0 cellpadding=4 border=0>
	<tr>
		<td></td>
		<td><input type=submit value='Next &gt;&gt;'></td>
	</tr>
	</table>
	</form>
    "

    return "
	<table height=400 width=600 cellspacing=0 cellpadding=0 border=0 background='$bg'>
	<tr valign=top><td>$wizard</td></tr>
	<tr align=center valign=bottom><td>$progress<br>&nbsp;</td></tr>
	</table>
    "
}



ad_proc -public im_sysconfig_parse_groups { group_list } {
    Takes a komma separated list of groups and returns a 
    TCL list with group_ids.
} {
    set groups [split $group_list ","]
    set result [list]
    foreach g $groups {
	set gid [im_profile::profile_id_from_name -profile [string trim $g]]
	if {[string is integer $gid]} { lappend result $gid }
    }
    return $result
}


ad_proc -public im_sysconfig_load_configuration { file } {
    Reads the content of the configuration file and applies the
    configuration to the current server.
} {
    set current_user_id [ad_maybe_redirect_for_registration]

    set csv_files_content [fileutil::cat $file]
    set csv_files [split $csv_files_content "\n"]
    
    set separator [im_csv_guess_separator $csv_files]
    set separator ";"

    ns_log Notice "import-conf-2: trying with separator=$separator"
    # Split the header into its fields
    set csv_header [string trim [lindex $csv_files 0]]

    set csv_header_fields [im_csv_split $csv_header $separator]
    set csv_header_len [llength $csv_header_fields]
    set values_list_of_lists [im_csv_get_values $csv_files_content $separator]

    # Privileges are granted on a "magic object" in the system
    set privilege_grant_object_id [db_string priv_grant_object "
	select min(object_id)
	from acs_objects
	where object_type = 'apm_service'
    "]


    # ------------------------------------------------------------
    # Loop through the CSV lines
    
    set html ""
    set type ""
    set key ""
    set value ""
    set package_key ""
    
    set cnt 1
    foreach csv_line_fields $values_list_of_lists {
	incr cnt
	
	# Write columns to local variables
	for {set i 0} {$i < [llength $csv_header_fields]} {incr i} {
	    set var [lindex $csv_header_fields $i]
	    set val [lindex $csv_line_fields $i]
	    if {"" != $var} { set $var $val }
	}
	
	append html "<li>\n"
	append html "<li>line: $cnt\n"
	append html "<li>line=$cnt, type='$type', key='$key', package_key='$package_key', value='$value'\n"
	
	switch [string tolower $type] {
	    category {
		set type_name [split $key "."]
		set category_type [string tolower [lindex $type_name 0]]
		set category [string tolower [lindex $type_name 1]]
		set category_ids [db_list cat "select category_id from im_categories where lower(category_type) = :category_type and lower(category) = :category"]
		if {[llength $category_ids] > 1} {
		    append html "<li>line=$cnt, $type: found more the one category matching category_type='$category_type' and category='$category'."
		    continue
		}
		if {[llength $category_ids] < 1} {
		    append html "<li>line=$cnt, $type: Did not find a category matching category_type='$category_type' and category='$category'."
		    continue
		}
		set old_value [db_string old_cat "select enabled_p from im_categories where category_id = :category_ids" -default ""]
		if {$value != $old_value} {
		    db_dml menu_en "update im_categories set enabled_p = :value where category_id = :category_ids"
		    append html "<li>line=$cnt, $type: Successfully update category_type='$category_type' and category='$category'."
		} else {
		    append html "<li>line=$cnt, $type: No update necessary."
		}
	    }
	    menu {
		set menu_id [db_string menu "select menu_id from im_menus where label = :key" -default 0]
		if {0 != $menu_id} {
		    set old_value [db_string old_value "select enabled_p from im_menus where label = :key" -default ""]
		    if {$value != $old_value} {
			db_dml menu_en "update im_menus set enabled_p = :value where label = :key"
			append html "<li>line=$cnt, $type: Successfully update menu label='$value'.\n"
		    } else {
			append html "<li>line=$cnt, $type: No update necessary."
		    }
		} else {
		    append html "<li>line=$cnt, $type: Did not find menu label='$key'.\n"
		}
	    }
	    privilege {
		set privilege_exists_p [db_string priv "select count(*) from acs_privileges where privilege = :key" -default 0]
		if {0 != $privilege_exists_p} {
		    set old_value [db_string old_value "select im_sysconfig_display_privileges(:key)"]
		    if {1 || $value != $old_value} {

			set group_list [im_sysconfig_parse_groups $value]
			foreach g $group_list {
			    db_string grant_perms "select acs_permission__grant_permission(:privilege_grant_object_id, :g, :key)"
			    append html "<li>line=$cnt, $type: Granted privilege '$key' to group \#$g.\n"
			}

		    } else {
			append html "<li>line=$cnt, $type: No update necessary."
		    }
		} else {
		    append html "<li>line=$cnt, $type: Did not find menu label='$key'.\n"
		}
	    }
	    portlet {
		set portlet_id [db_string portlet "select plugin_id from im_component_plugins where plugin_name=:key and package_name=:package_key" -default 0]
		if {0 != $portlet_id} {
		    set old_value [db_string old_value "select enabled_p from im_component_plugins where plugin_name=:key and package_name=:package_key" -default ""]
		    if {$value != $old_value} {
			db_dml portlet "update im_component_plugins set enabled_p = :value where plugin_name=:key and package_name=:package_key"
			append html "<li>line=$cnt, $type: Successfully update portlet '$value'.\n"
		    } else {
			append html "<li>line=$cnt, $type: No update necessary."
		    }
		} else {
		    append html "<li>line=$cnt, $type: Did not find portlet '$value'.\n"
		}
	    }
	    parameter {
		set parameter_id [db_string param "select parameter_id from apm_parameters where package_key = :package_key and lower(parameter_name) = lower(:key)" -default 0]
		if {0 == $parameter_id} {
		    append html "<li>line=$cnt, $type: Did not find parameter with package_key='$package_key' and name='$key'.\n"
		    continue
		}
		set old_value [db_string old_val "select min(attr_value) from apm_parameter_values where parameter_id = :parameter_id" -default ""]
		if {$value != $old_value} {
		    db_dml param "update apm_parameter_values set attr_value = :value where parameter_id = :parameter_id"
		    append html "<li>line=$cnt, $type: Successfully update parameter='$key'.\n"
		} else {
		    append html "<li>line=$cnt, $type: No update necessary."
		}
	    }
	    default {
		append html "<li>line=$cnt, type='$type' not implemented yet.\n"
	    }
	}
    }

    # Force recalculation of cached menus etc
    im_permission_flush

    return $html
}

