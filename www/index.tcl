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


