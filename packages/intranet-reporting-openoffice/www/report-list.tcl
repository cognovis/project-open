# /packages/intranet-reporting-openoffice/www/report-list.tcl
#
# Copyright (c) 1998-2012 ]project-open[
# All rights reserved

# ---------------------------------------------------------------
# 1. Page Contract
# ---------------------------------------------------------------

ad_page_contract {
    @author frank.bergmann@ticket-open.com
} {
}

# ---------------------------------------------------------------
# Defaults & Security
# ---------------------------------------------------------------

set current_user_id [ad_maybe_redirect_for_registration]
set page_title [lang::message::lookup "" intranet-reporting-openoffice.Report_List "List of available OpenOffice Reports"]
set context_bar [im_context_bar $page_title]

set find_cmd [im_filestorage_find_cmd]

# Determine the template
set pageroot [ns_info pageroot]
set serverroot [join [lrange [split $pageroot "/"] 0 end-1] "/"]

# Package template path
set template_path_list [parameter::get_from_package_key -package_key "intranet-reporting-openoffice" -parameter "TemplatePathList" -default "/filestorage/templates /packages/intranet-reporting-openoffice/templates /packages/intranet-cust-santander/templates"]

set base_url "/intranet-reporting-openoffice"

# ---------------------------------------------------------------
# Check for a TCL file in the template directories
# ---------------------------------------------------------------

template::multirow create reports report_file_name url

set pathes {}
foreach template_path $template_path_list {
    lappend pathes "${serverroot}${template_path}"
}

foreach path $pathes {
    set files ""
    catch { set files [exec $find_cmd $path -noleaf -type f] }
    foreach file $files {

	set file_name [lindex [split $file "/"] end]
	set file_ext [lindex [split $file_name "."] end]
	set file_body [lrange [split $file_name "."] 0 end-1]

	switch $file_body {
	    "report-list" { continue }
	    "project-oneslide" { continue }
	    default {
		set hash($file_name) $file_name
	    }
	}
    }
}

foreach file_name [array names hash] {
    set file_ext [lindex [split $file_name "."] end]
    set file_body [lrange [split $file_name "."] 0 end-1]
    
    switch $file_ext {
	odp {
	    # Check if there is a .tcl version of this file
	    set tcl_file_name "$file_body.tcl"
	    if {[info exists hash($tcl_file_name)]} { continue }
	    template::multirow append reports $file_name "$base_url/$file_name"
	}
	tcl {
	    template::multirow append reports $file_name "$base_url/$file_body"
	}
	default {
	    # template::multirow append reports $file_name "$base_url/$file_body"
	}
    }
    
}

template::multirow sort reports report_file_name

list::create \
    -name reports \
    -multirow reports \
    -key report_file_name \
    -row_pretty_plural "[_ intranet-dynfield.Unmapped_Attributes]" \
    -selected_format "normal" \
    -class "list" \
    -main_class "list" \
    -sub_class "narrow" \
    -pass_properties {
    } -actions {
    } -elements {
        report_file_name {
            label "[lang::message::lookup {} intranet-reporting-openoffice.Report_Filename {Report Name}]"
            display_col report_file_name
	    link_url_eval $url
        }
    }
