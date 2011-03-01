# /packages/intranet-search-pg-files/www/index.tcl
#
# Copyright (C) 2006 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.


ad_page_contract {
    Show files that are not indexed by the FTS
    @author frank.bergmann@project-open.com
} {
    { return_url "" }
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


set page_title "Full-Text Index Status"
set context_bar [im_context_bar $page_title]
set context ""

set return_url [im_url_with_query]

# ------------------------------------------------------
# Get the list and status of all indexed files 
# ------------------------------------------------------

set list_id "biz_objects"
set export_var_list [list]
set bulk_actions_list [list Reindex reindex-biz-object]

template::list::create \
    -name $list_id \
    -multirow biz_objects_multirow \
    -key object_id \
    -bulk_actions $bulk_actions_list \
    -bulk_action_export_vars { return_url } \
    -bulk_action_method POST \
    -row_pretty_plural "[_ intranet-core.File]" \
    -elements {
	object_type_pretty {
	    label "Type"
	}
	object_name {
	    label "Object"
	    link_url_eval $object_url
	}
	indexed_objects {
	    label "Indexed<br>Objects"
	}
	last_update_pretty {
	    label "Last Indexed"
	}
    }

db_multirow -extend { object_url object_reindex_url reindex } biz_objects_multirow biz_objects_query "
	select	o.*,
		ou.url as object_base_url,
		ot.pretty_name as object_type_pretty,
		acs_object__name(o.object_id) as object_name,
		to_char(bo.last_update, 'YYYY-MM-DD HH24:MI') as last_update_pretty,
		(
			select	count(*) 
			from	im_search_objects so
			where	so.biz_object_id = bo.object_id
				and so.object_type_id = 6
		) as indexed_objects
	from	im_search_pg_file_biz_objects bo,
		acs_objects o,
		acs_object_types ot
		LEFT OUTER JOIN (
			select	*
			from	im_biz_object_urls
			where	url_type = 'view'
		) ou ON (ot.object_type = ou.object_type)
	where
		bo.object_id = o.object_id
		and o.object_type = ot.object_type
	order by
		o.object_type
" {
	set object_url "$object_base_url$object_id"
	if {"" == $object_base_url} { set object_url "" }

	set reindex "Reindex"
	set return_url [im_url_with_query]
	set object_reindex_url [export_vars -base "/intranet-search-pg-files/reindex-biz-object" {object_id return_url}]
}


# ------------------------------------------------------
# Get the list and status of all indexed files 
# ------------------------------------------------------

set list_id "file_list"
set export_var_list [list]
set bulk_actions_list [list]

template::list::create \
    -name $list_id \
    -multirow file_lines \
    -key file_id \
    -has_checkboxes \
    -bulk_actions $bulk_actions_list \
    -bulk_action_export_vars  {
	file_id
    } \
    -row_pretty_plural "[_ intranet-core.File]" \
    -elements {
	object_name {
	    label "Object"
	}
	folder_path {
	    label "Folder"
	}
	filename {
	    label "File"
	}
	last_updated {
	    label "Last Updated"
	}
	last_modified {
	    label "Last Modified"
	}
	ft_indexed_p {
	    label "FTI?"
	}
    }

db_multirow -extend {file_chk} file_lines file_lines "
	select	ff.path as folder_path,
		ff.object_id,
		acs_object__name(ff.object_id) as object_name,
		f.file_id,
		f.filename,
		f.last_modified,
		f.last_updated::date as last_updated,
		f.ft_indexed_p
	from
		im_fs_folders ff,
		im_fs_files f,
		acs_objects o
	where
		f.folder_id = ff.folder_id
		and ff.object_id = o.object_id
	order by
		o.object_type,
		ff.object_id,
		ff.path,
		f.filename
" {
    set file_chk "<input type=\"checkbox\" name=\"file_id\" value=\"$file_id\" id=\"file_list,$file_id\">"
}


