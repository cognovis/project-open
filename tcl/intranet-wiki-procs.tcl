# /tcl/intranet-wiki-procs.tcl

ad_library {
    Wiki Interface Library
    @author frank.bergmann@project-open.com
    @creation-date  27 April 2005
}

ad_proc im_wiki_home_component { } {
    Wiki component to be shown at the system home page
} {
    set folder_id [wiki::get_folder_id]
    set colspan 1
	
    # Get the list of currently existing Wiki installations
    set wikis_sql "
	select
		ap.package_id,
		cf.folder_id,
		cr.title
	from
		apm_packages ap,
		cr_folders cf,
		cr_items ci,
		cr_revisions cr
	where
		ap.package_key = 'wiki'
		and cf.package_id = ap.package_id
		and ci.parent_id = cf.folder_id
		and ci.name = 'index'
		and cr.revision_id = ci.live_revision
    "
    set wikis_html ""
    db_foreach wikis $wikis_sql {
	append wikis_html "<tr><td>
	  <A href="$package_id>$title</a>
	</td></tr>\n"
    }

    set html "
<table>
<tr>
  <td colspan=$colspan>
    &nbsp;
  </td>
</tr>
<tr>
  <td class=rowtitle colspan=$colspan>Title</td>
</tr>
$wikis_html
</table>
"
  
    return [im_table_with_title "Wikis" $html]
}
