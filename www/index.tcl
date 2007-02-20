# /packages/intranet-wiki/www/index.tcl
#
# Copyright (C) 2003-2004 Project/Open
#
# All rights reserved. Please check
# http://www.project-open.com/ for licensing details.

ad_page_contract {
    Show the list of current task and allow the project
    manager to create new tasks.

    @author fraber@project-open.com
    @creation-date Nov 2003
} {

}

set user_id [auth::require_login]
set return_url "[ad_conn url]?[ad_conn query]"
set parent_var :folder_id
set page_title "Active Wikis"

# Redirect to wiki if there is exactly one..
set folder_ids [db_list folder_ids "
	select f.folder_id 
	from apm_packages p, cr_folders f 
	where	p.package_id = f.package_id 
		and p.package_key = 'wiki'
"]

if {[llength $folder_ids] == 1} {
    set folder_id [lindex $folder_ids 0]
    ad_returnredirect [export_vars -base "/wiki/admin/index?" {folder_id}]
    ad_script_abort
}



set wiki_component [im_wiki_home_component]
    
# Get the list of currently existing Wiki installations
set wikis_sql "
        select
                ap.package_id,
                cf.folder_id,
		ci.name,
                sn.name as wiki_mount
        from
                apm_packages ap,
                cr_folders cf,
                cr_items ci,
                cr_revisions cr,
                site_nodes sn
        where
                ap.package_key = 'wiki'
                and cf.package_id = ap.package_id
                and ci.parent_id = cf.folder_id
                and cr.revision_id = ci.live_revision
                and sn.object_id = ap.package_id
	order by lower(ci.name)
"

set ctr 0
set page_list "
<table>
<tr class=rowtitle>
  <td class=rowtitle>Wiki</td>
  <td class=rowtitle>Page</td>
</tr>
"
db_foreach wikis $wikis_sql {

    append page_list "
<tr class=roweven>
  <td>$wiki_mount</td>
  <td>
    <a href=\"/$wiki_mount/[ns_urlencode $name]\">$name</a>
  </td>
</tr>\n"
    incr ctr
}

if {0 == $ctr} {
    append page_list "<tr><td colspan=99>No Wiki Pages</td></tr>\n"
}

append page_list "
</table>
"

