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

permission::require_permission -party_id $user_id \
	    -object_id $folder_id -privilege admin
    
set parent_var :folder_id


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
    -page_size 50 \
    -page_query_name get_folder_contents_paginate \
    -actions $actions \
    -elements {
	title {
	    label "Name"
	    link_html { title "View this item"}
	    link_url_col item_url
	    orderby title
	}
	live_size {
	    label "Live Size"
	}
	live_publish_date {
	    label "Live Date"
	    display_eval { [lc_time_fmt $live_publish_date "%y-%m-%d %H:%M"] }
	    orderby u.publish_date
	}
	latest_size {
	    label "Latest Size"
	}
	latest_publish_date {
	    label "Latest Date"
	    display_eval { [lc_time_fmt $latest_publish_date "%y-%m-%d %H:%M"] }
	    orderby v.publish_date
	}
	latest_creation_user {
	    label "Latest Creation User"
	}
    } \
    -filters {
	folder_id {}
	parent_id {} 
	mount_point {}
    }

set wiki_mount "l10n-pm"

db_multirow -extend { item_url latest_size live_size } folder_contents get_folder_contents "" {
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
