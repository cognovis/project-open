# /packages/intranet-sysconf/www/import-conf/import-conf-2.tcl
#
# Copyright (C) 2012 ]project-open[
#

ad_page_contract {
    Parse a CSV file and update the configuration.
    @author frank.bergmann@project-open.com
} {
    return_url
    upload_file
}

# ---------------------------------------------------------------
# Defaults & Security
# ---------------------------------------------------------------

set current_user_id [ad_maybe_redirect_for_registration]
set user_is_admin_p [im_is_user_site_wide_or_intranet_admin $current_user_id]
if {!$user_is_admin_p} {
    ad_return_complaint 1 "<li>[_ intranet-core.lt_You_need_to_be_a_syst]"
    return
}

set page_title [lang::message::lookup "" intranet-sysconfig.Import_Conf "Import Configuration"]
set context_bar [im_context_bar {} $page_title]

# Get the file from the user.
# number_of_bytes is the upper-limit
set max_n_bytes [ad_parameter -package_id [im_package_filestorage_id] MaxNumberOfBytes "" 0]
set tmp_filename [ns_queryget upload_file.tmpfile]
im_security_alert_check_tmpnam -location "import-conf-2.tcl" -value $tmp_filename
if { $max_n_bytes && ([file size $tmp_filename] > $max_n_bytes) } {
    ad_return_complaint 1 "Your file is larger than the maximum permissible upload size:  [util_commify_number $max_n_bytes] bytes"
    return
}

# strip off the C:\directories... crud and just get the file name
if ![regexp {([^//\\]+)$} $upload_file match company_filename] {
    # couldn't find a match
    set company_filename $upload_file
}

if {[regexp {\.\.} $company_filename]} {
    set error "Filename contains forbidden characters"
    ad_returnredirect "/error.tcl?[export_url_vars error]"
}

if {![file readable $tmp_filename]} {
    ad_return_complaint 1 "Unable to read the file '$tmp_filename'. <br>
    Please check the file permissions or contact your system administrator.\n"
    ad_script_abort
}

set csv_files_content [fileutil::cat $tmp_filename]
set csv_files [split $csv_files_content "\n"]

set separator [im_csv_guess_separator $csv_files]
ns_log Notice "import-conf-2: trying with separator=$separator"
# Split the header into its fields
set csv_header [string trim [lindex $csv_files 0]]
set csv_header_fields [im_csv_split $csv_header $separator]
set csv_header_len [llength $csv_header_fields]
set values_list_of_lists [im_csv_get_values $csv_files_content $separator]


# ------------------------------------------------------------
# Render Result Header

set ttt {
}

ad_return_top_of_page "
        [im_header]
        [im_navbar]
	<ul>
"




# ------------------------------------------------------------
# Loop through the CSV lines

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

    ns_write "<li>\n"
    ns_write "<li>line: $cnt\n"
    ns_write "<li>line=$cnt, type='$type', key='$key', package_key='$package_key', value='$value'\n"

    switch [string tolower $type] {
	category {
	    set type_name [split $key "."]
	    set category_type [string tolower [lindex $type_name 0]]
	    set category [string tolower [lindex $type_name 1]]
	    set category_ids [db_list cat "select category_id from im_categories where lower(category_type) = :category_type and lower(category) = :category"]
	    if {[llength $category_ids] > 1} {
		ns_write "<li>line=$cnt, $type: found more the one category matching category_type='$category_type' and category='$category'."
		continue
	    }
	    if {[llength $category_ids] < 1} {
		ns_write "<li>line=$cnt, $type: Did not find a category matching category_type='$category_type' and category='$category'."
		continue
	    }
	    set old_value [db_string old_cat "select enabled_p from im_categories where category_id = :category_ids" -default ""]
	    if {$value != $old_value} {
		db_dml menu_en "update im_categories set enabled_p = :value where category_id = :category_ids"
		ns_write "<li>line=$cnt, $type: Successfully update category_type='$category_type' and category='$category'."
	    } else {
		ns_write "<li>line=$cnt, $type: No update necessary."
	    }
	}
	menu {
	    set menu_id [db_string menu "select menu_id from im_menus where label=:value" -default 0]
	    if {0 != $menu_id} {
		set old_value [db_string old_value "select enabled_p from im_menus where label = :key" -default ""]
		if {$value != $old_value} {
		    db_dml menu_en "update im_menus set enabled_p = :value where label = :value"
		    ns_write "<li>line=$cnt, $type: Successfully update menu label='$value'.\n"
		} else {
		    ns_write "<li>line=$cnt, $type: No update necessary."
		}
	    } else {
	        ns_write "<li>line=$cnt, $type: Did not find menu label='$value'.\n"
	    }
	}
	portlet {
	    set portlet_id [db_string portlet "select plugin_id from im_component_plugins where plugin_name=:key and package_name=:package_key" -default 0]
	    if {0 != $portlet_id} {
		set old_value [db_string old_value "select enabled_p from im_component_plugins where plugin_name=:key and package_name=:package_key" -default ""]
		if {$value != $old_value} {
		    db_dml portlet "update im_component_plugins set enabled_p = :value where plugin_name=:key and package_name=:package_key"
		    ns_write "<li>line=$cnt, $type: Successfully update portlet '$value'.\n"
		} else {
		    ns_write "<li>line=$cnt, $type: No update necessary."
		}
	    } else {
	        ns_write "<li>line=$cnt, $type: Did not find portlet '$value'.\n"
	    }
	}
	parameter {
	    set parameter_id [db_string param "select parameter_id from apm_parameters where package_key = :package_key and lower(parameter_name) = lower(:key)" -default 0]
	    if {0 == $parameter_id} {
		ns_write "<li>line=$cnt, $type: Did not find parameter with package_key='$package_key' and name='$key'.\n"
		continue
	    }
	    set old_value [db_string old_val "select min(attr_value) from apm_parameter_values where parameter_id = :parameter_id" -default ""]
	    if {$value != $old_value} {
		db_dml param "update apm_parameter_values set attr_value = :value where parameter_id = :parameter_id"
		ns_write "<li>line=$cnt, $type: Successfully update parameter='$key'.\n"
	    } else {
		ns_write "<li>line=$cnt, $type: No update necessary."
	    }
	}
	default {
	    ns_write "<li>line=$cnt, type='$type' not implemented yet.\n"
	}
    }

}


# ------------------------------------------------------------
# Render Report Footer

ns_write "
	</ul>
	<p><A HREF=$return_url>Return to Project Page</A>
"
ns_write [im_footer]
