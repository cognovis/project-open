# /packages/intranet-release-mgmt/www/add-items.tcl
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
    project_id:integer,multiple
    return_url
    { release_status_id "[im_release_mgmt_status_default]" }
}

set user_id [ad_maybe_redirect_for_registration]
set page_title [lang::message::lookup "" intranet-release-mgmt.Release_Items "Release Items"]

# -------------------------------------------------------------
# Permissions
#
# The project admin (=> Release Manager) can do everything.
# The managers of the individual Release Items can change 
# _their_ release stati.

im_project_permissions $user_id $release_project_id view read write admin
if {!$write} {
    ad_return_complaint 1 "<li>[_ intranet-core.lt_You_have_insufficient_6]"
    return
}

foreach pid $project_id {

    set exists_p [db_string count "
	select	count(*)
	from	im_release_items i,
		acs_rels r
	where
		i.rel_id = r.rel_id
		and r.object_id_one = :release_project_id
		and r.object_id_two = :pid
    "]

    if {!$exists_p} {

	    set max_sort_order [db_string max_sort_order "
	        select  coalesce(max(i.sort_order),0)
	        from    im_release_items i,
	                acs_rels r
	        where
	                i.rel_id = r.rel_id
	                and r.object_id_one = :release_project_id
	    " -default 0]

	    db_string add_user "
		select im_release_item__new (
			null,
			'im_release_item',
			:release_project_id,
			:pid,
			null,
			:user_id,
			'[ad_conn peeraddr]',
			:release_status_id,
                        [expr $max_sort_order + 10]
		)
	    "
    }
}

ad_returnredirect $return_url
