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
    bread_crum_path:optional
}

if { ![info_exists bread_crum_path] } {

    set url "/intranet/"
} else {
    
    set url "/intranet/index.tcl?bread_crum_path=$bread_crum_path"

}


db_release_unused_handles
ad_returnredirect "$url"
#ad_returnredirect "/intranet/"



