# packages/intranet-search-pg/www/search.tcl
#
# Copyright (C) 1998-2004 various parties
# The code is based on ArsDigita ACS 3.4
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
    @author Neophytos Demetriou <k2pts@cytanet.com.cy>
    @author Frank Bergmann <frank.bergmann@project-open.com>
    @creation-date May 20th, 2005
    @cvs-id $Id$

    This search page uses the "TSearch2" full text index (FTI)
    and the P/O permission system to locate suitable business
    objects for a search query.<p>

    The main problem of searching in P/O is it's relatively
    strict permission system with object specific permissions
    that can only be tested via a (relatively slow) TCL routine.
    For example: Project are readable for the "key account"
    managers of the project's customer.<p>

    So this search page contains several performance optimizations:
    <ul>
    <li>Rapid exclusion of non-allowed objects:<br>
	A search query can return millions of object_id's in
	the worst case. Testing each of these objects for permission
	would take minutes or even hours.
	However, we can (frequently!) discard a large number of
	these objects when they are located in projects (or 
	companies, offices, ...) that are outside of the permission
	scope of the current user. This is why the "im_search_objects"
	table explicitely carries the "business_object_id".

    <li>Explicit permissions for specific "profiles":<br>
	Explicit permissions are given for certain user groups,
	most notably "Registered Users". So documents in a project
	folder that are marked as publicly readable can be found
	even if the project may not be readable at all.
    </ul>

} {
    {q:trim ""}
    {t:trim ""}
    {offset:integer 0}
    {results_per_page:integer 0}
    {type:multiple "all"}
    {include_deleted_p 0}
} 

# -----------------------------------------------------------
# Default & Security
# -----------------------------------------------------------

set user_id [ad_maybe_redirect_for_registration]
set current_user_id $user_id
set page_title "Search Results for \"$q\""
set package_id [ad_conn package_id]
set package_url [ad_conn package_url]
set package_url_with_extras $package_url
set context [list]
set context_base_url $package_url

# Determine the user's group memberships
set user_is_employee_p [im_user_is_employee_p $user_id]
set user_is_customer_p [im_user_is_customer_p $user_id]
set user_is_wheel_p [im_profile::member_p -profile_id [im_wheel_group_id] -user_id $user_id]
set user_is_admin_p [im_is_user_site_wide_or_intranet_admin $user_id]
set user_is_admin_p [expr $user_is_admin_p || $user_is_wheel_p]


if {"" == $q} {
    ad_return_complaint 1 [_ search.lt_You_must_specify_some]
}

if { $results_per_page <= 0} {
    set results_per_page [ad_parameter -package_id $package_id SearchResultsPerPage -default 20]
} else {
    set results_per_page $results_per_page
}

set limit [expr 100 * $results_per_page]

if {[lsearch im_document $type] >= 0} {
    ad_return_complaint 1 "<h3>Not implemented yet</h3>
    Sorry, searching for documents has not been implemented yet."
    return
}

set q [string tolower $q]

# Remove accents and other special characters from
# search query. Also remove "@", "-" and "." and 
# convert them to spaces
set q [db_exec_plsql normalize "select norm_text(:q)"]

set query $q
set nquery [llength $q]


# -------------------------------------------------
# Check if it's a simple query...
# -------------------------------------------------

set simple_query 1
if {$nquery > 1} {

    # Check that all keywords are alphanumeric
    foreach keyword $query {

	if {![regexp {^[a-zA-Z0-9]*$} $keyword]} {
	    set simple_query 0
	}
    }

}

# insert "&" between elements of a simple query
if {$simple_query && $nquery > 1} {
    set q [join $query " & "]
}

# -------------------------------------------------
# 
# -------------------------------------------------

