# /packages/intranet-filestorage/www/index.tcl
#
# Copyright (C) 2003-2004 Project/Open
#
# All rights reserved. Please check
# http://www.project-open.com/ for licensing details.

ad_page_contract {
    Show the list of current task and allow the project
    manager to create new tasks.

    @author frank.bergmann@project-open.com
    @creation-date Nov 2003
} {
    { bread_crum_path "" }
}


# oacs_util::vars_to_ns_set -ns_set ns_set -var_list var_list

set url_vars [info vars {[a-z]*}]
set bind_vars [ns_set create]
foreach var $url_vars { 
    set value [expr $$var]
    ns_log Notice "/intranet-filestorage/index: $var=$value"
    # Remove the "parse_level" variable (what is it for???)
    if {[regexp {^parse_level} $var]} { continue }
    # don't include variables with empty value
    if {"" == $value} { continue }
    ns_set put $bind_vars $var $value
}

set user_id [ad_maybe_redirect_for_registration]
set return_url [im_url_with_query]
set current_url_without_vars [ns_conn url]

ns_log Notice "---dins la pagina index"
set html [im_filestorage_home_component $user_id $current_url_without_vars $return_url $bind_vars]

doc_return  200 text/html $html
db_release_unused_handles
# ad_returnredirect "/intranet/"



