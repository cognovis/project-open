# /packages/intranet-sysconfig/www/index.tcl
#
# Copyright (c) 2006 ]project-open[
#
# This program is free software. You can redistribute it
# and/or modify it under the terms of the GNU General
# Public License as published by the Free Software Foundation;
# either version 2 of the License, or (at your option)
# any later version. This program is distributed in the
# hope that it will be useful, but WITHOUT ANY WARRANTY;
# without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.
# See the GNU General Public License for more details.

ad_page_contract {
  Home page for SysConfig

  @author frank.bergmann@project-open.com
} {
    { return_url "" }
}

set current_user_id [ad_maybe_redirect_for_registration]
set user_is_admin_p [im_is_user_site_wide_or_intranet_admin $current_user_id]
if {!$user_is_admin_p} {
    ad_return_complaint 1 "<li>[_ intranet-core.lt_You_need_to_be_a_syst]"
    return
}

# Determine the template
set pageroot [ns_info pageroot]
set serverroot [join [lrange [split $pageroot "/"] 0 end-1] "/"]
set find_cmd [im_filestorage_find_cmd]
if {"" == $return_url} { set return_url [im_url_with_query] }

set page_title "[lang::message::lookup "" intranet-sysconfig.SysConfig "SysConfig"]"
set context_bar [im_context_bar $page_title]

set bgcolor(0) " class=rowodd"
set bgcolor(1) " class=roweven"



# ---------------------------------------------------------------
# Search for suitable configuration files
# ---------------------------------------------------------------

template::multirow create templates template_name url

set base_path "$serverroot/packages/intranet-sysconfig/templates"
set files ""
catch { set files [exec $find_cmd $base_path -noleaf -type f] }
foreach file $files {
    set file_name [lindex [split $file "/"] end]
    set file_ext [lindex [split $file_name "."] end]
    set file_body [lrange [split $file_name "."] 0 end-1]
    

    switch $file_body {
	"CVS" - Entries - Root - Repository { continue }
	"" { continue }
	default {
	    set hash($file_name) $file_name
	}
    }
}

set base_url "/intranet-sysconfig/import-conf/import-conf-2"
foreach file_name [array names hash] {
    set file_ext [lindex [split $file_name "."] end]
    set file_body [lrange [split $file_name "."] 0 end-1]
    
    set abs_file_name "$base_path/$file_name"
    set url [export_vars -base $base_url {{config_file $abs_file_name} return_url}]

    template::multirow append templates $file_name $url 
   
}

template::multirow sort templates template_name

list::create \
    -name templates \
    -multirow templates \
    -key template_file_name \
    -row_pretty_plural "[_ intranet-dynfield.Unmapped_Attributes]" \
    -selected_format "normal" \
    -class "list" \
    -main_class "list" \
    -sub_class "narrow" \
    -pass_properties {
    } -actions {
    } -elements {
        template_file_name {
            label "[lang::message::lookup {} intranet-sysconfig.Templates Templates]"
            display_col template_name
	    link_url_eval $url
        }
    }