if {$nquery > 1} {
    
    if {[catch {
	db_string test_query "select to_tsquery('default',:q)"
    } errmsg]} {
	ad_return_complaint 1 "<H2>Bad Query</h2>
        The <span class=brandsec>&\#93;</span><span class=brandfirst>project-open</span><span class=brandsec>&\#91;</span>
        search engine is capable of processing complex queries with more then
        one word. <br>
        However, you need to instruct the search engine how to search:
        <p>
        <ul>
          <li>Keyword1 <b>&</b> Keyword2:<br>
              Searches for objects that contain both keywords.<br>&nbsp;
          <li>Keyword1 <b>|</b> Keyword2:<br>
              Searches for objects that contain either of the two keywords.<br>&nbsp;
          <li><b>!</b>Keyword:<br>
              Searches for all object that DO NOT contain Keyword.<br>&nbsp;
          <li><b>(</b>Query<b>)</b>:<br>
              You can use parentesis to group queries.<br>&nbsp;
        </ul>
        
        <H3>Examples</h3>
	<ul>
	  <li><b>'project & open'</b>:<br>
	      Searches for all objects that contain both 'project' and 'open'.
	      <br>&nbsp;

	  <li><b>'project | open'</b>:<br>
	      Searches for all objects that contain either 'project' or 'open'.
	      <br>&nbsp;

	</ul>
        "

    }

}

set urlencoded_query [ad_urlencode $q]
if { $offset < 0 } { set offset 0 }
set t0 [clock clicks -milliseconds]


# -----------------------------------------------------------
# Prepare the list of searchable object types
# -----------------------------------------------------------

set sql "
	select
		sot.object_type_id,
		aot.object_type,
		aot.pretty_name as object_type_pretty_name,
		aot.pretty_plural as object_type_pretty_plural
	from
		im_search_object_types sot,
		acs_object_types aot
	where
		sot.object_type = aot.object_type
"

set objects_html ""
db_foreach object_type $sql {
    set checked ""
    if {[string equal $type "all"] || [lsearch $type $object_type] >= 0} {
	set checked " checked"
    }
    append objects_html "
	<tr>
	  <td>
	    <input type=checkbox name=type value='$object_type' $checked>
	  </td>
	  <td>
	    $object_type_pretty_plural
	  </td>
	</tr>
"
}


# -----------------------------------------------------------
# Permissions for different types of business objects
# -----------------------------------------------------------

# --------------------- Project -----------------------------------
set project_perm_sql "
			and p.project_id in (
			        select
			                p.project_id
			        from
			                im_projects p,
			                acs_rels r
			        where
			                r.object_id_one = p.project_id
			                and r.object_id_two = :current_user_id
			)"

if {[im_permission $user_id "view_projects_all"]} {
        set project_perm_sql ""
}

# --------------------- Companies ----------------------------------
set company_perm_sql "
			and c.company_id in (
			        select
			                c.company_id
			        from
			                im_companies c,
			                acs_rels r
			        where
			                r.object_id_one = c.company_id
			                and r.object_id_two = :current_user_id
					and c.company_status_id not in ([im_company_status_deleted])
			)"

if {[im_permission $user_id "view_companies_all"]} {
        set company_perm_sql "
			and c.company_status_id not in ([im_company_status_deleted])
	"
}


# --------------------- Invoices -----------------------------------
# Let a user see the invoice if he can read/admin either the 
# customer or the provider of the invoice
# Include the join with "im_invoices", because it is actually
# very selective (few cost items are financial documents)


set customer_sql "
	select distinct
		c.company_id
	from
		im_companies c,
		acs_rels r
	where
		c.company_type_id in ([join [im_sub_categories [im_company_type_customer]] ","])
		and r.object_id_one = c.company_id
		and r.object_id_two = :current_user_id
		and c.company_path != 'internal'
"
if {![im_user_is_customer_p $user_id]} { set customer_sql "select 0 as company_id" }


set provider_sql "
	select distinct
		c.company_id
	from
		im_companies c,
		acs_rels r
	where
		c.company_type_id in ([join [im_sub_categories [im_company_type_provider]] ","])
		and r.object_id_one = c.company_id
		and r.object_id_two = :current_user_id
		and c.company_path != 'internal'
"
if {![im_user_is_freelance_p $user_id]} { set provider_sql "select 0 as company_id" }


set invoice_perm_sql "
			and i.invoice_id in (
				select
					i.invoice_id
				from
					im_invoices i,
					im_costs c
				where
					i.invoice_id = c.cost_id
					and (
					    c.customer_id in ($customer_sql)
					OR
					    c.provider_id in ($provider_sql)
					)
			)"

