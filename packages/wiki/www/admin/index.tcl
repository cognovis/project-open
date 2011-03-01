ad_page_contract {
    List contents of a folder
    List path of this folder
    List path of any symlinks to this folder


    @author Michael Steigman
    @author Frank Bergmann (frank.bergmann@project-open.com)
    @creation-date April 2005
} {
    folder_id:integer
    { mount_point "sitemap" }
    { parent_id:integer ""}
    { orderby "latest_publish_date,desc" }
    { page:optional }
    { modified_only 0 }
}

set original_folder_id $folder_id
set user_id [auth::require_login]
set root_id [cm::modules::${mount_point}::getRootFolderID]
set return_url "[ad_conn url]?[ad_conn query]"
set parent_var :folder_id

permission::require_permission -party_id $user_id \
	    -object_id $folder_id -privilege admin
    

# Where in the site map did we mount this wiki package?
# (The package may be mounted several times)

set wiki_mount_sql "
        select
                sn.name as wiki_mount
        from
                apm_packages ap,
                cr_folders cf,
                site_nodes sn
        where
		cf.folder_id = :folder_id
		and ap.package_id = cf.package_id
                and sn.object_id = ap.package_id
"

db_1row wiki_mount $wiki_mount_sql



# Show only the modified items?
set modified_only_where ""
if {$modified_only} {
    set modified_only_where "\tand i.latest_revision != i.live_revision\n"
}

    
# Resolve the symlink, if any
set resolved_id [db_string get_resolved_id ""]
    
if { $resolved_id != $folder_id } {
    set is_symlink t
    set item_id $resolved_id
    set what "Link"
} else {
    set is_symlink f
    set what "Folder"
}
    

db_1row get_info "" -column_array info
if { $info(parent_id) == 0  } {
    # at root; this will change once inheritance is set up for modules
    set parent_id ""
} else {
    set parent_id $info(parent_id)
}


# Get the index page ID
set index_page_id [db_string get_index_page_id ""]

set page_title "$info(label)"

# set actions "Attributes [export_vars -base attributes?mount_point=sitemap {folder_id}] \"Folder Attributes\""
set actions [list]

template::list::create \
    -name folder_items \
    -multirow folder_contents \
    -has_checkboxes \
    -key item_id \
    -page_size 100 \
    -page_query_name get_folder_contents_paginate \
    -actions $actions \
    -elements {
	title {
	    label "Wiki Page"
	    link_html { title "View this item"}
	    orderby title
	}

	live_preview {
	    label "Confirmed<br>Version"
	    link_html { title "View the latest confirmed version of this item"}
	    link_url_col live_preview_url
	}
	live_publish_date {
	    label "Confirmation<br>Date"
	    display_eval { [lc_time_fmt $live_publish_date "%y-%m-%d"] }
	    orderby u.publish_date
	}
	live_size {
	    label "Confirmed<br>Size"
	}


	latest_preview {
	    label "New<br>Version"
	    link_html { title "View the latest version of this item"}
	    link_url_col latest_preview_url
	}
	latest_publish_date {
	    label "New<br>Date"
	    display_eval { [lc_time_fmt $latest_publish_date "%y-%m-%d"] }
	    orderby v.publish_date
	}
	latest_size {
	    label "New<br>Size"
	}

	latest_creation_user_name {
	    label "Modified by"
	    link_html { title "More information about this user"}
	    link_url_col latest_creation_user_url
	    orderby latest_creation_user_name
	}
	cancel_action {
	    label "Revert"
	    link_html { title "Revert to last confirmed value"}
	    link_url_col cancel_action_url
	}
	confirm_action {
	    label "Confirm"
	    link_html { title "Confirm the new revision"}
	    link_url_col confirm_action_url
	}
	delete_action {
	    label "Delete"
	    link_html { title "Delete the item with all revisions"}
	    link_url_col delete_action_url
	}
    } \
    -filters {
	folder_id {}
	parent_id {} 
	mount_point {}
    }

db_multirow -extend { item_url latest_size live_size cancel_action confirm_action cancel_action_url delete_action delete_action_url confirm_action_url live_preview latest_preview live_preview_url latest_preview_url cms_admin_url latest_creation_user_url } folder_contents get_folder_contents "" {

    set cancel_action "Revert"
    set cancel_action_url [export_vars -base "update_latest_revision?item_id=$item_id&revision_id=$live_revision_id" { return_url} ]
    set confirm_action "Confirm"
    set confirm_action_url [export_vars -base "update_live_revision?item_id=$item_id&revision_id=$latest_revision_id" { return_url} ]
    set delete_action "Delete"
    set delete_action_url [export_vars -base "delete?item_id=$item_id&revision_id=$latest_revision_id" { return_url} ]

    set latest_preview "New"
    set latest_preview_url "/$wiki_mount/[ns_urlencode $name]"
    set live_preview "Confirmed"
    set live_preview_url "/$wiki_mount/[ns_urlencode $name]?revision_id=$live_revision_id"
    set cms_admin_url "/cms/modules/items/index?item_id=$item_id"
    set latest_creation_user_url "/intranet/users/view?user_id=$latest_creation_user"

    switch $content_type {
	content_folder {
	    set folder_id $item_id
	    set item_url [export_vars -base index?mount_point=sitemap { folder_id parent_id }]
	}
	default {
	    set item_url [export_vars -base /$wiki_mount/[ns_urlencode $name]]
	}
    }

    if { ![ template::util::is_nil content_length ] } {
	set live_size [lc_numeric [expr $live_length / 1000.00] "%.2f"]
    } else {
	set live_size "-"
    }

    if { ![ template::util::is_nil content_length ] } {
	set latest_size [lc_numeric [expr $latest_length / 1000.00] "%.2f"]
    } else {
	set latest_size "-"
    }

}



#    set item_url [export_vars -base /cms/modules/items/index?mount_point=sitemap { item_id revision_id parent_id }]
