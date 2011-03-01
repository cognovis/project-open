# /packages/intranet-wiki/www/index.tcl
#
# Copyright (C) 2003 - 2009 ]project-open[
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

# ----------------------------------------------------
# Show pages

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
		and 't' = acs_permission__permission_p(ap.package_id, :user_id, 'read')
	order by lower(ci.name)
"

set ctr 0
set page_list "
<table class='table_list_page'>
<thead>
<tr class=rowtitle>
  <td class=rowtitle>Wiki</td>
  <td class=rowtitle>Page</td>
</tr>
</thead>
<tbody>
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
</tbody>
</table>
"

