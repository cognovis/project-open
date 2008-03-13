# /packages/intranet-search-pg-files/www/reindex-biz-object.tcl
#
# Copyright (C) 2008 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.


ad_page_contract {
    Show files that are not indexed by the FTS
    @author frank.bergmann@project-open.com
} {
    object_id:integer,multiple
    return_url
}



# ------------------------------------------------------
# Defaults & Security
# ------------------------------------------------------

set user_id [ad_maybe_redirect_for_registration]
set user_is_admin_p [im_is_user_site_wide_or_intranet_admin $user_id]
if {!$user_is_admin_p} {
    ad_return_complaint 1 "You have insufficient privileges to use this page"
    return
}

set errors [list]
foreach oid $object_id {
    set result [intranet_search_pg_files_index_object -object_id $oid]
    set err [lindex $result 1]
    foreach e $err { lappend errors $e}
}
ad_return_complaint 1 "<pre>[join $errors "<br>"]</pre>"

ad_returnredirect $return_url