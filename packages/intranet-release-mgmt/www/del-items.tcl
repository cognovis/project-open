# /packages/intranet-release-mgmt/www/del-items.tcl
#
# Copyright (c) 2003-2007 ]project-open[
# All rights reserved.
#
# Author: frank.bergmann@project-open.com

ad_page_contract {
    Add a new release item to a project

    @author frank.bergmann@project-open.com
} {
    release_project_id:integer
    item_id:integer,multiple
    return_url
}

set user_id [ad_maybe_redirect_for_registration]
set page_title [lang::message::lookup "" intranet-release-mgmt.Release_Items "Release Items"]

im_project_permissions $user_id $release_project_id view read write admin
if {!$write} {
    ad_return_complaint 1 "<li>[_ intranet-core.lt_You_have_insufficient_6]"
    return
}

foreach pid $item_id {
    im_exec_dml del_release_item "im_release_item__delete(:release_project_id, :pid)"
}

ad_returnredirect $return_url