if {[im_permission $user_id "view_invoices"]} {
	set invoice_perm_sql ""
}

# ad_return_complaint 1 $invoice_perm_sql



# --------------------- Users -----------------------------------
# The list of prohibited users: They belong 
# to a group which the current user should not see
set user_perm_sql "
			and person_id not in (
select distinct
	cc.user_id
from
	cc_users cc,
	(
		select  group_id
		from    groups
		where   group_id > 0
			and 'f' = im_object_permission_p(group_id,8849,'read')
	) forbidden_groups,
	group_approved_member_map gamm
where
	cc.user_id = gamm.member_id
	and gamm.group_id = forbidden_groups.group_id
			)"

if {[im_permission $user_id "view_users_all"]} {
	set user_perm_sql ""
}

# user_perm_sql is very slow (~20 seconds), so
# just leave the permission check for later...
set user_perm_sql ""

# Don't show deleted users (by default...)
set deleted_users_sql "
	and p.person_id not in (
		select	m.member_id
		from	group_member_map m, 
			membership_rels mr
		where  	m.group_id = acs__magic_object_id('registered_users') 
		  	AND m.rel_id = mr.rel_id 
		  	AND m.container_id = m.group_id 
		  	AND m.rel_type::text = 'membership_rel'
			AND mr.member_state != 'approved'
	)
"
if {1 == $include_deleted_p} {
    set deleted_users_sql ""
}


# --------------------- Files -----------------------------------
set file_perm_sql "
			and p.file_id in (
			        select
			                p.file_id
			        from
			                im_files p,
			                acs_rels r
			        where
			                r.object_id_one = p.file_id
			                and r.object_id_two = :current_user_id
			)"

if {[im_permission $user_id "view_projects_all"]} {
        set file_perm_sql ""
}




# --------------------- Forums -----------------------------------
set forum_perm_sql ""



# -----------------------------------------------------------
# Build a suitable select for object types
# -----------------------------------------------------------

foreach t $type { lappend types "'$t'"} 
set object_type_where "object_type in ([join $types ","])"
if {[string equal "all" $type]} {
    set object_type_where "1=1"
}


# -----------------------------------------------------------
# Main SQL
# -----------------------------------------------------------

set sql "
	select
		acs_object__name(so.object_id) as name,
		acs_object__name(so.biz_object_id) as biz_object_name,
		(rank(so.fti, :q::tsquery) * sot.rel_weight)::numeric(12,2) as rank,
		fti as full_text_index,
		bou.url,
		so.object_id,
		sot.object_type,
		aot.pretty_name as object_type_pretty_name,
		so.biz_object_id,
		so.popularity,
		readable_biz_objs.object_type as biz_object_type
	from
		im_search_objects so,
		acs_object_types aot,
		(	select	*
			from	im_search_object_types 
			where	$object_type_where
		) sot
		left outer join (
			select	*
			from	im_biz_object_urls
			where	url_type = 'view'
		) bou on (sot.object_type = bou.object_type),
		(
			select	project_id as object_id,
				'im_project' as object_type
			from	im_projects p
			where	1=1
				$project_perm_sql
		    UNION
			select	company_id as object_id,
				'im_company' as object_type
			from	im_companies c
			where	1=1
				$company_perm_sql
		    UNION
			select	invoice_id as object_id,
				'im_invoice' as object_type
			from	im_invoices i
			where	1=1
				$invoice_perm_sql
		    UNION
			select	person_id as object_id,
				'user' as object_type
			from	persons p
			where	1=1
				$deleted_users_sql
				$user_perm_sql
                    UNION
                        select  item_id as object_id,
                                'content_item' as object_type
                        from    cr_items c
                        where   1=1
		) readable_biz_objs
	where
		so.object_type_id = sot.object_type_id
		and sot.object_type = aot.object_type
		and so.biz_object_id = readable_biz_objs.object_id
		and so.fti @@ to_tsquery('default',:q)
	order by
		(rank(so.fti, :q::tsquery) * sot.rel_weight) DESC
	offset :offset
	limit :limit
"

set high 0
set count 0
set result_html ""

db_foreach full_text_query $sql {

    incr count

    # Skip further permissions checking if we reach the
    # maximum number of records. However, keep on counting
    # until "limit" in order to get an idea of the total
    # number of results
    if {$count > $results_per_page} {
	continue
    }

    set name_link $name
    if {"" != $url} {
	set name_link "<a href=\"$url$object_id\">$name</a>\n"
    }
    
    set text [im_tsvector_to_headline $full_text_index]
    set headline [db_string headline "select headline(:text, :q::tsquery)" -default ""]

    # Final permission test: Make sure no object slips through security
    # even if it's kind of slow to do this iteratively...
    switch $object_type {
	im_project { 
	    im_project_permissions $user_id $object_id view read write admin
	    if {!$read} { continue }
	}
	user { 
	    im_user_permissions $user_id $object_id view read write admin
	    if {!$read} { continue }
	}
	im_fs_file { 
	    # The file is readable if it's business object is readable
	    # AND if the folder is readable

	    # Very ugly: The biz_object_id is not checked for "user"
	    # because it is very slow... So check it here now.
	    if {"user" == $biz_object_type} {
		im_user_permissions $user_id $biz_object_id view read write admin
		if {!$read} { continue }
	    }

	    # Determine if the current user belongs to the admins of
	    # the "business object". This allows to skip any other permission
	    # checks.
	    set object_admin_sql "
				( select count(*) 
				  from	acs_rels r,
					im_biz_object_members m
				  where	r.object_id_two = :current_user_id
					and r.object_id_one = :biz_object_id
					and r.rel_id = m.rel_id
					and m.object_role_id in (1301, 1302, 1303)
				)::integer\n"
	    if {$user_is_admin_p} { set object_admin_sql "1::integer\n" }

	    # Determine the permissions for the file
	    db_1row forum_perm "
		select
			f.filename,
			'1' as file_permission_p
		from
			im_fs_files f
		where
			f.file_id = :object_id
	    "
	    if {!$file_permission_p} { continue }

	    # Only with files - biz_object_id==0 means Home Filestorage
#	    if {0 == $biz_object_id} { set biz_object_name [lang::message::lookup "" intranet-fs.Home_Filestorage "Home Filestorage"] }

	    set name_link "<a href=\"$url$object_id\">$biz_object_name: $filename</a>\n"
	}
	im_forum_topic { 
	    # The topic is readable if it's business object is readable
	    # AND if the user belongs to the right "sphere"

	    # Very ugly: The biz_object_id is not checked for "user"
	    # because it is very slow... So check it here now.
	    if {"user" == $biz_object_type} {
		im_user_permissions $user_id $biz_object_id view read write admin
		if {!$read} { continue }
	    }

	    # Determine if the current user belongs to the admins of
	    # the "business object". This is necessary, because there
	    # is the forum permission "PM Only" which gives rights only"
	    # to the (project) managers of the of the container biz object
	    set object_admin_sql "
				( select count(*) 
				  from	acs_rels r,
					im_biz_object_members m
				  where	r.object_id_two = :current_user_id
					and r.object_id_one = :biz_object_id
					and r.rel_id = m.rel_id
					and m.object_role_id in (1301, 1302, 1303)
				)::integer\n"
	    if {$user_is_admin_p} { set object_admin_sql "1::integer\n" }

	    # 070802 fraber: This line fixes a rare situation where
	    # the im_search_objects contains a forum line that doesn't exist.
	    # However, I couldn't reproduce how the line got there.
	    set forum_permission_p 0

	    # Determine the permissions for the forum item
	    db_0or1row forum_perm "
		select
			t.subject,
			im_forum_permission(
				:current_user_id::integer,
				t.owner_id,
				t.asignee_id,
				t.object_id,
				t.scope,
				1::integer,
				$object_admin_sql ,
				:user_is_employee_p::integer,
				:user_is_customer_p::integer
			) as forum_permission_p
		from
			im_forum_topics t
		where
			t.topic_id = :object_id
	    "
	    if {!$forum_permission_p} { continue }
	    set name_link "<a href=\"$url$object_id\">$biz_object_name: $subject</a>\n"

	}
	content_item {
	    db_1row content_item_detail "
               select	name, content_type
               from	cr_items 
               where	item_id = :object_id
            "
	    switch $content_type {
		"content_revision" {
		    # Wiki
		    set read_p [permission::permission_p \
				    -object_id $object_id \
				    -party_id $user_id \
				    -privilege "read" ]

		    if {!$read_p} { continue }
		    set name_link "<a href=\"/wiki/$name\">wiki: $name</a>\n"
		} 
		"workflow_case_log_entry" {
		    # Bug-Tracker
		    set bug_number [db_string bug_from_cr_item "
                        select bug_number from bt_bugs,cr_items where item_id=:object_id and cr_items.parent_id=bug_id
                    "]
		    if {!$bug_number} { continue }
		    set name_link "<a href=\"/bug-tracker/bug?bug_number=$bug_number\">bug: $bug_number $name</a>"
		}
		"::xowiki::Page" {
		    set page_name ""
		    set package_mount ""
		    db_0or1row page_info "
			select  s.name as package_mount,
				i.name as page_name
			from
			        cr_items i,
			        cr_folders f,
			        apm_packages p,
			        site_nodes s
			where
			        i.item_id = :object_id and
			        i.parent_id = f.folder_id and
			        f.package_id = p.package_id and
			        p.package_id = s.object_id
		    "
		    set name_link "<a href=\"/$package_mount/$page_name\">$page_name</a>"
		    set object_type_pretty_name "XoWiki Page"
		}
		default {
		    set name_link "unknown content_item type: $content_type"
		}
	    }
	}
    }

    # Render the object.
    # With some objects we want to show more information...
    switch $object_type {
	im_project - im_ticket - im_timesheet_task {
	    set parent_name ""
	    set parent_id ""
	    db_0or1row parent_info "
		select	parents.project_name as parent_name,
			parents.project_id as parent_id
		from	im_projects parents,
			im_projects children
		where	parents.project_id = children.parent_id and
			children.project_id = :object_id
	    "
	    set parent_html "<font>[lang::message::lookup "" intranet-search-pg.Parent "Parent"]: <a href=\"[export_vars -base "/intranet/projects/view" {{project_id $parent_id}}]\">$parent_name</a></font><br>\n"
	    if {"" == $parent_name} { set parent_html "" }
	    append result_html "
	      <tr>
		<td>
		  <font>$object_type_pretty_name: $name_link</font><br>
		  $parent_html
		  $headline
		  <br>&nbsp;
		</td>
	      </tr>
	    "
	}
	default {
	    append result_html "
	      <tr>
		<td>
		  <font>$object_type_pretty_name: $name_link</font><br>
		  $headline
		  <br>&nbsp;
		</td>
	      </tr>
	    "
	}
    }
}


set tend [clock clicks -milliseconds]
set elapsed [format "%.02f" [expr double(abs($tend - $t0)) / 1000.0]]

set num_results [expr $offset + $count]

set from_result_page 1
set current_result_page [expr ($offset / $results_per_page) + 1]
set to_result_page [expr ceil(double($num_results) / double($results_per_page))]


set result_page_html ""

for {set i $from_result_page} {$i <= $to_result_page} { incr i } {
    set page_offset [expr ($i-1) * $results_per_page]
    set url "search?q=${urlencoded_query}&offset=$page_offset"
    if {$i == $current_result_page} {
	append result_page_html "$i "
    } else {
	append result_page_html "<a href=\"$url\">$i</a> "
    }
}


set url_previous ""
set url_next ""
append url_previous "search?q=${urlencoded_query}"
append url_next "search?q=${urlencoded_query}"
if { [expr $current_result_page - 1] > $from_result_page } { 
    append url_previous "&offset=[expr ($current_result_page - 2) * $results_per_page]"
}
if { $current_result_page < $to_result_page } { 
    append url_next "&offset=[expr $current_result_page * $results_per_page]"
}
if { $results_per_page > 0 } {
    append url_previous "&results_per_page=$results_per_page"
    append url_next "&results_per_page=$results_per_page"
}


